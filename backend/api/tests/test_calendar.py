"""Tests for the /api/v1/calendar endpoints."""

import pytest


@pytest.mark.asyncio
async def test_get_calendar_events_valid_month(client, mock_firestore):
    """GET /api/v1/calendar?month=YYYY-MM should return events for that month."""
    # Seed some events directly into the mock
    mock_firestore.events["evt-seed-1"] = {
        "id": "evt-seed-1",
        "userId": "test-user-001",
        "profileId": "profile-001",
        "plantName": "Tommy Tomato",
        "date": "2026-03-15",
        "eventType": "needs_water",
        "description": "Water thoroughly",
        "completed": False,
    }
    mock_firestore.events["evt-seed-2"] = {
        "id": "evt-seed-2",
        "userId": "test-user-001",
        "profileId": "profile-001",
        "plantName": "Tommy Tomato",
        "date": "2026-03-20",
        "eventType": "needs_sun",
        "description": "Move to sunny spot",
        "completed": False,
    }

    response = await client.get("/api/v1/calendar", params={"month": "2026-03"})

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["plantName"] == "Tommy Tomato"


@pytest.mark.asyncio
async def test_get_calendar_events_empty_month(client):
    """GET /api/v1/calendar should return empty list for a month with no events."""
    response = await client.get("/api/v1/calendar", params={"month": "2025-01"})

    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_get_calendar_events_filters_by_month(client, mock_firestore):
    """Events from other months should not be returned."""
    mock_firestore.events["evt-march"] = {
        "id": "evt-march",
        "userId": "test-user-001",
        "profileId": "p-1",
        "plantName": "Plant",
        "date": "2026-03-10",
        "eventType": "needs_water",
        "description": "March event",
        "completed": False,
    }
    mock_firestore.events["evt-april"] = {
        "id": "evt-april",
        "userId": "test-user-001",
        "profileId": "p-1",
        "plantName": "Plant",
        "date": "2026-04-10",
        "eventType": "needs_water",
        "description": "April event",
        "completed": False,
    }

    response = await client.get("/api/v1/calendar", params={"month": "2026-03"})

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == "evt-march"


@pytest.mark.asyncio
async def test_invalid_month_format_returns_400(client):
    """GET /api/v1/calendar with invalid month format should return 400."""
    # Missing leading zero
    response = await client.get("/api/v1/calendar", params={"month": "2026-3"})
    assert response.status_code == 400

    # Wrong format entirely
    response = await client.get("/api/v1/calendar", params={"month": "March 2026"})
    assert response.status_code == 400

    # Invalid month number
    response = await client.get("/api/v1/calendar", params={"month": "2026-13"})
    assert response.status_code == 400

    # Empty string
    response = await client.get("/api/v1/calendar", params={"month": ""})
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_missing_month_param_returns_422(client):
    """GET /api/v1/calendar without month param should return 422."""
    response = await client.get("/api/v1/calendar")
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_complete_event(client, mock_firestore):
    """PUT /api/v1/calendar/{id}/complete should mark event as completed."""
    mock_firestore.events["evt-complete-1"] = {
        "id": "evt-complete-1",
        "userId": "test-user-001",
        "profileId": "profile-001",
        "plantName": "Tommy Tomato",
        "date": "2026-03-22",
        "eventType": "needs_water",
        "description": "Water the plant",
        "completed": False,
    }

    response = await client.put("/api/v1/calendar/evt-complete-1/complete")

    assert response.status_code == 200
    data = response.json()
    assert data["completed"] is True
    assert data["id"] == "evt-complete-1"


@pytest.mark.asyncio
async def test_complete_nonexistent_event_returns_404(client):
    """PUT /api/v1/calendar/{id}/complete should return 404 for nonexistent event."""
    response = await client.put("/api/v1/calendar/nonexistent-evt/complete")

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_calendar_requires_auth(client_no_auth):
    """Calendar endpoints should return 401 without auth header."""
    response = await client_no_auth.get("/api/v1/calendar", params={"month": "2026-03"})
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_december_month_boundary(client, mock_firestore):
    """GET /api/v1/calendar for December should handle year boundary correctly."""
    mock_firestore.events["evt-dec"] = {
        "id": "evt-dec",
        "userId": "test-user-001",
        "profileId": "p-1",
        "plantName": "Winter Plant",
        "date": "2026-12-15",
        "eventType": "needs_water",
        "description": "Winter watering",
        "completed": False,
    }

    response = await client.get("/api/v1/calendar", params={"month": "2026-12"})

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["date"] == "2026-12-15"
