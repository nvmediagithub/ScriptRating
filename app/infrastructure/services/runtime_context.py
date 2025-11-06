"""
Runtime service singletons shared across FastAPI routes.
"""
from app.infrastructure.repositories.file_system_document_parser import FileSystemDocumentParser
from app.infrastructure.services.openrouter_client import OpenRouterClient
from config.settings import settings

from .analysis_manager import AnalysisManager
from .knowledge_base import KnowledgeBase
from .script_store import ScriptStore


document_parser = FileSystemDocumentParser()
knowledge_base = KnowledgeBase()
script_store = ScriptStore()
openrouter_client = OpenRouterClient(
    api_key=settings.openrouter_api_key,
    base_url=settings.openrouter_base_url,
    referer=settings.openrouter_referer,
    app_name=settings.openrouter_app_name,
    timeout=settings.openrouter_timeout,
)
analysis_manager = AnalysisManager(knowledge_base=knowledge_base, script_store=script_store)
