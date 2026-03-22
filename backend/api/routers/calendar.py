"""Router for calendar event operations."""

import logging
import re
from typing import List

from fastapi import APIRouter, HTTPException, Query, Request

from models.calendar_event import CalendarEventResponse

logger = logging.getLogger(__name__)

router = APIRouter()

MONTH_PATTERN = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")


@router.get("/calendar", response_model=List[CalendarEventResponse])
async def get_calendar_events(
    request: Request,
    month: str = Query(..., description="Month in YYYY-MM format", example="2026-03"),
):
    """Get calendar events for a specific month."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    if not MONTH_PATTERN.match(month):
        raise HTTPException(
            status_code=400,
            detail="Invalid month format. Use YYYY-MM (e.g., 2026-03)",
        )

    firestore = request.app.state.firestore_service

    try:
        events = await firestore.get_events_by_month(user_id, month)
        return events
    except Exception as e:
        logger.error(f"Error fetching calendar for user {user_id}, month {month}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve calendar events")


@router.put("/calendar/{event_id}/complete", response_model=CalendarEventResponse)
async def complete_event(request: Request, event_id: str):
    """Mark a calendar event as completed."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    firestore = request.app.state.firestore_service

    try:
        event = await firestore.update_event(user_id, event_id, {"completed": True})
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        return event
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error completing event {event_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to update event")
