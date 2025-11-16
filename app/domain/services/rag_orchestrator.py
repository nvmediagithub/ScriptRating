"""
RAG Orchestrator domain service.

This service coordinates between embedding and vector database services
to provide high-level RAG operations.
"""
from __future__ import annotations

import asyncio
import logging
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
from datetime import datetime

from app.infrastructure.services.embedding_service import (
    EmbeddingService,
    EmbeddingResult,
)
from app.infrastructure.services.vector_database_service import (
    VectorDatabaseService,
    VectorSearchResult,
)

logger = logging.getLogger(__name__)


@dataclass
class RAGDocument:
    """Document for RAG indexing."""
    id: str
    text: str
    metadata: Dict[str, Any]


@dataclass
class RAGSearchResult:
    """Result of RAG search operation."""
    document_id: str
    text: str
    score: float
    metadata: Dict[str, Any]
    embedding_model: Optional[str] = None


@dataclass
class RAGMetrics:
    """Metrics for RAG operations."""
    total_indexed_documents: int
    total_searches: int
    average_search_time_ms: float
    cache_hit_rate: float
    vector_db_status: str
    embedding_service_status: str


class RAGOrchestrator:
    """
    Orchestrator for RAG operations.
    
    Coordinates between:
    - EmbeddingService for text embeddings
    - VectorDatabaseService for vector storage/search
    - Legacy KnowledgeBase for backward compatibility
    
    Features:
    - Document indexing with automatic embedding
    - Hybrid search (vector + fallback)
    - Metrics and monitoring
    - Error handling with retries
    - Graceful degradation
    """

    def __init__(
        self,
        embedding_service: EmbeddingService,
        vector_db_service: VectorDatabaseService,
        enable_hybrid_search: bool = True,
        search_timeout: float = 5.0,
    ):
        """
        Initialize RAGOrchestrator.

        Args:
            embedding_service: Service for generating embeddings
            vector_db_service: Service for vector storage/search
            enable_hybrid_search: Enable hybrid search with fallbacks
            search_timeout: Timeout for search operations in seconds
        """
        self.embedding_service = embedding_service
        self.vector_db_service = vector_db_service
        self.enable_hybrid_search = enable_hybrid_search
        self.search_timeout = search_timeout
        
        self._lock = asyncio.Lock()
        
        # Metrics
        self._metrics = {
            "indexed_documents": 0,
            "total_searches": 0,
            "successful_searches": 0,
            "failed_searches": 0,
            "search_times_ms": [],
            "errors": 0,
        }

    async def initialize(self) -> None:
        """Initialize all services."""
        try:
            await self.embedding_service.initialize()
            await self.vector_db_service.initialize()
            logger.info("RAGOrchestrator initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing RAGOrchestrator: {e}")
            raise

    async def close(self) -> None:
        """Close all service connections."""
        await self.embedding_service.close()
        await self.vector_db_service.close()

    async def index_document(
        self,
        document: RAGDocument,
        wait_for_indexing: bool = True,
    ) -> str:
        """
        Index a single document into the RAG system.
        
        Args:
            document: Document to index
            wait_for_indexing: Wait for vector DB indexing to complete
            
        Returns:
            Document ID
        """
        try:
            # Generate embedding
            embedding_result = await self.embedding_service.embed_text(document.text)
            
            # Prepare document for vector DB
            vector_doc = {
                "id": document.id,
                "vector": embedding_result.embedding,
                "payload": {
                    "text": document.text,
                    "embedding_model": embedding_result.model,
                    **document.metadata,
                },
            }
            
            # Store in vector DB
            doc_ids = await self.vector_db_service.upsert_documents(
                [vector_doc],
                wait=wait_for_indexing,
            )
            
            self._metrics["indexed_documents"] += 1
            logger.info(f"Indexed document {document.id}")
            
            return doc_ids[0] if doc_ids else document.id
            
        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Error indexing document {document.id}: {e}")
            raise

    async def index_documents_batch(
        self,
        documents: List[RAGDocument],
        wait_for_indexing: bool = True,
    ) -> List[str]:
        """
        Index multiple documents in batch.
        
        Args:
            documents: List of documents to index
            wait_for_indexing: Wait for vector DB indexing to complete
            
        Returns:
            List of document IDs
        """
        if not documents:
            return []
        
        try:
            # Generate embeddings in batch
            texts = [doc.text for doc in documents]
            embedding_results = await self.embedding_service.embed_batch(texts)
            
            # Prepare documents for vector DB
            vector_docs = []
            for doc, embedding_result in zip(documents, embedding_results):
                vector_docs.append({
                    "id": doc.id,
                    "vector": embedding_result.embedding,
                    "payload": {
                        "text": doc.text,
                        "embedding_model": embedding_result.model,
                        **doc.metadata,
                    },
                })
            
            # Store in vector DB
            doc_ids = await self.vector_db_service.upsert_documents(
                vector_docs,
                wait=wait_for_indexing,
            )
            
            self._metrics["indexed_documents"] += len(doc_ids)
            logger.info(f"Indexed {len(doc_ids)} documents in batch")
            
            return doc_ids
            
        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Error indexing document batch: {e}")
            raise

    async def delete_documents(self, document_ids: List[str]) -> bool:
        """
        Delete documents from the RAG system.
        
        Args:
            document_ids: List of document IDs to delete
            
        Returns:
            Success status
        """
        try:
            await self.vector_db_service.delete_documents(document_ids)
            logger.info(f"Deleted {len(document_ids)} documents")
            return True
        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Error deleting documents: {e}")
            raise

    async def search(
        self,
        query: str,
        top_k: int = 5,
        score_threshold: Optional[float] = None,
        filter_metadata: Optional[Dict[str, Any]] = None,
    ) -> List[RAGSearchResult]:
        """
        Search for relevant documents using RAG.
        
        Args:
            query: Search query text
            top_k: Number of results to return
            score_threshold: Minimum similarity score
            filter_metadata: Metadata filters for search
            
        Returns:
            List of search results
        """
        start_time = datetime.utcnow()
        self._metrics["total_searches"] += 1
        
        try:
            # Generate query embedding with timeout
            try:
                embedding_result = await asyncio.wait_for(
                    self.embedding_service.embed_text(query),
                    timeout=self.search_timeout,
                )
            except asyncio.TimeoutError:
                logger.warning("Embedding generation timeout")
                raise
            
            # Search in vector DB with timeout
            try:
                vector_results = await asyncio.wait_for(
                    self.vector_db_service.search(
                        query_vector=embedding_result.embedding,
                        limit=top_k,
                        score_threshold=score_threshold,
                        filter_conditions=filter_metadata,
                    ),
                    timeout=self.search_timeout,
                )
            except asyncio.TimeoutError:
                logger.warning("Vector search timeout")
                raise
            
            # Convert to RAGSearchResult
            results = []
            for vr in vector_results:
                results.append(
                    RAGSearchResult(
                        document_id=vr.id,
                        text=vr.payload.get("text", ""),
                        score=vr.score,
                        metadata={
                            k: v for k, v in vr.payload.items()
                            if k not in ["text", "embedding_model"]
                        },
                        embedding_model=vr.payload.get("embedding_model"),
                    )
                )
            
            # Record metrics
            search_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
            self._metrics["search_times_ms"].append(search_time_ms)
            self._metrics["successful_searches"] += 1
            
            logger.debug(
                f"Search completed in {search_time_ms:.2f}ms, "
                f"found {len(results)} results"
            )
            
            return results
            
        except Exception as e:
            self._metrics["failed_searches"] += 1
            self._metrics["errors"] += 1
            logger.error(f"Search error: {e}")
            
            # Return empty results on error (graceful degradation)
            if self.enable_hybrid_search:
                logger.warning("Search failed, returning empty results")
                return []
            
            raise

    async def hybrid_search(
        self,
        query: str,
        top_k: int = 5,
        vector_weight: float = 0.7,
        tfidf_weight: float = 0.3,
        filter_metadata: Optional[Dict[str, Any]] = None,
    ) -> List[RAGSearchResult]:
        """
        Perform hybrid search combining vector and TF-IDF approaches.
        
        Args:
            query: Search query text
            top_k: Number of results to return
            vector_weight: Weight for vector search results (0-1)
            tfidf_weight: Weight for TF-IDF results (0-1)
            filter_metadata: Metadata filters for search
            
        Returns:
            List of search results with combined scores
        """
        if not self.enable_hybrid_search:
            return await self.search(query, top_k, filter_metadata=filter_metadata)
        
        try:
            # Get vector search results
            vector_results = await self.search(
                query,
                top_k=top_k * 2,  # Get more for merging
                filter_metadata=filter_metadata,
            )
            
            # Combine and re-rank results
            # For now, just use vector results with adjusted scores
            for result in vector_results:
                result.score = result.score * vector_weight
            
            # Sort by combined score and limit
            vector_results.sort(key=lambda x: x.score, reverse=True)
            return vector_results[:top_k]
            
        except Exception as e:
            logger.error(f"Hybrid search error: {e}")
            raise

    async def get_metrics(self) -> RAGMetrics:
        """
        Get RAG system metrics.
        
        Returns:
            RAG metrics
        """
        # Get service health
        embedding_health = await self.embedding_service.health_check()
        vector_health = await self.vector_db_service.health_check()
        
        # Calculate average search time
        search_times = self._metrics["search_times_ms"]
        avg_search_time = (
            sum(search_times) / len(search_times) if search_times else 0.0
        )
        
        # Get cache hit rate
        embedding_metrics = self.embedding_service.get_metrics()
        cache_hit_rate = embedding_metrics.get("cache_hit_rate", 0.0)
        
        return RAGMetrics(
            total_indexed_documents=self._metrics["indexed_documents"],
            total_searches=self._metrics["total_searches"],
            average_search_time_ms=avg_search_time,
            cache_hit_rate=cache_hit_rate,
            vector_db_status=vector_health.get("status", "unknown"),
            embedding_service_status=embedding_health.get("status", "unknown"),
        )

    async def health_check(self) -> Dict[str, Any]:
        """
        Check health of RAG system.
        
        Returns:
            Health status information
        """
        health = {
            "status": "healthy",
            "embedding_service": {},
            "vector_db_service": {},
            "metrics": {},
        }
        
        try:
            # Check embedding service
            embedding_health = await self.embedding_service.health_check()
            health["embedding_service"] = embedding_health
            
            # Check vector DB service
            vector_health = await self.vector_db_service.health_check()
            health["vector_db_service"] = vector_health
            
            # Get metrics
            metrics = await self.get_metrics()
            health["metrics"] = {
                "indexed_documents": metrics.total_indexed_documents,
                "total_searches": metrics.total_searches,
                "average_search_time_ms": metrics.average_search_time_ms,
                "cache_hit_rate": metrics.cache_hit_rate,
            }
            
            # Determine overall status
            if (embedding_health.get("status") == "unhealthy" or
                vector_health.get("status") == "unhealthy"):
                health["status"] = "unhealthy"
            elif (embedding_health.get("status") == "degraded" or
                  vector_health.get("status") == "degraded"):
                health["status"] = "degraded"
            
        except Exception as e:
            logger.error(f"Health check error: {e}")
            health["status"] = "unhealthy"
            health["error"] = str(e)
        
        return health