"""
In-memory knowledge base for normative documents used in RAG lookups.

The knowledge base stores paragraph-level chunks with metadata (page, paragraph
number, document id) and exposes intelligent retrieval prioritizing vector search
with TF-IDF fallback to provide references for LLM reasoning and reporting.

This module integrates with the RAG infrastructure (EmbeddingService,
VectorDatabaseService, RAGOrchestrator) with confidence-based routing,
hybrid search, caching, and comprehensive metrics tracking.
"""
from __future__ import annotations

import asyncio
import uuid
import logging
import time
import hashlib
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple
from enum import Enum

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

logger = logging.getLogger(__name__)


class SearchStrategy(Enum):
    """Search strategy options."""
    VECTOR_ONLY = "vector_only"
    TFIDF_ONLY = "tfidf_only"
    HYBRID = "hybrid"
    AUTO = "auto"  # Confidence-based routing


@dataclass
class SearchMetrics:
    """Metrics for search operations."""
    total_queries: int = 0
    vector_searches: int = 0
    tfidf_searches: int = 0
    hybrid_searches: int = 0
    cache_hits: int = 0
    cache_misses: int = 0
    average_vector_score: float = 0.0
    average_tfidf_score: float = 0.0
    search_times_ms: List[float] = field(default_factory=list)
    errors: int = 0


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
    Manage normative knowledge entries and perform intelligent similarity search.

    This class prioritizes vector search with confidence-based routing to TF-IDF fallback,
    supports hybrid search, caching, and comprehensive metrics tracking.
    """

    def __init__(
        self,
        rag_orchestrator: Optional[Any] = None,
        use_rag_when_available: bool = True,
        search_strategy: SearchStrategy = SearchStrategy.AUTO,
        enable_hybrid_search: bool = True,
        enable_caching: bool = True,
        cache_ttl_seconds: int = 300,
        confidence_threshold: float = 0.7,
    ) -> None:
        """
        Initialize KnowledgeBase with intelligent routing.

        Args:
            rag_orchestrator: Optional RAGOrchestrator for vector search
            use_rag_when_available: Use RAG when available, fallback to TF-IDF
            search_strategy: Search strategy (AUTO, VECTOR_ONLY, TFIDF_ONLY, HYBRID)
            enable_hybrid_search: Enable hybrid search combining vector and TF-IDF
            enable_caching: Enable query result caching
            cache_ttl_seconds: Cache TTL in seconds
            confidence_threshold: Confidence threshold for auto-routing (0-1)
        """
        self._entries: List[KnowledgeEntry] = []
        self._vectorizer: Optional[TfidfVectorizer] = None
        self._matrix = None
        self._lock = asyncio.Lock()

        # RAG integration
        self._rag_orchestrator = rag_orchestrator
        self._use_rag_when_available = use_rag_when_available
        self._rag_enabled = False

        # Search configuration
        self._search_strategy = search_strategy
        self._enable_hybrid_search = enable_hybrid_search
        self._enable_caching = enable_caching
        self._cache_ttl_seconds = cache_ttl_seconds
        self._confidence_threshold = confidence_threshold

        # Caching
        self._query_cache: Dict[str, Tuple[List[Dict[str, Any]], float]] = {}
        self._cache_lock = asyncio.Lock()

        # Metrics
        self._metrics = SearchMetrics()

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

    async def query(self, text: str, top_k: int = 3, strategy: Optional[SearchStrategy] = None) -> List[Dict[str, Any]]:
        """
        Retrieve the top-k most relevant knowledge chunks using intelligent routing.

        Features:
        - Confidence-based routing between vector and TF-IDF search
        - Query result caching
        - Hybrid search combining both methods
        - Comprehensive metrics tracking

        Args:
            text: Query text
            top_k: Number of results to return
            strategy: Override default search strategy

        Returns:
            List of relevant knowledge chunks with metadata
        """
        start_time = time.time()
        self._metrics.total_queries += 1

        try:
            # Check cache first
            if self._enable_caching:
                cached_result = await self._get_cached_result(text)
                if cached_result:
                    self._metrics.cache_hits += 1
                    search_time_ms = (time.time() - start_time) * 1000
                    self._metrics.search_times_ms.append(search_time_ms)
                    return cached_result

            self._metrics.cache_misses += 1

            # Determine search strategy
            effective_strategy = strategy or self._search_strategy

            # Execute search based on strategy
            if effective_strategy == SearchStrategy.VECTOR_ONLY:
                results = await self._query_vector_only(text, top_k)
            elif effective_strategy == SearchStrategy.TFIDF_ONLY:
                results = await self._query_tfidf_only(text, top_k)
            elif effective_strategy == SearchStrategy.HYBRID:
                results = await self._query_hybrid(text, top_k)
            else:  # AUTO (confidence-based routing)
                results = await self._query_with_confidence_routing(text, top_k)

            # Cache results if enabled
            if self._enable_caching and results:
                await self._cache_result(text, results)

            # Record metrics
            search_time_ms = (time.time() - start_time) * 1000
            self._metrics.search_times_ms.append(search_time_ms)

            return results

        except Exception as e:
            self._metrics.errors += 1
            logger.error(f"Query failed: {e}")
            # Return empty results on error (graceful degradation)
            return []

    async def _query_with_confidence_routing(self, text: str, top_k: int) -> List[Dict[str, Any]]:
        """Query with confidence-based routing between vector and TF-IDF."""
        # Try vector search first
        if self._rag_enabled:
            try:
                vector_results = await self._query_with_rag(text, top_k * 2)  # Get more for comparison
                self._metrics.vector_searches += 1

                # Check confidence of vector results
                if vector_results and vector_results[0].get("score", 0) >= self._confidence_threshold:
                    # High confidence, use vector results
                    return vector_results[:top_k]

                # Low confidence, try hybrid if enabled
                if self._enable_hybrid_search:
                    return await self._query_hybrid(text, top_k)

                # Otherwise fallback to TF-IDF
                logger.info("Vector search confidence below threshold, using TF-IDF")
                return await self._query_with_tfidf(text, top_k)

            except Exception as e:
                logger.warning(f"Vector search failed, falling back to TF-IDF: {e}")

        # Fallback to TF-IDF
        return await self._query_with_tfidf(text, top_k)

    async def _query_vector_only(self, text: str, top_k: int) -> List[Dict[str, Any]]:
        """Query using only vector search."""
        if not self._rag_enabled:
            logger.warning("Vector search requested but RAG not enabled")
            return []

        self._metrics.vector_searches += 1
        return await self._query_with_rag(text, top_k)

    async def _query_tfidf_only(self, text: str, top_k: int) -> List[Dict[str, Any]]:
        """Query using only TF-IDF search."""
        self._metrics.tfidf_searches += 1
        return await self._query_with_tfidf(text, top_k)

    async def _query_hybrid(self, text: str, top_k: int) -> List[Dict[str, Any]]:
        """Query using hybrid search combining vector and TF-IDF."""
        self._metrics.hybrid_searches += 1

        # Get results from both methods (with more candidates for better fusion)
        vector_results = []
        tfidf_results = []

        if self._rag_enabled:
            try:
                vector_results = await self._query_with_rag(text, top_k * 2)
            except Exception as e:
                logger.warning(f"Vector search failed in hybrid mode: {e}")

        tfidf_results = await self._query_with_tfidf(text, top_k * 2)

        # Combine and re-rank results using weighted scoring
        combined_results = self._fuse_search_results(vector_results, tfidf_results, top_k)
        return combined_results

    def _fuse_search_results(
        self,
        vector_results: List[Dict[str, Any]],
        tfidf_results: List[Dict[str, Any]],
        top_k: int,
        vector_weight: float = 0.7,
        tfidf_weight: float = 0.3
    ) -> List[Dict[str, Any]]:
        """Fuse vector and TF-IDF results using weighted scoring."""
        # Create a map of document_id -> best result for deduplication
        result_map: Dict[str, Dict[str, Any]] = {}

        # Process vector results
        for result in vector_results:
            doc_id = result.get("document_id", "")
            if doc_id not in result_map:
                result_map[doc_id] = result.copy()
                result_map[doc_id]["vector_score"] = result.get("score", 0)
                result_map[doc_id]["tfidf_score"] = 0.0
            else:
                result_map[doc_id]["vector_score"] = max(
                    result_map[doc_id].get("vector_score", 0),
                    result.get("score", 0)
                )

        # Process TF-IDF results
        for result in tfidf_results:
            doc_id = result.get("document_id", "")
            if doc_id not in result_map:
                result_map[doc_id] = result.copy()
                result_map[doc_id]["tfidf_score"] = result.get("score", 0)
                result_map[doc_id]["vector_score"] = 0.0
            else:
                result_map[doc_id]["tfidf_score"] = max(
                    result_map[doc_id].get("tfidf_score", 0),
                    result.get("score", 0)
                )

        # Calculate combined scores and sort
        for doc_id, result in result_map.items():
            vector_score = result.get("vector_score", 0)
            tfidf_score = result.get("tfidf_score", 0)
            combined_score = vector_weight * vector_score + tfidf_weight * tfidf_score
            result["score"] = combined_score

        # Sort by combined score and return top-k
        sorted_results = sorted(result_map.values(), key=lambda x: x["score"], reverse=True)
        return sorted_results[:top_k]

    async def _query_with_rag(self, text: str, top_k: int) -> List[Dict[str, Any]]:
        """Query using RAG orchestrator."""
        if not self._rag_orchestrator:
            return []

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
    async def _get_cached_result(self, query_text: str) -> Optional[List[Dict[str, Any]]]:
        """Get cached result if available and not expired."""
        if not self._enable_caching:
            return None

        cache_key = self._generate_cache_key(query_text)

        async with self._cache_lock:
            if cache_key in self._query_cache:
                cached_results, timestamp = self._query_cache[cache_key]
                if time.time() - timestamp < self._cache_ttl_seconds:
                    return cached_results
                else:
                    # Remove expired cache entry
                    del self._query_cache[cache_key]

        return None

    async def _cache_result(self, query_text: str, results: List[Dict[str, Any]]) -> None:
        """Cache query results."""
        if not self._enable_caching or not results:
            return

        cache_key = self._generate_cache_key(query_text)

        async with self._cache_lock:
            self._query_cache[cache_key] = (results, time.time())

            # Clean up old cache entries if too many
            if len(self._query_cache) > 1000:  # Configurable limit
                oldest_key = min(
                    self._query_cache.keys(),
                    key=lambda k: self._query_cache[k][1]
                )
                del self._query_cache[oldest_key]

    def _generate_cache_key(self, query_text: str) -> str:
        """Generate a cache key for the query."""
        # Normalize query and create hash
        normalized = query_text.strip().lower()
        return hashlib.md5(normalized.encode('utf-8')).hexdigest()

    def get_search_metrics(self) -> Dict[str, Any]:
        """Get comprehensive search metrics."""
        search_times = self._metrics.search_times_ms
        avg_search_time = (
            sum(search_times) / len(search_times) if search_times else 0.0
        )

        cache_hit_rate = (
            self._metrics.cache_hits / (self._metrics.cache_hits + self._metrics.cache_misses)
            if (self._metrics.cache_hits + self._metrics.cache_misses) > 0 else 0.0
        )

        return {
            "total_queries": self._metrics.total_queries,
            "vector_searches": self._metrics.vector_searches,
            "tfidf_searches": self._metrics.tfidf_searches,
            "hybrid_searches": self._metrics.hybrid_searches,
            "cache_hits": self._metrics.cache_hits,
            "cache_misses": self._metrics.cache_misses,
            "cache_hit_rate": cache_hit_rate,
            "average_search_time_ms": avg_search_time,
            "errors": self._metrics.errors,
            "search_strategy": self._search_strategy.value,
            "caching_enabled": self._enable_caching,
            "hybrid_enabled": self._enable_hybrid_search,
            "confidence_threshold": self._confidence_threshold,
        }

    def set_search_strategy(self, strategy: SearchStrategy) -> None:
        """Update the search strategy."""
        self._search_strategy = strategy
        logger.info(f"Search strategy changed to: {strategy.value}")

    def clear_cache(self) -> None:
        """Clear the query result cache."""
        self._query_cache.clear()
        logger.info("Query cache cleared")

    def update_configuration(
        self,
        enable_caching: Optional[bool] = None,
        cache_ttl_seconds: Optional[int] = None,
        enable_hybrid_search: Optional[bool] = None,
        confidence_threshold: Optional[float] = None,
    ) -> None:
        """Update runtime configuration."""
        if enable_caching is not None:
            self._enable_caching = enable_caching
            if not enable_caching:
                self.clear_cache()

        if cache_ttl_seconds is not None:
            self._cache_ttl_seconds = cache_ttl_seconds

        if enable_hybrid_search is not None:
            self._enable_hybrid_search = enable_hybrid_search

        if confidence_threshold is not None:
            self._confidence_threshold = confidence_threshold

        logger.info("KnowledgeBase configuration updated")
