"""Tests for the /api/v1/chat endpoints."""

import json

import pytest


@pytest.mark.asyncio
async def test_send_chat_message_returns_sse_stream(client):
    """POST /api/v1/chat should return a streaming SSE response."""
    payload = {"content": "How do I care for my tomato plant?"}

    response = await client.post("/api/v1/chat", json=payload)

    assert response.status_code == 200
    assert "text/event-stream" in response.headers.get("content-type", "")

    # Parse SSE events from the response body
    body = response.text
    events = []
    for line in body.strip().split("\n"):
        if line.startswith("data: "):
            event_data = json.loads(line[6:])
            events.append(event_data)

    # Should have chunk events and a done event
    chunk_events = [e for e in events if e.get("type") == "chunk"]
    done_events = [e for e in events if e.get("type") == "done"]

    assert len(chunk_events) > 0, "Should receive at least one chunk event"
    assert len(done_events) == 1, "Should receive exactly one done event"

    # Verify chunk content
    for chunk in chunk_events:
        assert "content" in chunk
        assert len(chunk["content"]) > 0

    # Verify done event has messageId
    assert "messageId" in done_events[0]


@pytest.mark.asyncio
async def test_send_chat_message_saves_user_message(client, mock_firestore):
    """POST /api/v1/chat should save the user message to Firestore."""
    payload = {"content": "Tell me about watering schedules"}

    await client.post("/api/v1/chat", json=payload)

    # Check that a user message was saved
    user_messages = [
        m for m in mock_firestore.messages.values()
        if m["role"] == "user" and m["userId"] == "test-user-001"
    ]
    assert len(user_messages) >= 1
    assert user_messages[0]["content"] == "Tell me about watering schedules"


@pytest.mark.asyncio
async def test_send_chat_message_saves_assistant_response(client, mock_firestore):
    """POST /api/v1/chat should save the full assistant response after streaming."""
    payload = {"content": "What soil is best?"}

    await client.post("/api/v1/chat", json=payload)

    # Check that an assistant message was saved
    assistant_messages = [
        m for m in mock_firestore.messages.values()
        if m["role"] == "assistant" and m["userId"] == "test-user-001"
    ]
    assert len(assistant_messages) >= 1
    # The mock streams "Hello! ", "I can help ", "with your plants."
    assert assistant_messages[0]["content"] == "Hello! I can help with your plants."


@pytest.mark.asyncio
async def test_send_empty_message_returns_422(client):
    """POST /api/v1/chat with empty content should return 422."""
    response = await client.post("/api/v1/chat", json={"content": ""})
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_chat_history(client, mock_firestore):
    """GET /api/v1/chat/history should return chat messages."""
    # Seed some messages
    await mock_firestore.save_message("test-user-001", "user", "Hello")
    await mock_firestore.save_message("test-user-001", "assistant", "Hi there!")
    await mock_firestore.save_message("test-user-001", "user", "How's my plant?")

    response = await client.get("/api/v1/chat/history")

    assert response.status_code == 200
    data = response.json()
    assert "messages" in data
    assert len(data["messages"]) == 3

    # Messages should be in chronological order
    roles = [m["role"] for m in data["messages"]]
    assert roles == ["user", "assistant", "user"]


@pytest.mark.asyncio
async def test_get_chat_history_empty(client):
    """GET /api/v1/chat/history should return empty list when no messages exist."""
    response = await client.get("/api/v1/chat/history")

    assert response.status_code == 200
    data = response.json()
    assert data["messages"] == []


@pytest.mark.asyncio
async def test_get_chat_history_only_returns_user_messages(client, mock_firestore):
    """Chat history should only include messages for the authenticated user."""
    # Save messages for two different users
    await mock_firestore.save_message("test-user-001", "user", "My message")
    await mock_firestore.save_message("other-user-999", "user", "Not my message")

    response = await client.get("/api/v1/chat/history")

    assert response.status_code == 200
    data = response.json()
    assert len(data["messages"]) == 1
    assert data["messages"][0]["content"] == "My message"


@pytest.mark.asyncio
async def test_clear_chat_history(client, mock_firestore):
    """DELETE /api/v1/chat/history should remove all messages for the user."""
    # Seed messages
    await mock_firestore.save_message("test-user-001", "user", "Hello")
    await mock_firestore.save_message("test-user-001", "assistant", "Hi!")

    # Verify messages exist
    history = await mock_firestore.get_chat_history("test-user-001")
    assert len(history) == 2

    # Clear history
    response = await client.delete("/api/v1/chat/history")
    assert response.status_code == 204

    # Verify messages are gone
    history_after = await mock_firestore.get_chat_history("test-user-001")
    assert len(history_after) == 0


@pytest.mark.asyncio
async def test_clear_chat_history_does_not_affect_other_users(client, mock_firestore):
    """DELETE /api/v1/chat/history should only clear the authenticated user's messages."""
    await mock_firestore.save_message("test-user-001", "user", "My message")
    await mock_firestore.save_message("other-user-999", "user", "Their message")

    response = await client.delete("/api/v1/chat/history")
    assert response.status_code == 204

    # Other user's messages should still exist
    other_history = await mock_firestore.get_chat_history("other-user-999")
    assert len(other_history) == 1
    assert other_history[0]["content"] == "Their message"


@pytest.mark.asyncio
async def test_chat_requires_auth(client_no_auth):
    """Chat endpoints should return 401 without auth header."""
    response = await client_no_auth.post("/api/v1/chat", json={"content": "Hello"})
    assert response.status_code == 401

    response = await client_no_auth.get("/api/v1/chat/history")
    assert response.status_code == 401

    response = await client_no_auth.delete("/api/v1/chat/history")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_chat_sse_headers(client):
    """POST /api/v1/chat should return correct SSE headers."""
    response = await client.post("/api/v1/chat", json={"content": "Test"})

    assert response.status_code == 200
    assert "text/event-stream" in response.headers.get("content-type", "")
    assert response.headers.get("cache-control") == "no-cache"
