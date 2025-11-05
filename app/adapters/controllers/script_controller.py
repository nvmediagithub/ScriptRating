"""
Script controller.

This module contains the controller for handling script-related HTTP requests.
Placeholder implementation for future development.
"""
from typing import Optional

from app.use_cases.scripts.get_script import GetScriptUseCase


class ScriptController:
    """
    Controller for script operations.

    This class handles HTTP requests related to scripts and orchestrates
    the execution of corresponding use cases.
    """

    def __init__(self, get_script_use_case: GetScriptUseCase):
        """
        Initialize the controller with required dependencies.

        Args:
            get_script_use_case: Use case for getting scripts.
        """
        self.get_script_use_case = get_script_use_case

    async def get_script(self, script_id: str) -> Optional[dict]:
        """
        Handle GET request for retrieving a script by ID.

        Args:
            script_id: The unique identifier of the script.

        Returns:
            Dictionary representation of the script if found, None otherwise.
        """
        script = await self.get_script_use_case.execute(script_id)
        if script:
            return {
                "id": script.id,
                "title": script.title,
                "content": script.content,
                "author": script.author,
                "created_at": script.created_at.isoformat(),
                "updated_at": script.updated_at.isoformat(),
                "rating": script.rating,
            }
        return None