"""Deterministic schedule generator based on structured plant data.

Replaces AI-generated schedules for profiles that have wateringFrequencyDays set.
Falls back to AI for profiles without structured watering data.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Tuple

logger = logging.getLogger(__name__)


def generate_deterministic_events(
    profiles: list,
    start_date: str,
    days_ahead: int = 30,
) -> Tuple[List[dict], List[dict]]:
    """
    Generate deterministic watering events from structured plant profile data.

    For each profile with wateringFrequencyDays, creates needs_water events
    every N days. Profiles without wateringFrequencyDays are sent to AI fallback.

    Args:
        profiles: List of plant profile dicts from Firestore.
        start_date: Start date as YYYY-MM-DD string.
        days_ahead: Number of days ahead to generate (default 30).

    Returns:
        Tuple of (deterministic_events, ai_fallback_profiles).
    """
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = start + timedelta(days=days_ahead)

    deterministic_events: List[dict] = []
    ai_fallback_profiles: List[dict] = []

    for profile in profiles:
        profile_id = profile.get("id", "")
        plant_name = profile.get("name", "Unknown")
        freq = profile.get("wateringFrequencyDays")

        if not freq:
            ai_fallback_profiles.append(profile)
            continue

        # Generate watering events every N days
        if freq > 0:
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

    logger.info(
        f"Deterministic generator: {len(deterministic_events)} events for "
        f"{len(profiles) - len(ai_fallback_profiles)} profiles, "
        f"{len(ai_fallback_profiles)} profiles need AI fallback"
    )

    return deterministic_events, ai_fallback_profiles
