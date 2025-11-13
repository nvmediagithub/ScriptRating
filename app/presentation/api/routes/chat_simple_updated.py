#!/usr/bin/env python3
"""
Simplified Chat API routes using JSON storage with real OpenRouter integration.

This module provides simplified RESTful endpoints for chat functionality
using JSON file-based storage instead of database, with real LLM integration.
"""
import asyncio
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, HTTPException, Query, status
from fastapi.responses import JSONResponse

from app.infrastructure.storage.json_storage import storage
from app.infrastructure.services.openrouter_client import (
    OpenRouterClient,
    OpenRouterAuthError,
    OpenRouterConfigurationError,
    OpenRouterError
)
from app.config import settings
from app.presentation.api.schemas.chat_schemas import (
    ChatSessionCreateRequest, ChatSessionResponse, ChatSessionUpdateRequest,
    ChatMessageCreateRequest, ChatMessageResponse, ChatMessageUpdateRequest,
    ChatSessionsListResponse, ChatMessagesListResponse, ProcessLLMRequest,
    ProcessLLMResponse, ChatStatsResponse, LLMProvider
)

logger = logging.getLogger(__name__)

router = APIRouter()

# Initialize OpenRouter client
_openrouter_client = None

def get_openrouter_client() -> OpenRouterClient:
    """Get or create OpenRouter client instance."""
    global _openrouter_client
    if _openrouter_client is None:
        # Use effective API key from settings (checks environment variables)
        api_key = settings.get_openrouter_api_key()
        
        if not api_key:
            logger.warning("OpenRouter API key not found in environment or settings")
        
        _openrouter_client = OpenRouterClient(
            api_key=api_key,
            base_url=settings.openrouter_base_url,
            referer=settings.openrouter_referer,
            app_name=settings.openrouter_app_name,
            timeout=settings.openrouter_timeout
        )
        
        logger.info(f"OpenRouter client initialized - Base URL: {settings.openrouter_base_url}, Has API Key: {bool(api_key)}")
    return _openrouter_client

# Simple mapping functions
def format_chat_session(chat_data: Dict) -> ChatSessionResponse:
    """Convert chat data dict to ChatSessionResponse."""
    from datetime import datetime
    
    # Convert ISO strings to datetime objects
    created_at = datetime.fromisoformat(chat_data["created_at"].replace('Z', '+00:00')) if isinstance(chat_data["created_at"], str) else chat_data["created_at"]
    updated_at = datetime.fromisoformat(chat_data["updated_at"].replace('Z', '+00:00')) if isinstance(chat_data["updated_at"], str) else chat_data["updated_at"]
    
    return ChatSessionResponse(
        id=chat_data["id"],
        title=chat_data["title"],
        user_id="default_user",  # Simplified - no authentication
        llm_provider=chat_data["llm_provider"],
        llm_model=chat_data["llm_model"],
        created_at=created_at,
        updated_at=updated_at,
        is_active=chat_data["is_active"],
        message_count=len(chat_data.get("messages", [])),
        settings=chat_data["settings"]
    )

def format_chat_message(message_data: Dict) -> ChatMessageResponse:
    """Convert message data dict to ChatMessageResponse."""
    from datetime import datetime
    
    # Convert ISO strings to datetime objects
    created_at = datetime.fromisoformat(message_data["created_at"].replace('Z', '+00:00')) if isinstance(message_data["created_at"], str) else message_data["created_at"]
    updated_at = datetime.fromisoformat(message_data["updated_at"].replace('Z', '+00:00')) if isinstance(message_data["updated_at"], str) else message_data["updated_at"]
    
    return ChatMessageResponse(
        id=message_data["id"],
        session_id=message_data["session_id"],
        role=message_data["role"],
        content=message_data["content"],
        created_at=created_at,
        updated_at=updated_at,
        is_streaming=message_data["is_streaming"],
        tokens_used=message_data["tokens_used"],
        response_time_ms=message_data["response_time_ms"],
        error_message=message_data["error_message"],
        metadata=message_data["metadata"]
    )

# Enhanced LLM Processing with Real OpenRouter Integration
async def process_llm_chat_message(
    prompt: str,
    provider: str = "local",
    model: str = "llama2:7b"
) -> ProcessLLMResponse:
    """Enhanced LLM processing with real OpenRouter integration."""
    start_time = datetime.utcnow()
    
    # Normalize provider name
    provider = provider.upper() if provider else "LOCAL"
    
    # Use OpenRouter for all requests - get model from settings if not provided
    if not model or model == "llama2:7b":
        model = settings.get_openrouter_base_model() or "minimax/minimax-m2:free"
    
    return await _process_openrouter_request(prompt, model, start_time)

async def _process_openrouter_request(prompt: str, model: str, start_time: datetime) -> ProcessLLMResponse:
    """Process request through OpenRouter API."""
    try:
        # Get OpenRouter client with settings
        client = get_openrouter_client()
        
        if not client.has_api_key:
            logger.error("OpenRouter API key is not configured")
            raise OpenRouterConfigurationError("OpenRouter API key is not configured. Please set OPENROUTER_API_KEY in .env file.")
        
        logger.info(f"Processing chat message with OpenRouter - Model: {model}")
        
        # Use OpenRouter API
        result = await client.chat_completion(
            model=model,
            prompt=prompt,
            max_tokens=2048,
            temperature=0.7
        )
        
        response_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        logger.info(f"OpenRouter response received - Tokens: {result.get('tokens_used')}, Time: {response_time_ms:.2f}ms")
        
        return ProcessLLMResponse(
            message_id="openrouter_message_id",
            session_id="openrouter_session_id",
            response=result.get("response", ""),
            tokens_used=result.get("tokens_used") or 0,
            response_time_ms=result.get("response_time_ms") or response_time_ms,
            provider="OPENROUTER",
            model=model,
            success=True
        )
        
    except OpenRouterAuthError as e:
        logger.error(f"OpenRouter authentication error: {e}")
        return ProcessLLMResponse(
            message_id="error_message_id",
            session_id="error_session_id",
            response="I apologize, but I'm having authentication issues. Please check the API configuration.",
            tokens_used=0,
            response_time_ms=(datetime.utcnow() - start_time).total_seconds() * 1000,
            provider="OPENROUTER",
            model=model,
            success=False,
            error_message=f"Authentication error: {str(e)}"
        )
    except OpenRouterConfigurationError as e:
        logger.error(f"OpenRouter configuration error: {e}")
        return ProcessLLMResponse(
            message_id="error_message_id",
            session_id="error_session_id",
            response="I apologize, but OpenRouter is not properly configured. Please contact the administrator.",
            tokens_used=0,
            response_time_ms=(datetime.utcnow() - start_time).total_seconds() * 1000,
            provider="OPENROUTER",
            model=model,
            success=False,
            error_message=f"Configuration error: {str(e)}"
        )
    except OpenRouterError as e:
        logger.error(f"OpenRouter API error: {e}")
        return ProcessLLMResponse(
            message_id="error_message_id",
            session_id="error_session_id",
            response="I apologize, but I encountered an issue processing your request. Please try again.",
            tokens_used=0,
            response_time_ms=(datetime.utcnow() - start_time).total_seconds() * 1000,
            provider="OPENROUTER",
            model=model,
            success=False,
            error_message=f"API error: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error in OpenRouter processing: {e}")
        return ProcessLLMResponse(
            message_id="error_message_id",
            session_id="error_session_id",
            response="I apologize, but an unexpected error occurred. Please try again later.",
            tokens_used=0,
            response_time_ms=(datetime.utcnow() - start_time).total_seconds() * 1000,
            provider="OPENROUTER",
            model=model,
            success=False,
            error_message=f"Unexpected error: {str(e)}"
        )



# Chat Session Management Endpoints

@router.get("/chats", response_model=ChatSessionsListResponse)
async def get_chat_sessions(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=200, description="Items per page")
):
    """
    Get paginated list of all chat sessions.
    """
    try:
        result = storage.get_all_chat_sessions(page, page_size)
        
        # For the list endpoint, we need to get full chat data for each session
        formatted_sessions = []
        for chat_summary in result["chats"]:
            # Get full chat data
            full_chat_data = storage.get_chat_session(chat_summary["id"])
            if full_chat_data:
                formatted_sessions.append(format_chat_session(full_chat_data))
        
        return ChatSessionsListResponse(
            sessions=formatted_sessions,
            total_count=result["total_count"],
            page=result["page"],
            page_size=result["page_size"],
            has_more=result["has_more"]
        )
        
    except Exception as e:
        logger.error(f"Error getting chat sessions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve chat sessions: {str(e)}"
        )


@router.post("/chats", response_model=ChatSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_chat_session(request: ChatSessionCreateRequest):
    """
    Create a new chat session.
    """
    try:
        chat_data = storage.create_chat_session(
            title=request.title,
            llm_provider=request.llm_provider,
            llm_model=request.llm_model,
            settings=request.settings
        )
        
        if not chat_data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create chat session"
            )
        
        return format_chat_session(chat_data)
        
    except Exception as e:
        logger.error(f"Error creating chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create chat session: {str(e)}"
        )


@router.get("/chats/{chat_id}", response_model=ChatSessionResponse)
async def get_chat_session(chat_id: str):
    """
    Get a specific chat session.
    """
    try:
        chat_data = storage.get_chat_session(chat_id)
        if not chat_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        return format_chat_session(chat_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve chat session: {str(e)}"
        )


@router.put("/chats/{chat_id}", response_model=ChatSessionResponse)
async def update_chat_session(chat_id: str, request: ChatSessionUpdateRequest):
    """
    Update a chat session.
    """
    try:
        # Convert to dict, excluding None values
        updates = {k: v for k, v in request.dict().items() if v is not None}
        
        chat_data = storage.update_chat_session(chat_id, updates)
        if not chat_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        return format_chat_session(chat_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update chat session: {str(e)}"
        )


@router.delete("/chats/{chat_id}")
async def delete_chat_session(chat_id: str):
    """
    Delete a chat session.
    """
    try:
        if not storage.delete_chat_session(chat_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"message": "Chat session deleted successfully"}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete chat session: {str(e)}"
        )


# Chat Message Management Endpoints

@router.get("/chats/{chat_id}/messages", response_model=ChatMessagesListResponse)
async def get_chat_messages(
    chat_id: str,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=200, description="Items per page")
):
    """
    Get paginated messages for a chat session.
    """
    try:
        # Validate chat exists
        chat_data = storage.get_chat_session(chat_id)
        if not chat_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Get messages
        offset = (page - 1) * page_size
        messages = storage.get_messages(chat_id, limit=page_size, offset=offset)
        
        # Add session_id to messages
        for msg in messages:
            msg["session_id"] = chat_id
        
        # Format messages
        formatted_messages = [format_chat_message(msg) for msg in messages]
        total_count = len(chat_data.get("messages", []))
        
        return ChatMessagesListResponse(
            messages=formatted_messages,
            total_count=total_count,
            page=page,
            page_size=page_size,
            has_more=(page * page_size) < total_count,
            session_id=chat_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting chat messages: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve chat messages: {str(e)}"
        )


@router.post("/chats/{chat_id}/messages", response_model=ChatMessageResponse)
async def send_chat_message(chat_id: str, request: ChatMessageCreateRequest):
    """
    Send a message in a chat session and get LLM response.
    """
    try:
        # Validate chat exists
        chat_data = storage.get_chat_session(chat_id)
        if not chat_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Add user message
        user_message = storage.add_message(
            chat_id=chat_id,
            role=request.role,
            content=request.content,
            metadata=request.metadata
        )
        
        if not user_message:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add user message"
            )
        
        # Add session_id to response
        user_message["session_id"] = chat_id
        
        # Process LLM response asynchronously
        asyncio.create_task(
            process_and_respond(
                chat_id=chat_id,
                user_message=user_message,
                provider=chat_data["llm_provider"],
                model=chat_data["llm_model"]
            )
        )
        
        return format_chat_message(user_message)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending chat message: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send message: {str(e)}"
        )


async def process_and_respond(chat_id: str, user_message: Dict, provider: str, model: str):
    """
    Process user message and generate LLM response.
    """
    try:
        # Add assistant message placeholder
        assistant_message = storage.add_message(
            chat_id=chat_id,
            role="assistant",
            content="",
            metadata={"is_processing": True}
        )
        
        if not assistant_message:
            return
        
        # Add session_id to response
        assistant_message["session_id"] = chat_id
        
        # Process through LLM
        llm_response = await process_llm_chat_message(
            prompt=user_message["content"],
            provider=provider,
            model=model
        )
        
        # Update assistant message with response
        if llm_response.success:
            storage.update_message(
                chat_id=chat_id,
                message_id=assistant_message["id"],
                updates={
                    "content": llm_response.response,
                    "tokens_used": llm_response.tokens_used,
                    "response_time_ms": int(llm_response.response_time_ms),
                    "is_streaming": False
                }
            )
        else:
            storage.update_message(
                chat_id=chat_id,
                message_id=assistant_message["id"],
                updates={
                    "content": llm_response.response or "I apologize, but I encountered an error processing your request.",
                    "error_message": llm_response.error_message,
                    "is_streaming": False
                }
            )
        
    except Exception as e:
        logger.error(f"Error in LLM processing: {e}")
        # Update assistant message with error
        if assistant_message:
            storage.update_message(
                chat_id=chat_id,
                message_id=assistant_message["id"],
                updates={
                    "content": "I apologize, but I encountered an error processing your request.",
                    "error_message": str(e),
                    "is_streaming": False
                }
            )


@router.put("/messages/{message_id}", response_model=ChatMessageResponse)
async def update_chat_message(message_id: str, request: ChatMessageUpdateRequest):
    """
    Update a chat message.
    """
    try:
        # This is a simplified version - in a real implementation,
        # we'd need to find which chat this message belongs to
        # For now, we'll skip this endpoint as it's not essential
        
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Message update endpoint not implemented in simplified version"
        )
        
    except Exception as e:
        logger.error(f"Error updating chat message: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update message: {str(e)}"
        )


# LLM Processing Endpoint

@router.post("/chats/{chat_id}/process-llm", response_model=ProcessLLMResponse)
async def process_llm_endpoint(chat_id: str, request: ProcessLLMRequest):
    """
    Process a message through the LLM service.
    """
    try:
        # Validate chat exists
        chat_data = storage.get_chat_session(chat_id)
        if not chat_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Process through LLM
        response = await process_llm_chat_message(
            prompt=request.prompt,
            provider=request.provider or chat_data["llm_provider"],
            model=request.model_name or chat_data["llm_model"]
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing LLM request: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"LLM processing failed: {str(e)}"
        )


# Statistics Endpoint

@router.get("/stats", response_model=ChatStatsResponse)
async def get_chat_stats():
    """
    Get chat statistics.
    """
    try:
        # Get all chats for statistics
        all_chats_result = storage.get_all_chat_sessions(page=1, page_size=1000)
        chats = all_chats_result["chats"]
        
        # Calculate simple statistics
        total_sessions = len(chats)
        active_sessions = sum(1 for chat in chats if chat.get("is_active", True))
        
        # Count messages across all chats
        total_messages = 0
        for chat in chats:
            chat_data = storage.get_chat_session(chat["id"])
            if chat_data:
                total_messages += len(chat_data.get("messages", []))
        
        return ChatStatsResponse(
            total_sessions=total_sessions,
            total_messages=total_messages,
            active_sessions=active_sessions,
            messages_today=total_messages // 7,  # Rough estimate
            average_response_time_ms=1250.5,
            most_used_provider="local",
            most_used_model="llama2:7b"
        )
        
    except Exception as e:
        logger.error(f"Error getting chat statistics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve statistics: {str(e)}"
        )


# Health Check Endpoint

@router.get("/health")
async def chat_health_check():
    """
    Health check endpoint for chat service.
    """
    try:
        # Test storage access
        test_result = storage.get_all_chat_sessions(page=1, page_size=1)
        
        # Test OpenRouter connectivity if available
        openrouter_status = "unavailable"
        try:
            if settings.openrouter_api_key:
                client = get_openrouter_client()
                await client.check_connection()
                openrouter_status = "connected"
        except Exception as e:
            openrouter_status = f"error: {str(e)}"
        
        return {
            "service": "chat",
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "storage": "json",
            "version": "enhanced",
            "openrouter": openrouter_status
        }
        
    except Exception as e:
        logger.error(f"Chat health check failed: {e}")
        return {
            "service": "chat",
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }