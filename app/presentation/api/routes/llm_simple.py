#!/usr/bin/env python3
"""
Simplified LLM configuration and management routes with just two modes: Local and OpenRouter.

This module provides the simplest possible endpoints for managing LLM providers.
"""
import asyncio
import os
import random
import logging
from datetime import datetime
from typing import Dict, Any

from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse

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
)

logger = logging.getLogger(__name__)

# Simple provider configuration - just two modes
class SimpleProviderConfig:
    def __init__(self):
        # OpenRouter configuration from environment (using the enhanced settings)
        from app.config import settings
        self.openrouter_api_key = settings.get_openrouter_api_key()
        self.openrouter_base_model = settings.get_openrouter_base_model()
        self.openrouter_base_url = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
        
        # Default active configuration
        self.active_mode = "local"
        self.active_model = "llama2:7b"
        
        # Check if OpenRouter is configured
        self.openrouter_available = bool(self.openrouter_api_key)
        
        # Local provider availability (mocked for now)
        self.local_available = True

    def get_openrouter_api_key(self) -> str:
        """Get OpenRouter API key."""
        return self.openrouter_api_key
    
    def get_openrouter_base_model(self) -> str:
        """Get OpenRouter base model."""
        return self.openrouter_base_model

# Global configuration instance
config = SimpleProviderConfig()

# Simple models configuration
SIMPLE_MODELS = {
    "llama2:7b": {
        "model_name": "llama2:7b",
        "provider": "local",
        "context_window": 4096,
    },
    "gpt-3.5-turbo": {
        "model_name": config.get_openrouter_base_model() or "gpt-3.5-turbo",
        "provider": "openrouter",
        "context_window": 4096,
    },
    "minimax/minimax-m2:free": {
        "model_name": config.get_openrouter_base_model() or "minimax/minimax-m2:free",
        "provider": "openrouter",
        "context_window": 4096,
    },
}

router = APIRouter()

# Configuration Endpoints

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
        "openrouter": [config.get_openrouter_base_model() or "gpt-3.5-turbo", "minimax/minimax-m2:free"]
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
        },
        "openrouter": {
            "provider": "openrouter",
            "available": config.openrouter_available,
            "configured": config.openrouter_available,
            "base_url": config.openrouter_base_url,
            "timeout": 30,
        }
    }

    return {
        "active_provider": config.active_mode,
        "active_model": config.active_model,
        "providers": providers,
        "models": SIMPLE_MODELS,
        "openrouter_api_key_configured": config.openrouter_available,
        "openrouter_base_model": config.openrouter_base_model,
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

        # Check provider availability with detailed error
        if provider == "openrouter" and not config.openrouter_available:
            api_key_status = "not configured"
            if config.openrouter_api_key:
                api_key_status = f"configured ({config.openrouter_api_key[:8]}...)"
            
            raise HTTPException(
                status_code=400,
                detail=f"OpenRouter is not available. API Key Status: {api_key_status}. Please check your .env configuration."
            )

        # Validate model
        if model_name is None:
            # Use default model for provider
            model_name = "llama2:7b" if provider == "local" else (config.get_openrouter_base_model() or "gpt-3.5-turbo")

        if model_name not in SIMPLE_MODELS:
            available_models = list(SIMPLE_MODELS.keys())
            raise HTTPException(status_code=400, detail=f"Model '{model_name}' not available. Available: {available_models}")

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

# Status and Health Endpoints

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
        
        if not is_available:
            if config.openrouter_api_key:
                error_message = f"OpenRouter API key configured but service unavailable"
            else:
                error_message = "OpenRouter not configured - API key missing"
        else:
            error_message = None

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

# Testing and Health

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

    # Mock response based on provider
    if provider == "local":
        mock_responses = [
            "This is a local test response. I understand your question.",
            "Local model responding: Here's what I think about that.",
            "Local LLM test: Processing completed successfully."
        ]
    else:
        mock_responses = [
            "This is an OpenRouter test response. I understand your question.",
            "OpenRouter model responding: Here's what I think about that.",
            "OpenRouter LLM test: Processing completed successfully."
        ]

    response = random.choice(mock_responses)
    tokens_used = len(response.split()) * 1.3  # Rough estimation
    response_time = random.uniform(500, 2000)  # Response time in ms

    return LLMTestResponse(
        model_name=model_name,
        provider=provider,
        prompt=test_request.prompt,
        response=response,
        tokens_used=int(tokens_used),
        response_time_ms=response_time,
        success=True
    )

@router.get("/local/models")
async def get_local_models():
    """
    Get information about local models - simplified.
    """
    return {
        "loaded_models": ["llama2:7b"],
        "available_models": ["llama2:7b"],
        "total_models": 1,
        "memory_usage_mb": 2048,
        "status": "running"
    }

@router.post("/local/models/load")
async def load_local_model(request: Dict[str, Any]):
    """
    Load a local model - simplified.
    """
    model_name = request.get("model_name")
    if model_name not in ["llama2:7b"]:
        raise HTTPException(status_code=400, detail="Model not available for local loading")
    
    # Simulate model loading
    await asyncio.sleep(random.uniform(1.0, 3.0))
    
    return {
        "model_name": model_name,
        "status": "loaded",
        "memory_usage_mb": 2048,
        "load_time_seconds": random.uniform(2.0, 5.0)
    }

@router.post("/local/models/unload")
async def unload_local_model(request: Dict[str, Any]):
    """
    Unload a local model - simplified.
    """
    model_name = request.get("model_name")
    if model_name not in ["llama2:7b"]:
        raise HTTPException(status_code=400, detail="Model not available for local unloading")
    
    # Simulate model unloading
    await asyncio.sleep(random.uniform(0.5, 1.0))
    
    return {
        "model_name": model_name,
        "status": "unloaded",
        "freed_memory_mb": 1024
    }

@router.get("/openrouter/status")
async def get_openrouter_status():
    """
    Get OpenRouter status - simplified.
    """
    return {
        "connected": config.openrouter_available,
        "credits_remaining": None,
        "rate_limit_remaining": None,
        "error_message": None if config.openrouter_available else "OpenRouter API key not configured",
    }

@router.get("/openrouter/models")
async def get_openrouter_models():
    """
    Get OpenRouter models - simplified.
    """
    return {
        "models": [config.get_openrouter_base_model() or "gpt-3.5-turbo", "minimax/minimax-m2:free"],
        "total": 2,
        "cached": True
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
        "local_models_available": 1,
        "openrouter_connected": config.openrouter_available,
        "active_provider": config.active_mode,
        "active_model": config.active_model,
        "system_healthy": config.local_available or config.openrouter_available
    }

# Performance Monitoring (simplified)

@router.get("/performance")
async def get_performance_metrics():
    """
    Get performance metrics - simplified.
    """
    # Mock performance data based on active provider
    multiplier = random.uniform(0.8, 1.2)
    
    return {
        "total_requests": int(100 * multiplier),
        "successful_requests": int(95 * multiplier),
        "failed_requests": int(5 * multiplier),
        "average_response_time_ms": random.uniform(800, 1200),
        "tokens_per_second": random.uniform(15, 25),
        "cost_usd": random.uniform(0.01, 0.05) if config.active_mode == "openrouter" else 0.0,
        "active_sessions": max(1, int(2 * multiplier)),
        "total_cost": 0.0 if config.active_mode == "local" else 0.05 * multiplier,
    }

@router.get("/usage")
async def get_usage_statistics():
    """
    Get usage statistics - simplified.
    """
    return {
        "total_requests": 150,
        "successful_requests": 142,
        "failed_requests": 8,
        "total_tokens_used": 15420,
        "average_response_time_ms": 1050.5,
        "requests_per_hour": 12,
        "cost_usd": 0.25,
        "most_used_provider": config.active_mode,
        "most_used_model": config.active_model,
    }