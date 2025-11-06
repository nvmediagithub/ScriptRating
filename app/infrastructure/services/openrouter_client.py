"""
Async OpenRouter API client.

Provides lightweight helpers for listing models, checking connectivity, and
running chat completions using the OpenRouter REST API.
"""
from __future__ import annotations

import json
from typing import Any, Dict, List, Optional

import httpx


class OpenRouterError(Exception):
    """Base class for OpenRouter client errors."""


class OpenRouterConfigurationError(OpenRouterError):
    """Raised when client configuration is incomplete (e.g. missing API key)."""


class OpenRouterAuthError(OpenRouterError):
    """Raised when OpenRouter rejects the provided credentials."""


class OpenRouterClient:
    """Async HTTP client for interacting with the OpenRouter API."""

    def __init__(
        self,
        *,
        api_key: Optional[str],
        base_url: str,
        referer: Optional[str] = None,
        app_name: Optional[str] = None,
        timeout: int = 30,
    ):
        self._api_key = api_key
        self.base_url = base_url.rstrip("/")
        self.referer = referer
        self.app_name = app_name
        self.timeout = timeout

    # --------------------------------------------------------------------- #
    # Public helpers
    # --------------------------------------------------------------------- #
    def update_api_key(self, api_key: Optional[str]) -> None:
        """Update API key at runtime."""
        self._api_key = api_key

    @property
    def has_api_key(self) -> bool:
        """Return True when an API key is configured."""
        return bool(self._api_key)

    async def list_models(self) -> List[str]:
        """Return a list of available model identifiers."""
        response = await self._request("GET", "/models")
        payload = response.json()
        data = payload.get("data", [])
        return [
            item.get("id") or item.get("name")
            for item in data
            if isinstance(item, dict)
        ]

    async def check_connection(self) -> bool:
        """
        Check connectivity by issuing a lightweight models request.

        Returns:
            bool: True when the API responds successfully.
        """
        await self._request("GET", "/models")
        return True

    async def chat_completion(
        self,
        *,
        model: str,
        prompt: str,
        max_tokens: int,
        temperature: float,
    ) -> Dict[str, Any]:
        """
        Execute a chat completion request.

        Returns:
            Dict[str, Any]: Parsed response containing text, tokens, cost, and latency.
        """
        payload = {
            "model": model,
            "messages": [
                {"role": "user", "content": prompt},
            ],
            "max_tokens": max_tokens,
            "temperature": temperature,
        }

        response = await self._request("POST", "/chat/completions", json=payload)
        data = response.json()

        message_content = ""
        choices = data.get("choices") or []
        if choices and isinstance(choices[0], dict):
            message = choices[0].get("message") or {}
            message_content = message.get("content") or ""

        usage = data.get("usage") or {}
        total_tokens = usage.get("total_tokens")
        total_cost = usage.get("total_cost")

        try:
            cost_value = float(total_cost) if total_cost is not None else None
        except (TypeError, ValueError):
            cost_value = None

        return {
            "response": message_content,
            "tokens_used": total_tokens,
            "cost": cost_value,
            "response_time_ms": response.elapsed.total_seconds() * 1000.0,
        }

    # --------------------------------------------------------------------- #
    # Internal helpers
    # --------------------------------------------------------------------- #
    async def _request(self, method: str, endpoint: str, **kwargs: Any) -> httpx.Response:
        if not self._api_key:
            raise OpenRouterConfigurationError("OpenRouter API key is not configured")

        headers = kwargs.pop("headers", {})
        headers.setdefault("Authorization", f"Bearer {self._api_key}")
        headers.setdefault("Content-Type", "application/json")

        if self.referer:
            headers.setdefault("HTTP-Referer", self.referer)
            headers.setdefault("Referer", self.referer)
        if self.app_name:
            headers.setdefault("X-Title", self.app_name)

        async with httpx.AsyncClient(
            base_url=self.base_url,
            timeout=self.timeout,
        ) as client:
            response = await client.request(method, endpoint, headers=headers, **kwargs)

        if response.status_code == 401:
            raise OpenRouterAuthError("OpenRouter rejected the provided API key")

        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            message = self._extract_error_message(exc.response)
            raise OpenRouterError(message) from exc

        return response

    @staticmethod
    def _extract_error_message(response: httpx.Response) -> str:
        """Extract a human-readable error message from OpenRouter responses."""
        if not response.content:
            return f"OpenRouter request failed with status {response.status_code}"

        try:
            payload = response.json()
        except json.JSONDecodeError:
            return response.text

        if isinstance(payload, dict):
            detail = payload.get("error") or payload.get("message")
            if isinstance(detail, dict):
                return detail.get("message") or json.dumps(detail)
            if isinstance(detail, str):
                return detail

        return json.dumps(payload)
