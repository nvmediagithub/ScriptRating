import pytest
from fastapi.testclient import TestClient

from app.infrastructure.services.runtime_context import openrouter_client
from app.presentation.api.main import create_app


client = TestClient(create_app())


@pytest.fixture(autouse=True)
def restore_openrouter_key():
    """Ensure OpenRouter API key is restored after each test."""
    original_key = getattr(openrouter_client, "_api_key", None)
    yield
    openrouter_client.update_api_key(original_key)


def test_openrouter_status_without_key():
    openrouter_client.update_api_key(None)

    response = client.get("/api/v1/llm/openrouter/status")

    assert response.status_code == 200
    payload = response.json()
    assert payload["connected"] is False
    assert payload["error_message"]


def test_openrouter_models_with_mocked_client(monkeypatch):
    async def fake_list_models():
        return ["gpt-4", "claude-3-haiku"]

    openrouter_client.update_api_key("test-key")
    monkeypatch.setattr(openrouter_client, "list_models", fake_list_models)

    response = client.get("/api/v1/llm/openrouter/models")

    assert response.status_code == 200
    payload = response.json()
    assert payload["models"] == ["gpt-4", "claude-3-haiku"]
    assert payload["total"] == 2


def test_openrouter_call_success(monkeypatch):
    async def fake_chat_completion(**kwargs):
        return {
            "response": "Mocked completion",
            "tokens_used": 42,
            "cost": 0.0021,
            "response_time_ms": 120.0,
        }

    async def fake_list_models():
        return ["gpt-4"]

    openrouter_client.update_api_key("test-key")
    monkeypatch.setattr(openrouter_client, "chat_completion", fake_chat_completion)
    monkeypatch.setattr(openrouter_client, "list_models", fake_list_models)

    response = client.post(
        "/api/v1/llm/openrouter/call",
        json={
            "model": "gpt-4",
            "prompt": "Hello",
            "max_tokens": 50,
            "temperature": 0.7,
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["response"] == "Mocked completion"
    assert payload["tokens_used"] == 42
    assert payload["cost"] == pytest.approx(0.0021)


def test_openrouter_call_without_key_returns_error():
    openrouter_client.update_api_key(None)

    response = client.post(
        "/api/v1/llm/openrouter/call",
        json={
            "model": "any-model",
            "prompt": "Test",
            "max_tokens": 10,
            "temperature": 0.7,
        },
    )

    assert response.status_code == 400
    assert "API key" in response.json()["detail"]
