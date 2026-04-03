"""Router for photo upload operations."""

import logging
import os
import uuid

from fastapi import APIRouter, File, HTTPException, Request, UploadFile
from pydantic import BaseModel, Field

from google.cloud import storage

logger = logging.getLogger(__name__)

router = APIRouter()


class PhotoUploadResponse(BaseModel):
    url: str = Field(..., description="Public URL of the uploaded photo")

    model_config = {"populate_by_name": True}


class PlantIdentifyResponse(BaseModel):
    plant_type: str = Field(..., alias="plantType", description="Identified plant type")
    confidence: str = Field(..., description="Confidence level: high, medium, or low")
    description: str = Field("", description="Brief description of the plant")

    model_config = {"populate_by_name": True}


class PlantLookupResponse(BaseModel):
    plant_type: str = Field(..., alias="plantType")
    confidence: str = Field(...)
    description: str = Field("")
    origin: str = Field("", description="Geographic origin of the plant")
    history: str = Field("", description="Brief history and cultural significance")
    fun_facts: list[str] = Field(default_factory=list, alias="funFacts")
    care_summary: str = Field("", alias="careSummary")
    sun_needs: str = Field("", alias="sunNeeds")
    water_needs: str = Field("", alias="waterNeeds")
    difficulty: str = Field("", description="Easy, Moderate, or Hard")

    model_config = {"populate_by_name": True}


@router.post("/photos/upload", response_model=PhotoUploadResponse, status_code=201)
async def upload_photo(request: Request, file: UploadFile = File(...)):
    """Upload a plant photo directly. Returns the public URL."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    bucket_name = os.getenv("GCS_BUCKET", "healthy-plant-uploads")

    try:
        client = storage.Client()
        bucket = client.bucket(bucket_name)

        filename = f"{uuid.uuid4().hex}.jpg"
        blob_path = f"users/{user_id}/plants/{filename}"
        blob = bucket.blob(blob_path)

        contents = await file.read()
        blob.upload_from_string(contents, content_type="image/jpeg")

        public_url = f"https://storage.googleapis.com/{bucket_name}/{blob_path}"
        logger.info(f"Uploaded photo for user {user_id}: {public_url}")
        return PhotoUploadResponse(url=public_url)
    except Exception as e:
        logger.error(f"Error uploading photo for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to upload photo")


@router.post("/photos/identify", response_model=PlantIdentifyResponse)
async def identify_plant(request: Request, file: UploadFile = File(...)):
    """Identify a plant from an uploaded photo using AI vision."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    ai_service = request.app.state.ai_service

    try:
        contents = await file.read()
        media_type = file.content_type or "image/jpeg"
        result = await ai_service.identify_plant_from_image(contents, media_type)
        return PlantIdentifyResponse(
            plant_type=result.get("plant_type", ""),
            confidence=result.get("confidence", "low"),
            description=result.get("description", ""),
        )
    except Exception as e:
        logger.error(f"Error identifying plant for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to identify plant")


@router.post("/photos/lookup", response_model=PlantLookupResponse)
async def lookup_plant(request: Request, file: UploadFile = File(...)):
    """Identify a plant from a photo and return detailed info: history, origin, care."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    ai_service = request.app.state.ai_service

    try:
        contents = await file.read()
        media_type = file.content_type or "image/jpeg"
        result = await ai_service.lookup_plant_from_image(contents, media_type)
        return PlantLookupResponse(**result)
    except Exception as e:
        logger.error(f"Error looking up plant for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to look up plant")
