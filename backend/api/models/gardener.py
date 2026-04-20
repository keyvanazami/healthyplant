"""Pydantic models for gardener profiles and social features."""

from typing import List, Optional

from pydantic import BaseModel, Field


class GardenerProfileUpsertRequest(BaseModel):
    bio: Optional[str] = Field(None, max_length=300)
    experience_level: Optional[str] = Field(None, alias="experienceLevel")
    avatar_url: Optional[str] = Field(None, alias="avatarURL")
    is_public: bool = Field(True, alias="isPublic")
    climate_zone: Optional[str] = Field(None, alias="climateZone", max_length=100)

    model_config = {"populate_by_name": True}


class GardenerProfileResponse(BaseModel):
    user_id: str = Field(..., alias="userId")
    display_name: Optional[str] = Field(None, alias="displayName")
    bio: Optional[str] = None
    experience_level: Optional[str] = Field(None, alias="experienceLevel")
    avatar_url: Optional[str] = Field(None, alias="avatarURL")
    is_public: bool = Field(True, alias="isPublic")
    climate_zone: Optional[str] = Field(None, alias="climateZone")
    follower_count: int = Field(0, alias="followerCount")
    following_count: int = Field(0, alias="followingCount")
    is_following: bool = Field(False, alias="isFollowing")
    rank_name: Optional[str] = Field(None, alias="rankName")
    created_at: Optional[str] = Field(None, alias="createdAt")
    updated_at: Optional[str] = Field(None, alias="updatedAt")

    model_config = {"populate_by_name": True, "from_attributes": True}


class FCMTokenRequest(BaseModel):
    fcm_token: str = Field(..., alias="fcmToken")

    model_config = {"populate_by_name": True}


class FollowResponse(BaseModel):
    is_following: bool = Field(..., alias="isFollowing")
    follower_count: int = Field(..., alias="followerCount")

    model_config = {"populate_by_name": True}
