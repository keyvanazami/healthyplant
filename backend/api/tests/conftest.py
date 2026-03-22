"""Pytest fixtures for Healthy Plant API tests."""

import asyncio
from datetime import datetime, timezone
from typing import AsyncGenerator, List, Optional
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from main import app
from services.firestore_service import FirestoreService
from services.ai_service import AIService
from services.storage_service import StorageService


# ---------------------------------------------------------------------------
# Mock Services
# ---------------------------------------------------------------------------

class MockFirestoreService:
    """In-memory mock of FirestoreService for testing."""

    def __init__(self):
        self.profiles: dict[str, dict] = {}
        self.events: dict[str, dict] = {}
        self.messages: dict[str, dict] = {}
        self._profile_counter = 0
        self._event_counter = 0
        self._message_counter = 0

    # -- Profiles --

    async def create_profile(self, user_id: str, data: dict) -> dict:
        self._profile_counter += 1
        doc_id = f"profile-{self._profile_counter:04d}"
        now = datetime.now(timezone.utc).isoformat()
        doc = {
            "id": doc_id,
            "userId": user_id,
            "sunNeeds": None,
            "waterNeeds": None,
            "harvestTime": None,
            "aiLastUpdated": None,
            "createdAt": now,
            "updatedAt": now,
            **data,
        }
        self.profiles[doc_id] = doc
        return doc

    async def get_profiles(self, user_id: str) -> List[dict]:
        return [
            p for p in self.profiles.values()
            if p.get("userId") == user_id
        ]

    async def get_profile(self, user_id: str, profile_id: str) -> Optional[dict]:
        profile = self.profiles.get(profile_id)
        if profile and profile.get("userId") == user_id:
            return profile
        return None

    async def update_profile(self, user_id: str, profile_id: str, data: dict) -> dict:
        profile = self.profiles.get(profile_id)
        if not profile:
            raise Exception("Profile not found")
        now = datetime.now(timezone.utc).isoformat()
        profile.update(data)
        profile["updatedAt"] = now
        return profile

    async def delete_profile(self, user_id: str, profile_id: str) -> None:
        self.profiles.pop(profile_id, None)

    async def delete_events_for_profile(self, user_id: str, profile_id: str) -> None:
        to_delete = [
            eid for eid, e in self.events.items()
            if e.get("profileId") == profile_id and e.get("userId") == user_id
        ]
        for eid in to_delete:
            del self.events[eid]

    # -- Calendar Events --

    async def get_events_by_month(self, user_id: str, month: str) -> List[dict]:
        year, month_num = month.split("-")
        start = f"{month}-01"
        if int(month_num) == 12:
            end = f"{int(year) + 1}-01-01"
        else:
            end = f"{year}-{int(month_num) + 1:02d}-01"

        return [
            e for e in self.events.values()
            if e.get("userId") == user_id
            and start <= e.get("date", "") < end
        ]

    async def update_event(self, user_id: str, event_id: str, data: dict) -> Optional[dict]:
        event = self.events.get(event_id)
        if not event or event.get("userId") != user_id:
            return None
        event.update(data)
        return event

    async def create_events(self, user_id: str, events: List[dict]) -> List[dict]:
        created = []
        for event_data in events:
            self._event_counter += 1
            eid = f"evt-{self._event_counter:04d}"
            now = datetime.now(timezone.utc).isoformat()
            doc = {
                "id": eid,
                "userId": user_id,
                "profileId": event_data.get("profileId", ""),
                "plantName": event_data.get("plantName", ""),
                "date": event_data.get("date", ""),
                "eventType": event_data.get("eventType", ""),
                "description": event_data.get("description", ""),
                "completed": False,
                "createdAt": now,
            }
            self.events[eid] = doc
            created.append(doc)
        return created

    # -- Chat Messages --

    async def save_message(self, user_id: str, role: str, content: str) -> dict:
        self._message_counter += 1
        msg_id = f"msg-{self._message_counter:04d}"
        now = datetime.now(timezone.utc).isoformat()
        doc = {
            "id": msg_id,
            "userId": user_id,
            "role": role,
            "content": content,
            "timestamp": now,
        }
        self.messages[msg_id] = doc
        return doc

    async def get_chat_history(self, user_id: str, limit: int = 50) -> List[dict]:
        user_messages = [
            m for m in self.messages.values()
            if m.get("userId") == user_id
        ]
        # Sort by timestamp and limit
        user_messages.sort(key=lambda m: m.get("timestamp", ""))
        return user_messages[-limit:]

    async def clear_chat_history(self, user_id: str) -> None:
        to_delete = [
            mid for mid, m in self.messages.items()
            if m.get("userId") == user_id
        ]
        for mid in to_delete:
            del self.messages[mid]


class MockAIService:
    """Mock AI service that returns canned responses."""

    def __init__(self):
        self.client = True  # Pretend client is initialized

    async def generate_plant_recommendations(
        self, plant_type: str, age_days: int, planted_date: str
    ) -> dict:
        return {
            "sun_needs": f"Full sun for {plant_type}",
            "water_needs": f"Water every 2-3 days for {plant_type}",
            "harvest_time": f"60-80 days for {plant_type}",
        }

    async def chat_stream(self, message: str, history: list, plant_profiles: list):
        """Yield mock chunks for SSE streaming."""
        chunks = ["Hello! ", "I can help ", "with your plants."]
        for chunk in chunks:
            yield chunk

    async def generate_calendar_events(self, profiles: list, current_date: str) -> list:
        return []


class MockStorageService:
    """Mock storage service."""

    async def generate_upload_url(self, filename: str) -> dict:
        return {
            "upload_url": f"https://mock-storage.example.com/upload/{filename}",
            "public_url": f"https://mock-storage.example.com/public/{filename}",
        }


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def mock_firestore():
    """Fresh MockFirestoreService instance."""
    return MockFirestoreService()


@pytest.fixture
def mock_ai():
    """Fresh MockAIService instance."""
    return MockAIService()


@pytest.fixture
def mock_storage():
    """Fresh MockStorageService instance."""
    return MockStorageService()


@pytest_asyncio.fixture
async def client(mock_firestore, mock_ai, mock_storage) -> AsyncGenerator[AsyncClient, None]:
    """
    Async HTTP test client with mocked services injected into the FastAPI app state.
    """
    # Inject mock services into app state
    app.state.firestore_service = mock_firestore
    app.state.ai_service = mock_ai
    app.state.storage_service = mock_storage

    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport,
        base_url="http://testserver",
        headers={"X-User-ID": "test-user-001"},
    ) as ac:
        yield ac


@pytest_asyncio.fixture
async def client_no_auth(mock_firestore, mock_ai, mock_storage) -> AsyncGenerator[AsyncClient, None]:
    """Test client without the X-User-ID header (unauthenticated)."""
    app.state.firestore_service = mock_firestore
    app.state.ai_service = mock_ai
    app.state.storage_service = mock_storage

    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport,
        base_url="http://testserver",
    ) as ac:
        yield ac
