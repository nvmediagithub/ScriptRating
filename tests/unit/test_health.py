"""
Tests for health check endpoints.
"""
import pytest
from fastapi.testclient import TestClient

from app.presentation.api.main import create_app


@pytest.fixture
def client():
    """Create test client for FastAPI app."""
    app = create_app()
    return TestClient(app)


def test_health_check(client):
    """Test health check endpoint returns success."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


def test_readiness_check(client):
    """Test readiness check endpoint returns success."""
    response = client.get("/api/v1/health/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready"
    assert "version" in data