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

    async def create_profile_with_id(
        self, user_id: str, profile_id: str, data: dict
    ) -> dict:
        """Create a profile with a specific document ID (used for migration)."""
        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("profiles")
            .document(profile_id)
        )
        await doc_ref.set(data)
        return {"id": profile_id, **data}

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

    async def get_all_events(self, user_id: str, limit: int = 500) -> List[dict]:
        """Get all calendar events for a user (used for migration)."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("calendar_events")
        )
        docs = collection.limit(limit).stream()

        events = []
        async for doc in docs:
            event = doc.to_dict()
            event["id"] = doc.id
            events.append(event)
        return events

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

    # ──────────────────────────────────────────────
    # Community operations
    # ──────────────────────────────────────────────

    async def create_community_plant(self, data: dict) -> dict:
        """Create a community plant document."""
        collection = self.db.collection("community_plants")
        doc_ref = collection.document()
        await doc_ref.set(data)
        return {"id": doc_ref.id, **data}

    async def community_plant_exists(self, user_id: str, profile_id: str) -> Optional[dict]:
        """Check if a profile is already shared. Returns the doc if found."""
        collection = self.db.collection("community_plants")
        query = (
            collection
            .where("sourceUserId", "==", user_id)
            .where("sourceProfileId", "==", profile_id)
            .limit(1)
        )
        docs = query.stream()
        async for doc in docs:
            result = doc.to_dict()
            result["id"] = doc.id
            return result
        return None

    async def get_community_plants(
        self, plant_type: Optional[str] = None, limit: int = 50
    ) -> List[dict]:
        """Get community plants, optionally filtered by plant type."""
        collection = self.db.collection("community_plants")

        if plant_type:
            query = collection.where(
                "plantTypeLower", "==", plant_type.lower()
            ).limit(limit)
        else:
            query = collection.order_by(
                "sharedAt", direction=firestore.Query.DESCENDING
            ).limit(limit)

        docs = query.stream()

        plants = []
        async for doc in docs:
            plant = doc.to_dict()
            plant["id"] = doc.id
            plants.append(plant)

        # Sort filtered results by sharedAt since we can't combine where + order_by without composite index
        if plant_type:
            plants.sort(key=lambda p: p.get("sharedAt", ""), reverse=True)

        return plants

    async def get_community_plant(self, community_id: str) -> Optional[dict]:
        """Get a single community plant by ID."""
        doc_ref = self.db.collection("community_plants").document(community_id)
        doc = await doc_ref.get()
        if not doc.exists:
            return None
        result = doc.to_dict()
        result["id"] = doc.id
        return result

    async def get_community_plants_by_user(self, user_id: str) -> List[dict]:
        """Get all community plants shared by a specific user."""
        collection = self.db.collection("community_plants")
        query = collection.where("sourceUserId", "==", user_id)
        docs = query.stream()

        plants = []
        async for doc in docs:
            plant = doc.to_dict()
            plant["id"] = doc.id
            plants.append(plant)
        return plants

    async def delete_community_plant(self, community_id: str) -> None:
        """Delete a community plant and its comments subcollection."""
        doc_ref = self.db.collection("community_plants").document(community_id)

        # Delete comments subcollection first
        comments = doc_ref.collection("comments").stream()
        batch = self.db.batch()
        count = 0
        async for comment in comments:
            batch.delete(comment.reference)
            count += 1
            if count >= 499:
                await batch.commit()
                batch = self.db.batch()
                count = 0
        if count > 0:
            await batch.commit()

        await doc_ref.delete()

    async def add_comment(self, community_id: str, data: dict) -> dict:
        """Add a comment to a community plant."""
        collection = (
            self.db.collection("community_plants")
            .document(community_id)
            .collection("comments")
        )
        doc_ref = collection.document()
        await doc_ref.set(data)
        return {"id": doc_ref.id, **data}

    async def get_comments(self, community_id: str, limit: int = 50) -> List[dict]:
        """Get comments for a community plant, ordered chronologically."""
        collection = (
            self.db.collection("community_plants")
            .document(community_id)
            .collection("comments")
        )
        query = collection.order_by("createdAt").limit(limit)
        docs = query.stream()

        comments = []
        async for doc in docs:
            comment = doc.to_dict()
            comment["id"] = doc.id
            comments.append(comment)
        return comments

    async def increment_comment_count(self, community_id: str) -> None:
        """Increment the comment count on a community plant."""
        doc_ref = self.db.collection("community_plants").document(community_id)
        await doc_ref.update({"commentCount": firestore.Increment(1)})

    # ──────────────────────────────────────────────
    # Sensor operations
    # ──────────────────────────────────────────────

    async def create_sensor(self, user_id: str, sensor_id: str, data: dict) -> dict:
        """Create a sensor document."""
        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
        )
        await doc_ref.set(data)
        return {"id": doc_ref.id, **data}

    async def get_sensors(self, user_id: str) -> List[dict]:
        """Get all sensors for a user."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
        )
        docs = collection.stream()

        sensors = []
        async for doc in docs:
            sensor = doc.to_dict()
            sensor["id"] = doc.id
            sensors.append(sensor)
        return sensors

    async def get_sensor(self, user_id: str, sensor_id: str) -> Optional[dict]:
        """Get a single sensor by ID."""
        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
        )
        doc = await doc_ref.get()
        if not doc.exists:
            return None
        result = doc.to_dict()
        result["id"] = doc.id
        return result

    async def get_sensor_by_token(self, device_token: str) -> Optional[dict]:
        """Look up a sensor by its device token using the top-level sensor_tokens index."""
        token_ref = self.db.collection("sensor_tokens").document(device_token)
        token_doc = await token_ref.get()
        if not token_doc.exists:
            return None
        token_data = token_doc.to_dict()
        user_id = token_data.get("userId")
        sensor_id = token_data.get("sensorId")
        if not user_id or not sensor_id:
            return None
        sensor_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
        )
        sensor_doc = await sensor_ref.get()
        if not sensor_doc.exists:
            return None
        result = sensor_doc.to_dict()
        result["id"] = sensor_doc.id
        result["userId"] = user_id
        return result

    async def update_sensor(self, user_id: str, sensor_id: str, data: dict) -> dict:
        """Update sensor fields."""
        doc_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
        )
        await doc_ref.update(data)
        doc = await doc_ref.get()
        result = doc.to_dict()
        result["id"] = doc.id
        return result

    async def delete_sensor(self, user_id: str, sensor_id: str) -> None:
        """Delete a sensor and all its readings."""
        sensor_ref = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
        )

        # Delete readings subcollection
        readings = sensor_ref.collection("readings").stream()
        batch = self.db.batch()
        count = 0
        async for doc in readings:
            batch.delete(doc.reference)
            count += 1
            if count >= 499:
                await batch.commit()
                batch = self.db.batch()
                count = 0
        if count > 0:
            await batch.commit()

        await sensor_ref.delete()

    # ──────────────────────────────────────────────
    # Gardener profile operations
    # ──────────────────────────────────────────────

    async def get_public_gardeners(self, limit: int = 50) -> List[dict]:
        """List public gardener profiles (users root docs where isPublic=true)."""
        query = (
            self.db.collection("users")
            .where("isPublic", "==", True)
            .limit(limit)
        )
        results = []
        async for doc in query.stream():
            data = doc.to_dict()
            data["userId"] = doc.id
            results.append(data)
        return results

    async def get_gardener_profile(self, user_id: str) -> Optional[dict]:
        """Read users/{user_id} root document. Returns None if not set yet."""
        doc_ref = self.db.collection("users").document(user_id)
        doc = await doc_ref.get()
        if not doc.exists:
            return None
        return doc.to_dict()

    async def upsert_gardener_profile(self, user_id: str, data: dict) -> dict:
        """Create or update the gardener profile fields on the users root doc."""
        now = datetime.now(timezone.utc).isoformat()
        doc_ref = self.db.collection("users").document(user_id)
        doc = await doc_ref.get()
        if not doc.exists:
            data["createdAt"] = now
        data["updatedAt"] = now
        await doc_ref.set(data, merge=True)
        updated = await doc_ref.get()
        return updated.to_dict() or {}

    async def update_fcm_token(self, user_id: str, token: str) -> None:
        """Store or refresh the FCM device token on the user document."""
        doc_ref = self.db.collection("users").document(user_id)
        now = datetime.now(timezone.utc).isoformat()
        await doc_ref.set({"fcmToken": token, "updatedAt": now}, merge=True)

    # ──────────────────────────────────────────────
    # Follow / follower operations
    # ──────────────────────────────────────────────

    async def get_follower_count(self, user_id: str) -> int:
        collection = (
            self.db.collection("users").document(user_id).collection("followers")
        )
        count = 0
        async for _ in collection.stream():
            count += 1
        return count

    async def get_following_count(self, user_id: str) -> int:
        collection = (
            self.db.collection("users").document(user_id).collection("following")
        )
        count = 0
        async for _ in collection.stream():
            count += 1
        return count

    async def is_following(self, follower_id: str, target_id: str) -> bool:
        doc_ref = (
            self.db.collection("users")
            .document(follower_id)
            .collection("following")
            .document(target_id)
        )
        doc = await doc_ref.get()
        return doc.exists

    async def follow_gardener(self, follower_id: str, target_id: str) -> None:
        """Symmetric batch write: follower's following/ and target's followers/."""
        now = datetime.now(timezone.utc).isoformat()
        batch = self.db.batch()
        following_ref = (
            self.db.collection("users")
            .document(follower_id)
            .collection("following")
            .document(target_id)
        )
        followers_ref = (
            self.db.collection("users")
            .document(target_id)
            .collection("followers")
            .document(follower_id)
        )
        batch.set(following_ref, {"followedAt": now})
        batch.set(followers_ref, {"followedAt": now})
        await batch.commit()

    async def unfollow_gardener(self, follower_id: str, target_id: str) -> None:
        """Symmetric batch delete."""
        batch = self.db.batch()
        following_ref = (
            self.db.collection("users")
            .document(follower_id)
            .collection("following")
            .document(target_id)
        )
        followers_ref = (
            self.db.collection("users")
            .document(target_id)
            .collection("followers")
            .document(follower_id)
        )
        batch.delete(following_ref)
        batch.delete(followers_ref)
        await batch.commit()

    async def get_following_list(self, user_id: str) -> List[str]:
        """Return list of user_ids the given user follows."""
        collection = (
            self.db.collection("users").document(user_id).collection("following")
        )
        ids = []
        async for doc in collection.stream():
            ids.append(doc.id)
        return ids

    async def get_follower_fcm_tokens(self, user_id: str) -> List[str]:
        """Collect FCM tokens from all followers of user_id."""
        followers_col = (
            self.db.collection("users").document(user_id).collection("followers")
        )
        tokens = []
        async for doc in followers_col.stream():
            follower_id = doc.id
            user_doc = await self.db.collection("users").document(follower_id).get()
            if user_doc.exists:
                token = user_doc.to_dict().get("fcmToken")
                if token:
                    tokens.append(token)
        return tokens

    async def notify_followers_of_share(
        self, sharer_id: str, plant_name: str, gardener_display_name: str
    ) -> None:
        """Fire-and-forget: fetch follower FCM tokens and send push notifications."""
        from services.fcm_service import send_new_plant_notification
        tokens = await self.get_follower_fcm_tokens(sharer_id)
        await send_new_plant_notification(tokens, gardener_display_name, plant_name)

    # ──────────────────────────────────────────────
    # Sensor reading operations
    # ──────────────────────────────────────────────

    async def create_sensor_reading(
        self, user_id: str, sensor_id: str, data: dict
    ) -> dict:
        """Store a sensor reading."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
            .collection("readings")
        )
        doc_ref = collection.document()
        await doc_ref.set(data)
        return {"id": doc_ref.id, **data}

    async def get_latest_sensor_reading(
        self, user_id: str, sensor_id: str
    ) -> Optional[dict]:
        """Get the most recent reading for a sensor."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
            .collection("readings")
        )
        query = (
            collection
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(1)
        )
        docs = query.stream()
        async for doc in docs:
            result = doc.to_dict()
            result["id"] = doc.id
            return result
        return None

    async def get_sensor_readings(
        self,
        user_id: str,
        sensor_id: str,
        since: str,
        limit: int = 100,
    ) -> List[dict]:
        """Get sensor readings since a given ISO timestamp."""
        collection = (
            self.db.collection("users")
            .document(user_id)
            .collection("sensors")
            .document(sensor_id)
            .collection("readings")
        )
        query = (
            collection
            .where("timestamp", ">=", since)
            .order_by("timestamp")
            .limit(limit)
        )
        docs = query.stream()

        readings = []
        async for doc in docs:
            reading = doc.to_dict()
            reading["id"] = doc.id
            readings.append(reading)
        return readings
