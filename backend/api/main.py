"""Healthy Plant API - FastAPI application."""

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

import firebase_admin
from firebase_admin import auth as firebase_auth, credentials

from routers import profiles, garden, calendar, chat, photos, community, sensors, auth, gardeners
from services.firestore_service import FirestoreService
from services.ai_service import AIService
from services.storage_service import StorageService
from services.sensor_service import SensorService

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown lifecycle handler."""
    logger.info("Starting Healthy Plant API...")
    # Initialize Firebase Admin SDK
    if not firebase_admin._apps:
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            firebase_admin.initialize_app()
        logger.info("Firebase Admin SDK initialized")
    app.state.firestore_service = FirestoreService()
    app.state.ai_service = AIService()
    app.state.storage_service = StorageService()
    app.state.sensor_service = SensorService(app.state.firestore_service)
    logger.info("Services initialized successfully.")
    yield
    logger.info("Shutting down Healthy Plant API...")


app = FastAPI(
    title="Healthy Plant API",
    description="Backend API for the Healthy Plant gardening assistant.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    """
    Firebase Auth middleware placeholder.

    For now, accepts a simple X-User-ID header. In production, this should
    verify a Firebase Bearer token and extract the userId from it.
    """
    # Skip auth for health check and docs
    if request.url.path in ("/health", "/docs", "/openapi.json", "/redoc"):
        return await call_next(request)

    # Device-token auth for sensor readings endpoint
    if request.url.path == "/api/v1/sensors/readings" and request.method == "POST":
        device_token = request.headers.get("X-Device-Token")
        if device_token:
            try:
                firestore = request.app.state.firestore_service
                sensor = await firestore.get_sensor_by_token(device_token)
                if sensor:
                    request.state.user_id = sensor["userId"]
                    request.state.sensor_id = sensor["sensorId"]
                    return await call_next(request)
            except Exception as e:
                logger.error(f"Device token auth error: {e}")
        return Response(
            content='{"detail": "Invalid device token"}',
            status_code=401,
            media_type="application/json",
        )

    # Try Firebase Bearer token first
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        try:
            decoded = firebase_auth.verify_id_token(token)
            request.state.user_id = decoded["uid"]
            return await call_next(request)
        except Exception as e:
            logger.warning(f"Firebase token verification failed: {e}")
            # Fall through to X-User-ID

    # Fall back to anonymous X-User-ID header
    user_id = request.headers.get("X-User-ID")
    if not user_id:
        return Response(
            content='{"detail": "Missing authentication"}',
            status_code=401,
            media_type="application/json",
        )

    request.state.user_id = user_id
    response = await call_next(request)
    return response


# Include routers
app.include_router(profiles.router, prefix="/api/v1", tags=["profiles"])
app.include_router(garden.router, prefix="/api/v1", tags=["garden"])
app.include_router(calendar.router, prefix="/api/v1", tags=["calendar"])
app.include_router(chat.router, prefix="/api/v1", tags=["chat"])
app.include_router(photos.router, prefix="/api/v1", tags=["photos"])
app.include_router(community.router, prefix="/api/v1", tags=["community"])
app.include_router(sensors.router, prefix="/api/v1", tags=["sensors"])
app.include_router(auth.router, prefix="/api/v1", tags=["auth"])
app.include_router(gardeners.router, prefix="/api/v1", tags=["gardeners"])


@app.get("/health")
async def health_check():
    """Health check endpoint for Cloud Run."""
    return {"status": "healthy", "service": "healthy-plant-api"}
