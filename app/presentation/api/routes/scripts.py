"""
Scripts API routes.

This module provides endpoints for script-related operations.
"""
from fastapi import APIRouter, Depends

from app.adapters.controllers.script_controller import ScriptController
from app.infrastructure.repositories.in_memory_script_repository import InMemoryScriptRepository
from app.use_cases.scripts.get_all_scripts import GetAllScriptsUseCase
from app.use_cases.scripts.get_script import GetScriptUseCase

router = APIRouter()

def get_script_controller() -> ScriptController:
    """Dependency injection for ScriptController."""
    repository = InMemoryScriptRepository()
    get_script_use_case = GetScriptUseCase(repository)
    get_all_scripts_use_case = GetAllScriptsUseCase(repository)
    return ScriptController(get_script_use_case, get_all_scripts_use_case)


@router.get("/scripts")
async def get_scripts(controller: ScriptController = Depends(get_script_controller)):
    """
    Get all scripts.

    Returns:
        List[dict]: List of script dictionaries.
    """
    return await controller.get_all_scripts()


@router.post("/scripts")
async def create_script():
    """
    Create a new script.

    Returns:
        dict: Placeholder response for script creation.
    """
    return {"script_id": "placeholder", "message": "Script creation - implementation pending"}


@router.get("/scripts/{script_id}")
async def get_script(script_id: str):
    """
    Get a specific script by ID.

    Args:
        script_id: The unique identifier of the script.

    Returns:
        dict: Placeholder response for script retrieval.
    """
    return {"script_id": script_id, "message": "Script retrieval - implementation pending"}