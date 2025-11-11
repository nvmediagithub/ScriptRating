#!/usr/bin/env python3
"""
Simplified LLM configuration and management routes with just two modes: Local and OpenRouter.

This module provides the simplest possible endpoints for managing LLM providers.
"""
import asyncio
import logging
import random
import os
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import APIRouter, HTTPException

from app.presentation.api.schemas import (
    LLMConfigResponse,
    LLMConfigUpdateRequest,
    LLMModelConfig,
    LLMModelsListResponse,
    LLMProvidersListResponse,
    LLMStatusResponse,
    LLMTestRequest,
    LLMTestResponse,
    LocalModelInfo,
    LocalModelsListResponse,
    LoadModelRequest,
    OpenRouterStatusResponse,
    UnloadModelRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter()

# Simple provider configuration - just two modes
class SimpleProviderConfig:
    def __init__(self):
        # OpenRouter configuration from environment
        self.openrouter_api_key = os.getenv("OPENROUTER_API_KEY")
        self.openrouter_base_url = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
        
        # Provider availability
        self.local_available = True  # Always available as placeholder
        self.openrouter_available = bool(self.openrouter_api_key)
        
        # Active mode
        self.active_mode = "local"
        self.active_model = "llama2:7b"

# Global configuration instance
config = SimpleProviderConfig()

# Mock models for simple two-mode setup
SIMPLE_MODELS = {
    "llama2:7b": {
        "model_name": "llama2:7b",
        "provider": "local",
        "context_window": 4096,
        "max_tokens": 2048,
        "temperature": 0.7,
        "top_p": 0.9,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0,
    },
    "gpt-3.5-turbo": {
        "model_name": "gpt-3.5-turbo",
        "provider": "openrouter",
        "context_window": 4096,
        "max_tokens": 2048,
        "temperature": 0.7,
        "top_p": 0.9,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0,
    },
    "minimax/minimax-m2:free": {
        "model_name": "minimax/minimax-m2:free",
        "provider": "openrouter",
        "context_window": 4096,
        "max_tokens": 2048,
        "temperature": 0.7,
        "top_p": 0.9,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0,
    }
}

# Mock local models
SIMPLE_LOCAL_MODELS = {
    "llama2:7b": {
        "model_name": "llama2:7b",
        "size_gb": 3.9,
        "loaded": True,
        "context_window": 4096,
        "max_tokens": 2048,
        "last_used": datetime.utcnow()
    }
}


@router.get("/providers")
async def get_llm_providers():
    """
    Get list of available LLM providers - simplified to just ["local", "openrouter"].
    """
    return {
        "providers": ["local", "openrouter"],
        "active_provider": config.active_mode
    }


@router.get("/models")
async def get_llm_models():
    """
    Get list of available LLM models - simplified.
    """
    models_by_provider = {
        "local": ["llama2:7b"],
        "openrouter": ["gpt-3.5-turbo", "minimax/minimax-m2:free"]
    }
    
    return {
        "models": list(SIMPLE_MODELS.keys()),
        "active_model": config.active_model,
        "models_by_provider": models_by_provider,
    }


@router.get("/config")
async def get_llm_config():
    """
    Get current LLM configuration - simplified to just two modes.
    """
    providers = {
        "local": {
            "provider": "local",
            "available": config.local_available,
            "configured": True,
            "base_url": "http://localhost:11434",
            "timeout": 30,
            "max_retries": 3,
        },
        "openrouter": {
            "provider": "openrouter",
            "available": config.openrouter_available,
            "configured": config.openrouter_available,
            "base_url": config.openrouter_base_url,
            "timeout": 30,
            "max_retries": 3,
        }
    }

    return {
        "active_provider": config.active_mode,
        "active_model": config.active_model,
        "providers": providers,
        "models": SIMPLE_MODELS,
    }


@router.put("/config")
async def update_llm_config(config_update: LLMConfigUpdateRequest):
    """
    Update LLM configuration - simplified.
    """
    global config
    
    if config_update.provider:
        if config_update.provider not in ["local", "openrouter"]:
            raise HTTPException(status_code=400, detail="Provider must be 'local' or 'openrouter'")
        
        # Check if provider is available
        if config_update.provider == "openrouter" and not config.openrouter_available:
            raise HTTPException(status_code=400, detail="OpenRouter is not configured")
        
        config.active_mode = config_update.provider

    if config_update.model_name:
        if config_update.model_name not in SIMPLE_MODELS:
            raise HTTPException(status_code=400, detail="Model not available")
        
        # Check if model is available for the current provider
        model_provider = SIMPLE_MODELS[config_update.model_name]["provider"]
        if model_provider != config.active_mode:
            raise HTTPException(status_code=400, detail="Model not available for current provider")
        
        config.active_model = config_update.model_name

    return await get_llm_config()


@router.put("/config/mode")
async def switch_llm_mode(provider: str, model_name: str = None):
    """
    Switch between local and openrouter modes - simplified endpoint.
    
    Args:
        provider: "local" or "openrouter"
        model_name: Optional model name (defaults to provider's default model)
    """
    global config
    
    try:
        logger.info(f"Switching LLM mode to provider: {provider}, model: {model_name}")

        if provider not in ["local", "openrouter"]:
            raise HTTPException(
                status_code=400,
                detail="Provider must be 'local' or 'openrouter'"
            )

        # Check provider availability
        if provider == "openrouter" and not config.openrouter_available:
            raise HTTPException(
                status_code=400,
                detail="OpenRouter is not configured. Please set OPENROUTER_API_KEY in your .env file."
            )

        # Validate model
        if model_name is None:
            # Use default model for provider
            model_name = "llama2:7b" if provider == "local" else "gpt-3.5-turbo"

        if model_name not in SIMPLE_MODELS:
            raise HTTPException(status_code=400, detail="Model not available")

        model_provider = SIMPLE_MODELS[model_name]["provider"]
        if model_provider != provider:
            raise HTTPException(
                status_code=400,
                detail=f"Model '{model_name}' is not available for provider '{provider}'"
            )

        # Switch configuration
        config.active_mode = provider
        config.active_model = model_name

        logger.info(f"Successfully switched to provider: {provider}, model: {model_name}")

        return await get_llm_config()
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error switching LLM mode: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to switch provider mode: {str(e)}"
        )


@router.get("/status/{provider}")
async def get_llm_status(provider: str):
    """
    Check status of LLM provider - simplified.
    """
    if provider not in ["local", "openrouter"]:
        raise HTTPException(status_code=404, detail="Provider not found")

    await asyncio.sleep(random.uniform(0.1, 0.3))

    if provider == "local":
        is_available = config.local_available
        response_time = random.uniform(50, 150) if is_available else None
        error_message = None if is_available else "Local provider not available"
    else:  # openrouter
        is_available = config.openrouter_available
        response_time = random.uniform(100, 300) if is_available else None
        error_message = None if is_available else "OpenRouter not configured"

    return {
        "provider": provider,
        "available": is_available,
        "healthy": is_available,
        "response_time_ms": response_time,
        "error_message": error_message,
        "last_checked_at": datetime.utcnow(),
    }


@router.get("/status")
async def get_all_llm_status():
    """
    Check status of all LLM providers - simplified.
    """
    statuses = []
    for provider in ["local", "openrouter"]:
        status = await get_llm_status(provider)
        statuses.append(status)

    return statuses


@router.post("/test")
async def test_llm(test_request: LLMTestRequest):
    """
    Test LLM with a prompt - simplified.
    """
    model_name = test_request.model_name or config.active_model
    
    if model_name not in SIMPLE_MODELS:
        raise HTTPException(status_code=400, detail="Model not available")

    model_config = SIMPLE_MODELS[model_name]
    provider = model_config["provider"]
    
    # Check if provider is available
    if provider == "openrouter" and not config.openrouter_available:
        raise HTTPException(status_code=503, detail="OpenRouter is not configured")
    
    if provider == "local" and not config.local_available:
        raise HTTPException(status_code=503, detail="Local provider is not available")

    # Simulate LLM processing
    await asyncio.sleep(random.uniform(0.5, 2.0))

    # Simple mock responses
    mock_responses = [
        "I understand your question. Let me help you with that.",
        "Based on my analysis, I can provide insights about this topic.",
        "The content appears to be appropriate for the intended audience.",
        "After careful consideration, here's my assessment..."
    ]

    response = random.choice(mock_responses)
    tokens_used = len(response.split()) * 2
    response_time = random.uniform(500, 2000)

    return {
        "model_name": model_name,
        "provider": provider,
        "prompt": test_request.prompt,
        "response": response,
        "tokens_used": tokens_used,
        "response_time_ms": response_time,
        "success": True
    }


@router.get("/local/models")
async def get_local_models():
    """
    Get list of available local models - simplified.
    """
    return {
        "models": list(SIMPLE_LOCAL_MODELS.values()),
        "loaded_models": [name for name, info in SIMPLE_LOCAL_MODELS.items() if info["loaded"]]
    }


@router.get("/openrouter/status")
async def get_openrouter_status():
    """
    Check OpenRouter status - simplified.
    """
    return {
        "connected": config.openrouter_available,
        "credits_remaining": None,
        "rate_limit_remaining": None,
        "error_message": None if config.openrouter_available else "OpenRouter API key not configured",
    }


@router.get("/config/health")
async def get_llm_health_summary():
    """
    Get overall LLM system health - simplified.
    """
    return {
        "providers_status": [
            {
                "provider": "local",
                "available": config.local_available,
                "healthy": config.local_available
            },
            {
                "provider": "openrouter", 
                "available": config.openrouter_available,
                "healthy": config.openrouter_available
            }
        ],
        "local_models_loaded": 1,
        "local_models_available": 1,
        "openrouter_connected": config.openrouter_available,
        "active_provider": config.active_mode,
        "active_model": config.active_model,
        "system_healthy": config.local_available or config.openrouter_available
    }


@router.get("/usage")
async def get_system_usage_stats(time_range: str = "24h"):
    """
    Get system-wide usage statistics - simplified.
    """
    multiplier = {"1h": 0.1, "24h": 1.0, "7d": 7.0, "30d": 30.0}.get(time_range, 1.0)
    
    return {
        "time_range": time_range,
        "generated_at": datetime.utcnow(),
        "system_stats": {
            "total_requests": int(100 * multiplier),
            "successful_requests": int(95 * multiplier),
            "failed_requests": int(5 * multiplier),
            "total_tokens_used": int(15000 * multiplier),
            "average_response_time_ms": 750.0,
            "error_rate": 5.0,
            "uptime_percentage": 98.0,
            "active_sessions": max(1, int(2 * multiplier)),
            "total_cost": 0.0 if config.active_mode == "local" else 0.05 * multiplier,
        }
    }