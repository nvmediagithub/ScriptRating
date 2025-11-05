"""
In-memory script repository implementation.

This is a stub/mock implementation for development and testing purposes.
In production, this would be replaced with a database-backed repository.
"""
from typing import Dict, List, Optional

from app.domain.entities.script import Script
from app.domain.repositories.script_repository import ScriptRepository


class InMemoryScriptRepository(ScriptRepository):
    """
    In-memory implementation of ScriptRepository.

    This implementation stores scripts in memory for development/testing.
    Not suitable for production use.
    """

    def __init__(self):
        """Initialize the repository with an empty script store."""
        self._scripts: Dict[str, Script] = {}

    async def get_by_id(self, script_id: str) -> Optional[Script]:
        """
        Retrieve a script by ID from memory.

        Args:
            script_id: The unique identifier of the script.

        Returns:
            Script instance if found, None otherwise.
        """
        return self._scripts.get(script_id)

    async def get_all(self) -> List[Script]:
        """
        Retrieve all scripts from memory.

        Returns:
            List of all Script instances.
        """
        return list(self._scripts.values())

    async def save(self, script: Script) -> None:
        """
        Save a script to memory.

        Args:
            script: The Script instance to save.
        """
        self._scripts[script.id] = script

    async def update(self, script: Script) -> None:
        """
        Update an existing script in memory.

        Args:
            script: The Script instance to update.
        """
        if script.id in self._scripts:
            self._scripts[script.id] = script

    async def delete(self, script_id: str) -> bool:
        """
        Delete a script from memory.

        Args:
            script_id: The unique identifier of the script to delete.

        Returns:
            True if deletion was successful, False otherwise.
        """
        if script_id in self._scripts:
            del self._scripts[script_id]
            return True
        return False