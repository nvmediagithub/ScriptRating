"""
RAG Orchestrator domain service with performance optimizations.

This service coordinates between embedding and vector database services
to provide high-level RAG operations with caching, batch processing, and query optimization.
"""
from __future__ import annotations

import asyncio
import logging
import re
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
from datetime import datetime
import heapq

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
class RAGIndexingResult:
    """Detailed result of RAG document indexing operation."""
    total_chunks: int
    chunks_processed: int
    embedding_generation_status: str  # "success", "failed", "partial"
    embedding_model_used: Optional[str]
    vector_db_indexing_status: str  # "success", "failed", "partial"
    documents_indexed: int
    indexing_time_ms: float
    processing_errors: List[str]
    document_ids: List[str]


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
        enable_query_expansion: bool = True,
        enable_result_reranking: bool = True,
        max_query_expansions: int = 3,
        batch_indexing_size: int = 50,
        cache_embeddings: bool = True,
    ):
        """
        Initialize RAGOrchestrator with performance optimizations.

        Args:
            embedding_service: Service for generating embeddings
            vector_db_service: Service for vector storage/search
            enable_hybrid_search: Enable hybrid search with fallbacks
            search_timeout: Timeout for search operations in seconds
            enable_query_expansion: Enable automatic query expansion
            enable_result_reranking: Enable result re-ranking
            max_query_expansions: Maximum number of query expansions
            batch_indexing_size: Batch size for document indexing
            cache_embeddings: Enable embedding caching
        """
        self.embedding_service = embedding_service
        self.vector_db_service = vector_db_service
        self.enable_hybrid_search = enable_hybrid_search
        self.search_timeout = search_timeout
        self.enable_query_expansion = enable_query_expansion
        self.enable_result_reranking = enable_result_reranking
        self.max_query_expansions = max_query_expansions
        self.batch_indexing_size = batch_indexing_size
        self.cache_embeddings = cache_embeddings

        self._lock = asyncio.Lock()

        # Query expansion terms for common concepts
        self._query_expansion_terms = {
            "ai": ["artificial intelligence", "machine learning", "neural networks", "deep learning"],
            "ml": ["machine learning", "algorithms", "data science", "statistics"],
            "data": ["information", "dataset", "database", "analytics"],
            "script": ["screenplay", "manuscript", "story", "narrative"],
            "rating": ["evaluation", "assessment", "classification", "analysis"],
        }

        # Metrics
        self._metrics = {
            "indexed_documents": 0,
            "total_searches": 0,
            "successful_searches": 0,
            "failed_searches": 0,
            "search_times_ms": [],
            "query_expansions_used": 0,
            "reranking_applied": 0,
            "cache_hits": 0,
            "cache_misses": 0,
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
    ) -> RAGIndexingResult:
        """
        Index multiple documents in optimized batches with detailed result reporting.

        Args:
            documents: List of documents to index
            wait_for_indexing: Wait for vector DB indexing to complete

        Returns:
            Detailed indexing result with processing information
        """
        if not documents:
            return RAGIndexingResult(
                total_chunks=0,
                chunks_processed=0,
                embedding_generation_status="success",
                embedding_model_used=None,
                vector_db_indexing_status="success",
                documents_indexed=0,
                indexing_time_ms=0.0,
                processing_errors=[],
                document_ids=[],
            )

        start_time = datetime.utcnow()
        processing_errors = []
        total_chunks = len(documents)
        chunks_processed = 0
        all_doc_ids = []

        try:
            # Process in optimized batches
            for i in range(0, len(documents), self.batch_indexing_size):
                batch = documents[i:i + self.batch_indexing_size]
                try:
                    batch_doc_ids = await self._index_batch(batch, wait_for_indexing)
                    all_doc_ids.extend(batch_doc_ids)
                    chunks_processed += len(batch)
                except Exception as e:
                    error_msg = f"Failed to index batch {i//self.batch_indexing_size + 1}: {str(e)}"
                    processing_errors.append(error_msg)
                    logger.warning(error_msg)

            indexing_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000

            # Determine overall status
            embedding_status = "success" if not processing_errors else ("partial" if chunks_processed > 0 else "failed")
            vector_status = "success" if not processing_errors else ("partial" if chunks_processed > 0 else "failed")

            # Get embedding model used (from the first successful batch)
            embedding_model_used = None
            if chunks_processed > 0:
                try:
                    # Try to get model info from embedding service
                    embedding_health = await self.embedding_service.health_check()
                    embedding_model_used = embedding_health.get("model", None)
                except Exception:
                    pass

            result = RAGIndexingResult(
                total_chunks=total_chunks,
                chunks_processed=chunks_processed,
                embedding_generation_status=embedding_status,
                embedding_model_used=embedding_model_used,
                vector_db_indexing_status=vector_status,
                documents_indexed=len(all_doc_ids),
                indexing_time_ms=indexing_time_ms,
                processing_errors=processing_errors,
                document_ids=all_doc_ids,
            )

            logger.info(
                f"Indexed {len(all_doc_ids)}/{total_chunks} documents in {len(documents)//self.batch_indexing_size + 1} batches "
                f"({indexing_time_ms:.2f}ms)"
            )
            return result

        except Exception as e:
            self._metrics["errors"] += 1
            indexing_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
            error_msg = f"Fatal error during batch indexing: {str(e)}"

            result = RAGIndexingResult(
                total_chunks=total_chunks,
                chunks_processed=chunks_processed,
                embedding_generation_status="failed",
                embedding_model_used=None,
                vector_db_indexing_status="failed",
                documents_indexed=len(all_doc_ids),
                indexing_time_ms=indexing_time_ms,
                processing_errors=[error_msg] + processing_errors,
                document_ids=all_doc_ids,
            )

            logger.error(error_msg)
            return result

    async def _index_batch(
        self,
        documents: List[RAGDocument],
        wait_for_indexing: bool = True,
    ) -> List[str]:
        """Index a batch of documents with optimizations."""
        # Generate embeddings in batch with caching
        texts = [doc.text for doc in documents]
        embedding_results = await self.embedding_service.embed_batch(texts)

        # Prepare documents for vector DB with performance metadata
        vector_docs = []
        for doc, embedding_result in zip(documents, embedding_results):
            vector_docs.append({
                "id": doc.id,
                "vector": embedding_result.embedding,
                "payload": {
                    "text": doc.text,
                    "embedding_model": embedding_result.model,
                    "batch_indexed": True,
                    "batch_size": len(documents),
                    "indexed_at": datetime.utcnow().isoformat(),
                    **doc.metadata,
                },
            })

        # Store in vector DB with batch processing
        doc_ids = await self.vector_db_service.upsert_documents(
            vector_docs,
            wait=wait_for_indexing,
        )

        self._metrics["indexed_documents"] += len(doc_ids)
        return doc_ids

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
        use_cache: bool = True,
    ) -> List[RAGSearchResult]:
        """
        Search for relevant documents using RAG with query optimization.

        Args:
            query: Search query text
            top_k: Number of results to return
            score_threshold: Minimum similarity score
            filter_metadata: Metadata filters for search
            use_cache: Whether to use result caching

        Returns:
            List of search results
        """
        start_time = datetime.utcnow()
        self._metrics["total_searches"] += 1

        try:
            # Apply query expansion if enabled
            expanded_queries = [query]
            if self.enable_query_expansion:
                expanded_queries.extend(self._expand_query(query))
                self._metrics["query_expansions_used"] += len(expanded_queries) - 1

            # Generate embeddings for all query variations
            all_results = []
            for q in expanded_queries[:self.max_query_expansions + 1]:  # Include original + expansions
                try:
                    embedding_result = await asyncio.wait_for(
                        self.embedding_service.embed_text(q),
                        timeout=self.search_timeout,
                    )

                    # Search in vector DB
                    vector_results = await asyncio.wait_for(
                        self.vector_db_service.search(
                            query_vector=embedding_result.embedding,
                            limit=top_k * 2,  # Get more for re-ranking
                            score_threshold=score_threshold,
                            filter_conditions=filter_metadata,
                            use_cache=use_cache,
                        ),
                        timeout=self.search_timeout,
                    )

                    # Convert and collect results
                    for vr in vector_results:
                        result = RAGSearchResult(
                            document_id=vr.id,
                            text=vr.payload.get("text", ""),
                            score=vr.score,
                            metadata={
                                k: v for k, v in vr.payload.items()
                                if k not in ["text", "embedding_model"]
                            },
                            embedding_model=vr.payload.get("embedding_model"),
                        )
                        # Add query expansion info
                        if q != query:
                            result.metadata["query_expansion"] = q
                            result.score *= 0.95  # Slight penalty for expanded queries

                        all_results.append(result)

                except asyncio.TimeoutError:
                    logger.warning(f"Timeout for query variation: {q}")
                    continue

            # Apply result re-ranking if enabled
            if self.enable_result_reranking and all_results:
                all_results = self._rerank_results(all_results, query)
                self._metrics["reranking_applied"] += 1

            # Remove duplicates and limit results
            seen_ids = set()
            unique_results = []
            for result in all_results:
                if result.document_id not in seen_ids:
                    seen_ids.add(result.document_id)
                    unique_results.append(result)
                    if len(unique_results) >= top_k:
                        break

            # Record metrics
            search_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
            self._metrics["search_times_ms"].append(search_time_ms)
            self._metrics["successful_searches"] += 1

            logger.debug(
                f"Search completed in {search_time_ms:.2f}ms, "
                f"found {len(unique_results)} results "
                f"(expanded: {len(expanded_queries)-1}, reranked: {self.enable_result_reranking})"
            )

            return unique_results

        except Exception as e:
            self._metrics["failed_searches"] += 1
            self._metrics["errors"] += 1
            logger.error(f"Search error: {e}")

            # Return empty results on error (graceful degradation)
            if self.enable_hybrid_search:
                logger.warning("Search failed, returning empty results")
                return []

            raise

    def _expand_query(self, query: str) -> List[str]:
        """Expand query with related terms for better recall."""
        expanded = []
        query_lower = query.lower()

        # Check for expansion terms
        for key, terms in self._query_expansion_terms.items():
            if key in query_lower:
                # Add related terms that aren't already in the query
                for term in terms:
                    if term not in query_lower:
                        expanded_query = f"{query} {term}"
                        expanded.append(expanded_query)
                        if len(expanded) >= 2:  # Limit expansions per key
                            break
                if len(expanded) >= self.max_query_expansions:
                    break

        return expanded[:self.max_query_expansions]

    def _rerank_results(self, results: List[RAGSearchResult], original_query: str) -> List[RAGSearchResult]:
        """Re-rank results based on relevance to original query."""
        if not results:
            return results

        query_words = set(re.findall(r'\b\w+\b', original_query.lower()))

        for result in results:
            text_words = set(re.findall(r'\b\w+\b', result.text.lower()))
            metadata_words = set()
            for key, value in result.metadata.items():
                if isinstance(value, str):
                    metadata_words.update(re.findall(r'\b\w+\b', value.lower()))

            # Calculate word overlap score
            text_overlap = len(query_words & text_words)
            metadata_overlap = len(query_words & metadata_words)

            # Boost score for results with more query term matches
            relevance_boost = (text_overlap * 0.1) + (metadata_overlap * 0.05)

            # Boost score for results that contain important terms
            important_terms = {'script', 'rating', 'analysis', 'content', 'review'}
            important_matches = len(query_words & important_terms)
            result.score += relevance_boost + (important_matches * 0.02)

        # Re-sort by adjusted scores
        results.sort(key=lambda x: x.score, reverse=True)
        return results

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
            # Get vector search results with optimizations
            vector_results = await self.search(
                query,
                top_k=top_k * 3,  # Get more for better hybrid combining
                filter_metadata=filter_metadata,
            )

            # Apply hybrid scoring
            scored_results = []
            for result in vector_results:
                # Primary score from vector search
                vector_score = result.score * vector_weight

                # Secondary score from text matching (TF-IDF style)
                query_words = set(re.findall(r'\b\w+\b', query.lower()))
                text_words = set(re.findall(r'\b\w+\b', result.text.lower()))

                # Calculate simple TF-IDF-like score
                tfidf_score = len(query_words & text_words) / len(query_words) if query_words else 0
                tfidf_score *= tfidf_weight

                # Combine scores
                combined_score = vector_score + tfidf_score

                # Create new result with combined score
                combined_result = RAGSearchResult(
                    document_id=result.document_id,
                    text=result.text,
                    score=combined_score,
                    metadata={**result.metadata, "vector_score": vector_score, "tfidf_score": tfidf_score},
                    embedding_model=result.embedding_model,
                )
                scored_results.append(combined_result)

            # Sort by combined score and limit
            scored_results.sort(key=lambda x: x.score, reverse=True)
            return scored_results[:top_k]

        except Exception as e:
            logger.error(f"Hybrid search error: {e}")
            raise

    async def get_metrics(self) -> RAGMetrics:
        """
        Get RAG system metrics with performance data.

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

        # Get combined cache hit rate
        embedding_metrics = self.embedding_service.get_metrics()
        vector_metrics = self.vector_db_service.get_metrics()

        embedding_cache_hit_rate = embedding_metrics.get("cache_hit_rate", 0.0)
        vector_cache_hit_rate = vector_metrics.get("performance_metrics", {}).get("cache_hit_rate", 0.0)
        combined_cache_hit_rate = (embedding_cache_hit_rate + vector_cache_hit_rate) / 2

        return RAGMetrics(
            total_indexed_documents=self._metrics["indexed_documents"],
            total_searches=self._metrics["total_searches"],
            average_search_time_ms=avg_search_time,
            cache_hit_rate=combined_cache_hit_rate,
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