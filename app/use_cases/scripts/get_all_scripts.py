"""
Get All Scripts Use Case.

This use case handles retrieving all scripts.
"""
from typing import List

from app.domain.entities.script import Script
from app.domain.repositories.script_repository import ScriptRepository


class GetAllScriptsUseCase:
    """
    Use case for retrieving all scripts.

    This class encapsulates the business logic for fetching all scripts
    from the repository.
    """

    def __init__(self, script_repository: ScriptRepository):
        """
        Initialize the use case with required dependencies.

        Args:
            script_repository: Repository for script data access.
        """
        self.script_repository = script_repository

    async def execute(self) -> List[Script]:
        """
        Execute the get all scripts use case.

        Returns:
            List of all Script instances.
        """
        return await self.script_repository.get_all()