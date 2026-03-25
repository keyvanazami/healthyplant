"""Router for calendar event operations."""

import logging
import re
from datetime import datetime, timedelta, timezone
from typing import List

from fastapi import APIRouter, HTTPException, Query, Request

from models.calendar_event import CalendarEventCompleteResponse, CalendarEventResponse
from services.schedule_service import generate_deterministic_events

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


@router.post("/calendar/generate", response_model=List[CalendarEventResponse])
async def generate_calendar(
    request: Request,
    days: int = Query(default=30, ge=1, le=90, description="Days ahead to generate"),
):
    """Generate calendar events using deterministic scheduling for profiles with
    structured data, falling back to AI for profiles without it."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    firestore = request.app.state.firestore_service
    ai_service = request.app.state.ai_service

    try:
        profiles = await firestore.get_profiles(user_id)
        if not profiles:
            return []

        current_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")

        # Hybrid approach: deterministic for structured profiles, AI for the rest
        deterministic_events, ai_profiles = generate_deterministic_events(
            profiles, current_date, days_ahead=days
        )

        # Fall back to AI only for profiles missing structured data
        ai_events = []
        if ai_profiles:
            ai_events = await ai_service.generate_calendar_events(
                ai_profiles, current_date
            )

        all_events = deterministic_events + (ai_events or [])
        if not all_events:
            return []

        # Deduplicate against existing events
        new_events = []
        for event in all_events:
            exists = await firestore.event_exists(
                user_id,
                event.get("profileId", ""),
                event.get("date", ""),
                event.get("eventType", ""),
            )
            if not exists:
                new_events.append(event)

        if not new_events:
            return []

        created = await firestore.create_events(user_id, new_events)
        logger.info(
            f"Generated {len(created)} calendar events for user {user_id} "
            f"({len(deterministic_events)} deterministic, {len(ai_events)} AI)"
        )
        return created
    except Exception as e:
        logger.error(f"Error generating calendar for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate calendar events")


@router.put("/calendar/{event_id}/complete", response_model=CalendarEventCompleteResponse)
async def complete_event(request: Request, event_id: str):
    """Mark a calendar event as completed. If the profile has structured
    recurrence data, automatically creates the next occurrence."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    firestore = request.app.state.firestore_service

    try:
        completed_at = datetime.now(timezone.utc).isoformat()
        event = await firestore.update_event(
            user_id, event_id, {"completed": True, "completedAt": completed_at}
        )
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")

        # Reschedule on complete: if the profile has wateringFrequencyDays,
        # automatically create the next watering event
        next_event = None
        if event.get("eventType") == "needs_water":
            profile_id = event.get("profileId", "")
            if profile_id:
                profile = await firestore.get_profile(user_id, profile_id)
                if profile:
                    freq = profile.get("wateringFrequencyDays")
                    if freq and freq > 0:
                        next_date = (
                            datetime.now(timezone.utc) + timedelta(days=freq)
                        ).strftime("%Y-%m-%d")
                        next_event = await firestore.create_next_recurring_event(
                            user_id, event, freq
                        )
                        logger.info(
                            f"Auto-scheduled next watering for {event.get('plantName')} "
                            f"on {next_date}"
                        )

        # Return both the completed event and any newly created next event
        result = {**event}
        if next_event:
            result["nextEvent"] = next_event
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error completing event {event_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to update event")
