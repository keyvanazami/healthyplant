"""Router for plant profile CRUD operations."""

import logging
from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, HTTPException, Request

from models.plant_profile import (
    PlantProfileCreate,
    PlantProfileResponse,
    PlantProfileUpdate,
)

logger = logging.getLogger(__name__)

# Fields that affect care recommendations — changes trigger AI re-generation
CARE_RELEVANT_FIELDS = {"plantType", "ageDays", "plantedDate", "isIndoor"}

router = APIRouter()


def _get_user_id(request: Request) -> str:
    """Extract user ID from request state (set by auth middleware)."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    return user_id


@router.get("/profiles", response_model=List[PlantProfileResponse])
async def list_profiles(request: Request):
    """List all plant profiles for the authenticated user."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        profiles = await firestore.get_profiles(user_id)
        return profiles
    except Exception as e:
        logger.error(f"Error listing profiles for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve profiles")


@router.post("/profiles", response_model=PlantProfileResponse, status_code=201)
async def create_profile(request: Request, body: PlantProfileCreate):
    """Create a new plant profile and trigger AI recommendations asynchronously."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    ai_service = request.app.state.ai_service

    try:
        profile_data = body.model_dump(by_alias=True, exclude_none=True)
        profile = await firestore.create_profile(user_id, profile_data)

        # Trigger AI recommendation generation asynchronously (fire-and-forget)
        import asyncio

        asyncio.create_task(
            _generate_and_update_recommendations(
                ai_service, firestore, user_id, profile["id"], profile
            )
        )

        return profile
    except Exception as e:
        logger.error(f"Error creating profile for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create profile")


async def _generate_and_update_recommendations(
    ai_service, firestore, user_id: str, profile_id: str, profile: dict
):
    """Background task to generate AI recommendations, update the profile, and regenerate calendar."""
    try:
        gardener = await firestore.get_gardener_profile(user_id) or {}
        climate_zone = gardener.get("climateZone")
        recommendations = await ai_service.generate_plant_recommendations(
            plant_type=profile.get("plantType", ""),
            age_days=profile.get("ageDays", 0),
            planted_date=profile.get("plantedDate", ""),
            is_indoor=profile.get("isIndoor", False),
            climate_zone=climate_zone,
        )
        await firestore.update_profile(user_id, profile_id, {
            "sunNeeds": recommendations.get("sun_needs"),
            "waterNeeds": recommendations.get("water_needs"),
            "harvestTime": recommendations.get("harvest_time"),
            "wateringFrequencyDays": recommendations.get("watering_frequency_days"),
            "sunHoursMin": recommendations.get("sun_hours_min"),
            "sunHoursMax": recommendations.get("sun_hours_max"),
        })
        logger.info(f"AI recommendations updated for profile {profile_id}")

        # Regenerate calendar events after recommendations update
        await _regenerate_calendar_for_user(ai_service, firestore, user_id)
    except Exception as e:
        logger.error(f"Failed to generate AI recommendations for profile {profile_id}: {e}")


async def _regenerate_calendar_for_user(ai_service, firestore, user_id: str):
    """Regenerate calendar events for a user based on their current profiles."""
    try:
        current_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        profiles = await firestore.get_profiles(user_id)
        if not profiles:
            return

        events = await ai_service.generate_calendar_events(profiles, current_date)
        if not events:
            return

        # Deduplicate and save new events
        new_events = []
        for event in events:
            exists = await firestore.event_exists(
                user_id,
                event.get("profileId", ""),
                event.get("date", ""),
                event.get("eventType", ""),
            )
            if not exists:
                new_events.append(event)

        if new_events:
            await firestore.create_events(user_id, new_events)
            logger.info(f"Created {len(new_events)} calendar events for user {user_id}")
    except Exception as e:
        logger.error(f"Failed to regenerate calendar for user {user_id}: {e}")


@router.get("/profiles/{profile_id}", response_model=PlantProfileResponse)
async def get_profile(request: Request, profile_id: str):
    """Get a single plant profile by ID."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        profile = await firestore.get_profile(user_id, profile_id)
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")
        return profile
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting profile {profile_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve profile")


@router.put("/profiles/{profile_id}", response_model=PlantProfileResponse)
async def update_profile(request: Request, profile_id: str, body: PlantProfileUpdate):
    """Update an existing plant profile."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        existing = await firestore.get_profile(user_id, profile_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Profile not found")

        update_data = body.model_dump(by_alias=True, exclude_none=True)
        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        profile = await firestore.update_profile(user_id, profile_id, update_data)

        # If care-relevant fields changed, re-trigger AI recommendations + calendar regen
        if CARE_RELEVANT_FIELDS & set(update_data.keys()):
            ai_service = request.app.state.ai_service

            import asyncio

            asyncio.create_task(
                _generate_and_update_recommendations(
                    ai_service, firestore, user_id, profile_id, profile
                )
            )

        return profile
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating profile {profile_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to update profile")


@router.delete("/profiles/{profile_id}", status_code=204)
async def delete_profile(request: Request, profile_id: str):
    """Delete a plant profile and its associated calendar events."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        existing = await firestore.get_profile(user_id, profile_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Profile not found")

        # Delete associated calendar events first
        await firestore.delete_events_for_profile(user_id, profile_id)
        await firestore.delete_profile(user_id, profile_id)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting profile {profile_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete profile")
