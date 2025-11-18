"""
Health check routes.

This module provides comprehensive endpoints for health checks and monitoring of all backend services.
"""
import asyncio
from datetime import datetime
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, HTTPException
from app.infrastructure.services.rag_factory import RAGServiceFactory
from app.infrastructure.services.runtime_context import (
    get_knowledge_base,
    get_analysis_manager,
    document_parser,
    script_store,
    openrouter_client,
    settings,
)

router = APIRouter()


@router.get("/health")
async def health_check():
    """
    Basic health check endpoint.

    Returns:
        dict: Health status information.
    """
    return {"status": "healthy", "version": "0.1.0", "timestamp": datetime.utcnow().isoformat()}


@router.get("/health/ready")
async def readiness_check():
    """
    Readiness check endpoint for load balancer health checks.

    Returns:
        dict: Readiness status information.
    """
    return {"status": "ready", "version": "0.1.0", "timestamp": datetime.utcnow().isoformat()}


@router.get("/health/comprehensive")
async def comprehensive_health_check():
    """
    Comprehensive health status endpoint that provides detailed information about all backend services.

    Returns:
        dict: Detailed health status for all services including their status, configuration, and any errors.
    """
    health_status = {
        "timestamp": datetime.utcnow().isoformat(),
        "overall_status": "healthy",
        "services": {},
        "errors": [],
        "warnings": []
    }

    try:
        # Check core services
        await _check_core_services(health_status)

        # Check RAG services
        await _check_rag_services(health_status)

        # Check infrastructure services
        await _check_infrastructure_services(health_status)

        # Check configuration
        _check_configuration(health_status)

        # Determine overall status
        _determine_overall_status(health_status)

        return health_status

    except Exception as e:
        health_status["overall_status"] = "unhealthy"
        health_status["errors"].append(f"Health check failed: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail=f"Comprehensive health check error: {str(e)}"
        )


@router.get("/health/qdrant")
async def qdrant_health_check():
    """
    Qdrant-specific health check endpoint.

    Returns:
        dict: Qdrant health status information including collection details.
    """
    try:
        vector_db_service = RAGServiceFactory.get_vector_db_service()

        if not vector_db_service:
            raise HTTPException(
                status_code=503,
                detail="Qdrant service not available"
            )

        health_status = await vector_db_service.health_check()

        if health_status["status"] != "healthy":
            raise HTTPException(
                status_code=503,
                detail=f"Qdrant health check failed: {health_status}"
            )

        return health_status

    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Qdrant health check error: {str(e)}"
        )


@router.get("/health/rag")
async def rag_health_check():
    """
    RAG system health check endpoint.

    Returns:
        dict: RAG system health status including all components.
    """
    health_info = {
        "rag_services_initialized": RAGServiceFactory.is_initialized(),
        "embedding_service_available": False,
        "vector_db_service_available": False,
        "rag_orchestrator_available": False,
        "knowledge_base_available": False,
    }

    try:
        # Check embedding service
        embedding_service = RAGServiceFactory.get_embedding_service()
        if embedding_service:
            health_info["embedding_service_available"] = True

        # Check vector database service
        vector_db_service = RAGServiceFactory.get_vector_db_service()
        if vector_db_service:
            health_info["vector_db_service_available"] = True
            # Get detailed Qdrant status
            qdrant_health = await vector_db_service.health_check()
            health_info["qdrant_status"] = qdrant_health

        # Check RAG orchestrator
        rag_orchestrator = RAGServiceFactory.get_rag_orchestrator()
        if rag_orchestrator:
            health_info["rag_orchestrator_available"] = True

        # Check knowledge base
        knowledge_base = RAGServiceFactory.get_knowledge_base()
        if knowledge_base:
            health_info["knowledge_base_available"] = True

        # Overall status
        health_info["status"] = "healthy" if all([
            health_info["rag_services_initialized"],
            health_info["vector_db_service_available"],
        ]) else "degraded"

        return health_info

    except Exception as e:
        health_info["status"] = "unhealthy"
        health_info["error"] = str(e)
        raise HTTPException(
            status_code=503,
            detail=f"RAG health check error: {str(e)}"
        )


async def _check_core_services(health_status: Dict[str, Any]) -> None:
    """Check core services like knowledge base and analysis manager."""
    services = health_status["services"]

    try:
        # Check Knowledge Base
        kb = await get_knowledge_base()
        services["knowledge_base"] = {
            "status": "healthy" if kb else "unhealthy",
            "available": kb is not None,
            "has_rag_orchestrator": hasattr(kb, '_rag_orchestrator') if kb else False,
            "rag_orchestrator_available": getattr(kb, '_rag_orchestrator', None) is not None if kb else False,
        }

        if kb and hasattr(kb, 'get_rag_status'):
            try:
                rag_status = await kb.get_rag_status()
                services["knowledge_base"]["rag_status"] = rag_status
            except Exception as e:
                services["knowledge_base"]["rag_status_error"] = str(e)

    except Exception as e:
        services["knowledge_base"] = {"status": "unhealthy", "error": str(e)}
        health_status["errors"].append(f"Knowledge base check failed: {str(e)}")

    try:
        # Check Analysis Manager
        analysis_mgr = await get_analysis_manager()
        services["analysis_manager"] = {
            "status": "healthy" if analysis_mgr else "unhealthy",
            "available": analysis_mgr is not None,
        }
    except Exception as e:
        services["analysis_manager"] = {"status": "unhealthy", "error": str(e)}
        health_status["errors"].append(f"Analysis manager check failed: {str(e)}")


async def _check_rag_services(health_status: Dict[str, Any]) -> None:
    """Check RAG-related services."""
    services = health_status["services"]

    services["rag_factory"] = {
        "status": "healthy" if RAGServiceFactory.is_initialized() else "unhealthy",
        "initialized": RAGServiceFactory.is_initialized(),
    }

    # Check individual RAG components
    rag_components = [
        ("embedding_service", RAGServiceFactory.get_embedding_service),
        ("vector_db_service", RAGServiceFactory.get_vector_db_service),
        ("rag_orchestrator", RAGServiceFactory.get_rag_orchestrator),
        ("knowledge_base", RAGServiceFactory.get_knowledge_base),
    ]

    for component_name, getter in rag_components:
        try:
            component = getter()
            services[f"rag_{component_name}"] = {
                "status": "healthy" if component else "unhealthy",
                "available": component is not None,
                "type": type(component).__name__ if component else None,
            }

            # Add detailed health check for vector database
            if component_name == "vector_db_service" and component:
                try:
                    detailed_health = await component.health_check()
                    services[f"rag_{component_name}"]["detailed_health"] = detailed_health
                except Exception as e:
                    services[f"rag_{component_name}"]["detailed_health_error"] = str(e)

            # Add detailed health check for RAG orchestrator
            if component_name == "rag_orchestrator" and component:
                try:
                    orch_health = await component.health_check()
                    services[f"rag_{component_name}"]["detailed_health"] = orch_health
                except Exception as e:
                    services[f"rag_{component_name}"]["detailed_health_error"] = str(e)

        except Exception as e:
            services[f"rag_{component_name}"] = {"status": "unhealthy", "error": str(e)}
            health_status["errors"].append(f"RAG {component_name} check failed: {str(e)}")


async def _check_infrastructure_services(health_status: Dict[str, Any]) -> None:
    """Check infrastructure services like document parser, script store, etc."""
    services = health_status["services"]

    # Check Document Parser
    try:
        services["document_parser"] = {
            "status": "healthy",
            "available": document_parser is not None,
            "supported_formats": document_parser.get_supported_formats() if document_parser else [],
        }
    except Exception as e:
        services["document_parser"] = {"status": "unhealthy", "error": str(e)}
        health_status["errors"].append(f"Document parser check failed: {str(e)}")

    # Check Script Store
    try:
        services["script_store"] = {
            "status": "healthy",
            "available": script_store is not None,
        }
    except Exception as e:
        services["script_store"] = {"status": "unhealthy", "error": str(e)}
        health_status["errors"].append(f"Script store check failed: {str(e)}")

    # Check OpenRouter Client
    try:
        services["openrouter_client"] = {
            "status": "healthy",
            "available": openrouter_client is not None,
            "api_key_configured": bool(settings.openrouter_api_key),
            "base_url": settings.openrouter_base_url,
        }
    except Exception as e:
        services["openrouter_client"] = {"status": "unhealthy", "error": str(e)}
        health_status["errors"].append(f"OpenRouter client check failed: {str(e)}")


def _check_configuration(health_status: Dict[str, Any]) -> None:
    """Check configuration settings and environment variables."""
    config = health_status.setdefault("configuration", {})

    # Check RAG configuration
    try:
        from app.config.rag_config import get_rag_config
        rag_config = get_rag_config()
        config["rag"] = {
            "enabled": rag_config.is_rag_enabled(),
            "primary_provider": rag_config.embedding_primary_provider,
            "fallback_providers": rag_config.embedding_fallback_providers,
            "qdrant_url": rag_config.qdrant_url,
        }
    except Exception as e:
        config["rag"] = {"error": str(e)}
        health_status["warnings"].append(f"RAG configuration check failed: {str(e)}")

    # Check critical environment variables
    env_checks = {
        "OPENROUTER_API_KEY": bool(settings.effective_openrouter_api_key),
        "QDRANT_URL": bool(getattr(settings, 'qdrant_url', None)),
        "EMBEDDING_PRIMARY_PROVIDER": bool(settings.effective_embedding_provider),
    }

    config["environment"] = env_checks

    missing_env_vars = [k for k, v in env_checks.items() if not v]
    if missing_env_vars:
        health_status["warnings"].append(f"Missing environment variables: {', '.join(missing_env_vars)}")


def _determine_overall_status(health_status: Dict[str, Any]) -> None:
    """Determine the overall system status based on individual service statuses."""
    services = health_status["services"]
    errors = health_status["errors"]

    if errors:
        health_status["overall_status"] = "unhealthy"
        return

    # Check if critical services are healthy
    critical_services = ["rag_vector_db_service", "rag_knowledge_base"]
    for service in critical_services:
        if service in services and services[service].get("status") != "healthy":
            health_status["overall_status"] = "degraded"
            return

    # All services are healthy
    health_status["overall_status"] = "healthy"
