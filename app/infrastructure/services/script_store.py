"""
In-memory storage for uploaded script documents ready for analysis.

The store keeps normalized representations of uploaded scripts including
paragraph-level metadata extracted during parsing.
"""
from __future__ import annotations

import asyncio
from typing import Any, Dict, Optional


class ScriptStore:
    """Thread-safe in-memory storage for uploaded script content."""

    def __init__(self) -> None:
        self._scripts: Dict[str, Dict[str, Any]] = {}
        self._lock = asyncio.Lock()

    async def save_script(self, document_id: str, payload: Dict[str, Any]) -> None:
        """Persist the normalized script payload."""
        async with self._lock:
            self._scripts[document_id] = payload

    async def get_script(self, document_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve an uploaded script payload."""
        async with self._lock:
            return self._scripts.get(document_id)

    async def delete_script(self, document_id: str) -> None:
        """Remove a stored script payload."""
        async with self._lock:
            self._scripts.pop(document_id, None)
