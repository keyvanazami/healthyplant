"""Tests for the /api/v1/profiles endpoints."""

import pytest


@pytest.mark.asyncio
async def test_create_profile(client):
    """POST /api/v1/profiles should create a new profile and return 201."""
    payload = {
        "name": "Tommy Tomato",
        "plantType": "Tomato",
        "ageDays": 45,
        "plantedDate": "2026-02-05",
        "heightFeet": 1,
        "heightInches": 8,
        "photoURL": None,
    }

    response = await client.post("/api/v1/profiles", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Tommy Tomato"
    assert data["plantType"] == "Tomato"
    assert data["ageDays"] == 45
    assert data["heightFeet"] == 1
    assert data["heightInches"] == 8
    assert "id" in data
    assert "createdAt" in data
    assert "updatedAt" in data


@pytest.mark.asyncio
async def test_create_profile_with_photo(client):
    """POST /api/v1/profiles with a photoURL should persist it."""
    payload = {
        "name": "Basil Buddy",
        "plantType": "Basil",
        "ageDays": 10,
        "plantedDate": "2026-03-12",
        "heightFeet": 0,
        "heightInches": 4,
        "photoURL": "https://example.com/basil.jpg",
    }

    response = await client.post("/api/v1/profiles", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Basil Buddy"


@pytest.mark.asyncio
async def test_list_profiles_empty(client):
    """GET /api/v1/profiles should return empty list when no profiles exist."""
    response = await client.get("/api/v1/profiles")

    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_list_profiles_returns_created(client):
    """GET /api/v1/profiles should return all profiles for the user."""
    # Create two profiles
    for name in ["Plant A", "Plant B"]:
        await client.post("/api/v1/profiles", json={
            "name": name,
            "plantType": "Tomato",
            "ageDays": 10,
            "plantedDate": "2026-03-01",
            "heightFeet": 1,
            "heightInches": 0,
        })

    response = await client.get("/api/v1/profiles")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    names = {p["name"] for p in data}
    assert "Plant A" in names
    assert "Plant B" in names


@pytest.mark.asyncio
async def test_get_single_profile(client):
    """GET /api/v1/profiles/{id} should return a single profile."""
    create_resp = await client.post("/api/v1/profiles", json={
        "name": "Solo Plant",
        "plantType": "Cactus",
        "ageDays": 100,
        "plantedDate": "2025-12-01",
        "heightFeet": 0,
        "heightInches": 6,
    })
    profile_id = create_resp.json()["id"]

    response = await client.get(f"/api/v1/profiles/{profile_id}")

    assert response.status_code == 200
    assert response.json()["id"] == profile_id
    assert response.json()["name"] == "Solo Plant"


@pytest.mark.asyncio
async def test_get_nonexistent_profile_returns_404(client):
    """GET /api/v1/profiles/{id} should return 404 for nonexistent ID."""
    response = await client.get("/api/v1/profiles/nonexistent-id-999")

    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_update_profile(client):
    """PUT /api/v1/profiles/{id} should update the profile."""
    create_resp = await client.post("/api/v1/profiles", json={
        "name": "Old Name",
        "plantType": "Tomato",
        "ageDays": 10,
        "plantedDate": "2026-03-01",
        "heightFeet": 1,
        "heightInches": 0,
    })
    profile_id = create_resp.json()["id"]

    update_resp = await client.put(f"/api/v1/profiles/{profile_id}", json={
        "name": "New Name",
        "plantType": "Cherry Tomato",
    })

    assert update_resp.status_code == 200
    data = update_resp.json()
    assert data["name"] == "New Name"
    assert data["plantType"] == "Cherry Tomato"


@pytest.mark.asyncio
async def test_update_nonexistent_profile_returns_404(client):
    """PUT /api/v1/profiles/{id} should return 404 for nonexistent ID."""
    response = await client.put("/api/v1/profiles/fake-id", json={
        "name": "Nope",
    })

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_delete_profile(client):
    """DELETE /api/v1/profiles/{id} should remove the profile."""
    create_resp = await client.post("/api/v1/profiles", json={
        "name": "Delete Me",
        "plantType": "Weed",
        "ageDays": 1,
        "plantedDate": "2026-03-20",
        "heightFeet": 0,
        "heightInches": 1,
    })
    profile_id = create_resp.json()["id"]

    delete_resp = await client.delete(f"/api/v1/profiles/{profile_id}")
    assert delete_resp.status_code == 204

    # Verify it's gone
    get_resp = await client.get(f"/api/v1/profiles/{profile_id}")
    assert get_resp.status_code == 404


@pytest.mark.asyncio
async def test_delete_nonexistent_profile_returns_404(client):
    """DELETE /api/v1/profiles/{id} should return 404 for nonexistent ID."""
    response = await client.delete("/api/v1/profiles/nonexistent-id")

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_create_profile_missing_required_field(client):
    """POST /api/v1/profiles with missing required fields should return 422."""
    response = await client.post("/api/v1/profiles", json={
        "name": "Incomplete",
        # Missing plantType, ageDays, plantedDate, heightFeet, heightInches
    })

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_profiles_require_auth(client_no_auth):
    """Endpoints should return 401 without X-User-ID header."""
    response = await client_no_auth.get("/api/v1/profiles")
    assert response.status_code == 401
