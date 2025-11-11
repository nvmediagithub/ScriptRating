#!/usr/bin/env python3
"""
Test script for chat backend functionality.
"""
import os
import sys
import asyncio
import json
import time
from datetime import datetime
from typing import Dict, Any, Optional

# Add the app directory to the path
sys.path.insert(0, '.')

async def test_chat_server():
    """Test the chat server functionality."""
    print("=== Chat Backend Testing Script ===\n")
    
    # Test 1: Import chat models
    print("1. Testing Chat Models Import...")
    try:
        from app.models.chat_models import ChatSession, ChatMessage, Base
        print("✅ Chat models imported successfully")
    except Exception as e:
        print(f"❌ Failed to import chat models: {e}")
        return False
    
    # Test 2: Import chat schemas
    print("\n2. Testing Chat Schemas Import...")
    try:
        from app.presentation.api.schemas.chat_schemas import (
            ChatSessionCreateRequest, ChatMessageCreateRequest, 
            ProcessLLMRequest, LLMProvider
        )
        print("✅ Chat schemas imported successfully")
    except Exception as e:
        print(f"❌ Failed to import chat schemas: {e}")
        return False
    
    # Test 3: Import WebSocket manager
    print("\n3. Testing WebSocket Manager Import...")
    try:
        from app.infrastructure.websocket.manager import connection_manager
        print("✅ WebSocket manager imported successfully")
    except Exception as e:
        print(f"❌ Failed to import WebSocket manager: {e}")
        return False
    
    # Test 4: Test database initialization
    print("\n4. Testing Database Initialization...")
    try:
        from app.infrastructure.database.session import initialize_database
        engine = initialize_database()
        print(f"✅ Database initialized with engine: {engine}")
    except Exception as e:
        print(f"❌ Failed to initialize database: {e}")
        return False
    
    # Test 5: Test basic WebSocket connection manager
    print("\n5. Testing WebSocket Connection Manager...")
    try:
        manager = connection_manager
        # Test connection count
        count = manager.get_connection_count("test_session")
        print(f"✅ Connection manager working, test session count: {count}")
    except Exception as e:
        print(f"❌ Failed to test connection manager: {e}")
        return False
    
    # Test 6: Test model creation
    print("\n6. Testing Model Creation...")
    try:
        from app.models.chat_models import create_chat_session, create_chat_message
        from app.infrastructure.database.session import get_db_session
        
        with get_db_session() as db:
            # Create a test session
            session = create_chat_session(
                db=db,
                user_id="test_user",
                title="Test Chat Session",
                llm_provider="LOCAL",
                llm_model="test_model"
            )
            print(f"✅ Created test session: {session.id}")
            
            # Create a test message
            message = create_chat_message(
                db=db,
                session_id=session.id,
                role="user",
                content="Hello, this is a test message!"
            )
            print(f"✅ Created test message: {message.id}")
            
            # Test retrieval
            retrieved_session = db.query(ChatSession).filter(ChatSession.id == session.id).first()
            print(f"✅ Retrieved session: {retrieved_session.title}")
            
    except Exception as e:
        print(f"❌ Failed to test model creation: {e}")
        return False
    
    print("\n🎉 All basic tests passed!")
    print("\n" + "="*50)
    print("CHAT BACKEND MODULES VERIFICATION COMPLETE")
    print("="*50)
    print("\nModules successfully tested:")
    print("✅ Database models (ChatSession, ChatMessage)")
    print("✅ Pydantic schemas for API validation")
    print("✅ WebSocket connection manager")
    print("✅ Database initialization and session management")
    print("✅ CRUD operations for sessions and messages")
    print("\nThe chat backend infrastructure is ready for testing!")
    
    return True

if __name__ == "__main__":
    success = asyncio.run(test_chat_server())
    sys.exit(0 if success else 1)