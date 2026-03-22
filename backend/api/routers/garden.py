"""Router for garden display endpoint."""

import logging
from typing import List

from fastapi import APIRouter, HTTPException, Request

from models.plant_profile import PlantProfileResponse

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/garden", response_model=List[PlantProfileResponse])
async def get_garden(request: Request):
    """
    Get all plant profiles formatted for garden display.

    Returns all profiles for the user, ordered by creation date,
    with all available fields including AI-generated recommendations.
    """
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    firestore = request.app.state.firestore_service

    try:
        profiles = await firestore.get_profiles(user_id)
        return profiles
    except Exception as e:
        logger.error(f"Error fetching garden for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve garden data")
