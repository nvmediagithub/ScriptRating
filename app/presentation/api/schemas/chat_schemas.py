"""
Chat API schemas for request/response models.

This module contains Pydantic schemas for chat API endpoints,
providing validation and serialization for chat functionality.
"""
from datetime import datetime
from typing import Optional, List, Dict, Any
from uuid import UUID

from pydantic import BaseModel, Field, validator
from enum import Enum


class MessageRole(str, Enum):
    """Message role enumeration."""
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class LLMProvider(str, Enum):
    """LLM provider enumeration."""
    LOCAL = "LOCAL"
    OPENROUTER = "OPENROUTER"


class ChatSessionCreateRequest(BaseModel):
    """Request model for creating a new chat session."""
    title: Optional[str] = Field(None, max_length=500, description="Optional session title")
    llm_provider: LLMProvider = Field(..., description="LLM provider to use")
    llm_model: str = Field(..., min_length=1, max_length=100, description="LLM model name")
    settings: Optional[Dict[str, Any]] = Field(default=None, description="Optional session settings")
    
    @validator('llm_model')
    def validate_model_name(cls, v):
        """Validate model name format."""
        if not v.strip():
            raise ValueError("Model name cannot be empty")
        return v.strip()


class ChatSessionResponse(BaseModel):
    """Response model for chat session data."""
    id: str
    title: Optional[str]
    user_id: str
    llm_provider: str
    llm_model: str
    created_at: datetime
    updated_at: datetime
    is_active: bool
    message_count: int
    settings: Optional[Dict[str, Any]] = None
    
    class Config:
        from_attributes = True


class ChatMessageCreateRequest(BaseModel):
    """Request model for creating a new chat message."""
    content: str = Field(..., min_length=1, max_length=10000, description="Message content")
    role: MessageRole = Field(default=MessageRole.USER, description="Message role")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Optional message metadata")
    
    @validator('content')
    def validate_content(cls, v):
        """Validate message content."""
        if not v.strip():
            raise ValueError("Message content cannot be empty")
        return v.strip()


class ChatMessageResponse(BaseModel):
    """Response model for chat message data."""
    id: str
    session_id: str
    role: str
    content: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    is_streaming: bool
    llm_provider: Optional[str] = None
    llm_model: Optional[str] = None
    response_time_ms: Optional[int] = None
    tokens_used: int = 0
    error_message: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    
    class Config:
        from_attributes = True


class ChatMessagesListResponse(BaseModel):
    """Response model for paginated message list."""
    messages: List[ChatMessageResponse]
    total_count: int
    page: int
    page_size: int
    has_more: bool
    session_id: str


class ChatSessionsListResponse(BaseModel):
    """Response model for paginated session list."""
    sessions: List[ChatSessionResponse]
    total_count: int
    page: int
    page_size: int
    has_more: bool


class ChatMessageUpdateRequest(BaseModel):
    """Request model for updating a chat message (e.g., streaming response)."""
    content: Optional[str] = Field(None, min_length=1, max_length=10000, description="Updated message content")
    is_streaming: Optional[bool] = Field(None, description="Streaming status")
    tokens_used: Optional[int] = Field(None, ge=0, description="Token count")
    response_time_ms: Optional[int] = Field(None, ge=0, description="Response time in milliseconds")
    error_message: Optional[str] = Field(None, description="Error message if any")
    
    @validator('content')
    def validate_content(cls, v):
        """Validate message content if provided."""
        if v is not None and not v.strip():
            raise ValueError("Message content cannot be empty")
        return v


class WebSocketMessageType(str, Enum):
    """WebSocket message type enumeration."""
    CONNECTION_ESTABLISHED = "connection_established"
    USER_JOINED = "user_joined"
    USER_LEFT = "user_left"
    MESSAGE_UPDATE = "message_update"
    TYPING_INDICATOR = "typing_indicator"
    ERROR = "error"
    PING = "ping"
    PONG = "pong"
    MESSAGE_ACK = "message_ack"


class WebSocketMessage(BaseModel):
    """WebSocket message model for real-time communication."""
    type: WebSocketMessageType
    session_id: Optional[str] = None
    user_id: Optional[str] = None
    data: Optional[Dict[str, Any]] = None
    timestamp: Optional[datetime] = None
    message_id: Optional[str] = None
    
    class Config:
        use_enum_values = True


class TypingIndicatorMessage(BaseModel):
    """WebSocket message for typing indicators."""
    type: WebSocketMessageType = WebSocketMessageType.TYPING_INDICATOR
    user_id: str
    is_typing: bool
    session_id: Optional[str] = None


class ErrorResponse(BaseModel):
    """Standard error response model."""
    error: str
    error_code: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ChatSessionUpdateRequest(BaseModel):
    """Request model for updating a chat session."""
    title: Optional[str] = Field(None, max_length=500, description="Updated session title")
    is_active: Optional[bool] = Field(None, description="Session active status")
    settings: Optional[Dict[str, Any]] = Field(None, description="Updated session settings")
    
    @validator('title')
    def validate_title(cls, v):
        """Validate title if provided."""
        if v is not None and not v.strip():
            raise ValueError("Title cannot be empty")
        return v


class ProcessLLMRequest(BaseModel):
    """Request model for processing LLM response."""
    message_id: str = Field(..., description="ID of the message to process")
    session_id: str = Field(..., description="Session ID")
    prompt: str = Field(..., min_length=1, max_length=10000, description="Prompt to send to LLM")
    model_name: Optional[str] = Field(None, description="Override model name")
    provider: Optional[LLMProvider] = Field(None, description="Override provider")
    stream: bool = Field(default=False, description="Whether to stream response")
    max_tokens: Optional[int] = Field(None, ge=1, le=8192, description="Maximum tokens to generate")
    temperature: Optional[float] = Field(None, ge=0.0, le=2.0, description="Response creativity")
    
    @validator('prompt')
    def validate_prompt(cls, v):
        """Validate prompt content."""
        if not v.strip():
            raise ValueError("Prompt cannot be empty")
        return v.strip()


class ProcessLLMResponse(BaseModel):
    """Response model for LLM processing."""
    message_id: str
    session_id: str
    response: str
    tokens_used: int
    response_time_ms: float
    provider: str
    model: str
    success: bool
    error_message: Optional[str] = None


class ChatStatsResponse(BaseModel):
    """Response model for chat statistics."""
    total_sessions: int
    total_messages: int
    active_sessions: int
    messages_today: int
    average_response_time_ms: float
    most_used_provider: str
    most_used_model: str


class ConnectionStatus(BaseModel):
    """WebSocket connection status."""
    session_id: str
    user_id: str
    connected: bool
    connection_count: int
    user_count: int
    last_activity: Optional[datetime] = None


# Request models for pagination
class PaginationQuery(BaseModel):
    """Base pagination query parameters."""
    page: int = Field(default=1, ge=1, description="Page number")
    page_size: int = Field(default=50, ge=1, le=200, description="Items per page")


class MessagesPaginationQuery(PaginationQuery):
    """Pagination query for messages with optional timestamp filter."""
    before: Optional[datetime] = Field(None, description="Get messages before this timestamp")


class SessionsPaginationQuery(PaginationQuery):
    """Pagination query for sessions with optional filters."""
    user_id: Optional[str] = Field(None, description="Filter by user ID")
    is_active: Optional[bool] = Field(None, description="Filter by active status")
    llm_provider: Optional[LLMProvider] = Field(None, description="Filter by LLM provider")


# Utility functions for response formatting
def format_chat_message(message) -> ChatMessageResponse:
    """Format SQLAlchemy model to ChatMessageResponse."""
    return ChatMessageResponse(
        id=str(message.id),
        session_id=str(message.session_id),
        role=message.role,
        content=message.content,
        created_at=message.created_at,
        updated_at=message.updated_at,
        is_streaming=message.is_streaming,
        llm_provider=message.llm_provider,
        llm_model=message.llm_model,
        response_time_ms=message.response_time_ms,
        tokens_used=message.tokens_used,
        error_message=message.error_message,
        metadata=message.metadata or {}
    )


def format_chat_session(session) -> ChatSessionResponse:
    """Format SQLAlchemy model to ChatSessionResponse."""
    return ChatSessionResponse(
        id=str(session.id),
        title=session.title,
        user_id=session.user_id,
        llm_provider=session.llm_provider,
        llm_model=session.llm_model,
        created_at=session.created_at,
        updated_at=session.updated_at,
        is_active=session.is_active,
        message_count=len(session.messages),
        settings=session.settings or {}
    )


def create_paginated_response(
    items: list, 
    total_count: int, 
    page: int, 
    page_size: int,
    formatter_func=None
) -> Dict[str, Any]:
    """Create a standardized paginated response."""
    formatted_items = [formatter_func(item) if formatter_func else item for item in items]
    
    return {
        "items": formatted_items,
        "total_count": total_count,
        "page": page,
        "page_size": page_size,
        "has_more": (page * page_size) < total_count
    }