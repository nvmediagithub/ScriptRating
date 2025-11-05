"""
FastAPI application factory and configuration.

This module creates the main FastAPI application instance with all necessary
middleware, routes, and dependencies configured.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.presentation.api.routes.health import router as health_router
from app.presentation.api.routes.scripts import router as scripts_router
from app.presentation.api.routes.documents import router as documents_router
from app.presentation.api.routes.analysis import router as analysis_router
from app.presentation.api.routes.reports import router as reports_router
from app.presentation.api.routes.feedback import router as feedback_router
from app.presentation.api.routes.history import router as history_router
from app.presentation.api.routes.rag import router as rag_router
from app.presentation.api.routes.llm import router as llm_router


def create_app() -> FastAPI:
    """
    Create and configure the FastAPI application.

    Returns:
        FastAPI: Configured FastAPI application instance.
    """
    # Use the imported settings object

    app = FastAPI(
        title="Script Rating API",
        description="API for rating and analyzing scripts using clean architecture",
        version="0.1.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    # Configure CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
        allow_headers=["*"],
        expose_headers=["*"],
    )

    # Include routers
    app.include_router(health_router, prefix="/api/v1", tags=["Health"])
    app.include_router(scripts_router, prefix="/api/v1", tags=["Scripts"])
    app.include_router(documents_router, prefix="/api/v1/documents", tags=["Documents"])
    app.include_router(analysis_router, prefix="/api/v1/analysis", tags=["Analysis"])
    app.include_router(reports_router, prefix="/api/v1/reports", tags=["Reports"])
    app.include_router(feedback_router, prefix="/api/v1/feedback", tags=["Feedback"])
    app.include_router(history_router, prefix="/api/v1/history", tags=["History"])
    app.include_router(rag_router, prefix="/api/v1/rag", tags=["RAG"])
    app.include_router(llm_router, prefix="/api/v1/llm", tags=["LLM"])

    @app.on_event("startup")
    async def startup_event():
        """Handle application startup events."""
        # Initialize database connections, caches, etc.
        pass

    @app.on_event("shutdown")
    async def shutdown_event():
        """Handle application shutdown events."""
        # Close database connections, cleanup resources, etc.
        pass

    return app