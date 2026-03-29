"""Pydantic models for community features."""

from typing import List, Optional

from pydantic import BaseModel, Field


class ShareRequest(BaseModel):
    """Request model for sharing a plant profile to the community."""

    profile_id: str = Field(..., alias="profileId", description="ID of the profile to share")
    display_name: str = Field("Plant Lover", alias="displayName", max_length=50)

    model_config = {"populate_by_name": True}


class CommunityPlantResponse(BaseModel):
    """Response model for a community-shared plant."""

    id: str = Field(..., description="Community document ID")
    source_user_id: str = Field(..., alias="sourceUserId")
    source_profile_id: str = Field(..., alias="sourceProfileId")
    display_name: str = Field(..., alias="displayName")
    name: str
    plant_type: str = Field(..., alias="plantType")
    photo_url: Optional[str] = Field(None, alias="photoURL")
    age_days: int = Field(..., alias="ageDays")
    height_feet: int = Field(..., alias="heightFeet")
    height_inches: int = Field(..., alias="heightInches")
    sun_needs: Optional[str] = Field(None, alias="sunNeeds")
    water_needs: Optional[str] = Field(None, alias="waterNeeds")
    harvest_time: Optional[str] = Field(None, alias="harvestTime")
    shared_at: str = Field(..., alias="sharedAt")
    comment_count: int = Field(0, alias="commentCount")
    is_mine: bool = Field(False, alias="isMine")

    model_config = {"populate_by_name": True, "from_attributes": True}


class CommentRequest(BaseModel):
    """Request model for posting a comment."""

    content: str = Field(..., min_length=1, max_length=500, description="Comment text")
    display_name: str = Field("Plant Lover", alias="displayName", max_length=50)

    model_config = {"populate_by_name": True}


class CommentResponse(BaseModel):
    """Response model for a comment."""

    id: str = Field(..., description="Comment document ID")
    user_id: str = Field(..., alias="userId")
    display_name: str = Field(..., alias="displayName")
    content: str
    created_at: str = Field(..., alias="createdAt")

    model_config = {"populate_by_name": True, "from_attributes": True}


class PlantTypesResponse(BaseModel):
    """Response model for available plant types."""

    plant_types: List[str] = Field(default_factory=list, alias="plantTypes")

    model_config = {"populate_by_name": True}
