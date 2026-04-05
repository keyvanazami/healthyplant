"""FCM push notification service."""

import asyncio
import logging
from typing import List

from firebase_admin import messaging

logger = logging.getLogger(__name__)


async def send_new_plant_notification(
    tokens: List[str], gardener_name: str, plant_name: str
) -> None:
    """Send a multicast FCM push to a list of device tokens."""
    if not tokens:
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=f"{gardener_name} shared a new plant",
            body=f"Check out their {plant_name}",
        ),
        data={"type": "new_shared_plant"},
        tokens=tokens,
    )

    loop = asyncio.get_event_loop()
    try:
        response = await loop.run_in_executor(
            None, lambda: messaging.send_each_for_multicast(message)
        )
        logger.info(
            f"FCM multicast: {response.success_count} sent, "
            f"{response.failure_count} failed"
        )
    except Exception as e:
        logger.error(f"FCM multicast failed: {e}")
