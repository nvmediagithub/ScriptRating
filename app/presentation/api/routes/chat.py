"""
Chat API routes for real-time communication and session management.

This module provides RESTful endpoints for chat functionality including
session management, message handling, and WebSocket real-time communication.
"""
import asyncio
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app.config import settings
from app.models.chat_models import (
    ChatSession, ChatMessage, create_chat_session, create_chat_message,
    get_chat_sessions, get_chat_messages, get_chat_session, delete_chat_session,
    update_message_content, update_message_streaming_status
)
from app.presentation.api.schemas.chat_schemas import (
    ChatSessionCreateRequest, ChatSessionResponse, ChatSessionUpdateRequest,
    ChatMessageCreateRequest, ChatMessageResponse, ChatMessageUpdateRequest,
    ChatSessionsListResponse, ChatMessagesListResponse, ProcessLLMRequest,
    ProcessLLMResponse, ChatStatsResponse, WebSocketMessage, TypingIndicatorMessage,
    ErrorResponse, SessionsPaginationQuery, MessagesPaginationQuery,
    MessageRole, LLMProvider, format_chat_message, format_chat_session,
    create_paginated_response
)
from app.infrastructure.websocket.manager import connection_manager, WebSocketMessageHandler

logger = logging.getLogger(__name__)

router = APIRouter()

# Dependency to get database session
async def get_db():
    """Get database session from the database infrastructure."""
    from app.infrastructure.database.session import get_db as get_db_session
    return get_db_session()


# Authentication dependency (placeholder)
async def get_current_user_id() -> str:
    """Get current user ID from authentication (placeholder)."""
    # This would extract user ID from JWT token or session
    return "user_123"  # Placeholder


# LLM Service Integration
async def process_llm_chat_message(
    request: ProcessLLMRequest,
    session_id: str,
    user_id: str
) -> ProcessLLMResponse:
    """
    Process a message through the LLM service.
    
    This integrates with the existing LLM infrastructure from the llm.py routes.
    """
    # This would call the existing LLM service
    # For now, simulate processing
    
    start_time = datetime.utcnow()
    
    try:
        # Simulate LLM processing time
        await asyncio.sleep(1.0)
        
        # Mock response based on provider
        if request.provider == LLMProvider.LOCAL:
            response = "I understand your question. Let me help you with that."
        else:  # OpenRouter
            response = "Thank you for your question. Based on my analysis, I can provide insights about this topic."
        
        response_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
        tokens_used = len(response.split()) * 1.3  # Rough estimation
        
        return ProcessLLMResponse(
            message_id="mock_message_id",
            session_id=session_id,
            response=response,
            tokens_used=int(tokens_used),
            response_time_ms=response_time_ms,
            provider=request.provider or LLMProvider.LOCAL,
            model=request.model_name or "llama2:7b",
            success=True
        )
        
    except Exception as e:
        logger.error(f"LLM processing error: {e}")
        return ProcessLLMResponse(
            message_id="mock_message_id",
            session_id=session_id,
            response="",
            tokens_used=0,
            response_time_ms=(datetime.utcnow() - start_time).total_seconds() * 1000,
            provider=request.provider or LLMProvider.LOCAL,
            model=request.model_name or "llama2:7b",
            success=False,
            error_message=str(e)
        )


# Chat Session Management Endpoints

@router.get("/sessions", response_model=ChatSessionsListResponse)
async def get_chat_sessions_endpoint(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=200, description="Items per page"),
    user_id: Optional[str] = Query(None, description="Filter by user ID"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    llm_provider: Optional[LLMProvider] = Query(None, description="Filter by LLM provider"),
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Get paginated list of chat sessions for the current user.
    
    Supports filtering by user, active status, and LLM provider.
    """
    try:
        # For demo, using mock data
        # In real implementation, use db.query(ChatSession)...
        
        # Mock sessions
        mock_sessions = [
            ChatSession(
                id="session_1",
                user_id=current_user_id,
                title="Chat with Llama",
                llm_provider="LOCAL",
                llm_model="llama2:7b",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
                is_active=True,
                settings={}
            ),
            ChatSession(
                id="session_2",
                user_id=current_user_id,
                title="Analysis Discussion",
                llm_provider="OPENROUTER",
                llm_model=settings.get_openrouter_base_model() or "gpt-3.5-turbo",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
                is_active=True,
                settings={}
            )
        ]
        
        # Format and paginate
        formatted_sessions = [format_chat_session(session) for session in mock_sessions]
        total_count = len(formatted_sessions)
        
        # Simple pagination
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        paginated_sessions = formatted_sessions[start_idx:end_idx]
        
        return ChatSessionsListResponse(
            sessions=paginated_sessions,
            total_count=total_count,
            page=page,
            page_size=page_size,
            has_more=end_idx < total_count
        )
        
    except Exception as e:
        logger.error(f"Error getting chat sessions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve chat sessions: {str(e)}"
        )


@router.post("/sessions", response_model=ChatSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_chat_session_endpoint(
    request: ChatSessionCreateRequest,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Create a new chat session.
    """
    try:
        # Create session
        session = create_chat_session(
            db=db,
            user_id=current_user_id,
            title=request.title,
            llm_provider=request.llm_provider,
            llm_model=request.llm_model,
            settings=request.settings
        )
        
        return format_chat_session(session)
        
    except Exception as e:
        logger.error(f"Error creating chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create chat session: {str(e)}"
        )


@router.get("/sessions/{session_id}", response_model=ChatSessionResponse)
async def get_chat_session_endpoint(
    session_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Get a specific chat session with ownership validation.
    """
    try:
        session = get_chat_session(db, session_id, current_user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        return format_chat_session(session)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve chat session: {str(e)}"
        )


@router.put("/sessions/{session_id}", response_model=ChatSessionResponse)
async def update_chat_session_endpoint(
    session_id: str,
    request: ChatSessionUpdateRequest,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Update a chat session.
    """
    try:
        session = get_chat_session(db, session_id, current_user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Update fields
        if request.title is not None:
            session.title = request.title
        if request.is_active is not None:
            session.is_active = request.is_active
        if request.settings is not None:
            session.settings = request.settings
        
        session.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(session)
        
        return format_chat_session(session)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update chat session: {str(e)}"
        )


@router.delete("/sessions/{session_id}")
async def delete_chat_session_endpoint(
    session_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Delete a chat session.
    """
    try:
        # Clean up WebSocket connections
        await connection_manager.cleanup_session(session_id)
        
        # Delete session
        if not delete_chat_session(db, session_id, current_user_id):
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

@router.get("/sessions/{session_id}/messages", response_model=ChatMessagesListResponse)
async def get_chat_messages_endpoint(
    session_id: str,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=200, description="Items per page"),
    before: Optional[datetime] = Query(None, description="Get messages before this timestamp"),
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Get paginated messages for a chat session.
    """
    try:
        # Validate session ownership
        session = get_chat_session(db, session_id, current_user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Get messages
        messages = get_chat_messages(db, session_id, page_size, (page - 1) * page_size, before)
        
        # Format messages
        formatted_messages = [format_chat_message(msg) for msg in messages]
        total_count = len(formatted_messages)  # In real implementation, get actual count
        
        return ChatMessagesListResponse(
            messages=formatted_messages,
            total_count=total_count,
            page=page,
            page_size=page_size,
            has_more=(page * page_size) < total_count,
            session_id=session_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting chat messages: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve chat messages: {str(e)}"
        )


@router.post("/sessions/{session_id}/messages", response_model=ChatMessageResponse)
async def send_chat_message_endpoint(
    session_id: str,
    request: ChatMessageCreateRequest,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Send a message in a chat session.
    """
    try:
        # Validate session ownership
        session = get_chat_session(db, session_id, current_user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Create user message
        user_message = create_chat_message(
            db=db,
            session_id=session_id,
            role=request.role,
            content=request.content,
            message_metadata=request.metadata
        )
        
        # Broadcast to connected WebSocket clients
        await connection_manager.broadcast_message_update(session_id, user_message)
        
        # Start LLM processing (async)
        asyncio.create_task(
            process_and_respond(session_id, user_message.id, session.llm_provider, session.llm_model, request.content)
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


async def process_and_respond(
    session_id: str,
    user_message_id: str,
    provider: str,
    model: str,
    user_prompt: str
):
    """
    Process user message and generate LLM response.
    """
    try:
        # Create assistant message placeholder
        from app.infrastructure.database.session import get_db_session
        with get_db_session() as db:
            assistant_message = create_chat_message(
                db=db,
                session_id=session_id,
                role="assistant",
                content="",
                is_streaming=True
            )
            
            # Broadcast streaming start
            await connection_manager.broadcast_message_update(session_id, assistant_message)
            
            # Process through LLM
            llm_request = ProcessLLMRequest(
                message_id=assistant_message.id,
                session_id=session_id,
                prompt=user_prompt,
                provider=LLMProvider(provider),
                model_name=model,
                stream=True
            )
            
            llm_response = await process_llm_chat_message(llm_request, session_id, "system")
            
            # Update message with response
            if llm_response.success:
                final_message = update_message_content(
                    db=db,
                    message_id=assistant_message.id,
                    content=llm_response.response,
                    tokens_used=llm_response.tokens_used,
                    response_time_ms=int(llm_response.response_time_ms)
                )
            else:
                final_message = update_message_content(
                    db=db,
                    message_id=assistant_message.id,
                    content="I apologize, but I encountered an error processing your request.",
                    error_message=llm_response.error_message
                )
            
            # Broadcast final message
            if final_message:
                await connection_manager.broadcast_message_update(session_id, final_message)
        
    except Exception as e:
        logger.error(f"Error in LLM processing: {e}")
        # Broadcast error message
        await connection_manager.broadcast_error(session_id, "system", str(e))


@router.put("/messages/{message_id}", response_model=ChatMessageResponse)
async def update_chat_message_endpoint(
    message_id: str,
    request: ChatMessageUpdateRequest,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Update a chat message (e.g., for streaming responses).
    """
    try:
        # Get message and validate ownership through session
        message = db.query(ChatMessage).filter(ChatMessage.id == message_id).first()
        if not message:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Message not found"
            )
        
        # Validate ownership through session
        session = get_chat_session(db, str(message.session_id), current_user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        # Update message
        if request.content is not None:
            message.content = request.content
        if request.is_streaming is not None:
            message.is_streaming = request.is_streaming
        if request.tokens_used is not None:
            message.tokens_used = request.tokens_used
        if request.response_time_ms is not None:
            message.response_time_ms = request.response_time_ms
        if request.error_message is not None:
            message.error_message = request.error_message
        
        message.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(message)
        
        # Broadcast update
        await connection_manager.broadcast_message_update(str(message.session_id), message)
        
        return format_chat_message(message)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating chat message: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update message: {str(e)}"
        )


# WebSocket Endpoints

@router.websocket("/sessions/{session_id}/websocket")
async def chat_websocket_endpoint(
    websocket: WebSocket,
    session_id: str,
    db: Session = Depends(get_db)
):
    """
    WebSocket endpoint for real-time chat communication.
    """
    user_id = "placeholder_user"  # This would extract from connection or auth
    
    # Accept connection
    connected = await connection_manager.connect(websocket, session_id, user_id)
    if not connected:
        await websocket.close(code=4001, reason="Failed to establish connection")
        return
    
    message_handler = WebSocketMessageHandler(db)
    
    try:
        while True:
            # Receive message from WebSocket
            data = await websocket.receive_text()
            message_data = WebSocketMessage.parse_raw(data)
            
            # Handle message
            await message_handler.handle_message(websocket, message_data.dict(), session_id, user_id)
            
    except WebSocketDisconnect:
        connection_manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        connection_manager.disconnect(websocket)
        await websocket.close(code=4000, reason="Internal server error")


# LLM Processing Endpoints

@router.post("/sessions/{session_id}/process-llm", response_model=ProcessLLMResponse)
async def process_llm_endpoint(
    session_id: str,
    request: ProcessLLMRequest,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Process a message through the LLM service.
    """
    try:
        # Validate session ownership
        session = get_chat_session(db, session_id, current_user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Process through LLM
        response = await process_llm_chat_message(request, session_id, current_user_id)
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing LLM request: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"LLM processing failed: {str(e)}"
        )


# Statistics and Monitoring Endpoints

@router.get("/stats", response_model=ChatStatsResponse)
async def get_chat_stats_endpoint(
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id)
):
    """
    Get chat statistics for the current user.
    """
    try:
        # Mock statistics - in real implementation, query database
        return ChatStatsResponse(
            total_sessions=5,
            total_messages=42,
            active_sessions=2,
            messages_today=8,
            average_response_time_ms=1250.5,
            most_used_provider="LOCAL",
            most_used_model="llama2:7b"
        )
        
    except Exception as e:
        logger.error(f"Error getting chat statistics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve statistics: {str(e)}"
        )


@router.get("/health")
async def chat_health_check():
    """
    Health check endpoint for chat service.
    """
    return {
        "service": "chat",
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "active_connections": sum(len(connections) for connections in connection_manager.active_connections.values())
    }