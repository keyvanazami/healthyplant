"""Router for sensor device management and readings."""

import logging
import secrets
from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Request, Query

from models.sensor import (
    SensorRegister,
    SensorPairRequest,
    SensorAlertThresholds,
    SensorReadingSubmit,
    SensorReadingResponse,
    SensorResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter()


def _get_user_id(request: Request) -> str:
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    return user_id


# ──────────────────────────────────────────────
# Sensor device management
# ──────────────────────────────────────────────


@router.post("/sensors/register", response_model=SensorResponse, status_code=201)
async def register_sensor(request: Request, body: SensorRegister):
    """Register a new sensor device for the current user."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        # Check if sensor ID already registered for this user
        existing = await firestore.get_sensor(user_id, body.sensor_id)
        if existing:
            raise HTTPException(status_code=409, detail="Sensor already registered")

        device_token = secrets.token_urlsafe(32)
        now = datetime.now(timezone.utc).isoformat()

        sensor_data = {
            "sensorId": body.sensor_id,
            "deviceToken": device_token,
            "name": body.name,
            "profileId": None,
            "firmwareVersion": body.firmware_version,
            "lastSeen": None,
            "batteryPercent": None,
            "status": "offline",
            "thresholds": None,
            "createdAt": now,
        }

        result = await firestore.create_sensor(user_id, body.sensor_id, sensor_data)
        # Include deviceToken in response only on registration
        result["deviceToken"] = device_token
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error registering sensor for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to register sensor")


@router.get("/sensors", response_model=List[SensorResponse])
async def list_sensors(request: Request):
    """List all sensors registered to the current user."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    try:
        sensors = await firestore.get_sensors(user_id)
        # Compute online/offline status based on lastSeen
        cutoff = (datetime.now(timezone.utc) - timedelta(minutes=30)).isoformat()
        for s in sensors:
            last = s.get("lastSeen")
            s["status"] = "online" if last and last > cutoff else "offline"
        return sensors
    except Exception as e:
        logger.error(f"Error listing sensors for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to list sensors")


@router.get("/sensors/{sensor_id}", response_model=SensorResponse)
async def get_sensor(request: Request, sensor_id: str):
    """Get a single sensor by ID."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    sensor = await firestore.get_sensor(user_id, sensor_id)
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")
    return sensor


@router.delete("/sensors/{sensor_id}", status_code=204)
async def delete_sensor(request: Request, sensor_id: str):
    """Remove a sensor and all its readings."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    sensor = await firestore.get_sensor(user_id, sensor_id)
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")

    # Unpair from profile if linked
    if sensor.get("profileId"):
        await firestore.update_profile(
            user_id, sensor["profileId"],
            {"sensorId": None, "sensorLastReading": None},
        )

    await firestore.delete_sensor(user_id, sensor_id)


# ──────────────────────────────────────────────
# Pairing
# ──────────────────────────────────────────────


@router.put("/sensors/{sensor_id}/pair", response_model=SensorResponse)
async def pair_sensor(request: Request, sensor_id: str, body: SensorPairRequest):
    """Link a sensor to a plant profile."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    sensor = await firestore.get_sensor(user_id, sensor_id)
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")

    profile = await firestore.get_profile(user_id, body.profile_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    # Unpair from previous profile if any
    if sensor.get("profileId"):
        await firestore.update_profile(
            user_id, sensor["profileId"],
            {"sensorId": None, "sensorLastReading": None},
        )

    # Pair
    await firestore.update_sensor(user_id, sensor_id, {"profileId": body.profile_id})
    await firestore.update_profile(
        user_id, body.profile_id, {"sensorId": sensor_id}
    )

    return await firestore.get_sensor(user_id, sensor_id)


@router.put("/sensors/{sensor_id}/unpair", response_model=SensorResponse)
async def unpair_sensor(request: Request, sensor_id: str):
    """Unlink a sensor from its plant profile."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    sensor = await firestore.get_sensor(user_id, sensor_id)
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")

    if sensor.get("profileId"):
        await firestore.update_profile(
            user_id, sensor["profileId"],
            {"sensorId": None, "sensorLastReading": None},
        )

    await firestore.update_sensor(user_id, sensor_id, {"profileId": None})
    return await firestore.get_sensor(user_id, sensor_id)


# ──────────────────────────────────────────────
# Thresholds
# ──────────────────────────────────────────────


@router.put("/sensors/{sensor_id}/thresholds", response_model=SensorResponse)
async def set_thresholds(
    request: Request, sensor_id: str, body: SensorAlertThresholds
):
    """Set alert thresholds for a sensor."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    sensor = await firestore.get_sensor(user_id, sensor_id)
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")

    thresholds = body.model_dump(by_alias=True, exclude_none=True)
    await firestore.update_sensor(user_id, sensor_id, {"thresholds": thresholds})
    return await firestore.get_sensor(user_id, sensor_id)


# ──────────────────────────────────────────────
# Readings (from ESP32 via device token)
# ──────────────────────────────────────────────


@router.post("/sensors/readings", status_code=201)
async def submit_reading(request: Request, body: SensorReadingSubmit):
    """ESP32 submits a sensor reading. Authenticated via X-Device-Token."""
    # user_id and sensor_id are set by auth middleware for device-token auth
    user_id = getattr(request.state, "user_id", None)
    sensor_id = getattr(request.state, "sensor_id", None)
    if not user_id or not sensor_id:
        raise HTTPException(status_code=401, detail="Invalid device token")

    sensor_service = request.app.state.sensor_service

    try:
        reading_data = body.model_dump(by_alias=True, exclude_none=True)
        result = await sensor_service.process_reading(
            user_id, sensor_id, reading_data
        )
        return {"status": "ok", "readingId": result.get("id", "")}
    except Exception as e:
        logger.error(f"Error processing reading from sensor {sensor_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to process reading")


# ──────────────────────────────────────────────
# Reading history (from iOS app)
# ──────────────────────────────────────────────


@router.get(
    "/sensors/{sensor_id}/latest", response_model=Optional[SensorReadingResponse]
)
async def get_latest_reading(request: Request, sensor_id: str):
    """Get the most recent reading for a sensor."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    sensor = await firestore.get_sensor(user_id, sensor_id)
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")

    reading = await firestore.get_latest_sensor_reading(user_id, sensor_id)
    return reading


@router.get(
    "/sensors/{sensor_id}/readings", response_model=List[SensorReadingResponse]
)
async def get_readings(
    request: Request,
    sensor_id: str,
    hours_back: int = Query(24, alias="hoursBack", ge=1, le=720),
    limit: int = Query(100, ge=1, le=500),
):
    """Get reading history for a sensor."""
    user_id = _get_user_id(request)
    firestore = request.app.state.firestore_service

    sensor = await firestore.get_sensor(user_id, sensor_id)
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor not found")

    since = (
        datetime.now(timezone.utc) - timedelta(hours=hours_back)
    ).isoformat()

    readings = await firestore.get_sensor_readings(
        user_id, sensor_id, since=since, limit=limit
    )
    return readings
