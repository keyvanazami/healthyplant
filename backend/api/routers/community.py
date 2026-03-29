"""Router for community plant sharing and comments."""

import logging
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Request, Query

from models.community import (
    ShareRequest,
    CommunityPlantResponse,
    CommentRequest,
    CommentResponse,
    PlantTypesResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter()


def _get_user_id(request: Request) -> str:
    """Extract user ID from request state (set by auth middleware)."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    return user_id


@router.post("/community/share", response_model=CommunityPlantResponse, status_code=201)
async def share_profile(request: Request, body: ShareRequest):
    """Share a plant profile to the community."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        # Check if already shared
        existing = await firestore.community_plant_exists(user_id, body.profile_id)
        if existing:
            raise HTTPException(status_code=409, detail="Profile is already shared")

        # Fetch the user's private profile
        profile = await firestore.get_profile(user_id, body.profile_id)
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")

        now = datetime.now(timezone.utc).isoformat()
        community_data = {
            "sourceUserId": user_id,
            "sourceProfileId": body.profile_id,
            "displayName": body.display_name,
            "name": profile.get("name", ""),
            "plantType": profile.get("plantType", ""),
            "plantTypeLower": profile.get("plantType", "").lower(),
            "photoURL": profile.get("photoURL"),
            "ageDays": profile.get("ageDays", 0),
            "heightFeet": profile.get("heightFeet", 0),
            "heightInches": profile.get("heightInches", 0),
            "sunNeeds": profile.get("sunNeeds"),
            "waterNeeds": profile.get("waterNeeds"),
            "harvestTime": profile.get("harvestTime"),
            "sharedAt": now,
            "updatedAt": now,
            "commentCount": 0,
        }

        result = await firestore.create_community_plant(community_data)
        result["isMine"] = True
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sharing profile for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to share profile")


@router.delete("/community/{community_id}", status_code=204)
async def unshare_profile(request: Request, community_id: str):
    """Remove a shared plant from the community."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        plant = await firestore.get_community_plant(community_id)
        if not plant:
            raise HTTPException(status_code=404, detail="Community plant not found")

        if plant.get("sourceUserId") != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to unshare this plant")

        await firestore.delete_community_plant(community_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error unsharing community plant {community_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to unshare plant")


@router.get("/community/mine", response_model=List[CommunityPlantResponse])
async def list_my_shared(request: Request):
    """List all plants the current user has shared."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        plants = await firestore.get_community_plants_by_user(user_id)
        for plant in plants:
            plant["isMine"] = True
        return plants
    except Exception as e:
        logger.error(f"Error listing shared plants for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to list shared plants")


@router.get("/community/plant-types", response_model=PlantTypesResponse)
async def list_plant_types(request: Request):
    """Get distinct plant types available in the community."""
    _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        plants = await firestore.get_community_plants(limit=200)
        types_seen = set()
        ordered_types = []
        for plant in plants:
            pt = plant.get("plantType", "")
            if pt and pt not in types_seen:
                types_seen.add(pt)
                ordered_types.append(pt)
        return {"plantTypes": sorted(ordered_types)}
    except Exception as e:
        logger.error(f"Error listing plant types: {e}")
        raise HTTPException(status_code=500, detail="Failed to list plant types")


@router.get("/community/plants", response_model=List[CommunityPlantResponse])
async def browse_community(
    request: Request,
    plant_type: Optional[str] = Query(None, alias="plantType"),
):
    """Browse community plants, optionally filtered by plant type."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        plants = await firestore.get_community_plants(plant_type=plant_type)
        for plant in plants:
            plant["isMine"] = plant.get("sourceUserId") == user_id
        return plants
    except Exception as e:
        logger.error(f"Error browsing community plants: {e}")
        raise HTTPException(status_code=500, detail="Failed to browse community")


@router.get("/community/plants/{community_id}", response_model=CommunityPlantResponse)
async def get_community_plant(request: Request, community_id: str):
    """Get a single community plant by ID."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        plant = await firestore.get_community_plant(community_id)
        if not plant:
            raise HTTPException(status_code=404, detail="Community plant not found")
        plant["isMine"] = plant.get("sourceUserId") == user_id
        return plant
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting community plant {community_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to get community plant")


@router.get(
    "/community/plants/{community_id}/comments",
    response_model=List[CommentResponse],
)
async def list_comments(request: Request, community_id: str):
    """List comments for a community plant."""
    _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        plant = await firestore.get_community_plant(community_id)
        if not plant:
            raise HTTPException(status_code=404, detail="Community plant not found")

        comments = await firestore.get_comments(community_id)
        return comments
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing comments for {community_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to list comments")


@router.post(
    "/community/plants/{community_id}/comments",
    response_model=CommentResponse,
    status_code=201,
)
async def post_comment(request: Request, community_id: str, body: CommentRequest):
    """Post a comment on a community plant."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        plant = await firestore.get_community_plant(community_id)
        if not plant:
            raise HTTPException(status_code=404, detail="Community plant not found")

        now = datetime.now(timezone.utc).isoformat()
        comment_data = {
            "userId": user_id,
            "displayName": body.display_name,
            "content": body.content,
            "createdAt": now,
        }

        result = await firestore.add_comment(community_id, comment_data)
        await firestore.increment_comment_count(community_id)
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error posting comment on {community_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to post comment")
