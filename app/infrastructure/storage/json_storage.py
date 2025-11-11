#!/usr/bin/env python3
"""
Simple JSON-based storage system for chat data.

This module provides a simple file-based JSON storage system to replace
the complex SQLAlchemy database implementation.
"""
import json
import os
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import logging

logger = logging.getLogger(__name__)


class JSONStorage:
    """Simple JSON file-based storage for chat data."""
    
    def __init__(self, storage_dir: str = "storage/chats"):
        """Initialize JSON storage with a directory path."""
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self._ensure_index_file()
    
    def _ensure_index_file(self):
        """Ensure the chat index file exists."""
        index_file = self.storage_dir / "chats_index.json"
        if not index_file.exists():
            self._save_json(index_file, {"chats": []})
    
    def _load_json(self, file_path: Path) -> Dict:
        """Load JSON data from file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError) as e:
            logger.error(f"Error loading {file_path}: {e}")
            return {}
    
    def _save_json(self, file_path: Path, data: Dict) -> bool:
        """Save data to JSON file."""
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            logger.error(f"Error saving {file_path}: {e}")
            return False
    
    def _get_chat_file(self, chat_id: str) -> Path:
        """Get the file path for a specific chat."""
        return self.storage_dir / f"chat_{chat_id}.json"
    
    def _load_index(self) -> Dict:
        """Load the chat index."""
        return self._load_json(self.storage_dir / "chats_index.json")
    
    def _save_index(self, index_data: Dict) -> bool:
        """Save the chat index."""
        return self._save_json(self.storage_dir / "chats_index.json", index_data)
    
    # Chat Session Methods
    def create_chat_session(self, title: str, llm_provider: str = "local", 
                           llm_model: str = "llama2:7b", settings: Dict = None) -> Dict:
        """Create a new chat session."""
        chat_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        
        chat_data = {
            "id": chat_id,
            "title": title,
            "llm_provider": llm_provider,
            "llm_model": llm_model,
            "created_at": now,
            "updated_at": now,
            "is_active": True,
            "settings": settings or {},
            "messages": []
        }
        
        # Save chat file
        if self._save_json(self._get_chat_file(chat_id), chat_data):
            # Update index
            index_data = self._load_index()
            index_data["chats"].append({
                "id": chat_id,
                "title": title,
                "created_at": now,
                "updated_at": now,
                "is_active": True
            })
            self._save_index(index_data)
            return chat_data
        
        return None
    
    def get_chat_session(self, chat_id: str) -> Optional[Dict]:
        """Get a specific chat session by ID."""
        chat_file = self._get_chat_file(chat_id)
        return self._load_json(chat_file) or None
    
    def get_all_chat_sessions(self, page: int = 1, page_size: int = 50) -> Dict:
        """Get all chat sessions with pagination."""
        index_data = self._load_index()
        chats = index_data.get("chats", [])
        
        # Sort by updated_at descending
        chats.sort(key=lambda x: x.get("updated_at", ""), reverse=True)
        
        # Paginate
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        paginated_chats = chats[start_idx:end_idx]
        
        return {
            "chats": paginated_chats,
            "total_count": len(chats),
            "page": page,
            "page_size": page_size,
            "has_more": end_idx < len(chats)
        }
    
    def update_chat_session(self, chat_id: str, updates: Dict) -> Optional[Dict]:
        """Update a chat session."""
        chat_data = self.get_chat_session(chat_id)
        if not chat_data:
            return None
        
        # Update fields
        for key, value in updates.items():
            if key != "id":  # Don't allow changing ID
                chat_data[key] = value
        
        chat_data["updated_at"] = datetime.utcnow().isoformat()
        
        # Save chat file
        if self._save_json(self._get_chat_file(chat_id), chat_data):
            # Update index
            index_data = self._load_index()
            for i, chat in enumerate(index_data["chats"]):
                if chat["id"] == chat_id:
                    index_data["chats"][i].update({
                        "title": chat_data.get("title", chat.get("title")),
                        "updated_at": chat_data["updated_at"],
                        "is_active": chat_data.get("is_active", True)
                    })
                    break
            self._save_index(index_data)
            return chat_data
        
        return None
    
    def delete_chat_session(self, chat_id: str) -> bool:
        """Delete a chat session."""
        chat_file = self._get_chat_file(chat_id)
        
        try:
            # Delete chat file
            if chat_file.exists():
                chat_file.unlink()
            
            # Update index
            index_data = self._load_index()
            index_data["chats"] = [chat for chat in index_data.get("chats", []) 
                                 if chat["id"] != chat_id]
            self._save_index(index_data)
            
            return True
        except Exception as e:
            logger.error(f"Error deleting chat {chat_id}: {e}")
            return False
    
    # Chat Message Methods
    def add_message(self, chat_id: str, role: str, content: str, 
                   metadata: Dict = None) -> Optional[Dict]:
        """Add a message to a chat session."""
        chat_data = self.get_chat_session(chat_id)
        if not chat_data:
            return None
        
        message_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        
        message = {
            "id": message_id,
            "role": role,
            "content": content,
            "created_at": now,
            "updated_at": now,
            "is_streaming": False,
            "tokens_used": 0,
            "response_time_ms": 0,
            "error_message": None,
            "metadata": metadata or {}
        }
        
        chat_data["messages"].append(message)
        chat_data["updated_at"] = now
        
        # Save chat file
        if self._save_json(self._get_chat_file(chat_id), chat_data):
            return message
        
        return None
    
    def get_messages(self, chat_id: str, limit: int = 50, offset: int = 0) -> List[Dict]:
        """Get messages for a chat session with pagination."""
        chat_data = self.get_chat_session(chat_id)
        if not chat_data:
            return []
        
        messages = chat_data.get("messages", [])
        
        # Sort by created_at
        messages.sort(key=lambda x: x.get("created_at", ""))
        
        # Paginate
        return messages[offset:offset + limit]
    
    def update_message(self, chat_id: str, message_id: str, updates: Dict) -> Optional[Dict]:
        """Update a message in a chat session."""
        chat_data = self.get_chat_session(chat_id)
        if not chat_data:
            return None
        
        for message in chat_data["messages"]:
            if message["id"] == message_id:
                # Update fields
                for key, value in updates.items():
                    if key != "id":  # Don't allow changing ID
                        message[key] = value
                message["updated_at"] = datetime.utcnow().isoformat()
                
                # Save chat file
                if self._save_json(self._get_chat_file(chat_id), chat_data):
                    return message
                break
        
        return None
    
    def get_message(self, chat_id: str, message_id: str) -> Optional[Dict]:
        """Get a specific message by ID."""
        messages = self.get_messages(chat_id, limit=1000, offset=0)
        for message in messages:
            if message["id"] == message_id:
                return message
        return None


# Global storage instance
storage = JSONStorage()