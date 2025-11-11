"""
LLM configuration and management routes.

This module provides endpoints for managing LLM providers, models, and configurations.
"""
import asyncio
import logging
import random
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import APIRouter, HTTPException

from app.infrastructure.services import openrouter_client
from app.infrastructure.services.openrouter_client import (
    OpenRouterAuthError,
    OpenRouterConfigurationError,
    OpenRouterError,
)
from app.presentation.api.schemas import (
    LLMConfigResponse,
    LLMConfigUpdateRequest,
    LLMModelConfig,
    LLMProvider,
    LLMProviderSettings,
    LLMModelsListResponse,
    LLMProvidersListResponse,
    LLMStatusResponse,
    LLMTestRequest,
    LLMTestResponse,
    LocalModelInfo,
    LocalModelsListResponse,
    LoadModelRequest,
    OpenRouterCallRequest,
    OpenRouterCallResponse,
    OpenRouterModelsListResponse,
    OpenRouterStatusResponse,
    PerformanceMetrics,
    PerformanceReportResponse,
    UnloadModelRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter()

OPENROUTER_MAX_RETRIES = 3

PROVIDER_SETTINGS: Dict[LLMProvider, LLMProviderSettings] = {
    LLMProvider.LOCAL: LLMProviderSettings(
        provider="local",  # Use string value instead of enum to avoid validation issues
        base_url="http://localhost:11434",
        timeout=30,
        max_retries=3,
    ),
    LLMProvider.OPENROUTER: LLMProviderSettings(
        provider="openrouter",  # Use string value instead of enum to avoid validation issues
        api_key="configured" if openrouter_client.has_api_key else None,
        base_url=openrouter_client.base_url,
        timeout=openrouter_client.timeout,
        max_retries=OPENROUTER_MAX_RETRIES,
    ),
}

MOCK_MODELS: Dict[str, LLMModelConfig] = {
    "llama2:7b": LLMModelConfig(
        model_name="llama2:7b",
        provider="local",  # Use string value instead of enum to avoid validation issues
        context_window=4096,
        max_tokens=2048,
        temperature=0.7,
        top_p=0.9,
        frequency_penalty=0.0,
        presence_penalty=0.0,
    ),
    "mistral:7b": LLMModelConfig(
        model_name="mistral:7b",
        provider="local",  # Use string value instead of enum to avoid validation issues
        context_window=4096,
        max_tokens=2048,
        temperature=0.7,
        top_p=0.9,
        frequency_penalty=0.0,
        presence_penalty=0.0,
    ),
}


def _update_provider_settings(settings_update: LLMProviderSettings) -> None:
    """Persist provider settings and keep OpenRouter client in sync."""
    provider = settings_update.provider

    if provider == LLMProvider.OPENROUTER:
        # Update client configuration
        if settings_update.api_key is not None:
            api_key = settings_update.api_key.strip() or None
            openrouter_client.update_api_key(api_key)
        # Allow updating base URL / timeout at runtime
        if settings_update.base_url:
            openrouter_client.base_url = settings_update.base_url.rstrip("/")
        openrouter_client.timeout = settings_update.timeout

        sanitized = LLMProviderSettings(
            provider="openrouter",  # Use string value instead of enum to avoid validation issues
            api_key="configured" if openrouter_client.has_api_key else None,
            base_url=openrouter_client.base_url,
            timeout=openrouter_client.timeout,
            max_retries=settings_update.max_retries or OPENROUTER_MAX_RETRIES,
        )
        PROVIDER_SETTINGS[provider] = sanitized
        return

    PROVIDER_SETTINGS[provider] = settings_update


async def _model_available(model_name: str, provider: Optional[LLMProvider] = None) -> bool:
    """Check whether a model is available either locally or via OpenRouter."""
    if model_name in MOCK_MODELS:
        return True

    if provider and provider != LLMProvider.OPENROUTER:
        return False

    if not openrouter_client.has_api_key:
        return False

    try:
        remote_models = await openrouter_client.list_models()
    except OpenRouterError:
        return False

    return model_name in remote_models

ACTIVE_PROVIDER = LLMProvider.LOCAL
ACTIVE_MODEL = "llama2:7b"

# Mock local model data
MOCK_LOCAL_MODELS = {
    "llama2:7b": LocalModelInfo(
        model_name="llama2:7b",
        size_gb=3.9,
        loaded=True,
        context_window=4096,
        max_tokens=2048,
        last_used=datetime.utcnow()
    ),
    "mistral:7b": LocalModelInfo(
        model_name="mistral:7b",
        size_gb=4.1,
        loaded=False,
        context_window=4096,
        max_tokens=2048,
        last_used=None
    ),
    "llama2:13b": LocalModelInfo(
        model_name="llama2:13b",
        size_gb=7.3,
        loaded=False,
        context_window=4096,
        max_tokens=2048,
        last_used=None
    )
}

# Mock performance metrics
MOCK_PERFORMANCE_METRICS = {
    LLMProvider.LOCAL: PerformanceMetrics(
        total_requests=150,
        successful_requests=145,
        failed_requests=5,
        average_response_time_ms=850.5,
        total_tokens_used=25000,
        error_rate=3.33,
        uptime_percentage=97.8
    ),
    LLMProvider.OPENROUTER: PerformanceMetrics(
        total_requests=200,
        successful_requests=198,
        failed_requests=2,
        average_response_time_ms=1200.0,
        total_tokens_used=35000,
        error_rate=1.0,
        uptime_percentage=99.5
    )
}


@router.get("/providers", response_model=LLMProvidersListResponse)
async def get_llm_providers():
    """
    Get list of available LLM providers.

    Returns:
        LLMProvidersListResponse: List of providers and active provider.
    """
    return LLMProvidersListResponse(
        providers=list(PROVIDER_SETTINGS.keys()),
        active_provider=ACTIVE_PROVIDER
    )


@router.get("/models", response_model=LLMModelsListResponse)
async def get_llm_models():
    """
    Get list of available LLM models.

    Returns:
        LLMModelsListResponse: List of models grouped by provider.
    """
    config = await get_llm_config()

    models_by_provider: Dict[LLMProvider, List[str]] = {provider: [] for provider in LLMProvider}
    for model_name, model_config in config.models.items():
        models_by_provider.setdefault(model_config.provider, []).append(model_name)

    for model_list in models_by_provider.values():
        model_list.sort()

    return LLMModelsListResponse(
        models=list(config.models.keys()),
        active_model=config.active_model,
        models_by_provider=models_by_provider,
    )


@router.get("/config", response_model=LLMConfigResponse)
async def get_llm_config():
    """
    Get current LLM configuration.

    Returns:
        LLMConfigResponse: Current configuration including providers and models.
    """
    dynamic_models: Dict[str, LLMModelConfig] = dict(MOCK_MODELS)

    if openrouter_client.has_api_key:
        try:
            remote_models = await openrouter_client.list_models()
        except OpenRouterConfigurationError:
            remote_models = []
        except OpenRouterAuthError as exc:
            logger.warning("OpenRouter authentication failed: %s", exc)
            remote_models = []
        except OpenRouterError as exc:
            logger.warning("OpenRouter list_models error: %s", exc)
            remote_models = []

        for model_name in remote_models:
            dynamic_models[model_name] = LLMModelConfig(
                model_name=model_name,
                provider="openrouter",  # Use string value instead of enum to avoid validation issues
                context_window=4096,
                max_tokens=2048,
                temperature=0.7,
                top_p=0.9,
                frequency_penalty=0.0,
                presence_penalty=0.0,
            )

    # Keep provider metadata in sync with actual client state (without exposing key)
    current_openrouter_settings = PROVIDER_SETTINGS[LLMProvider.OPENROUTER]
    PROVIDER_SETTINGS[LLMProvider.OPENROUTER] = LLMProviderSettings(
        provider="openrouter",  # Use string value instead of enum to avoid validation issues
        api_key="configured" if openrouter_client.has_api_key else None,
        base_url=current_openrouter_settings.base_url,
        timeout=current_openrouter_settings.timeout,
        max_retries=current_openrouter_settings.max_retries,
    )

    return LLMConfigResponse(
        active_provider=ACTIVE_PROVIDER,
        active_model=ACTIVE_MODEL,
        providers=PROVIDER_SETTINGS,
        models=dynamic_models,
    )


@router.put("/config")
async def update_llm_config(config_update: LLMConfigUpdateRequest):
    """
    Update LLM configuration.

    Args:
        config_update: Configuration update request.

    Returns:
        LLMConfigResponse: Updated configuration.
    """
    global ACTIVE_PROVIDER, ACTIVE_MODEL

    if config_update.provider:
        if config_update.provider not in PROVIDER_SETTINGS:
            raise HTTPException(status_code=400, detail="Provider not available")
        ACTIVE_PROVIDER = config_update.provider

    if config_update.model_name:
        provider_hint = config_update.provider or ACTIVE_PROVIDER
        model_available = await _model_available(config_update.model_name, provider_hint)
        if not model_available:
            raise HTTPException(status_code=400, detail="Model not available")
        ACTIVE_MODEL = config_update.model_name

    if config_update.settings:
        if config_update.settings.provider not in PROVIDER_SETTINGS:
            raise HTTPException(status_code=400, detail="Provider not configured")
        _update_provider_settings(config_update.settings)

    if config_update.llm_model_config:
        model_name = config_update.llm_model_config.model_name
        MOCK_MODELS[model_name] = config_update.llm_model_config

    return await get_llm_config()


@router.get("/status/{provider}", response_model=LLMStatusResponse)
async def get_llm_status(provider: LLMProvider):
    """
    Check status of LLM provider.

    Args:
        provider: Provider to check status for.

    Returns:
        LLMStatusResponse: Status information including health and response time.
    """
    if provider not in PROVIDER_SETTINGS:
        raise HTTPException(status_code=404, detail="Provider not found")

    if provider == LLMProvider.OPENROUTER:
        checked_at = datetime.utcnow()
        try:
            start = datetime.utcnow()
            await openrouter_client.check_connection()
            elapsed_ms = (datetime.utcnow() - start).total_seconds() * 1000.0
            return LLMStatusResponse(
                provider=provider,
                available=True,
                healthy=True,
                response_time_ms=elapsed_ms,
                error_message=None,
                last_checked_at=checked_at,
            )
        except OpenRouterConfigurationError:
            return LLMStatusResponse(
                provider=provider,
                available=False,
                healthy=False,
                response_time_ms=None,
                error_message="OpenRouter API key is not configured",
                last_checked_at=checked_at,
            )
        except OpenRouterAuthError as exc:
            return LLMStatusResponse(
                provider=provider,
                available=False,
                healthy=False,
                response_time_ms=None,
                error_message=str(exc),
                last_checked_at=checked_at,
            )
        except OpenRouterError as exc:
            return LLMStatusResponse(
                provider=provider,
                available=False,
                healthy=False,
                response_time_ms=None,
                error_message=str(exc),
                last_checked_at=checked_at,
            )

    # Local provider heuristic (still mocked)
    await asyncio.sleep(random.uniform(0.1, 0.3))

    local_model = MOCK_LOCAL_MODELS.get(ACTIVE_MODEL)
    is_available = bool(local_model and local_model.loaded)
    response_time = random.uniform(50, 150) if is_available else None
    error_message = None if is_available else "Local model not loaded"

    return LLMStatusResponse(
        provider=provider,
        available=is_available,
        healthy=is_available,
        response_time_ms=response_time,
        error_message=error_message,
        last_checked_at=datetime.utcnow(),
    )


@router.get("/status", response_model=List[LLMStatusResponse])
async def get_all_llm_status():
    """
    Check status of all LLM providers.

    Returns:
        List[LLMStatusResponse]: Status information for all providers.
    """
    statuses = []
    for provider in PROVIDER_SETTINGS.keys():
        status = await get_llm_status(provider)
        statuses.append(status)

    return statuses


@router.post("/test", response_model=LLMTestResponse)
async def test_llm(test_request: LLMTestRequest):
    """
    Test LLM with a prompt.

    Args:
        test_request: Test request with prompt and optional model.

    Returns:
        LLMTestResponse: Test results including response and metadata.
    """
    model_name = test_request.model_name or ACTIVE_MODEL
    config = await get_llm_config()
    model_config = config.models.get(model_name)

    if model_config is None:
        raise HTTPException(status_code=400, detail="Model not available")

    # Check if provider is available
    status = await get_llm_status(model_config.provider)
    if not status.healthy:
        raise HTTPException(status_code=503, detail=f"Provider {model_config.provider} is not available")

    # Simulate LLM response
    await asyncio.sleep(random.uniform(0.5, 2.0))  # Simulate processing time

    # Mock responses based on provider
    if model_config.provider == LLMProvider.LOCAL:
        mock_responses = [
            "Based on my analysis of the content, I can provide insights about...",
            "The script appears to contain several key elements that...",
            "My evaluation shows that this material should be rated...",
            "After careful consideration, the content seems appropriate for..."
        ]
    else:  # OpenRouter
        mock_responses = [
            "I understand you're asking about content analysis. Let me help you with that.",
            "Based on the guidelines you provided, this content would be classified as...",
            "The material contains elements that suggest a rating of...",
            "From my assessment, the script's content aligns with the following criteria..."
        ]

    response = random.choice(mock_responses)
    tokens_used = len(response.split()) * 2  # Rough token estimation
    response_time = random.uniform(500, 2000)

    return LLMTestResponse(
        model_name=model_name,
        provider=model_config.provider,
        prompt=test_request.prompt,
        response=response,
        tokens_used=tokens_used,
        response_time_ms=response_time,
        success=True
    )


# Local Model Management Endpoints
@router.get("/local/models", response_model=LocalModelsListResponse)
async def get_local_models():
    """
    Get list of available local models with their info.

    Returns:
        LocalModelsListResponse: List of local models and loaded models.
    """
    return LocalModelsListResponse(
        models=list(MOCK_LOCAL_MODELS.values()),
        loaded_models=[name for name, info in MOCK_LOCAL_MODELS.items() if info.loaded]
    )


@router.get("/local/models/{model_name}", response_model=LocalModelInfo)
async def get_local_model_info(model_name: str):
    """
    Get detailed information about a specific local model.

    Args:
        model_name: Name of the model to get info for.

    Returns:
        LocalModelInfo: Detailed model information.
    """
    if model_name not in MOCK_LOCAL_MODELS:
        raise HTTPException(status_code=404, detail="Local model not found")

    return MOCK_LOCAL_MODELS[model_name]


# OpenRouter Integration Endpoints
@router.get("/openrouter/models", response_model=OpenRouterModelsListResponse)
async def get_openrouter_models():
    """
    Get list of available OpenRouter models.

    Returns:
        OpenRouterModelsListResponse: List of available models.
    """
    if not openrouter_client.has_api_key:
        return OpenRouterModelsListResponse(models=[], total=0)

    try:
        models = await openrouter_client.list_models()
    except OpenRouterConfigurationError:
        return OpenRouterModelsListResponse(models=[], total=0)
    except OpenRouterAuthError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc
    except OpenRouterError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return OpenRouterModelsListResponse(
        models=models,
        total=len(models),
    )


@router.post("/openrouter/call", response_model=OpenRouterCallResponse)
async def call_openrouter(request: OpenRouterCallRequest):
    """
    Make a call to OpenRouter API.

    Args:
        request: OpenRouter call request.

    Returns:
        OpenRouterCallResponse: API call response.
    """
    if not openrouter_client.has_api_key:
        raise HTTPException(status_code=400, detail="OpenRouter API key is not configured")

    if not await _model_available(request.model, LLMProvider.OPENROUTER):
        raise HTTPException(status_code=400, detail="Model not available on OpenRouter")

    try:
        result = await openrouter_client.chat_completion(
            model=request.model,
            prompt=request.prompt,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
        )
    except OpenRouterAuthError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc
    except OpenRouterConfigurationError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except OpenRouterError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return OpenRouterCallResponse(
        model=request.model,
        response=result.get("response", ""),
        tokens_used=result.get("tokens_used") or 0,
        cost=(result.get("cost") or 0.0),
        response_time_ms=result.get("response_time_ms") or 0.0,
    )


@router.get("/openrouter/status", response_model=OpenRouterStatusResponse)
async def get_openrouter_status():
    """
    Check OpenRouter API connectivity and status.

    Returns:
        OpenRouterStatusResponse: API status information.
    """
    if not openrouter_client.has_api_key:
        return OpenRouterStatusResponse(
            connected=False,
            credits_remaining=None,
            rate_limit_remaining=None,
            error_message="OpenRouter API key is not configured",
        )

    try:
        await openrouter_client.check_connection()
    except OpenRouterConfigurationError as exc:
        return OpenRouterStatusResponse(
            connected=False,
            credits_remaining=None,
            rate_limit_remaining=None,
            error_message=str(exc),
        )
    except OpenRouterAuthError as exc:
        return OpenRouterStatusResponse(
            connected=False,
            credits_remaining=None,
            rate_limit_remaining=None,
            error_message=str(exc),
        )
    except OpenRouterError as exc:
        return OpenRouterStatusResponse(
            connected=False,
            credits_remaining=None,
            rate_limit_remaining=None,
            error_message=str(exc),
        )

    return OpenRouterStatusResponse(
        connected=True,
        credits_remaining=None,
        rate_limit_remaining=None,
        error_message=None,
    )


# Performance Monitoring Endpoints
@router.get("/performance/{provider}", response_model=PerformanceReportResponse)
async def get_performance_report(provider: LLMProvider, time_range: str = "24h"):
    """
    Get performance metrics for a specific provider.

    Args:
        provider: LLM provider to get metrics for.
        time_range: Time range for the report (1h, 24h, 7d, 30d).

    Returns:
        PerformanceReportResponse: Performance metrics report.
    """
    if provider not in MOCK_PERFORMANCE_METRICS:
        raise HTTPException(status_code=404, detail=f"Performance metrics not available for {provider}")

    # Adjust metrics based on time range (mock adjustment)
    base_metrics = MOCK_PERFORMANCE_METRICS[provider]
    multiplier = {"1h": 0.1, "24h": 1.0, "7d": 7.0, "30d": 30.0}.get(time_range, 1.0)

    adjusted_metrics = PerformanceMetrics(
        total_requests=int(base_metrics.total_requests * multiplier),
        successful_requests=int(base_metrics.successful_requests * multiplier),
        failed_requests=int(base_metrics.failed_requests * multiplier),
        average_response_time_ms=base_metrics.average_response_time_ms,
        total_tokens_used=int(base_metrics.total_tokens_used * multiplier),
        error_rate=base_metrics.error_rate,
        uptime_percentage=base_metrics.uptime_percentage
    )

    return PerformanceReportResponse(
        provider=provider,
        metrics=adjusted_metrics,
        time_range=time_range,
        generated_at=datetime.utcnow()
    )


@router.get("/performance", response_model=List[PerformanceReportResponse])
async def get_all_performance_reports(time_range: str = "24h"):
    """
    Get performance metrics for all providers.

    Args:
        time_range: Time range for the reports (1h, 24h, 7d, 30d).

    Returns:
        List[PerformanceReportResponse]: Performance reports for all providers.
    """
    reports = []
    for provider in LLMProvider:
        if provider in MOCK_PERFORMANCE_METRICS:
            report = await get_performance_report(provider, time_range)
            reports.append(report)

    return reports


# Enhanced Status Checking Endpoints
@router.get("/status/enhanced/{provider}", response_model=LLMStatusResponse)
async def get_enhanced_status(provider: LLMProvider):
    """
    Get enhanced status information for a provider including performance metrics.

    Args:
        provider: Provider to check status for.

    Returns:
        LLMStatusResponse: Enhanced status information.
    """
    base_status = await get_llm_status(provider)

    # Add performance context to status
    if provider in MOCK_PERFORMANCE_METRICS:
        metrics = MOCK_PERFORMANCE_METRICS[provider]
        # Enhance error message with performance info if needed
        if not base_status.healthy and base_status.error_message:
            base_status.error_message += f" (Recent error rate: {metrics.error_rate}%)"

    return base_status


# Configuration Management Endpoints
@router.put("/config/mode")
async def switch_llm_mode(provider: LLMProvider, model_name: str):
    """
    Switch between local and API modes with model selection.

    Args:
        provider: Provider to switch to.
        model_name: Model name to activate.

    Returns:
        LLMConfigResponse: Updated configuration.
    """
    global ACTIVE_PROVIDER, ACTIVE_MODEL

    if provider not in PROVIDER_SETTINGS:
        raise HTTPException(status_code=400, detail="Provider not configured")

    # Validate model availability for provider
    if provider == LLMProvider.LOCAL:
        if model_name not in MOCK_LOCAL_MODELS:
            raise HTTPException(status_code=400, detail="Local model not available")
        # Ensure model is loaded
        if not MOCK_LOCAL_MODELS[model_name].loaded:
            raise HTTPException(status_code=400, detail="Local model not loaded")
    else:  # OpenRouter
        if not await _model_available(model_name, LLMProvider.OPENROUTER):
            if not openrouter_client.has_api_key:
                raise HTTPException(status_code=400, detail="OpenRouter API key is not configured")
            raise HTTPException(status_code=400, detail="OpenRouter model not available")

    ACTIVE_PROVIDER = provider
    ACTIVE_MODEL = model_name

    return await get_llm_config()


@router.get("/config/health")
async def get_llm_health_summary():
    """
    Get overall health summary of LLM system.

    Returns:
        Dict: Health summary including all providers and models.
    """
    all_status = await get_all_llm_status()
    local_models = await get_local_models()
    openrouter_status = await get_openrouter_status()

    return {
        "providers_status": [status.dict() for status in all_status],
        "local_models_loaded": len(local_models.loaded_models),
        "local_models_available": len(local_models.models),
        "openrouter_connected": openrouter_status.connected,
        "active_provider": ACTIVE_PROVIDER.value,
        "active_model": ACTIVE_MODEL,
        "system_healthy": all(status.healthy for status in all_status) and len(local_models.loaded_models) > 0
    }


@router.post("/local/models/load")
async def load_local_model(request: LoadModelRequest):
    """
    Load a local model into memory.

    Args:
        request: Load model request with model name.

    Returns:
        LocalModelInfo: Updated model information.
    """
    model_name = request.model_name

    if model_name not in MOCK_LOCAL_MODELS:
        raise HTTPException(status_code=404, detail="Local model not found")

    # Simulate loading time
    await asyncio.sleep(random.uniform(2.0, 5.0))

    # Update model status
    MOCK_LOCAL_MODELS[model_name].loaded = True
    MOCK_LOCAL_MODELS[model_name].last_used = datetime.utcnow()

    return MOCK_LOCAL_MODELS[model_name]


@router.post("/local/models/unload")
async def unload_local_model(request: UnloadModelRequest):
    """
    Unload a local model from memory.

    Args:
        request: Unload model request with model name.

    Returns:
        LocalModelInfo: Updated model information.
    """
    model_name = request.model_name

    if model_name not in MOCK_LOCAL_MODELS:
        raise HTTPException(status_code=404, detail="Local model not found")

    if not MOCK_LOCAL_MODELS[model_name].loaded:
        raise HTTPException(status_code=400, detail="Model is not currently loaded")

    # Simulate unloading time
    await asyncio.sleep(random.uniform(0.5, 1.0))

    # Update model status
    MOCK_LOCAL_MODELS[model_name].loaded = False

    return MOCK_LOCAL_MODELS[model_name]
