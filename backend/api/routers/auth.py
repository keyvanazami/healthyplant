"""Router for authentication and account migration."""

import logging

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

router = APIRouter()


class MigrateRequest(BaseModel):
    """Request to migrate data from an anonymous account to the authenticated one."""

    from_user_id: str = Field(..., alias="fromUserId")

    model_config = {"populate_by_name": True}


class MigrateResponse(BaseModel):
    migrated: bool
    profiles_moved: int = Field(0, alias="profilesMoved")
    events_moved: int = Field(0, alias="eventsMoved")
    messages_moved: int = Field(0, alias="messagesMoved")

    model_config = {"populate_by_name": True}


@router.post("/auth/migrate", response_model=MigrateResponse)
async def migrate_account(request: Request, body: MigrateRequest):
    """
    Migrate all data from an anonymous user to the authenticated user.

    Called after Google Sign-In when the user had existing anonymous data.
    Moves profiles, calendar events, and chat messages from the old userId
    to the new Firebase userId.
    """
    new_user_id = getattr(request.state, "user_id", None)
    if not new_user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    old_user_id = body.from_user_id

    if old_user_id == new_user_id:
        return MigrateResponse(migrated=False)

    firestore = request.app.state.firestore_service

    try:
        profiles_moved = 0
        events_moved = 0
        messages_moved = 0

        # Migrate profiles
        old_profiles = await firestore.get_profiles(old_user_id)
        for profile in old_profiles:
            profile_id = profile.pop("id")
            profile["userId"] = new_user_id
            await firestore.create_profile_with_id(
                new_user_id, profile_id, profile
            )
            profiles_moved += 1

        # Migrate calendar events
        old_events = await firestore.get_all_events(old_user_id)
        if old_events:
            for event in old_events:
                event.pop("id", None)
                event["userId"] = new_user_id
            await firestore.create_events(new_user_id, old_events)
            events_moved = len(old_events)

        # Migrate chat messages
        old_messages = await firestore.get_chat_history(old_user_id, limit=500)
        for msg in old_messages:
            msg.pop("id", None)
            msg["userId"] = new_user_id
            await firestore.save_message(
                new_user_id, msg.get("role", "user"), msg.get("content", "")
            )
            messages_moved += 1

        # Migrate sensors
        old_sensors = await firestore.get_sensors(old_user_id)
        for sensor in old_sensors:
            sensor_id = sensor.get("sensorId", sensor.get("id"))
            sensor["userId"] = new_user_id
            sensor.pop("id", None)
            await firestore.create_sensor(new_user_id, sensor_id, sensor)

        logger.info(
            f"Migrated data from {old_user_id} to {new_user_id}: "
            f"{profiles_moved} profiles, {events_moved} events, "
            f"{messages_moved} messages"
        )

        return MigrateResponse(
            migrated=True,
            profiles_moved=profiles_moved,
            events_moved=events_moved,
            messages_moved=messages_moved,
        )

    except Exception as e:
        logger.error(f"Migration failed from {old_user_id} to {new_user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to migrate account data")
