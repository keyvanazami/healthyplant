"""Pydantic models for plant profiles."""

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


class PlantProfileCreate(BaseModel):
    """Request model for creating a plant profile."""

    name: str = Field(..., min_length=1, max_length=100, description="Display name for the plant")
    plant_type: str = Field("", alias="plantType", max_length=100, description="Type/species of the plant")
    photo_url: Optional[str] = Field(None, alias="photoURL", description="URL of the plant photo")
    age_days: int = Field(..., alias="ageDays", ge=0, description="Age of the plant in days")
    planted_date: str = Field(..., alias="plantedDate", description="Date the plant was planted (YYYY-MM-DD)")
    height_feet: int = Field(..., alias="heightFeet", ge=0, description="Height in feet")
    height_inches: int = Field(..., alias="heightInches", ge=0, le=11, description="Height remaining inches")

    model_config = {"populate_by_name": True}


class PlantProfileUpdate(BaseModel):
    """Request model for updating a plant profile. All fields optional."""

    name: Optional[str] = Field(None, min_length=1, max_length=100)
    plant_type: Optional[str] = Field(None, alias="plantType", min_length=1, max_length=100)
    photo_url: Optional[str] = Field(None, alias="photoURL")
    age_days: Optional[int] = Field(None, alias="ageDays", ge=0)
    planted_date: Optional[str] = Field(None, alias="plantedDate")
    height_feet: Optional[int] = Field(None, alias="heightFeet", ge=0)
    height_inches: Optional[int] = Field(None, alias="heightInches", ge=0, le=11)
    sun_needs: Optional[str] = Field(None, alias="sunNeeds", description="AI-generated sun requirements")
    water_needs: Optional[str] = Field(None, alias="waterNeeds", description="AI-generated water requirements")
    harvest_time: Optional[str] = Field(None, alias="harvestTime", description="AI-generated harvest time estimate")

    model_config = {"populate_by_name": True}


class PlantProfileResponse(BaseModel):
    """Response model for a plant profile."""

    id: str = Field(..., description="Firestore document ID")
    user_id: str = Field(..., alias="userId")
    name: str
    plant_type: str = Field(..., alias="plantType")
    photo_url: Optional[str] = Field(None, alias="photoURL")
    age_days: int = Field(..., alias="ageDays")
    planted_date: str = Field(..., alias="plantedDate")
    height_feet: int = Field(..., alias="heightFeet")
    height_inches: int = Field(..., alias="heightInches")
    sun_needs: Optional[str] = Field(None, alias="sunNeeds")
    water_needs: Optional[str] = Field(None, alias="waterNeeds")
    harvest_time: Optional[str] = Field(None, alias="harvestTime")
    watering_frequency_days: Optional[int] = Field(None, alias="wateringFrequencyDays")
    sun_hours_min: Optional[int] = Field(None, alias="sunHoursMin")
    sun_hours_max: Optional[int] = Field(None, alias="sunHoursMax")
    ai_last_updated: Optional[str] = Field(None, alias="aiLastUpdated")
    sensor_id: Optional[str] = Field(None, alias="sensorId")
    sensor_last_reading: Optional[Any] = Field(None, alias="sensorLastReading")
    created_at: str = Field(..., alias="createdAt")
    updated_at: str = Field(..., alias="updatedAt")

    model_config = {"populate_by_name": True, "from_attributes": True}
