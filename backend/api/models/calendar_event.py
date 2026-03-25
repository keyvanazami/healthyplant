"""Pydantic models for calendar events."""

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class EventType(str, Enum):
    """Types of care events for plants."""

    NEEDS_WATER = "needs_water"
    NEEDS_SUN = "needs_sun"
    NEEDS_TREATMENT = "needs_treatment"


class CalendarEventResponse(BaseModel):
    """Response model for a calendar event."""

    id: str = Field(..., description="Firestore document ID")
    user_id: str = Field(..., alias="userId")
    profile_id: str = Field(..., alias="profileId")
    plant_name: str = Field(..., alias="plantName")
    date: str = Field(..., description="Event date in YYYY-MM-DD format")
    event_type: EventType = Field(..., alias="eventType")
    description: str = Field(..., description="Human-readable description of the care task")
    completed: bool = Field(default=False)
    completed_at: Optional[str] = Field(None, alias="completedAt", description="ISO timestamp when event was completed")

    model_config = {"populate_by_name": True, "from_attributes": True}


class CalendarEventCompleteResponse(BaseModel):
    """Response model when completing an event, includes optional next recurring event."""

    id: str = Field(..., description="Firestore document ID")
    user_id: str = Field(..., alias="userId")
    profile_id: str = Field(..., alias="profileId")
    plant_name: str = Field(..., alias="plantName")
    date: str = Field(..., description="Event date in YYYY-MM-DD format")
    event_type: EventType = Field(..., alias="eventType")
    description: str = Field(..., description="Human-readable description of the care task")
    completed: bool = Field(default=False)
    completed_at: Optional[str] = Field(None, alias="completedAt")
    next_event: Optional[CalendarEventResponse] = Field(
        None, alias="nextEvent",
        description="Automatically created next recurring event, if applicable"
    )

    model_config = {"populate_by_name": True, "from_attributes": True}
