"""
Chat database models for SQLAlchemy.

This module contains SQLAlchemy models for chat sessions and messages
to support the real-time chat functionality.
"""
import uuid
from datetime import datetime
from typing import Optional, Dict, Any, List

from sqlalchemy import (
    Column, String, DateTime, Text, Boolean, Integer, 
    ForeignKey, JSON, CheckConstraint, Index
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, Session
from sqlalchemy.sql import func

from app.config import settings

# Use PostgreSQL UUID if available, otherwise use String for SQLite compatibility
if "postgresql" in settings.database_url:
    from sqlalchemy.dialects.postgresql import UUID as PG_UUID
    UUIDType = PG_UUID(as_uuid=True)
else:
    # SQLite compatibility
    UUIDType = String(36)


Base = declarative_base()


class ChatSession(Base):
    """
    Chat session model representing a conversation between user and LLM.
    """
    __tablename__ = "chat_sessions"

    # Primary key
    id = Column(
        UUIDType,
        primary_key=True,
        default=str(uuid.uuid4)
    )
    
    # Basic session information
    user_id = Column(String(255), nullable=False, index=True)
    title = Column(String(500), nullable=True)
    
    # LLM configuration for this session
    llm_provider = Column(String(50), nullable=False, index=True)
    llm_model = Column(String(100), nullable=False, index=True)
    
    # Session metadata
    settings = Column(JSON, nullable=True, default=dict)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Timestamps
    created_at = Column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        nullable=False
    )
    updated_at = Column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        onupdate=func.now(),
        nullable=False
    )
    
    # Relationships
    messages = relationship("ChatMessage", back_populates="session", cascade="all, delete-orphan")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("llm_provider IN ('LOCAL', 'OPENROUTER')", name="check_valid_llm_provider"),
        CheckConstraint("is_active IN (0, 1)", name="check_valid_is_active"),
        Index("idx_chat_sessions_user_active", "user_id", "is_active"),
        Index("idx_chat_sessions_created", "created_at"),
    )
    
    def __repr__(self) -> str:
        return f"<ChatSession(id='{self.id}', title='{self.title}', provider='{self.llm_provider}')>"
    
    @property
    def message_count(self) -> int:
        """Get the number of messages in this session."""
        return len(self.messages)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert session to dictionary for API responses."""
        return {
            "id": str(self.id),
            "title": self.title,
            "user_id": self.user_id,
            "llm_provider": self.llm_provider,
            "llm_model": self.llm_model,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "is_active": self.is_active,
            "message_count": self.message_count,
            "settings": self.settings or {},
        }


class ChatMessage(Base):
    """
    Chat message model representing a single message in a conversation.
    """
    __tablename__ = "chat_messages"

    # Primary key
    id = Column(
        UUIDType,
        primary_key=True,
        default=str(uuid.uuid4)
    )
    
    # Foreign key to session
    session_id = Column(
        UUIDType, 
        ForeignKey("chat_sessions.id", ondelete="CASCADE"), 
        nullable=False, 
        index=True
    )
    
    # Message content and metadata
    role = Column(String(20), nullable=False, index=True)
    content = Column(Text, nullable=False)
    
    # LLM processing metrics
    llm_provider = Column(String(50), nullable=True, index=True)
    llm_model = Column(String(100), nullable=True, index=True)
    response_time_ms = Column(Integer, nullable=True)
    tokens_used = Column(Integer, default=0, nullable=False)
    error_message = Column(Text, nullable=True)
    
    # Real-time processing state
    is_streaming = Column(Boolean, default=False, nullable=False)
    
    # Message metadata
    message_metadata = Column(JSON, nullable=True, default=dict)
    
    # Timestamps
    created_at = Column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        nullable=False
    )
    updated_at = Column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        onupdate=func.now(),
        nullable=True
    )
    
    # Relationships
    session = relationship("ChatSession", back_populates="messages")
    
    # Constraints and indexes
    __table_args__ = (
        CheckConstraint("role IN ('user', 'assistant', 'system')", name="check_valid_message_role"),
        CheckConstraint("is_streaming IN (0, 1)", name="check_valid_is_streaming"),
        CheckConstraint("tokens_used >= 0", name="check_positive_tokens"),
        Index("idx_chat_messages_session_created", "session_id", "created_at"),
        Index("idx_chat_messages_role", "role"),
        Index("idx_chat_messages_created", "created_at"),
    )
    
    def __repr__(self) -> str:
        return f"<ChatMessage(id='{self.id}', role='{self.role}', session_id='{self.session_id}')>"
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert message to dictionary for API responses."""
        return {
            "id": str(self.id),
            "session_id": str(self.session_id),
            "role": self.role,
            "content": self.content,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "is_streaming": self.is_streaming,
            "llm_provider": self.llm_provider,
            "llm_model": self.llm_model,
            "response_time_ms": self.response_time_ms,
            "tokens_used": self.tokens_used,
            "error_message": self.error_message,
            "metadata": self.message_metadata or {},
        }


# Database utility functions
def create_chat_session(
    db: Session,
    user_id: str,
    title: Optional[str] = None,
    llm_provider: str = "LOCAL",
    llm_model: str = "llama2:7b",
    settings: Optional[Dict[str, Any]] = None
) -> ChatSession:
    """
    Create a new chat session.
    
    Args:
        db: Database session
        user_id: User identifier
        title: Optional session title
        llm_provider: LLM provider ("LOCAL" or "OPENROUTER")
        llm_model: Model name
        settings: Optional session settings
    
    Returns:
        Created ChatSession instance
    """
    session = ChatSession(
        user_id=user_id,
        title=title or f"Chat with {llm_model}",
        llm_provider=llm_provider,
        llm_model=llm_model,
        settings=settings or {},
    )
    
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def create_chat_message(
    db: Session,
    session_id: str,
    role: str,
    content: str,
    llm_provider: Optional[str] = None,
    llm_model: Optional[str] = None,
    response_time_ms: Optional[int] = None,
    tokens_used: int = 0,
    error_message: Optional[str] = None,
    message_metadata: Optional[Dict[str, Any]] = None
) -> ChatMessage:
    """
    Create a new chat message.
    
    Args:
        db: Database session
        session_id: Chat session ID
        role: Message role ("user", "assistant", "system")
        content: Message content
        llm_provider: Optional LLM provider
        llm_model: Optional model name
        response_time_ms: Optional response time in milliseconds
        tokens_used: Number of tokens used
        error_message: Optional error message
        message_metadata: Optional message metadata
    
    Returns:
        Created ChatMessage instance
    """
    message = ChatMessage(
        session_id=session_id,
        role=role,
        content=content,
        llm_provider=llm_provider,
        llm_model=llm_model,
        response_time_ms=response_time_ms,
        tokens_used=tokens_used,
        error_message=error_message,
        message_metadata=message_metadata or {},
    )
    
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


def get_chat_sessions(
    db: Session,
    user_id: str,
    limit: int = 50,
    offset: int = 0
) -> List[ChatSession]:
    """
    Get chat sessions for a user with pagination.
    
    Args:
        db: Database session
        user_id: User identifier
        limit: Maximum number of sessions to return
        offset: Number of sessions to skip
    
    Returns:
        List of ChatSession instances
    """
    return (
        db.query(ChatSession)
        .filter(ChatSession.user_id == user_id)
        .order_by(ChatSession.updated_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )


def get_chat_messages(
    db: Session,
    session_id: str,
    limit: int = 50,
    offset: int = 0,
    before: Optional[datetime] = None
) -> List[ChatMessage]:
    """
    Get messages for a chat session with pagination.
    
    Args:
        db: Database session
        session_id: Chat session ID
        limit: Maximum number of messages to return
        offset: Number of messages to skip
        before: Optional timestamp to get messages before
    
    Returns:
        List of ChatMessage instances
    """
    query = db.query(ChatMessage).filter(ChatMessage.session_id == session_id)
    
    if before:
        query = query.filter(ChatMessage.created_at < before)
    
    return (
        query.order_by(ChatMessage.created_at.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )


def get_chat_session(db: Session, session_id: str, user_id: str) -> Optional[ChatSession]:
    """
    Get a specific chat session with ownership validation.
    
    Args:
        db: Database session
        session_id: Chat session ID
        user_id: User identifier for ownership check
    
    Returns:
        ChatSession instance or None if not found
    """
    return (
        db.query(ChatSession)
        .filter(ChatSession.id == session_id, ChatSession.user_id == user_id)
        .first()
    )


def delete_chat_session(db: Session, session_id: str, user_id: str) -> bool:
    """
    Delete a chat session with ownership validation.
    
    Args:
        db: Database session
        session_id: Chat session ID
        user_id: User identifier for ownership check
    
    Returns:
        True if session was deleted, False otherwise
    """
    session = get_chat_session(db, session_id, user_id)
    if session:
        db.delete(session)
        db.commit()
        return True
    return False


def update_message_streaming_status(
    db: Session,
    message_id: str,
    is_streaming: bool
) -> Optional[ChatMessage]:
    """
    Update the streaming status of a message.
    
    Args:
        db: Database session
        message_id: Message ID
        is_streaming: Streaming status
    
    Returns:
        Updated ChatMessage instance or None if not found
    """
    message = db.query(ChatMessage).filter(ChatMessage.id == message_id).first()
    if message:
        message.is_streaming = is_streaming
        message.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(message)
    return message


def update_message_content(
    db: Session,
    message_id: str,
    content: str,
    tokens_used: Optional[int] = None,
    response_time_ms: Optional[int] = None,
    error_message: Optional[str] = None
) -> Optional[ChatMessage]:
    """
    Update message content and metrics.
    
    Args:
        db: Database session
        message_id: Message ID
        content: New message content
        tokens_used: Optional updated token count
        response_time_ms: Optional response time
        error_message: Optional error message
    
    Returns:
        Updated ChatMessage instance or None if not found
    """
    message = db.query(ChatMessage).filter(ChatMessage.id == message_id).first()
    if message:
        message.content = content
        if tokens_used is not None:
            message.tokens_used = tokens_used
        if response_time_ms is not None:
            message.response_time_ms = response_time_ms
        if error_message is not None:
            message.error_message = error_message
        message.is_streaming = False
        message.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(message)
    return message