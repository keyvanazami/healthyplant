"""Healthy Plant API - FastAPI application."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

from routers import profiles, garden, calendar, chat, photos, community
from services.firestore_service import FirestoreService
from services.ai_service import AIService
from services.storage_service import StorageService

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown lifecycle handler."""
    logger.info("Starting Healthy Plant API...")
    app.state.firestore_service = FirestoreService()
    app.state.ai_service = AIService()
    app.state.storage_service = StorageService()
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

    user_id = request.headers.get("X-User-ID")
    if not user_id:
        return Response(
            content='{"detail": "Missing X-User-ID header"}',
            status_code=401,
            media_type="application/json",
        )

    # Attach userId to request state for downstream use
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


@app.get("/health")
async def health_check():
    """Health check endpoint for Cloud Run."""
    return {"status": "healthy", "service": "healthy-plant-api"}
