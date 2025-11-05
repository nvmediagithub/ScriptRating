"""
Get Script Use Case.

This use case handles retrieving a script by its ID.
"""
from typing import Optional

from app.domain.entities.script import Script
from app.domain.repositories.script_repository import ScriptRepository


class GetScriptUseCase:
    """
    Use case for retrieving a script by ID.

    This class encapsulates the business logic for fetching a script
    from the repository.
    """

    def __init__(self, script_repository: ScriptRepository):
        """
        Initialize the use case with required dependencies.

        Args:
            script_repository: Repository for script data access.
        """
        self.script_repository = script_repository

    async def execute(self, script_id: str) -> Optional[Script]:
        """
        Execute the get script use case.

        Args:
            script_id: The unique identifier of the script to retrieve.

        Returns:
            Script instance if found, None otherwise.
        """
        return await self.script_repository.get_by_id(script_id)