"""Router for gardener profiles and the follow system."""

import asyncio
import logging
from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, HTTPException, Request

from models.gardener import (
    FCMTokenRequest,
    FollowResponse,
    GardenerProfileResponse,
    GardenerProfileUpsertRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter()

# ── helpers ────────────────────────────────────────────────────────────────────

_RANK_TIERS = [
    ("Seedling", 0),
    ("Sprout", 50),
    ("Grower", 200),
    ("Gardener", 500),
    ("Green Thumb", 1000),
    ("Expert", 2000),
    ("Master Gardener", 4000),
]


async def _compute_rank(firestore, user_id: str) -> str:
    """Compute gardening rank from plant profile creation dates."""
    try:
        profiles = await firestore.get_profiles(user_id)
        now = datetime.now(timezone.utc)
        score = 0
        for p in profiles:
            created_at = p.get("createdAt", "")
            if created_at:
                try:
                    dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                    if dt.tzinfo is None:
                        dt = dt.replace(tzinfo=timezone.utc)
                    days = (now - dt).days
                    score += max(0, days)
                except (ValueError, TypeError):
                    pass
        score += len(profiles) * 30
        rank_name = _RANK_TIERS[0][0]
        for name, min_score in _RANK_TIERS:
            if score >= min_score:
                rank_name = name
        return rank_name
    except Exception:
        return _RANK_TIERS[0][0]


def _get_user_id(request: Request) -> str:
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    return user_id


def _is_anonymous(user_id: str) -> bool:
    """Heuristic: Firebase UIDs are 28 chars; anonymous UUIDs are 36 (with hyphens)."""
    return len(user_id) > 30 and "-" in user_id


async def _build_response(
    firestore,
    user_id: str,
    requester_id: str,
) -> GardenerProfileResponse:
    """Fetch profile doc, counts, and isFollowing flag, return response model."""
    profile = await firestore.get_gardener_profile(user_id) or {}
    follower_count = await firestore.get_follower_count(user_id)
    following_count = await firestore.get_following_count(user_id)
    is_following = (
        False
        if requester_id == user_id
        else await firestore.is_following(requester_id, user_id)
    )
    rank_name = await _compute_rank(firestore, user_id)
    return GardenerProfileResponse(
        userId=user_id,
        displayName=profile.get("displayName"),
        bio=profile.get("bio"),
        experienceLevel=profile.get("experienceLevel"),
        avatarURL=profile.get("avatarURL"),
        isPublic=profile.get("isPublic", True),
        followerCount=follower_count,
        followingCount=following_count,
        isFollowing=is_following,
        rankName=rank_name,
        createdAt=profile.get("createdAt"),
        updatedAt=profile.get("updatedAt"),
    )


# ── own profile ────────────────────────────────────────────────────────────────


@router.get("/gardeners/me", response_model=GardenerProfileResponse)
async def get_my_profile(request: Request):
    """Fetch the authenticated user's gardener profile."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    try:
        return await _build_response(firestore, user_id, user_id)
    except Exception as e:
        logger.error(f"Error fetching gardener profile for {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch profile")


@router.put("/gardeners/me", response_model=GardenerProfileResponse)
async def upsert_my_profile(request: Request, body: GardenerProfileUpsertRequest):
    """Create or update the authenticated user's gardener profile."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    try:
        data = {
            "bio": body.bio,
            "experienceLevel": body.experience_level,
            "avatarURL": body.avatar_url,
            "isPublic": body.is_public,
        }
        # Remove None values so they don't overwrite existing fields on merge
        data = {k: v for k, v in data.items() if v is not None}
        data["isPublic"] = body.is_public  # always write this bool
        await firestore.upsert_gardener_profile(user_id, data)
        return await _build_response(firestore, user_id, user_id)
    except Exception as e:
        logger.error(f"Error upserting gardener profile for {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to update profile")


@router.put("/gardeners/me/fcm-token", status_code=204)
async def register_fcm_token(request: Request, body: FCMTokenRequest):
    """Register or refresh the user's FCM device token."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    try:
        await firestore.update_fcm_token(user_id, body.fcm_token)
    except Exception as e:
        logger.error(f"Error storing FCM token for {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to store FCM token")


@router.get("/gardeners/me/following", response_model=List[GardenerProfileResponse])
async def list_my_following(request: Request):
    """List all gardener profiles the current user follows."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    try:
        following_ids = await firestore.get_following_list(user_id)
        results = []
        for target_id in following_ids:
            try:
                profile = await _build_response(firestore, target_id, user_id)
                results.append(profile)
            except Exception:
                pass  # skip profiles that fail to load
        return results
    except Exception as e:
        logger.error(f"Error listing following for {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to list following")


# ── public gardener list ───────────────────────────────────────────────────────


@router.get("/gardeners", response_model=List[GardenerProfileResponse])
async def list_public_gardeners(request: Request):
    """List all public gardener profiles."""
    firestore = request.app.state.firestore_service
    requester_id = getattr(request.state, "user_id", "") or ""
    try:
        raw = await firestore.get_public_gardeners()
        results = await asyncio.gather(
            *[_build_response(firestore, g["userId"], requester_id) for g in raw if "userId" in g],
            return_exceptions=True,
        )
        return [r for r in results if isinstance(r, GardenerProfileResponse)]
    except Exception as e:
        logger.error(f"Error listing public gardeners: {e}")
        raise HTTPException(status_code=500, detail="Failed to list gardeners")


# ── public profiles ────────────────────────────────────────────────────────────


@router.get("/gardeners/{user_id}", response_model=GardenerProfileResponse)
async def get_gardener_profile(request: Request, user_id: str):
    """Fetch a public gardener profile by user ID."""
    requester_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    try:
        profile = await firestore.get_gardener_profile(user_id) or {}
        is_owner = requester_id == user_id
        if not profile.get("isPublic", True) and not is_owner:
            raise HTTPException(status_code=404, detail="Profile is private")
        return await _build_response(firestore, user_id, requester_id)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching gardener profile {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch profile")


@router.get("/gardeners/{user_id}/plants")
async def get_gardener_plants(request: Request, user_id: str):
    """List community plants shared by a specific gardener."""
    requester_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    try:
        profile = await firestore.get_gardener_profile(user_id) or {}
        is_owner = requester_id == user_id
        if not profile.get("isPublic", True) and not is_owner:
            raise HTTPException(status_code=404, detail="Profile is private")
        plants = await firestore.get_community_plants_by_user(user_id)
        for plant in plants:
            plant["isMine"] = plant.get("sourceUserId") == requester_id
        return plants
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching plants for gardener {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch plants")


# ── follow / unfollow ──────────────────────────────────────────────────────────


@router.post("/gardeners/{user_id}/follow", response_model=FollowResponse)
async def follow_gardener(request: Request, user_id: str):
    """Follow a gardener. Idempotent."""
    requester_id = _get_user_id(request)
    if _is_anonymous(requester_id):
        raise HTTPException(status_code=403, detail="sign_in_required")
    if requester_id == user_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    firestore = request.app.state.firestore_service
    try:
        already = await firestore.is_following(requester_id, user_id)
        if not already:
            await firestore.follow_gardener(requester_id, user_id)
        count = await firestore.get_follower_count(user_id)
        return FollowResponse(isFollowing=True, followerCount=count)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error following {user_id} by {requester_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to follow")


@router.delete("/gardeners/{user_id}/follow", response_model=FollowResponse)
async def unfollow_gardener(request: Request, user_id: str):
    """Unfollow a gardener."""
    requester_id = _get_user_id(request)
    firestore = request.app.state.firestore_service
    try:
        already = await firestore.is_following(requester_id, user_id)
        if already:
            await firestore.unfollow_gardener(requester_id, user_id)
        count = await firestore.get_follower_count(user_id)
        return FollowResponse(isFollowing=False, followerCount=count)
    except Exception as e:
        logger.error(f"Error unfollowing {user_id} by {requester_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to unfollow")
