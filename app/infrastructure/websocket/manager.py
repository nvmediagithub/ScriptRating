"""
WebSocket connection manager for real-time chat functionality.

This module handles WebSocket connections, message broadcasting,
and real-time communication for chat sessions.
"""
import json
import logging
from datetime import datetime
from typing import Dict, Set, Optional, Any
from uuid import UUID

from fastapi import WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from app.models.chat_models import ChatSession, ChatMessage
from app.config import settings

logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages WebSocket connections for chat sessions.
    
    Maintains active connections and handles message broadcasting
    to all connected clients for a given chat session.
    """
    
    def __init__(self):
        # session_id -> Set[WebSocket]
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # WebSocket -> session_id mapping
        self.connection_sessions: Dict[WebSocket, str] = {}
        # session_id -> user_id -> WebSocket
        self.session_users: Dict[str, Dict[str, WebSocket]] = {}
    
    async def connect(
        self, 
        websocket: WebSocket, 
        session_id: str, 
        user_id: str
    ) -> bool:
        """
        Accept a WebSocket connection and add to the session.
        
        Args:
            websocket: WebSocket connection
            session_id: Chat session ID
            user_id: User identifier
        
        Returns:
            True if connection was accepted, False otherwise
        """
        try:
            await websocket.accept()
            
            # Add to active connections
            if session_id not in self.active_connections:
                self.active_connections[session_id] = set()
            self.active_connections[session_id].add(websocket)
            
            # Track connection session mapping
            self.connection_sessions[websocket] = session_id
            
            # Track user in session
            if session_id not in self.session_users:
                self.session_users[session_id] = {}
            self.session_users[session_id][user_id] = websocket
            
            logger.info(f"WebSocket connected: session={session_id}, user={user_id}")
            
            # Send connection acknowledgment
            await self.send_personal_message(
                {
                    "type": "connection_established",
                    "session_id": session_id,
                    "user_id": user_id,
                    "timestamp": datetime.utcnow().isoformat()
                },
                websocket
            )
            
            # Notify other users in session
            await self.broadcast_to_session(
                session_id,
                {
                    "type": "user_joined",
                    "user_id": user_id,
                    "timestamp": datetime.utcnow().isoformat()
                },
                exclude_user=user_id
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to establish WebSocket connection: {e}")
            return False
    
    def disconnect(self, websocket: WebSocket) -> Optional[str]:
        """
        Remove a WebSocket connection and return the session ID.
        
        Args:
            websocket: WebSocket connection to remove
        
        Returns:
            Session ID if connection existed, None otherwise
        """
        session_id = self.connection_sessions.get(websocket)
        if not session_id:
            return None
        
        try:
            # Remove from active connections
            if session_id in self.active_connections:
                self.active_connections[session_id].discard(websocket)
                if not self.active_connections[session_id]:
                    del self.active_connections[session_id]
            
            # Remove from session users (find which user)
            user_id = None
            if session_id in self.session_users:
                for uid, ws in self.session_users[session_id].items():
                    if ws == websocket:
                        user_id = uid
                        break
                if user_id:
                    del self.session_users[session_id][user_id]
                    if not self.session_users[session_id]:
                        del self.session_users[session_id]
            
            # Remove from connection mapping
            del self.connection_sessions[websocket]
            
            logger.info(f"WebSocket disconnected: session={session_id}, user={user_id}")
            
            # Notify other users in session
            if user_id:
                import asyncio
                asyncio.create_task(
                    self.broadcast_to_session(
                        session_id,
                        {
                            "type": "user_left",
                            "user_id": user_id,
                            "timestamp": datetime.utcnow().isoformat()
                        }
                    )
                )
            
            return session_id
            
        except Exception as e:
            logger.error(f"Error during WebSocket disconnection: {e}")
            return None
    
    async def send_personal_message(
        self, 
        message: Dict[str, Any], 
        websocket: WebSocket
    ) -> bool:
        """
        Send a message to a specific WebSocket connection.
        
        Args:
            message: Message to send
            websocket: Target WebSocket connection
        
        Returns:
            True if sent successfully, False otherwise
        """
        try:
            await websocket.send_text(json.dumps(message, default=str))
            return True
        except Exception as e:
            logger.error(f"Failed to send personal message: {e}")
            return False
    
    async def broadcast_to_session(
        self, 
        session_id: str, 
        message: Dict[str, Any],
        exclude_user: Optional[str] = None
    ) -> int:
        """
        Broadcast a message to all WebSocket connections in a session.
        
        Args:
            session_id: Chat session ID
            message: Message to broadcast
            exclude_user: Optional user ID to exclude from broadcast
        
        Returns:
            Number of connections that received the message
        """
        sent_count = 0
        if session_id not in self.active_connections:
            return 0
        
        # Add session info to message
        message["session_id"] = session_id
        message["broadcast_timestamp"] = datetime.utcnow().isoformat()
        
        # Get all connections for this session
        connections = self.active_connections[session_id].copy()
        
        # Filter out excluded user if specified
        if exclude_user and session_id in self.session_users:
            if exclude_user in self.session_users[session_id]:
                exclude_ws = self.session_users[session_id][exclude_user]
                connections.discard(exclude_ws)
        
        # Send to all remaining connections
        disconnected = []
        for websocket in connections:
            try:
                if await self.send_personal_message(message, websocket):
                    sent_count += 1
                else:
                    disconnected.append(websocket)
            except Exception as e:
                logger.error(f"Error broadcasting to websocket: {e}")
                disconnected.append(websocket)
        
        # Clean up disconnected websockets
        for ws in disconnected:
            self.disconnect(ws)
        
        return sent_count
    
    async def broadcast_message_update(
        self,
        session_id: str,
        message: ChatMessage
    ) -> int:
        """
        Broadcast a message update (new message, typing, etc.) to session.
        
        Args:
            session_id: Chat session ID
            message: ChatMessage instance
        
        Returns:
            Number of connections that received the update
        """
        message_data = {
            "type": "message_update",
            "message": message.to_dict(),
            "action": "new_message" if message.created_at == message.updated_at else "message_updated"
        }
        
        return await self.broadcast_to_session(session_id, message_data)
    
    async def broadcast_typing_indicator(
        self,
        session_id: str,
        user_id: str,
        is_typing: bool
    ) -> int:
        """
        Broadcast typing indicator to session.
        
        Args:
            session_id: Chat session ID
            user_id: User typing
            is_typing: Whether user is typing
        
        Returns:
            Number of connections that received the indicator
        """
        message_data = {
            "type": "typing_indicator",
            "user_id": user_id,
            "is_typing": is_typing
        }
        
        return await self.broadcast_to_session(session_id, message_data, exclude_user=user_id)
    
    async def broadcast_error(
        self,
        session_id: str,
        user_id: str,
        error_message: str,
        error_code: Optional[str] = None
    ) -> bool:
        """
        Broadcast error message to a specific user.
        
        Args:
            session_id: Chat session ID
            user_id: Target user ID
            error_message: Error description
            error_code: Optional error code
        
        Returns:
            True if error was sent successfully
        """
        if session_id not in self.session_users or user_id not in self.session_users[session_id]:
            return False
        
        websocket = self.session_users[session_id][user_id]
        error_data = {
            "type": "error",
            "error_message": error_message,
            "error_code": error_code or "UNKNOWN_ERROR",
            "timestamp": datetime.utcnow().isoformat()
        }
        
        return await self.send_personal_message(error_data, websocket)
    
    def get_connection_count(self, session_id: str) -> int:
        """
        Get the number of active connections for a session.
        
        Args:
            session_id: Chat session ID
        
        Returns:
            Number of active connections
        """
        return len(self.active_connections.get(session_id, set()))
    
    def get_user_count(self, session_id: str) -> int:
        """
        Get the number of unique users connected to a session.
        
        Args:
            session_id: Chat session ID
        
        Returns:
            Number of unique users
        """
        return len(self.session_users.get(session_id, {}))
    
    def is_user_connected(self, session_id: str, user_id: str) -> bool:
        """
        Check if a user is connected to a session.
        
        Args:
            session_id: Chat session ID
            user_id: User identifier
        
        Returns:
            True if user is connected
        """
        return (
            session_id in self.session_users and 
            user_id in self.session_users[session_id]
        )
    
    async def cleanup_session(self, session_id: str) -> None:
        """
        Clean up all connections for a session (e.g., when session is deleted).
        
        Args:
            session_id: Chat session ID to clean up
        """
        if session_id in self.active_connections:
            # Close all connections
            for websocket in self.active_connections[session_id].copy():
                try:
                    await websocket.close()
                except Exception:
                    pass  # Connection might already be closed
                self.disconnect(websocket)
        
        logger.info(f"Cleaned up session connections: {session_id}")


# Global connection manager instance
connection_manager = ConnectionManager()


class WebSocketMessageHandler:
    """
    Handles incoming WebSocket messages and routes them appropriately.
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.manager = connection_manager
    
    async def handle_message(
        self, 
        websocket: WebSocket, 
        data: Dict[str, Any],
        session_id: str,
        user_id: str
    ) -> bool:
        """
        Handle an incoming WebSocket message.
        
        Args:
            websocket: WebSocket connection
            data: Message data
            session_id: Chat session ID
            user_id: User identifier
        
        Returns:
            True if message was handled successfully
        """
        message_type = data.get("type")
        
        try:
            if message_type == "ping":
                return await self._handle_ping(websocket)
            elif message_type == "typing_start":
                return await self._handle_typing_start(session_id, user_id)
            elif message_type == "typing_stop":
                return await self._handle_typing_stop(session_id, user_id)
            elif message_type == "send_message":
                return await self._handle_send_message(data, session_id, user_id)
            else:
                logger.warning(f"Unknown WebSocket message type: {message_type}")
                return False
                
        except Exception as e:
            logger.error(f"Error handling WebSocket message: {e}")
            await self.manager.broadcast_error(session_id, user_id, str(e))
            return False
    
    async def _handle_ping(self, websocket: WebSocket) -> bool:
        """Handle ping message."""
        return await self.manager.send_personal_message(
            {"type": "pong", "timestamp": datetime.utcnow().isoformat()},
            websocket
        )
    
    async def _handle_typing_start(self, session_id: str, user_id: str) -> bool:
        """Handle typing start indicator."""
        await self.manager.broadcast_typing_indicator(session_id, user_id, True)
        return True
    
    async def _handle_typing_stop(self, session_id: str, user_id: str) -> bool:
        """Handle typing stop indicator."""
        await self.manager.broadcast_typing_indicator(session_id, user_id, False)
        return True
    
    async def _handle_send_message(
        self, 
        data: Dict[str, Any], 
        session_id: str, 
        user_id: str
    ) -> bool:
        """
        Handle send message request.
        
        This would typically be processed by the chat API endpoints,
        but can also be handled via WebSocket for real-time sending.
        """
        # For now, just acknowledge the message
        # The actual message processing should be done via REST API
        await self.manager.send_personal_message(
            {
                "type": "message_ack",
                "request_id": data.get("request_id"),
                "message": "Message queued for processing",
                "timestamp": datetime.utcnow().isoformat()
            },
            self.manager.session_users[session_id][user_id]
        )
        return True