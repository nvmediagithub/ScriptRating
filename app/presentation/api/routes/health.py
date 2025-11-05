"""
Health check routes.

This module provides endpoints for health checks and monitoring.
"""
from fastapi import APIRouter

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