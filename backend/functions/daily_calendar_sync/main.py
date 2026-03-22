"""Cloud Function for daily calendar sync via Cloud Scheduler.

Iterates all users and their plant profiles, generates care events for the
next 7 days using AI, and writes them to Firestore with deduplication.

Trigger: Cloud Scheduler (e.g., daily at 6:00 AM UTC)
"""

import json
import logging
import os
from datetime import datetime, timezone

import anthropic
from google.cloud import firestore

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

MODEL = "claude-sonnet-4-20250514"
MAX_TOKENS = 2048

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
    """Process a single user: fetch profiles, generate events, write to Firestore."""
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

    # Generate calendar events via AI
    events = _generate_events(profiles, current_date)
    if not events:
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

    for event in events:
        profile_id = event.get("profileId", "")
        date = event.get("date", "")
        event_type = event.get("eventType", "")

        # Check for duplicate
        if _event_exists(events_ref, profile_id, date, event_type):
            logger.debug(
                f"Skipping duplicate event: {profile_id}/{date}/{event_type}"
            )
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

    logger.info(f"Created {events_created} events for user {user_id}")
    return events_created


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


def _generate_events(profiles: list, current_date: str) -> list:
    """Generate calendar events for the next 7 days using Claude."""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        logger.error("ANTHROPIC_API_KEY not set")
        return []

    client = anthropic.Anthropic(api_key=api_key)

    plants_summary = "\n".join(
        f"- {p.get('name', 'Unknown')} ({p.get('plantType', 'Unknown')}): "
        f"age {p.get('ageDays', 0)} days, "
        f"sun needs: {p.get('sunNeeds', 'unknown')}, "
        f"water needs: {p.get('waterNeeds', 'unknown')}, "
        f"profile ID: {p.get('id', '')}"
        for p in profiles
    )

    prompt = f"""You are an expert gardener creating a 7-day care calendar. Today is {current_date}.

Plants in the garden:
{plants_summary}

Generate care events for the next 7 days. For each event, consider the plant's specific needs.

Respond with ONLY a JSON array (no markdown, no extra text). Each element must have:
- "profileId": the profile ID string from above
- "plantName": the plant name
- "date": date string in YYYY-MM-DD format (must be within next 7 days from {current_date})
- "eventType": one of "needs_water", "needs_sun", "needs_treatment"
- "description": a brief, actionable description

Generate realistic events based on each plant's care requirements. Not every plant needs attention every day."""

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
