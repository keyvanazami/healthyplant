"""AI service using Anthropic Claude for plant care recommendations and chat."""

import json
import logging
import os
from typing import AsyncGenerator

import anthropic

logger = logging.getLogger(__name__)

MODEL = "claude-sonnet-4-20250514"
MAX_TOKENS = 1024
CHAT_MAX_TOKENS = 2048


class AIService:
    """Service for AI-powered plant care features using Claude."""

    def __init__(self):
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            logger.warning("ANTHROPIC_API_KEY not set. AI features will be unavailable.")
        self.client = anthropic.AsyncAnthropic(api_key=api_key) if api_key else None

    async def generate_plant_recommendations(
        self, plant_type: str, age_days: int, planted_date: str
    ) -> dict:
        """
        Generate care recommendations for a plant.

        Returns:
            dict with keys: sun_needs, water_needs, harvest_time
        """
        if not self.client:
            logger.warning("AI client not initialized, returning defaults")
            return {
                "sun_needs": "Full sun (6-8 hours)",
                "water_needs": "Water when top inch of soil is dry",
                "harvest_time": "Varies by variety",
            }

        prompt = f"""You are an expert botanist and gardener. Given the following plant information, provide specific care recommendations.

Plant type: {plant_type}
Age: {age_days} days
Planted date: {planted_date}

Respond with ONLY a JSON object (no markdown, no extra text) with these exact keys:
- "sun_needs": A concise description of sunlight requirements (e.g., "Full sun, 6-8 hours daily")
- "water_needs": A concise watering schedule and tips (e.g., "Water deeply every 3-4 days, keep soil moist but not waterlogged")
- "harvest_time": When to expect harvest or peak bloom, relative to the planted date (e.g., "Ready to harvest in approximately 60-75 days from planting")
- "watering_frequency_days": An integer for how often to water in days (e.g., 3 means every 3 days)
- "sun_hours_min": An integer for minimum recommended sun hours per day (e.g., 4)
- "sun_hours_max": An integer for maximum recommended sun hours per day (e.g., 8)

Be specific to this plant type and its current age."""

        try:
            response = await self.client.messages.create(
                model=MODEL,
                max_tokens=MAX_TOKENS,
                messages=[{"role": "user", "content": prompt}],
            )

            text = response.content[0].text.strip()

            # Parse JSON response, handling potential markdown wrapping
            if text.startswith("```"):
                text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()

            recommendations = json.loads(text)
            return {
                "sun_needs": recommendations.get("sun_needs", ""),
                "water_needs": recommendations.get("water_needs", ""),
                "harvest_time": recommendations.get("harvest_time", ""),
                "watering_frequency_days": recommendations.get("watering_frequency_days"),
                "sun_hours_min": recommendations.get("sun_hours_min"),
                "sun_hours_max": recommendations.get("sun_hours_max"),
            }
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI response as JSON: {e}")
            return {
                "sun_needs": "Unable to generate - please try again",
                "water_needs": "Unable to generate - please try again",
                "harvest_time": "Unable to generate - please try again",
            }
        except Exception as e:
            logger.error(f"AI recommendation generation failed: {e}")
            raise

    async def generate_calendar_events(
        self, profiles: list, current_date: str
    ) -> list:
        """
        Generate care calendar events for the next 7 days based on plant profiles.

        Args:
            profiles: List of plant profile dicts.
            current_date: Current date as YYYY-MM-DD string.

        Returns:
            List of event dicts with keys: profileId, plantName, date, eventType, description
        """
        if not self.client:
            logger.warning("AI client not initialized, returning empty events")
            return []

        if not profiles:
            return []

        plants_lines = []
        for p in profiles:
            line = (
                f"- {p.get('name', 'Unknown')} ({p.get('plantType', 'Unknown')}): "
                f"age {p.get('ageDays', 0)} days, "
                f"sun needs: {p.get('sunNeeds', 'unknown')}, "
                f"water needs: {p.get('waterNeeds', 'unknown')}, "
                f"profile ID: {p.get('id', '')}"
            )
            # Include structured data when available for precise scheduling
            freq = p.get("wateringFrequencyDays")
            sun_min = p.get("sunHoursMin")
            sun_max = p.get("sunHoursMax")
            if freq is not None:
                line += f", watering every {freq} days"
            if sun_min is not None and sun_max is not None:
                line += f", {sun_min}-{sun_max}h sun/day"
            plants_lines.append(line)

        plants_summary = "\n".join(plants_lines)

        prompt = f"""You are an expert gardener creating a 7-day care calendar. Today is {current_date}.

Plants in the garden:
{plants_summary}

Generate care events for the next 7 days. For each event, consider the plant's specific needs.

IMPORTANT scheduling rules:
- If a plant has a "watering every N days" value, schedule watering events exactly every N days starting from {current_date}. Do NOT guess a different frequency.
- If a plant has sun hour requirements, generate "needs_sun" events on days when sun exposure reminders would be helpful.
- If no structured frequency data is provided, infer a reasonable schedule from the text-based water/sun needs.
- Not every plant needs attention every day.

Respond with ONLY a JSON array (no markdown, no extra text). Each element must have:
- "profileId": the profile ID string from above
- "plantName": the plant name
- "date": date string in YYYY-MM-DD format (must be within next 7 days from {current_date})
- "eventType": one of "needs_water", "needs_sun", "needs_treatment"
- "description": a brief, actionable description (e.g., "Water thoroughly at base, avoid leaves")

Generate realistic events based on each plant's care requirements."""

        try:
            response = await self.client.messages.create(
                model=MODEL,
                max_tokens=CHAT_MAX_TOKENS,
                messages=[{"role": "user", "content": prompt}],
            )

            text = response.content[0].text.strip()
            if text.startswith("```"):
                text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()

            events = json.loads(text)
            if not isinstance(events, list):
                logger.error("AI returned non-list for calendar events")
                return []

            # Validate event structure
            valid_types = {"needs_water", "needs_sun", "needs_treatment"}
            validated = []
            for event in events:
                if (
                    isinstance(event, dict)
                    and event.get("eventType") in valid_types
                    and event.get("date")
                    and event.get("profileId")
                ):
                    validated.append(event)
            return validated

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI calendar response: {e}")
            return []
        except Exception as e:
            logger.error(f"AI calendar generation failed: {e}")
            raise

    async def chat_stream(
        self, message: str, history: list, plant_profiles: list
    ) -> AsyncGenerator[str, None]:
        """
        Stream a chat response from Claude about plant care.

        Args:
            message: The user's current message.
            history: List of previous message dicts with 'role' and 'content'.
            plant_profiles: List of the user's plant profile dicts for context.

        Yields:
            Text chunks as they arrive from the AI.
        """
        if not self.client:
            yield "I'm sorry, the AI service is currently unavailable. Please check your API key configuration."
            return

        # Build plant context
        if plant_profiles:
            plant_context = "The user has the following plants:\n" + "\n".join(
                f"- {p.get('name', 'Unknown')} ({p.get('plantType', 'Unknown')}): "
                f"age {p.get('ageDays', 0)} days, "
                f"height {p.get('heightFeet', 0)}'{p.get('heightInches', 0)}\", "
                f"sun: {p.get('sunNeeds', 'unknown')}, "
                f"water: {p.get('waterNeeds', 'unknown')}"
                for p in plant_profiles
            )
        else:
            plant_context = "The user hasn't added any plants yet."

        system_prompt = f"""You are a friendly, knowledgeable plant care assistant for the Healthy Plant app. You help users take care of their plants with practical, science-based advice.

{plant_context}

Guidelines:
- Be warm, encouraging, and concise.
- Provide specific, actionable advice tailored to the user's actual plants when relevant.
- If asked about a plant the user doesn't have, still help but suggest they add it to their garden.
- For diagnosis questions, ask clarifying questions if needed (e.g., "Can you describe the discoloration?").
- Keep responses under 300 words unless the user asks for detailed information."""

        # Build message history for Claude (last N messages for context window)
        claude_messages = []
        for msg in history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role in ("user", "assistant") and content:
                claude_messages.append({"role": role, "content": content})

        # Add current message
        claude_messages.append({"role": "user", "content": message})

        # Ensure messages alternate properly (Claude requirement)
        claude_messages = _ensure_alternating_messages(claude_messages)

        try:
            async with self.client.messages.stream(
                model=MODEL,
                max_tokens=CHAT_MAX_TOKENS,
                system=system_prompt,
                messages=claude_messages,
            ) as stream:
                async for text in stream.text_stream:
                    yield text
        except Exception as e:
            logger.error(f"Chat stream error: {e}")
            yield f"I'm sorry, I encountered an error. Please try again."


def _ensure_alternating_messages(messages: list) -> list:
    """
    Ensure messages alternate between user and assistant roles.
    Claude requires strictly alternating roles.
    """
    if not messages:
        return messages

    cleaned = []
    for msg in messages:
        if cleaned and cleaned[-1]["role"] == msg["role"]:
            # Merge consecutive same-role messages
            cleaned[-1]["content"] += "\n" + msg["content"]
        else:
            cleaned.append(msg)

    # Ensure first message is from user
    if cleaned and cleaned[0]["role"] != "user":
        cleaned = cleaned[1:]

    # Ensure last message is from user
    if cleaned and cleaned[-1]["role"] != "user":
        cleaned = cleaned[:-1]

    return cleaned if cleaned else [{"role": "user", "content": "Hello"}]
