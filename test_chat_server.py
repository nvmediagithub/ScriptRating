#!/usr/bin/env python3
"""
Minimal FastAPI server for testing chat functionality.
"""
import sys
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Add the app directory to the path
sys.path.insert(0, '.')

# Import only what we need
from app.config import settings
from app.presentation.api.routes.chat import router as chat_router
from app.presentation.api.routes.health import router as health_router

# Create minimal FastAPI app
app = FastAPI(
    title="Script Rating Chat API",
    description="Chat API for testing purposes",
    version="0.1.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include only the routers we need for testing
app.include_router(health_router, prefix="/api/v1", tags=["Health"])
app.include_router(chat_router, prefix="/api/v1/chat", tags=["Chat"])

if __name__ == "__main__":
    import uvicorn
    print("Starting chat test server on http://localhost:8000")
    print("Available endpoints:")
    print("  - Health: http://localhost:8000/api/v1/health")
    print("  - Chat sessions: http://localhost:8000/api/v1/chat/sessions")
    print("  - Chat health: http://localhost:8000/api/v1/chat/health")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")