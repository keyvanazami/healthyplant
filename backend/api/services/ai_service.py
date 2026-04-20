"""AI service using Google Gemini for plant care recommendations and chat."""

import json
import logging
import os
from typing import AsyncGenerator

import google.generativeai as genai

logger = logging.getLogger(__name__)

MODEL = "gemini-3.1-flash-image-preview"
MAX_TOKENS = 1024
CHAT_MAX_TOKENS = 2048


class AIService:
    """Service for AI-powered plant care features using Gemini."""

    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            logger.warning("GEMINI_API_KEY not set. AI features will be unavailable.")
            self.model = None
        else:
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel(MODEL)

    async def identify_plant_from_image(self, image_data: bytes, media_type: str = "image/jpeg") -> dict:
        """Identify a plant from an image using Gemini vision."""
        if not self.model:
            logger.warning("AI model not initialized, cannot identify plant")
            return {"plant_type": "", "confidence": "low", "description": "AI service unavailable"}

        prompt = (
            "Identify the plant in this image. Respond with ONLY a JSON object "
            "(no markdown, no extra text) with these keys:\n"
            '- "plant_type": the common name of the plant (e.g. "Tomato", "Basil", "Cactus")\n'
            '- "confidence": "high", "medium", or "low"\n'
            '- "description": a one-sentence description of the plant\n'
            "If there is no plant visible, set plant_type to an empty string."
        )

        try:
            image_part = {"mime_type": media_type, "data": image_data}
            response = await self.model.generate_content_async(
                [image_part, prompt],
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=1024,
                ),
            )

            raw_text = _extract_model_text(response)
            decoder = json.JSONDecoder()
            obj_start = raw_text.find("{")
            if obj_start == -1:
                raise json.JSONDecodeError("No JSON object found", raw_text, 0)
            result, _ = decoder.raw_decode(raw_text[obj_start:])
            return {
                "plant_type": result.get("plant_type", ""),
                "confidence": result.get("confidence", "low"),
                "description": result.get("description", ""),
            }
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse plant identification response: {e}")
            return {"plant_type": "", "confidence": "low", "description": "Could not identify plant"}
        except Exception as e:
            logger.error(f"Plant identification failed: {e}")
            return {"plant_type": "", "confidence": "low", "description": "Identification failed"}

    async def lookup_plant_from_image(self, image_data: bytes, media_type: str = "image/jpeg") -> dict:
        """Identify a plant from an image and return detailed info: history, origin, care."""
        if not self.model:
            return {
                "plant_type": "", "confidence": "low", "description": "AI service unavailable",
                "origin": "", "history": "", "fun_facts": [], "care_summary": "",
                "sun_needs": "", "water_needs": "", "difficulty": "",
            }

        prompt = (
            "Identify the plant in this image. Then provide detailed information about it.\n\n"
            "Respond with ONLY a JSON object (no markdown, no extra text) with these keys:\n"
            '- "plant_type": the common name (e.g. "Monstera Deliciosa", "Basil")\n'
            '- "confidence": "high", "medium", or "low"\n'
            '- "description": a one-sentence description of the plant\n'
            '- "origin": where this plant originally comes from geographically (1-2 sentences)\n'
            '- "history": brief history and cultural significance (2-3 sentences)\n'
            '- "fun_facts": an array of 2-3 interesting facts about this plant\n'
            '- "care_summary": a short paragraph on how to care for this plant\n'
            '- "sun_needs": concise sun requirements (e.g. "Bright indirect light")\n'
            '- "water_needs": concise watering needs (e.g. "Water every 1-2 weeks")\n'
            '- "difficulty": "Easy", "Moderate", or "Hard"\n\n'
            "If there is no plant visible, set plant_type to an empty string and leave other fields empty."
        )

        try:
            image_part = {"mime_type": media_type, "data": image_data}
            response = await self.model.generate_content_async(
                [image_part, prompt],
                generation_config=genai.types.GenerationConfig(max_output_tokens=2048),
            )

            raw_text = _extract_model_text(response)
            decoder = json.JSONDecoder()
            obj_start = raw_text.find("{")
            if obj_start == -1:
                raise json.JSONDecodeError("No JSON object found", raw_text, 0)
            result, _ = decoder.raw_decode(raw_text[obj_start:])
            return {
                "plant_type": result.get("plant_type", ""),
                "confidence": result.get("confidence", "low"),
                "description": result.get("description", ""),
                "origin": result.get("origin", ""),
                "history": result.get("history", ""),
                "fun_facts": result.get("fun_facts", []),
                "care_summary": result.get("care_summary", ""),
                "sun_needs": result.get("sun_needs", ""),
                "water_needs": result.get("water_needs", ""),
                "difficulty": result.get("difficulty", ""),
            }
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse plant lookup response: {e}")
            return {
                "plant_type": "", "confidence": "low", "description": "Could not identify plant",
                "origin": "", "history": "", "fun_facts": [], "care_summary": "",
                "sun_needs": "", "water_needs": "", "difficulty": "",
            }
        except Exception as e:
            logger.error(f"Plant lookup failed: {e}")
            return {
                "plant_type": "", "confidence": "low", "description": "Lookup failed",
                "origin": "", "history": "", "fun_facts": [], "care_summary": "",
                "sun_needs": "", "water_needs": "", "difficulty": "",
            }

    async def generate_plant_recommendations(
        self, plant_type: str, age_days: int, planted_date: str,
        is_indoor: bool = False, climate_zone: str = None
    ) -> dict:
        """Generate care recommendations for a plant."""
        if not self.model:
            logger.warning("AI model not initialized, returning defaults")
            return {
                "sun_needs": "Full sun (6-8 hours)",
                "water_needs": "Water when top inch of soil is dry",
                "harvest_time": "Varies by variety",
            }

        location_line = f'Location: {"Indoors" if is_indoor else "Outdoors"}'
        climate_line = f"Climate zone: {climate_zone}" if climate_zone else ""
        extra_context = f"\n{location_line}"
        if climate_line:
            extra_context += f"\n{climate_line}"

        if is_indoor:
            sun_guidance = (
                '- "sun_needs": A concise description of light requirements; since this is an indoor plant, '
                "account for artificial/window light (e.g., \"Bright indirect light from a south-facing window, 4-6 hours\")"
            )
        else:
            sun_guidance = (
                '- "sun_needs": A concise description of sunlight requirements in standard outdoor sun hours '
                '(e.g., "Full sun, 6-8 hours daily")'
            )

        prompt = f"""You are an expert botanist and gardener. Given the following plant information, provide specific care recommendations.

Plant type: {plant_type}
Age: {age_days} days
Planted date: {planted_date}{extra_context}

Respond with ONLY a JSON object (no markdown, no extra text) with these exact keys:
- {sun_guidance}
- "water_needs": A concise watering schedule and tips (e.g., "Water deeply every 3-4 days, keep soil moist but not waterlogged")
- "harvest_time": When to expect harvest or peak bloom, relative to the planted date (e.g., "Ready to harvest in approximately 60-75 days from planting")
- "watering_frequency_days": An integer for how often to water in days (e.g., 3 means every 3 days)
- "sun_hours_min": An integer for minimum recommended sun hours per day (e.g., 4)
- "sun_hours_max": An integer for maximum recommended sun hours per day (e.g., 8)

Be specific to this plant type and its current age."""

        try:
            response = await self.model.generate_content_async(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=MAX_TOKENS,
                ),
            )

            raw_text = _extract_model_text(response)
            decoder = json.JSONDecoder()
            obj_start = raw_text.find("{")
            if obj_start == -1:
                raise json.JSONDecodeError("No JSON object found", raw_text, 0)
            recommendations, _ = decoder.raw_decode(raw_text[obj_start:])
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
        """Generate care calendar events for the next 7 days based on plant profiles."""
        if not self.model:
            logger.warning("AI model not initialized, returning empty events")
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
            freq = p.get("wateringFrequencyDays")
            if freq is not None:
                line += f", watering every {freq} days"
            plants_lines.append(line)

        plants_summary = "\n".join(plants_lines)

        prompt = f"""You are an expert gardener creating a 7-day care calendar. Today is {current_date}.

Plants in the garden:
{plants_summary}

Generate care events for the next 7 days. For each event, consider the plant's specific needs.

IMPORTANT scheduling rules:
- If a plant has a "watering every N days" value, schedule watering events exactly every N days starting from {current_date}. Do NOT guess a different frequency.
- If no structured frequency data is provided, infer a reasonable watering schedule from the text-based water needs.
- Not every plant needs attention every day.

Respond with ONLY a JSON array (no markdown, no extra text). Each element must have:
- "profileId": the profile ID string from above
- "plantName": the plant name
- "date": date string in YYYY-MM-DD format (must be within next 7 days from {current_date})
- "eventType": one of "needs_water", "needs_treatment"
- "description": a brief, actionable description (e.g., "Water thoroughly at base, avoid leaves")

Generate realistic events based on each plant's care requirements."""

        try:
            response = await self.model.generate_content_async(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=CHAT_MAX_TOKENS,
                ),
            )

            raw_text = _extract_model_text(response)
            decoder = json.JSONDecoder()
            # Find the first [ and decode the array from there
            arr_start = raw_text.find("[")
            if arr_start == -1:
                logger.error("No JSON array found in calendar response")
                return []
            events, _ = decoder.raw_decode(raw_text[arr_start:])
            if not isinstance(events, list):
                logger.error("AI returned non-list for calendar events")
                return []

            valid_types = {"needs_water", "needs_treatment"}
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
        """Stream a chat response from Gemini about plant care."""
        if not self.model:
            yield "I'm sorry, the AI service is currently unavailable. Please check your API key configuration."
            return

        # Build plant context
        if plant_profiles:
            lines = []
            for p in plant_profiles:
                line = (
                    f"- {p.get('name', 'Unknown')} ({p.get('plantType', 'Unknown')}): "
                    f"age {p.get('ageDays', 0)} days, "
                    f"height {p.get('heightFeet', 0)}'{p.get('heightInches', 0)}\", "
                    f"sun: {p.get('sunNeeds', 'unknown')}, "
                    f"water: {p.get('waterNeeds', 'unknown')}"
                )
                sensor = p.get("sensorLastReading")
                if sensor:
                    parts = []
                    if sensor.get("soilMoisture") is not None:
                        parts.append(f"soil moisture {sensor['soilMoisture']:.0f}%")
                    if sensor.get("lightLux") is not None:
                        parts.append(f"light {sensor['lightLux']:.0f} lux")
                    if sensor.get("temperature") is not None:
                        parts.append(f"temp {sensor['temperature']:.1f}°C")
                    if sensor.get("humidity") is not None:
                        parts.append(f"humidity {sensor['humidity']:.0f}%")
                    if parts:
                        line += f" | LIVE SENSOR: {', '.join(parts)}"
                lines.append(line)
            plant_context = "The user has the following plants:\n" + "\n".join(lines)
        else:
            plant_context = "The user hasn't added any plants yet."

        system_instruction = f"""You are a friendly, knowledgeable plant care assistant for the Healthy Plant app. You help users take care of their plants with practical, science-based advice.

{plant_context}

Guidelines:
- Be warm, encouraging, and concise.
- Provide specific, actionable advice tailored to the user's actual plants when relevant.
- If asked about a plant the user doesn't have, still help but suggest they add it to their garden.
- For diagnosis questions, ask clarifying questions if needed (e.g., "Can you describe the discoloration?").
- Keep responses under 300 words unless the user asks for detailed information."""

        # Build Gemini chat history
        gemini_history = []
        for msg in history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if not content:
                continue
            gemini_role = "user" if role == "user" else "model"
            # Avoid consecutive same-role messages
            if gemini_history and gemini_history[-1]["role"] == gemini_role:
                gemini_history[-1]["parts"][0]["text"] += "\n" + content
            else:
                gemini_history.append({"role": gemini_role, "parts": [{"text": content}]})

        # Ensure history starts with user and alternates
        if gemini_history and gemini_history[0]["role"] != "user":
            gemini_history = gemini_history[1:]

        try:
            chat_model = genai.GenerativeModel(
                MODEL, system_instruction=system_instruction
            )
            chat = chat_model.start_chat(history=gemini_history)
            response = await chat.send_message_async(
                message,
                generation_config=genai.types.GenerationConfig(max_output_tokens=CHAT_MAX_TOKENS),
                stream=True,
            )
            async for chunk in response:
                if chunk.text:
                    yield chunk.text
        except Exception as e:
            logger.error(f"Chat stream error: {e}")
            yield "I'm sorry, I encountered an error. Please try again."


def _extract_model_text(response) -> str:
    """Extract the text content from a Gemini response, handling multiple parts."""
    text = ""
    try:
        for part in response.candidates[0].content.parts:
            if hasattr(part, "text") and part.text:
                text = part.text.strip()
    except (IndexError, AttributeError):
        text = response.text.strip() if response.text else ""

    if not text:
        text = response.text.strip() if response.text else ""

    logger.info(f"Raw AI response ({len(text)} chars): {text[:300]}")

    # Strip markdown code fencing if present
    import re
    match = re.search(r"```(?:json)?\s*\n?(.*?)```", text, re.DOTALL)
    if match:
        return match.group(1).strip()
    return text
