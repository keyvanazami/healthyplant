"""AI request rate limiting — per-user daily counters stored in Firestore.

Limits are read from environment variables so you can adjust them in Cloud Run
without redeploying code:

    AI_CHAT_DAILY_LIMIT      — chat messages per user per day    (default: 20)
    AI_SCAN_DAILY_LIMIT      — plant scans per user per day      (default: 10)
    AI_CALENDAR_DAILY_LIMIT  — calendar generations per day      (default: 5)

Usage is tracked in:
    users/{userId}/ai_usage/{YYYY-MM-DD}
        chatCount:     int
        scanCount:     int
        calendarCount: int
"""

import logging
import os
from datetime import datetime, timezone

from fastapi import HTTPException

logger = logging.getLogger(__name__)

# ── Configurable limits (set via Cloud Run env vars) ────────────────────────
LIMITS: dict[str, int] = {
    "chat":     int(os.getenv("AI_CHAT_DAILY_LIMIT",     "20")),
    "scan":     int(os.getenv("AI_SCAN_DAILY_LIMIT",     "10")),
    "calendar": int(os.getenv("AI_CALENDAR_DAILY_LIMIT", "5")),
}

FIELD: dict[str, str] = {
    "chat":     "chatCount",
    "scan":     "scanCount",
    "calendar": "calendarCount",
}


def _today() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


async def check_and_increment(db, user_id: str, category: str) -> None:
    """Check the daily limit for *category* and atomically increment the counter.

    Raises HTTP 429 if the limit is already reached.
    """
    limit = LIMITS[category]
    field = FIELD[category]
    doc_ref = (
        db.collection("users")
        .document(user_id)
        .collection("ai_usage")
        .document(_today())
    )

    # Captured outside the transaction callback so we can raise after
    limit_exceeded = False

    async def _txn(transaction):
        nonlocal limit_exceeded
        snapshot = await doc_ref.get(transaction=transaction)
        current = (snapshot.to_dict() or {}).get(field, 0)

        if current >= limit:
            limit_exceeded = True
            return  # Can't raise inside a transaction callback

        transaction.set(doc_ref, {field: current + 1}, merge=True)

    await db.run_async_transaction(_txn)

    if limit_exceeded:
        raise HTTPException(
            status_code=429,
            detail=f"Daily {category} limit of {limit} reached. Try again tomorrow.",
        )

    logger.debug(f"[RateLimit] {user_id} {category} incremented (limit={limit})")


async def get_usage(db, user_id: str) -> dict:
    """Return today's usage counts and limits for all AI categories."""
    doc_ref = (
        db.collection("users")
        .document(user_id)
        .collection("ai_usage")
        .document(_today())
    )
    snapshot = await doc_ref.get()
    data = snapshot.to_dict() if snapshot.exists else {}
    return {
        "date": _today(),
        "limits": LIMITS,
        "usage": {
            "chat":     data.get("chatCount", 0),
            "scan":     data.get("scanCount", 0),
            "calendar": data.get("calendarCount", 0),
        },
    }
