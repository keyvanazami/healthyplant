"""Cloud Function triggered when a new plant profile is created in Firestore.

Generates AI-powered care recommendations and updates the profile document.

Trigger: Firestore document creation on users/{userId}/profiles/{profileId}
"""

import json
import logging
import os
from datetime import datetime, timezone

import anthropic
from google.cloud import firestore

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

MODEL = "claude-sonnet-4-20250514"
MAX_TOKENS = 1024

# Initialize clients at module level for connection reuse
db = firestore.Client()


def on_profile_create(event, context):
    """
    Cloud Function entry point for Firestore document creation trigger.

    Args:
        event: The Firestore event payload containing the new document data.
        context: The event context with resource path information.
    """
    # Extract userId and profileId from the resource path
    # Format: projects/{project}/databases/(default)/documents/users/{userId}/profiles/{profileId}
    resource_path = context.resource
    path_parts = resource_path.split("/")

    try:
        users_idx = path_parts.index("users")
        user_id = path_parts[users_idx + 1]
        profile_id = path_parts[users_idx + 3]  # skip "profiles" at +2
    except (ValueError, IndexError) as e:
        logger.error(f"Failed to parse resource path '{resource_path}': {e}")
        return

    logger.info(f"Processing new profile: user={user_id}, profile={profile_id}")

    # Read the new profile document data from the event
    profile_data = event.get("value", {}).get("fields", {})
    plant_type = _extract_string_field(profile_data, "plantType")
    age_days = _extract_integer_field(profile_data, "ageDays")
    planted_date = _extract_string_field(profile_data, "plantedDate")

    if not plant_type:
        logger.warning(f"Profile {profile_id} has no plantType, skipping AI generation")
        return

    # Generate AI recommendations
    try:
        recommendations = generate_recommendations(plant_type, age_days, planted_date)
    except Exception as e:
        logger.error(f"Failed to generate recommendations for profile {profile_id}: {e}")
        return

    # Update the profile document
    now = datetime.now(timezone.utc).isoformat()
    update_data = {
        "sunNeeds": recommendations.get("sun_needs", ""),
        "waterNeeds": recommendations.get("water_needs", ""),
        "harvestTime": recommendations.get("harvest_time", ""),
        "aiLastUpdated": now,
        "updatedAt": now,
    }

    try:
        doc_ref = (
            db.collection("users")
            .document(user_id)
            .collection("profiles")
            .document(profile_id)
        )
        doc_ref.update(update_data)
        logger.info(f"Successfully updated profile {profile_id} with AI recommendations")
    except Exception as e:
        logger.error(f"Failed to update profile {profile_id}: {e}")


def generate_recommendations(plant_type: str, age_days: int, planted_date: str) -> dict:
    """Call Claude API to generate plant care recommendations."""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError("ANTHROPIC_API_KEY environment variable not set")

    client = anthropic.Anthropic(api_key=api_key)

    prompt = f"""You are an expert botanist and gardener. Given the following plant information, provide specific care recommendations.

Plant type: {plant_type}
Age: {age_days} days
Planted date: {planted_date}

Respond with ONLY a JSON object (no markdown, no extra text) with these exact keys:
- "sun_needs": A concise description of sunlight requirements (e.g., "Full sun, 6-8 hours daily")
- "water_needs": A concise watering schedule and tips (e.g., "Water deeply every 3-4 days, keep soil moist but not waterlogged")
- "harvest_time": When to expect harvest or peak bloom, relative to the planted date (e.g., "Ready to harvest in approximately 60-75 days from planting")

Be specific to this plant type and its current age."""

    response = client.messages.create(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        messages=[{"role": "user", "content": prompt}],
    )

    text = response.content[0].text.strip()

    # Handle potential markdown code block wrapping
    if text.startswith("```"):
        text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()

    recommendations = json.loads(text)
    return {
        "sun_needs": recommendations.get("sun_needs", ""),
        "water_needs": recommendations.get("water_needs", ""),
        "harvest_time": recommendations.get("harvest_time", ""),
    }


def _extract_string_field(fields: dict, key: str) -> str:
    """Extract a string value from Firestore event field data."""
    field = fields.get(key, {})
    return field.get("stringValue", "")


def _extract_integer_field(fields: dict, key: str) -> int:
    """Extract an integer value from Firestore event field data."""
    field = fields.get(key, {})
    return int(field.get("integerValue", 0))
