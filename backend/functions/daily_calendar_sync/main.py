"""Cloud Function for daily calendar sync via Cloud Scheduler.

Hybrid approach: uses deterministic scheduling for profiles with structured
data (wateringFrequencyDays, sunHoursMin/Max), and falls back to AI generation
only for profiles that don't have structured data yet.

Generates 30 days ahead to give users a full month of visibility.

Trigger: Cloud Scheduler (e.g., daily at 6:00 AM UTC)
"""

import json
import logging
import os
from datetime import datetime, timedelta, timezone

import anthropic
from google.cloud import firestore

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

MODEL = "claude-sonnet-4-20250514"
MAX_TOKENS = 2048
DAYS_AHEAD = 30

# Sun reminders are generated weekly (every 7 days)
SUN_REMINDER_INTERVAL_DAYS = 7

db = firestore.Client()


def daily_calendar_sync(request):
    """
    Cloud Function entry point for HTTP-triggered Cloud Scheduler.

    Args:
        request: The HTTP request from Cloud Scheduler.

    Returns:
        Tuple of (response_body, status_code).
    """
    current_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    logger.info(f"Starting daily calendar sync for {current_date}")

    total_events_created = 0
    total_users_processed = 0
    errors = []

    try:
        # Iterate all user documents
        users_ref = db.collection("users")
        users = users_ref.stream()

        for user_doc in users:
            user_id = user_doc.id
            total_users_processed += 1

            try:
                events_created = _process_user(user_id, current_date)
                total_events_created += events_created
            except Exception as e:
                error_msg = f"Error processing user {user_id}: {e}"
                logger.error(error_msg)
                errors.append(error_msg)

    except Exception as e:
        logger.error(f"Fatal error in daily_calendar_sync: {e}")
        return (json.dumps({"error": str(e)}), 500)

    result = {
        "date": current_date,
        "usersProcessed": total_users_processed,
        "eventsCreated": total_events_created,
        "errors": errors,
    }
    logger.info(f"Daily calendar sync complete: {result}")
    return (json.dumps(result), 200)


def _process_user(user_id: str, current_date: str) -> int:
    """Process a single user: fetch profiles, generate events, write to Firestore.

    Uses a hybrid approach:
    1. Profiles WITH structured data (wateringFrequencyDays, sunHours) →
       deterministic schedule generation (no AI call needed)
    2. Profiles WITHOUT structured data → AI-generated schedule (backward compat)

    This saves API costs and produces consistent, predictable schedules for
    profiles that have been enriched with structured care data.
    """
    # Fetch user's plant profiles
    profiles_ref = (
        db.collection("users")
        .document(user_id)
        .collection("profiles")
    )
    profile_docs = profiles_ref.stream()

    profiles = []
    for doc in profile_docs:
        profile = doc.to_dict()
        profile["id"] = doc.id
        profiles.append(profile)

    if not profiles:
        logger.info(f"User {user_id} has no profiles, skipping")
        return 0

    # Split profiles: structured data vs needs AI
    deterministic_events, ai_profiles = _generate_deterministic_events(
        profiles, current_date, DAYS_AHEAD
    )

    # Fall back to AI only for profiles without structured data
    ai_events = []
    if ai_profiles:
        ai_events = _generate_ai_events(ai_profiles, current_date)

    all_events = deterministic_events + ai_events
    if not all_events:
        return 0

    # Write events with deduplication
    events_created = 0
    events_ref = (
        db.collection("users")
        .document(user_id)
        .collection("calendar_events")
    )

    batch = db.batch()
    batch_count = 0

    for event in all_events:
        profile_id = event.get("profileId", "")
        date = event.get("date", "")
        event_type = event.get("eventType", "")

        # Check for duplicate
        if _event_exists(events_ref, profile_id, date, event_type):
            continue

        now = datetime.now(timezone.utc).isoformat()
        doc_data = {
            "userId": user_id,
            "profileId": profile_id,
            "plantName": event.get("plantName", ""),
            "date": date,
            "eventType": event_type,
            "description": event.get("description", ""),
            "completed": False,
            "createdAt": now,
        }

        doc_ref = events_ref.document()
        batch.set(doc_ref, doc_data)
        events_created += 1
        batch_count += 1

        if batch_count >= 499:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    if batch_count > 0:
        batch.commit()

    logger.info(
        f"Created {events_created} events for user {user_id} "
        f"({len(deterministic_events)} deterministic, {len(ai_events)} AI)"
    )
    return events_created


def _generate_deterministic_events(
    profiles: list, start_date: str, days_ahead: int
) -> tuple:
    """Generate deterministic events for profiles with structured data.

    Returns:
        Tuple of (events_list, ai_fallback_profiles_list)
    """
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = start + timedelta(days=days_ahead)

    deterministic_events = []
    ai_fallback_profiles = []

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
                    "description": f"Ensure {sun_min}-{sun_max}h of sunlight today",
                })
                current += timedelta(days=SUN_REMINDER_INTERVAL_DAYS)

    logger.info(
        f"Deterministic: {len(deterministic_events)} events, "
        f"{len(ai_fallback_profiles)} profiles need AI"
    )
    return deterministic_events, ai_fallback_profiles


def _event_exists(
    events_ref, profile_id: str, date: str, event_type: str
) -> bool:
    """Check if a matching event already exists (for deduplication)."""
    query = (
        events_ref
        .where("profileId", "==", profile_id)
        .where("date", "==", date)
        .where("eventType", "==", event_type)
        .limit(1)
    )
    results = list(query.stream())
    return len(results) > 0


def _generate_ai_events(profiles: list, current_date: str) -> list:
    """Generate calendar events via AI for profiles without structured data.

    This is the fallback path — only called for profiles that don't yet have
    wateringFrequencyDays or sunHoursMin/Max set.
    """
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        logger.error("ANTHROPIC_API_KEY not set")
        return []

    client = anthropic.Anthropic(api_key=api_key)

    plants_lines = []
    for p in profiles:
        line = (
            f"- {p.get('name', 'Unknown')} ({p.get('plantType', 'Unknown')}): "
            f"age {p.get('ageDays', 0)} days, "
            f"sun needs: {p.get('sunNeeds', 'unknown')}, "
            f"water needs: {p.get('waterNeeds', 'unknown')}, "
            f"profile ID: {p.get('id', '')}"
        )
        plants_lines.append(line)

    plants_summary = "\n".join(plants_lines)

    prompt = f"""You are an expert gardener creating a 7-day care calendar. Today is {current_date}.

Plants in the garden:
{plants_summary}

Generate care events for the next 7 days. For each event, consider the plant's specific needs.
Not every plant needs attention every day.

Respond with ONLY a JSON array (no markdown, no extra text). Each element must have:
- "profileId": the profile ID string from above
- "plantName": the plant name
- "date": date string in YYYY-MM-DD format (must be within next 7 days from {current_date})
- "eventType": one of "needs_water", "needs_sun", "needs_treatment"
- "description": a brief, actionable description

Generate realistic events based on each plant's care requirements."""

    try:
        response = client.messages.create(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            messages=[{"role": "user", "content": prompt}],
        )

        text = response.content[0].text.strip()
        if text.startswith("```"):
            text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()

        events = json.loads(text)
        if not isinstance(events, list):
            logger.error("AI returned non-list for calendar events")
            return []

        # Validate events
        valid_types = {"needs_water", "needs_sun", "needs_treatment"}
        return [
            e for e in events
            if isinstance(e, dict)
            and e.get("eventType") in valid_types
            and e.get("date")
            and e.get("profileId")
        ]

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse AI calendar response: {e}")
        return []
    except Exception as e:
        logger.error(f"AI calendar generation failed: {e}")
        return []
