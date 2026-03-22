"""Cloud Function for sending daily push notifications.

Queries today's calendar events across all users and sends FCM push
notifications, batched per user.

Trigger: Cloud Scheduler (e.g., daily at 8:00 AM local time per timezone)
"""

import json
import logging
import os
from collections import defaultdict
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, messaging
from google.cloud import firestore

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# Initialize Firebase Admin SDK (uses default credentials on GCP)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.Client()


def send_notifications(request):
    """
    Cloud Function entry point for HTTP-triggered Cloud Scheduler.

    Args:
        request: The HTTP request from Cloud Scheduler.

    Returns:
        Tuple of (response_body, status_code).
    """
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    logger.info(f"Starting notification dispatch for {today}")

    total_notifications_sent = 0
    total_users_notified = 0
    errors = []

    try:
        # Collect events grouped by user
        user_events = _collect_todays_events(today)

        for user_id, events in user_events.items():
            try:
                # Check if user has notifications enabled
                if not _user_has_notifications_enabled(user_id):
                    logger.debug(f"User {user_id} has notifications disabled, skipping")
                    continue

                # Get the user's FCM tokens
                fcm_tokens = _get_user_fcm_tokens(user_id)
                if not fcm_tokens:
                    logger.debug(f"User {user_id} has no FCM tokens, skipping")
                    continue

                # Build and send notification
                sent = _send_user_notification(user_id, events, fcm_tokens)
                if sent:
                    total_notifications_sent += sent
                    total_users_notified += 1

            except Exception as e:
                error_msg = f"Error sending notifications to user {user_id}: {e}"
                logger.error(error_msg)
                errors.append(error_msg)

    except Exception as e:
        logger.error(f"Fatal error in send_notifications: {e}")
        return (json.dumps({"error": str(e)}), 500)

    result = {
        "date": today,
        "usersNotified": total_users_notified,
        "notificationsSent": total_notifications_sent,
        "errors": errors,
    }
    logger.info(f"Notification dispatch complete: {result}")
    return (json.dumps(result), 200)


def _collect_todays_events(today: str) -> dict:
    """
    Query all users' calendar events for today.

    Returns:
        Dict mapping user_id to list of event dicts.
    """
    user_events = defaultdict(list)

    # Iterate all users
    users_ref = db.collection("users")
    users = users_ref.stream()

    for user_doc in users:
        user_id = user_doc.id
        events_ref = (
            db.collection("users")
            .document(user_id)
            .collection("calendar_events")
        )

        query = (
            events_ref
            .where("date", "==", today)
            .where("completed", "==", False)
        )

        for event_doc in query.stream():
            event = event_doc.to_dict()
            event["id"] = event_doc.id
            user_events[user_id].append(event)

    return dict(user_events)


def _user_has_notifications_enabled(user_id: str) -> bool:
    """Check if the user has push notifications enabled in their settings."""
    user_doc = db.collection("users").document(user_id).get()
    if not user_doc.exists:
        return False

    user_data = user_doc.to_dict()
    settings = user_data.get("settings", {})
    return settings.get("notificationsEnabled", True)  # Default to enabled


def _get_user_fcm_tokens(user_id: str) -> list:
    """Get all registered FCM tokens for a user."""
    user_doc = db.collection("users").document(user_id).get()
    if not user_doc.exists:
        return []

    user_data = user_doc.to_dict()
    tokens = user_data.get("fcmTokens", [])

    # Handle both single token string and list of tokens
    if isinstance(tokens, str):
        return [tokens] if tokens else []
    return [t for t in tokens if t]


def _send_user_notification(user_id: str, events: list, fcm_tokens: list) -> int:
    """
    Send a batched notification to a user about their plant care tasks.

    Args:
        user_id: The user's ID.
        events: List of today's uncompleted event dicts.
        fcm_tokens: List of FCM device tokens.

    Returns:
        Number of notifications successfully sent.
    """
    if not events or not fcm_tokens:
        return 0

    # Build notification content
    event_count = len(events)
    plant_names = list({e.get("plantName", "your plant") for e in events})

    if event_count == 1:
        event = events[0]
        title = f"Plant Care Reminder"
        body = f"{event.get('plantName', 'Your plant')}: {event.get('description', 'needs attention')}"
    elif len(plant_names) == 1:
        title = f"{plant_names[0]} needs attention"
        body = f"You have {event_count} care tasks for {plant_names[0]} today."
    else:
        title = f"{event_count} Plant Care Tasks Today"
        if len(plant_names) <= 3:
            body = f"Care needed for: {', '.join(plant_names)}"
        else:
            body = f"Care needed for {plant_names[0]}, {plant_names[1]}, and {len(plant_names) - 2} more plants"

    # Build the notification payload
    notification = messaging.Notification(
        title=title,
        body=body,
    )

    # Data payload for the app to handle
    data = {
        "type": "daily_care_reminder",
        "eventCount": str(event_count),
        "date": events[0].get("date", ""),
    }

    sent_count = 0
    stale_tokens = []

    for token in fcm_tokens:
        try:
            message = messaging.Message(
                notification=notification,
                data=data,
                token=token,
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            badge=event_count,
                            sound="default",
                        ),
                    ),
                ),
            )
            messaging.send(message)
            sent_count += 1
        except messaging.UnregisteredError:
            logger.info(f"Removing stale FCM token for user {user_id}")
            stale_tokens.append(token)
        except Exception as e:
            logger.error(f"Failed to send FCM to token for user {user_id}: {e}")

    # Clean up stale tokens
    if stale_tokens:
        _remove_stale_tokens(user_id, stale_tokens)

    return sent_count


def _remove_stale_tokens(user_id: str, stale_tokens: list) -> None:
    """Remove unregistered FCM tokens from the user's document."""
    try:
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()
        if not user_doc.exists:
            return

        user_data = user_doc.to_dict()
        current_tokens = user_data.get("fcmTokens", [])

        if isinstance(current_tokens, str):
            current_tokens = [current_tokens]

        updated_tokens = [t for t in current_tokens if t not in stale_tokens]
        user_ref.update({"fcmTokens": updated_tokens})
        logger.info(f"Removed {len(stale_tokens)} stale tokens for user {user_id}")
    except Exception as e:
        logger.error(f"Failed to remove stale tokens for user {user_id}: {e}")
