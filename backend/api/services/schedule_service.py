"""Deterministic schedule generator based on structured plant data.

Replaces AI-generated schedules for profiles that have wateringFrequencyDays
and/or sunHoursMin/sunHoursMax set. Falls back to AI for profiles without
structured data.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional, Tuple

logger = logging.getLogger(__name__)

# Sun reminders are generated weekly (every 7 days)
SUN_REMINDER_INTERVAL_DAYS = 7


def generate_deterministic_events(
    profiles: list,
    start_date: str,
    days_ahead: int = 30,
) -> Tuple[List[dict], List[dict]]:
    """
    Generate deterministic care events from structured plant profile data.

    For each profile with wateringFrequencyDays, creates needs_water events
    every N days. For profiles with sunHoursMin/sunHoursMax, creates weekly
    needs_sun reminder events.

    Args:
        profiles: List of plant profile dicts from Firestore.
        start_date: Start date as YYYY-MM-DD string.
        days_ahead: Number of days ahead to generate (default 30).

    Returns:
        Tuple of (deterministic_events, ai_fallback_profiles):
            - deterministic_events: List of event dicts for profiles with structured data
            - ai_fallback_profiles: List of profile dicts that need AI generation
    """
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = start + timedelta(days=days_ahead)

    deterministic_events: List[dict] = []
    ai_fallback_profiles: List[dict] = []

    for profile in profiles:
        profile_id = profile.get("id", "")
        plant_name = profile.get("name", "Unknown")
        freq = profile.get("wateringFrequencyDays")
        sun_min = profile.get("sunHoursMin")
        sun_max = profile.get("sunHoursMax")

        has_structured_data = freq is not None or (
            sun_min is not None and sun_max is not None
        )

        if not has_structured_data:
            ai_fallback_profiles.append(profile)
            continue

        # Generate watering events every N days
        if freq is not None and freq > 0:
            current = start
            while current < end:
                deterministic_events.append({
                    "profileId": profile_id,
                    "plantName": plant_name,
                    "date": current.strftime("%Y-%m-%d"),
                    "eventType": "needs_water",
                    "description": f"Water thoroughly (every {freq} days)",
                })
                current += timedelta(days=freq)

        # Generate weekly sun reminder events
        if sun_min is not None and sun_max is not None:
            current = start
            while current < end:
                deterministic_events.append({
                    "profileId": profile_id,
                    "plantName": plant_name,
                    "date": current.strftime("%Y-%m-%d"),
                    "eventType": "needs_sun",
                    "description": (
                        f"Ensure {sun_min}-{sun_max}h of sunlight today"
                    ),
                })
                current += timedelta(days=SUN_REMINDER_INTERVAL_DAYS)

    logger.info(
        f"Deterministic generator: {len(deterministic_events)} events for "
        f"{len(profiles) - len(ai_fallback_profiles)} profiles, "
        f"{len(ai_fallback_profiles)} profiles need AI fallback"
    )

    return deterministic_events, ai_fallback_profiles
