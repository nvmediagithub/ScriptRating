"""
Health check routes.

This module provides endpoints for health checks and monitoring.
"""
from fastapi import APIRouter, HTTPException
from app.infrastructure.services.rag_factory import RAGServiceFactory

router = APIRouter()


@router.get("/health")
async def health_check():
    """
    Basic health check endpoint.

    Returns:
        dict: Health status information.
    """
    return {"status": "healthy", "version": "0.1.0"}


@router.get("/health/ready")
async def readiness_check():
    """
    Readiness check endpoint for load balancer health checks.

    Returns:
        dict: Readiness status information.
    """
    return {"status": "ready", "version": "0.1.0"}


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