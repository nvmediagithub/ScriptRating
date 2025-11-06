"""
Infrastructure services package exposing runtime singletons.
"""

from .runtime_context import (
    analysis_manager,
    document_parser,
    knowledge_base,
    openrouter_client,
    script_store,
)

__all__ = [
    "analysis_manager",
    "document_parser",
    "knowledge_base",
    "openrouter_client",
    "script_store",
]
