"""Service for sensor business logic: readings, thresholds, alerts."""

import logging
from datetime import datetime, timezone

logger = logging.getLogger(__name__)


class SensorService:
    """Processes sensor readings and generates alerts."""

    def __init__(self, firestore_service):
        self.firestore = firestore_service

    async def process_reading(
        self, user_id: str, sensor_id: str, reading_data: dict
    ) -> dict:
        """Store a reading, update the linked profile, and check thresholds."""
        now = datetime.now(timezone.utc).isoformat()
        reading_data["timestamp"] = now

        # Store the reading
        reading = await self.firestore.create_sensor_reading(
            user_id, sensor_id, reading_data
        )

        # Update sensor lastSeen and battery
        update = {"lastSeen": now, "status": "online"}
        if reading_data.get("batteryPercent") is not None:
            update["batteryPercent"] = reading_data["batteryPercent"]
        await self.firestore.update_sensor(user_id, sensor_id, update)

        # Update linked profile's sensorLastReading
        sensor = await self.firestore.get_sensor(user_id, sensor_id)
        if sensor and sensor.get("profileId"):
            snapshot = {
                "soilMoisture": reading_data.get("soilMoisture"),
                "lightLux": reading_data.get("lightLux"),
                "temperature": reading_data.get("temperature"),
                "humidity": reading_data.get("humidity"),
                "timestamp": now,
            }
            await self.firestore.update_profile(
                user_id, sensor["profileId"], {"sensorLastReading": snapshot}
            )

            # Check thresholds
            thresholds = sensor.get("thresholds")
            if thresholds:
                await self._check_thresholds(
                    user_id, sensor["profileId"], sensor, reading_data, thresholds
                )

        return reading

    async def _check_thresholds(
        self,
        user_id: str,
        profile_id: str,
        sensor: dict,
        reading: dict,
        thresholds: dict,
    ):
        """Compare reading against thresholds and create calendar alerts."""
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        plant_name = ""

        # Get plant name from profile
        profile = await self.firestore.get_profile(user_id, profile_id)
        if profile:
            plant_name = profile.get("name", "")

        alerts = []

        # Soil too dry
        soil = reading.get("soilMoisture")
        min_soil = thresholds.get("soilMoistureMin")
        if soil is not None and min_soil is not None and soil < min_soil:
            exists = await self.firestore.event_exists(
                user_id, profile_id, today, "needs_water"
            )
            if not exists:
                alerts.append({
                    "profileId": profile_id,
                    "plantName": plant_name,
                    "date": today,
                    "eventType": "needs_water",
                    "description": f"Soil moisture low ({soil:.0f}%). Water now.",
                })

        # Temperature too low
        temp = reading.get("temperature")
        min_temp = thresholds.get("temperatureMin")
        if temp is not None and min_temp is not None and temp < min_temp:
            exists = await self.firestore.event_exists(
                user_id, profile_id, today, "move_inside"
            )
            if not exists:
                alerts.append({
                    "profileId": profile_id,
                    "plantName": plant_name,
                    "date": today,
                    "eventType": "move_inside",
                    "description": f"Temperature too low ({temp:.1f}°C). Move indoors.",
                })

        # Temperature too high
        max_temp = thresholds.get("temperatureMax")
        if temp is not None and max_temp is not None and temp > max_temp:
            exists = await self.firestore.event_exists(
                user_id, profile_id, today, "needs_treatment"
            )
            if not exists:
                alerts.append({
                    "profileId": profile_id,
                    "plantName": plant_name,
                    "date": today,
                    "eventType": "needs_treatment",
                    "description": f"Temperature too high ({temp:.1f}°C). Move to shade.",
                })

        if alerts:
            await self.firestore.create_events(user_id, alerts)
            logger.info(
                f"Created {len(alerts)} sensor alert(s) for user {user_id}, "
                f"profile {profile_id}"
            )
