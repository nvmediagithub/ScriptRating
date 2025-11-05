"""
Script repository interface.

This module defines the contract for script data access operations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional

from app.domain.entities.script import Script


class ScriptRepository(ABC):
    """
    Abstract interface for script data access operations.

    This interface defines the contract that any script repository
    implementation must fulfill, ensuring dependency inversion.
    """

    @abstractmethod
    async def get_by_id(self, script_id: str) -> Optional[Script]:
        """
        Retrieve a script by its unique identifier.

        Args:
            script_id: The unique identifier of the script.

        Returns:
            Script instance if found, None otherwise.
        """
        pass

    @abstractmethod
    async def get_all(self) -> List[Script]:
        """
        Retrieve all scripts.

        Returns:
            List of all Script instances.
        """
        pass

    @abstractmethod
    async def save(self, script: Script) -> None:
        """
        Save a script to the repository.

        Args:
            script: The Script instance to save.
        """
        pass

    @abstractmethod
    async def update(self, script: Script) -> None:
        """
        Update an existing script in the repository.

        Args:
            script: The Script instance to update.
        """
        pass

    @abstractmethod
    async def delete(self, script_id: str) -> bool:
        """
        Delete a script from the repository.

        Args:
            script_id: The unique identifier of the script to delete.

        Returns:
            True if deletion was successful, False otherwise.
        """
        pass