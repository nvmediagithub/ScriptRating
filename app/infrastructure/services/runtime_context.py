"""
Runtime service singletons shared across FastAPI routes.
"""
import asyncio
from app.infrastructure.repositories.file_system_document_parser import FileSystemDocumentParser
from app.infrastructure.services.openrouter_client import OpenRouterClient
from app.config.settings import Settings  # fixed import path

from .analysis_manager import AnalysisManager
from .script_store import ScriptStore


settings = Settings()

document_parser = FileSystemDocumentParser()
script_store = ScriptStore()
openrouter_client = OpenRouterClient(
    api_key=settings.openrouter_api_key,
    base_url=settings.openrouter_base_url,
    referer=settings.openrouter_referer,
    app_name=settings.openrouter_app_name,
    timeout=settings.openrouter_timeout,
)


async def _initialize_services():
    """Initialize services using RAG factory."""
    from .rag_factory import RAGServiceFactory

    return await RAGServiceFactory.initialize_services()


_knowledge_base = None
_analysis_manager = None


async def get_knowledge_base():
    """Get or initialize the knowledge base instance."""
    global _knowledge_base
    if _knowledge_base is None:
        _knowledge_base = await _initialize_services()
    return _knowledge_base


async def get_analysis_manager():
    """Get or initialize the analysis manager instance."""
    global _analysis_manager, _knowledge_base
    if _knowledge_base is None:
        _knowledge_base = await get_knowledge_base()
    if _analysis_manager is None:
        _analysis_manager = AnalysisManager(knowledge_base=_knowledge_base, script_store=script_store)
    return _analysis_manager


# Backward compatible module-level placeholders
knowledge_base = None  # Will be set by get_knowledge_base()
analysis_manager = None  # Will be set by get_analysis_manager()
