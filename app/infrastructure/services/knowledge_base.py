"""
In-memory knowledge base for normative documents used in RAG lookups.

The knowledge base stores paragraph-level chunks with metadata (page, paragraph
number, document id) and exposes simple TF-IDF based retrieval to provide
references for LLM reasoning and reporting.

This module now integrates with the new RAG infrastructure (EmbeddingService,
VectorDatabaseService, RAGOrchestrator) while maintaining backward compatibility.
"""
from __future__ import annotations

import asyncio
import uuid
import logging
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

logger = logging.getLogger(__name__)


@dataclass
class KnowledgeEntry:
    """Normalized representation of a paragraph-sized knowledge chunk."""

    entry_id: str
    document_id: str
    document_title: str
    page: int
    paragraph: int
    text: str
    metadata: Dict[str, Any]


class KnowledgeBase:
    """
    Manage normative knowledge entries and perform similarity search.
    
    This class now supports both legacy TF-IDF search and new vector-based RAG.
    When RAG orchestrator is provided, it will be used for enhanced search.
    """

    def __init__(
        self,
        rag_orchestrator: Optional[Any] = None,
        use_rag_when_available: bool = True,
    ) -> None:
        """
        Initialize KnowledgeBase.
        
        Args:
            rag_orchestrator: Optional RAGOrchestrator for enhanced search
            use_rag_when_available: Use RAG when available, fallback to TF-IDF
        """
        self._entries: List[KnowledgeEntry] = []
        self._vectorizer: Optional[TfidfVectorizer] = None
        self._matrix = None
        self._lock = asyncio.Lock()
        
        # New RAG integration
        self._rag_orchestrator = rag_orchestrator
        self._use_rag_when_available = use_rag_when_available
        self._rag_enabled = False

    async def initialize(self) -> None:
        """Initialize RAG orchestrator if available."""
        if self._rag_orchestrator and self._use_rag_when_available:
            try:
                # Check if already initialized
                if not hasattr(self._rag_orchestrator, '_initialized'):
                    await self._rag_orchestrator.initialize()
                    self._rag_orchestrator._initialized = True
                
                self._rag_enabled = True
                logger.info("KnowledgeBase: RAG orchestrator enabled")
            except Exception as e:
                logger.warning(f"Failed to initialize RAG orchestrator: {e}")
                self._rag_enabled = False

    async def ingest_document(
        self,
        document_id: str,
        document_title: str,
        paragraph_details: List[Dict[str, Any]],
    ) -> None:
        """
        Ingest (or re-ingest) a document into the knowledge base.

        Existing entries for the same document will be replaced.
        Automatically syncs with RAG orchestrator if available.
        """
        cleaned_entries = [
            KnowledgeEntry(
                entry_id=str(uuid.uuid4()),
                document_id=document_id,
                document_title=document_title,
                page=int(detail.get("page", 1)),
                paragraph=int(detail.get("paragraph_index", 1)),
                text=detail.get("text", "").strip(),
                metadata={
                    key: value
                    for key, value in detail.items()
                    if key not in {"text", "page", "paragraph_index"}
                },
            )
            for detail in paragraph_details
            if detail.get("text", "").strip()
        ]

        async with self._lock:
            self._entries = [
                entry for entry in self._entries if entry.document_id != document_id
            ]
            self._entries.extend(cleaned_entries)
            self._rebuild_index_locked()
        
        # Sync with RAG orchestrator if enabled
        if self._rag_enabled and self._rag_orchestrator:
            await self._sync_to_rag_orchestrator(cleaned_entries)

    async def remove_document(self, document_id: str) -> None:
        """Remove all knowledge entries associated with a document."""
        # Get entry IDs before removal for RAG sync
        entry_ids = []
        async with self._lock:
            entry_ids = [
                entry.entry_id
                for entry in self._entries
                if entry.document_id == document_id
            ]
            self._entries = [
                entry for entry in self._entries if entry.document_id != document_id
            ]
            self._rebuild_index_locked()
        
        # Sync with RAG orchestrator if enabled
        if self._rag_enabled and self._rag_orchestrator and entry_ids:
            try:
                await self._rag_orchestrator.delete_documents(entry_ids)
            except Exception as e:
                logger.warning(f"Failed to sync deletion to RAG: {e}")

    async def query(self, text: str, top_k: int = 3) -> List[Dict[str, Any]]:
        """
        Retrieve the top-k most relevant knowledge chunks for the query.
        
        Uses RAG orchestrator when available, falls back to TF-IDF.
        """
        # Try RAG orchestrator first if enabled
        if self._rag_enabled and self._rag_orchestrator:
            try:
                return await self._query_with_rag(text, top_k)
            except Exception as e:
                logger.warning(f"RAG query failed, falling back to TF-IDF: {e}")
        
        # Fallback to legacy TF-IDF search
        return await self._query_with_tfidf(text, top_k)

    async def _query_with_rag(self, text: str, top_k: int) -> List[Dict[str, Any]]:
        """Query using RAG orchestrator."""
        results = await self._rag_orchestrator.search(
            query=text,
            top_k=top_k,
        )
        
        # Convert RAG results to legacy format
        legacy_results = []
        for result in results:
            legacy_results.append({
                "document_id": result.metadata.get("document_id", ""),
                "title": result.metadata.get("document_title", ""),
                "page": result.metadata.get("page", 1),
                "paragraph": result.metadata.get("paragraph", 1),
                "excerpt": result.text,
                "score": result.score,
                "metadata": result.metadata,
            })
        
        return legacy_results

    async def _query_with_tfidf(self, text: str, top_k: int) -> List[Dict[str, Any]]:
        """Legacy TF-IDF query method."""
        query_text = text.strip()
        if not query_text:
            return []

        async with self._lock:
            if not self._entries or self._vectorizer is None or self._matrix is None:
                return []

            query_vector = self._vectorizer.transform([query_text])
            similarities = cosine_similarity(query_vector, self._matrix)[0]
            if not np.any(similarities):
                return []

            ranked_indices = np.argsort(similarities)[::-1][:top_k]
            results: List[Dict[str, Any]] = []
            for index in ranked_indices:
                entry = self._entries[int(index)]
                score = float(similarities[int(index)])
                results.append(
                    {
                        "document_id": entry.document_id,
                        "title": entry.document_title,
                        "page": entry.page,
                        "paragraph": entry.paragraph,
                        "excerpt": entry.text,
                        "score": score,
                        "metadata": entry.metadata,
                    }
                )
            return results

    async def _sync_to_rag_orchestrator(
        self,
        entries: List[KnowledgeEntry],
    ) -> None:
        """Sync entries to RAG orchestrator."""
        if not self._rag_orchestrator:
            return
        
        try:
            from app.domain.services.rag_orchestrator import RAGDocument
            
            # Convert entries to RAG documents
            rag_documents = []
            for entry in entries:
                rag_doc = RAGDocument(
                    id=entry.entry_id,
                    text=entry.text,
                    metadata={
                        "document_id": entry.document_id,
                        "document_title": entry.document_title,
                        "page": entry.page,
                        "paragraph": entry.paragraph,
                        **entry.metadata,
                    },
                )
                rag_documents.append(rag_doc)
            
            # Index in batch
            if rag_documents:
                await self._rag_orchestrator.index_documents_batch(
                    rag_documents,
                    wait_for_indexing=False,  # Async indexing
                )
                logger.info(f"Synced {len(rag_documents)} entries to RAG")
        
        except Exception as e:
            logger.error(f"Error syncing to RAG orchestrator: {e}")
            # Don't raise - maintain graceful degradation

    async def get_document_stats(self) -> List[Dict[str, Any]]:
        """Return aggregated statistics for indexed documents."""
        async with self._lock:
            stats: Dict[str, Dict[str, Any]] = {}
            for entry in self._entries:
                doc_stats = stats.setdefault(
                    entry.document_id,
                    {
                        "document_id": entry.document_id,
                        "title": entry.document_title,
                        "paragraphs_indexed": 0,
                    },
                )
                doc_stats["paragraphs_indexed"] += 1
            return list(stats.values())

    async def get_rag_status(self) -> Dict[str, Any]:
        """Get RAG integration status."""
        status = {
            "rag_available": self._rag_orchestrator is not None,
            "rag_enabled": self._rag_enabled,
            "use_rag_when_available": self._use_rag_when_available,
            "legacy_entries_count": len(self._entries),
        }
        
        if self._rag_enabled and self._rag_orchestrator:
            try:
                health = await self._rag_orchestrator.health_check()
                status["rag_health"] = health
            except Exception as e:
                status["rag_error"] = str(e)
        
        return status

    def _rebuild_index_locked(self) -> None:
        """Rebuild the TF-IDF index; caller must hold the lock."""
        texts = [entry.text for entry in self._entries if entry.text]
        if not texts:
            self._vectorizer = None
            self._matrix = None
            return

        self._vectorizer = TfidfVectorizer(
            lowercase=True,
            ngram_range=(1, 2),
            max_features=5000,
        )
        self._matrix = self._vectorizer.fit_transform(texts)
