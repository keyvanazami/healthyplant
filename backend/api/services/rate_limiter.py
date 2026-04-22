"""AI request rate limiting — per-user daily and lifetime counters in Firestore.

All limits are env vars — adjust in Cloud Run without redeploying:

    AI_CHAT_DAILY_LIMIT      — chat messages per user per day    (default: 20)
    AI_SCAN_DAILY_LIMIT      — plant scans per user per day      (default: 10)
    AI_CALENDAR_DAILY_LIMIT  — calendar generations per day      (default: 5)

    AI_CHAT_MAX_LIMIT        — lifetime chat cap for free users  (default: 500)
    AI_SCAN_MAX_LIMIT        — lifetime scan cap for free users  (default: 500)
    AI_CALENDAR_MAX_LIMIT    — lifetime calendar cap             (default: 500)

Premium users (isPremium: true on the user root doc) bypass all limits.

Firestore layout:
    users/{userId}                         — isPremium: bool
    users/{userId}/ai_usage/{YYYY-MM-DD}   — daily counters
    users/{userId}/ai_usage/total          — lifetime counters
        chatCount:     int
        scanCount:     int
        calendarCount: int
"""

import logging
import os
from datetime import datetime, timezone

from fastapi import HTTPException

logger = logging.getLogger(__name__)

# ── Daily limits ─────────────────────────────────────────────────────────────
DAILY_LIMITS: dict[str, int] = {
    "chat":     int(os.getenv("AI_CHAT_DAILY_LIMIT",     "20")),
    "scan":     int(os.getenv("AI_SCAN_DAILY_LIMIT",     "10")),
    "calendar": int(os.getenv("AI_CALENDAR_DAILY_LIMIT", "5")),
}

# ── Lifetime caps (free tier) ─────────────────────────────────────────────────
MAX_LIMITS: dict[str, int] = {
    "chat":     int(os.getenv("AI_CHAT_MAX_LIMIT",     "500")),
    "scan":     int(os.getenv("AI_SCAN_MAX_LIMIT",     "500")),
    "calendar": int(os.getenv("AI_CALENDAR_MAX_LIMIT", "500")),
}

FIELD: dict[str, str] = {
    "chat":     "chatCount",
    "scan":     "scanCount",
    "calendar": "calendarCount",
}


def _today() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


async def check_and_increment(db, user_id: str, category: str) -> None:
    """Check daily + lifetime limits, then increment both counters.

    Premium users (isPremium=true on user doc) bypass all checks.
    Raises HTTP 429 when a limit is reached.
    """
    daily_limit = DAILY_LIMITS[category]
    max_limit = MAX_LIMITS[category]
    field = FIELD[category]

    user_ref = db.collection("users").document(user_id)
    daily_ref = user_ref.collection("ai_usage").document(_today())
    total_ref = user_ref.collection("ai_usage").document("total")

    user_snap, daily_snap, total_snap = await db.get_all([user_ref, daily_ref, total_ref])

    daily_data = daily_snap.to_dict() if daily_snap.exists else {}
    total_data = total_snap.to_dict() if total_snap.exists else {}

    # Premium users skip all limits
    if (user_snap.to_dict() or {}).get("isPremium", False):
        await daily_ref.set({field: daily_data.get(field, 0) + 1}, merge=True)
        await total_ref.set({field: total_data.get(field, 0) + 1}, merge=True)
        return

    daily_count = daily_data.get(field, 0)
    total_count = total_data.get(field, 0)

    if total_count >= max_limit:
        raise HTTPException(
            status_code=429,
            detail=f"Lifetime {category} limit of {max_limit} reached. Upgrade to premium for unlimited access.",
        )
    if daily_count >= daily_limit:
        raise HTTPException(
            status_code=429,
            detail=f"Daily {category} limit of {daily_limit} reached. Try again tomorrow.",
        )

    await daily_ref.set({field: daily_count + 1}, merge=True)
    await total_ref.set({field: total_count + 1}, merge=True)

    logger.debug(f"[RateLimit] {user_id} {category} incremented")


async def get_usage(db, user_id: str) -> dict:
    """Return today's usage, lifetime usage, limits, and premium status."""
    user_ref = db.collection("users").document(user_id)
    daily_ref = user_ref.collection("ai_usage").document(_today())
    total_ref = user_ref.collection("ai_usage").document("total")

    user_snap, daily_snap, total_snap = await db.get_all([user_ref, daily_ref, total_ref])

    daily = daily_snap.to_dict() if daily_snap.exists else {}
    total = total_snap.to_dict() if total_snap.exists else {}
    is_premium = (user_snap.to_dict() or {}).get("isPremium", False)

    return {
        "date": _today(),
        "isPremium": is_premium,
        "dailyLimits": DAILY_LIMITS,
        "maxLimits": MAX_LIMITS,
        "dailyUsage": {
            "chat":     daily.get("chatCount", 0),
            "scan":     daily.get("scanCount", 0),
            "calendar": daily.get("calendarCount", 0),
        },
        "totalUsage": {
            "chat":     total.get("chatCount", 0),
            "scan":     total.get("scanCount", 0),
            "calendar": total.get("calendarCount", 0),
        },
    }
