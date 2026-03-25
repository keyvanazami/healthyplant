"""Firestore service for all database operations."""

import logging
import os
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional

from google.cloud import firestore

logger = logging.getLogger(__name__)


class FirestoreService:
    """Service for Firestore CRUD operations scoped to user subcollections."""

    def __init__(self):
        project_id = os.getenv("GCP_PROJECT_ID")
        try:
            self.db = firestore.AsyncClient(project=project_id)
            logger.info("Firestore client initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Firestore client: {e}")
            raise

    # ──────────────────────────────────────────────
    # Profile operations
    # ──────────────────────────────────────────────

    async def create_profile(self, user_id: str, data: dict) -> dict:
        """Create a new plant profile document."""
        now = datetime.now(timezone.utc).isoformat()
        doc_data = {
            **data,
            "userId": user_id,
            "sunNeeds": None,
            "waterNeeds": None,
            "harvestTime": None,
            "wateringFrequencyDays": None,
            "sunHoursMin": None,
            "sunHoursMax": None,
            "aiLastUpdated": None,
            "createdAt": now,
            "updatedAt": now,
        }

        collection = self.db.collection("users").document(user_id).collection("profiles")
        doc_ref = collection.document()
        await doc_ref.set(doc_data)

        return {"id": doc_ref.id, **doc_data}

    async def get_profiles(self, user_id: str) -> List[dict]:
        """Get all plant profiles for a user, ordered by creation date."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("profiles")
        )
        query = collection.order_by("createdAt", direction=firestore.Query.DESCENDING)
        docs = query.stream()

        profiles = []
        async for doc in docs:
            profile = doc.to_dict()
            profile["id"] = doc.id
            profiles.append(profile)
        return profiles

    async def get_profile(self, user_id: str, profile_id: str) -> Optional[dict]:
        """Get a single plant profile by ID."""
        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("profiles")
            .document(profile_id)
        )
        doc = await doc_ref.get()
        if not doc.exists:
            return None

        profile = doc.to_dict()
        profile["id"] = doc.id
        return profile

    async def update_profile(self, user_id: str, profile_id: str, data: dict) -> dict:
        """Update a plant profile with the given data."""
        now = datetime.now(timezone.utc).isoformat()
        update_data = {**data, "updatedAt": now}

        # Set aiLastUpdated if AI fields are being updated
        ai_fields = {"sunNeeds", "waterNeeds", "harvestTime", "wateringFrequencyDays", "sunHoursMin", "sunHoursMax"}
        if any(k in ai_fields for k in data):
            update_data["aiLastUpdated"] = now

        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("profiles")
            .document(profile_id)
        )
        await doc_ref.update(update_data)

        # Return the full updated document
        doc = await doc_ref.get()
        result = doc.to_dict()
        result["id"] = doc.id
        return result

    async def delete_profile(self, user_id: str, profile_id: str) -> None:
        """Delete a plant profile."""
        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("profiles")
            .document(profile_id)
        )
        await doc_ref.delete()

    # ──────────────────────────────────────────────
    # Calendar event operations
    # ──────────────────────────────────────────────

    async def create_events(self, user_id: str, events: List[dict]) -> List[dict]:
        """Create multiple calendar events. Returns list of created events."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("calendar_events")
        )

        created = []
        batch = self.db.batch()
        batch_count = 0

        for event_data in events:
            now = datetime.now(timezone.utc).isoformat()
            doc_data = {
                "userId": user_id,
                "profileId": event_data.get("profileId", ""),
                "plantName": event_data.get("plantName", ""),
                "date": event_data.get("date", ""),
                "eventType": event_data.get("eventType", ""),
                "description": event_data.get("description", ""),
                "completed": False,
                "createdAt": now,
            }

            doc_ref = collection.document()
            batch.set(doc_ref, doc_data)
            created.append({"id": doc_ref.id, **doc_data})
            batch_count += 1

            # Firestore batch limit is 500
            if batch_count >= 499:
                await batch.commit()
                batch = self.db.batch()
                batch_count = 0

        if batch_count > 0:
            await batch.commit()

        return created

    async def get_events_by_month(self, user_id: str, month: str) -> List[dict]:
        """
        Get calendar events for a specific month.

        Args:
            month: Month string in YYYY-MM format.
        """
        # Calculate date range for the month
        year, month_num = month.split("-")
        start_date = f"{month}-01"
        # Last possible day of month
        if int(month_num) == 12:
            end_date = f"{int(year) + 1}-01-01"
        else:
            end_date = f"{year}-{int(month_num) + 1:02d}-01"

        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("calendar_events")
        )

        query = (
            collection
            .where("date", ">=", start_date)
            .where("date", "<", end_date)
            .order_by("date")
        )
        docs = query.stream()

        events = []
        async for doc in docs:
            event = doc.to_dict()
            event["id"] = doc.id
            events.append(event)
        return events

    async def update_event(self, user_id: str, event_id: str, data: dict) -> Optional[dict]:
        """Update a calendar event."""
        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("calendar_events")
            .document(event_id)
        )

        doc = await doc_ref.get()
        if not doc.exists:
            return None

        await doc_ref.update(data)
        updated = await doc_ref.get()
        result = updated.to_dict()
        result["id"] = updated.id
        return result

    async def delete_events_for_profile(self, user_id: str, profile_id: str) -> None:
        """Delete all calendar events associated with a specific plant profile."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("calendar_events")
        )

        query = collection.where("profileId", "==", profile_id)
        docs = query.stream()

        batch = self.db.batch()
        count = 0
        async for doc in docs:
            batch.delete(doc.reference)
            count += 1
            if count >= 499:
                await batch.commit()
                batch = self.db.batch()
                count = 0

        if count > 0:
            await batch.commit()

    async def event_exists(
        self, user_id: str, profile_id: str, date: str, event_type: str
    ) -> bool:
        """Check if an event already exists for deduplication."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("calendar_events")
        )

        query = (
            collection
            .where("profileId", "==", profile_id)
            .where("date", "==", date)
            .where("eventType", "==", event_type)
            .limit(1)
        )
        docs = query.stream()
        async for _ in docs:
            return True
        return False

    async def create_next_recurring_event(
        self, user_id: str, completed_event: dict, frequency_days: int
    ) -> Optional[dict]:
        """Create the next recurring event based on a completed event.

        Schedules the next occurrence frequency_days from now. Deduplicates
        to avoid creating a duplicate if one already exists for that date.

        Args:
            user_id: The user's ID.
            completed_event: The event dict that was just completed.
            frequency_days: Number of days until next occurrence.

        Returns:
            The created event dict, or None if a duplicate already exists.
        """
        next_date = (
            datetime.now(timezone.utc) + timedelta(days=frequency_days)
        ).strftime("%Y-%m-%d")

        profile_id = completed_event.get("profileId", "")
        event_type = completed_event.get("eventType", "")

        # Deduplicate: don't create if one already exists for that date
        if await self.event_exists(user_id, profile_id, next_date, event_type):
            return None

        now = datetime.now(timezone.utc).isoformat()
        doc_data = {
            "userId": user_id,
            "profileId": profile_id,
            "plantName": completed_event.get("plantName", ""),
            "date": next_date,
            "eventType": event_type,
            "description": completed_event.get("description", ""),
            "completed": False,
            "createdAt": now,
        }

        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("calendar_events")
        )
        doc_ref = collection.document()
        await doc_ref.set(doc_data)

        return {"id": doc_ref.id, **doc_data}

    # ──────────────────────────────────────────────
    # Chat message operations
    # ──────────────────────────────────────────────

    async def save_message(self, user_id: str, role: str, content: str) -> dict:
        """Save a chat message to Firestore."""
        now = datetime.now(timezone.utc).isoformat()
        doc_data = {
            "userId": user_id,
            "role": role,
            "content": content,
            "timestamp": now,
        }

        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("chat_messages")
        )
        doc_ref = collection.document()
        await doc_ref.set(doc_data)

        return {"id": doc_ref.id, **doc_data}

    async def get_chat_history(self, user_id: str, limit: int = 50) -> List[dict]:
        """Get the most recent chat messages for a user."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("chat_messages")
        )

        query = (
            collection
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        docs = query.stream()

        messages = []
        async for doc in docs:
            msg = doc.to_dict()
            msg["id"] = doc.id
            messages.append(msg)

        # Reverse to get chronological order
        messages.reverse()
        return messages

    async def clear_chat_history(self, user_id: str) -> None:
        """Delete all chat messages for a user."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("chat_messages")
        )

        docs = collection.stream()
        batch = self.db.batch()
        count = 0

        async for doc in docs:
            batch.delete(doc.reference)
            count += 1
            if count >= 499:
                await batch.commit()
                batch = self.db.batch()
                count = 0

        if count > 0:
            await batch.commit()
