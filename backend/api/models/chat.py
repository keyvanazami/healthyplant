"""Pydantic models for chat functionality."""

from typing import List

from pydantic import BaseModel, Field


class ChatMessageRequest(BaseModel):
    """Request model for sending a chat message."""

    content: str = Field(..., min_length=1, max_length=2000, description="The user's message")


class ChatMessageResponse(BaseModel):
    """Response model for a single chat message."""

    id: str = Field(..., description="Firestore document ID")
    user_id: str = Field(..., alias="userId")
    role: str = Field(..., description="Message role: 'user' or 'assistant'")
    content: str = Field(..., description="Message text content")
    timestamp: str = Field(..., description="ISO 8601 timestamp")

    model_config = {"populate_by_name": True, "from_attributes": True}


class ChatHistoryResponse(BaseModel):
    """Response model for chat history."""

    messages: List[ChatMessageResponse] = Field(default_factory=list)
