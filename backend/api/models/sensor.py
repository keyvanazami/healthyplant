"""Pydantic models for sensor devices and readings."""

from typing import Optional

from pydantic import BaseModel, Field


class SensorRegister(BaseModel):
    """Request model for registering a new sensor device."""

    sensor_id: str = Field(..., alias="sensorId", description="Hardware ID printed on device")
    name: str = Field(..., min_length=1, max_length=100, description="User-friendly name")
    firmware_version: Optional[str] = Field(None, alias="firmwareVersion")

    model_config = {"populate_by_name": True}


class SensorPairRequest(BaseModel):
    """Request model for pairing a sensor with a plant profile."""

    profile_id: str = Field(..., alias="profileId")

    model_config = {"populate_by_name": True}


class SensorAlertThresholds(BaseModel):
    """Request model for setting sensor alert thresholds."""

    soil_moisture_min: Optional[float] = Field(None, alias="soilMoistureMin", ge=0, le=100)
    soil_moisture_max: Optional[float] = Field(None, alias="soilMoistureMax", ge=0, le=100)
    temperature_min: Optional[float] = Field(None, alias="temperatureMin")
    temperature_max: Optional[float] = Field(None, alias="temperatureMax")

    model_config = {"populate_by_name": True}


class SensorReadingSubmit(BaseModel):
    """Request model for ESP32 submitting a sensor reading."""

    soil_moisture: Optional[float] = Field(None, alias="soilMoisture", ge=0, le=100)
    light_lux: Optional[float] = Field(None, alias="lightLux", ge=0)
    temperature: Optional[float] = Field(None, alias="temperature")
    humidity: Optional[float] = Field(None, alias="humidity", ge=0, le=100)
    soil_temperature: Optional[float] = Field(None, alias="soilTemperature")
    pressure: Optional[float] = Field(None, alias="pressure")
    battery_percent: Optional[int] = Field(None, alias="batteryPercent", ge=0, le=100)

    model_config = {"populate_by_name": True}


class SensorReadingResponse(BaseModel):
    """Response model for a sensor reading."""

    id: str
    timestamp: str
    soil_moisture: Optional[float] = Field(None, alias="soilMoisture")
    light_lux: Optional[float] = Field(None, alias="lightLux")
    temperature: Optional[float] = Field(None, alias="temperature")
    humidity: Optional[float] = Field(None, alias="humidity")
    soil_temperature: Optional[float] = Field(None, alias="soilTemperature")
    pressure: Optional[float] = Field(None, alias="pressure")

    model_config = {"populate_by_name": True, "from_attributes": True}


class SensorLastReading(BaseModel):
    """Embedded reading snapshot stored on the plant profile."""

    soil_moisture: Optional[float] = Field(None, alias="soilMoisture")
    light_lux: Optional[float] = Field(None, alias="lightLux")
    temperature: Optional[float] = Field(None, alias="temperature")
    humidity: Optional[float] = Field(None, alias="humidity")
    timestamp: Optional[str] = None

    model_config = {"populate_by_name": True, "from_attributes": True}


class SensorResponse(BaseModel):
    """Response model for a sensor device."""

    id: str
    sensor_id: str = Field(..., alias="sensorId")
    name: str
    profile_id: Optional[str] = Field(None, alias="profileId")
    firmware_version: Optional[str] = Field(None, alias="firmwareVersion")
    last_seen: Optional[str] = Field(None, alias="lastSeen")
    battery_percent: Optional[int] = Field(None, alias="batteryPercent")
    status: str = "offline"
    thresholds: Optional[SensorAlertThresholds] = None
    created_at: str = Field(..., alias="createdAt")

    model_config = {"populate_by_name": True, "from_attributes": True}
