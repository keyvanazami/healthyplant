"""Router for AI chat with SSE streaming."""

import json
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from models.chat import ChatHistoryResponse, ChatMessageRequest, ChatMessageResponse
from services.rate_limiter import check_and_increment, get_usage

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/chat")
async def send_chat_message(request: Request, body: ChatMessageRequest):
    """
    Send a message and receive an AI response via Server-Sent Events (SSE).

    The response streams text chunks as SSE events. The full assistant message
    is saved to Firestore after streaming completes.
    """
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    firestore = request.app.state.firestore_service
    ai_service = request.app.state.ai_service

    await check_and_increment(firestore.db, user_id, "chat")

    try:
        # Save user message
        user_message = await firestore.save_message(
            user_id=user_id,
            role="user",
            content=body.content,
        )

        # Load conversation history for context
        history = await firestore.get_chat_history(user_id, limit=20)

        # Load plant profiles for context
        profiles = await firestore.get_profiles(user_id)

        # Stream the AI response via SSE
        async def event_generator():
            full_response = ""
            try:
                async for chunk in ai_service.chat_stream(
                    message=body.content,
                    history=history,
                    plant_profiles=profiles,
                ):
                    full_response += chunk
                    # SSE format: data: <json>\n\n
                    event_data = json.dumps({"type": "chunk", "content": chunk})
                    yield f"data: {event_data}\n\n"

                # Save the full assistant response to Firestore
                assistant_message = await firestore.save_message(
                    user_id=user_id,
                    role="assistant",
                    content=full_response,
                )

                # Send done event with the saved message ID
                done_data = json.dumps({
                    "type": "done",
                    "messageId": assistant_message.get("id", ""),
                })
                yield f"data: {done_data}\n\n"

            except Exception as e:
                logger.error(f"Error during chat stream for user {user_id}: {e}")
                error_data = json.dumps({"type": "error", "content": str(e)})
                yield f"data: {error_data}\n\n"

        return StreamingResponse(
            event_generator(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )
    except Exception as e:
        logger.error(f"Error in chat endpoint for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to process chat message")


@router.get("/chat/ai-usage")
async def get_ai_usage(request: Request):
    """Return today's AI usage counts and limits for the authenticated user."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    firestore = request.app.state.firestore_service
    return await get_usage(firestore.db, user_id)


@router.get("/chat/history", response_model=ChatHistoryResponse)
async def get_chat_history(request: Request):
    """Get the last 50 chat messages for the authenticated user."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    firestore = request.app.state.firestore_service

    try:
        messages = await firestore.get_chat_history(user_id, limit=50)
        return ChatHistoryResponse(messages=messages)
    except Exception as e:
        logger.error(f"Error fetching chat history for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve chat history")


@router.delete("/chat/history", status_code=204)
async def clear_chat_history(request: Request):
    """Clear all chat history for the authenticated user."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    firestore = request.app.state.firestore_service

    try:
        await firestore.clear_chat_history(user_id)
    except Exception as e:
        logger.error(f"Error clearing chat history for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to clear chat history")
