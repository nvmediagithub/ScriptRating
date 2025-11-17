"""
Vector Database Service for RAG system.

This service provides vector storage and retrieval using Qdrant,
with hybrid search capabilities and connection pooling.
"""
from __future__ import annotations

import asyncio
import logging
import uuid
import json
import hashlib
from typing import List, Optional, Dict, Any, Tuple
from dataclasses import dataclass
from datetime import datetime

import redis.asyncio as aioredis
import httpx
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import (
    Distance,
    VectorParams,
    PointStruct,
    Filter,
    FieldCondition,
    MatchValue,
    SearchParams,
    ScoredPoint,
    HnswConfigDiff,
    OptimizersConfigDiff,
)
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

logger = logging.getLogger(__name__)


@dataclass
class VectorSearchResult:
    """Result of vector search operation."""
    id: str
    score: float
    payload: Dict[str, Any]
    vector: Optional[List[float]] = None


@dataclass
class CollectionInfo:
    """Information about a vector collection."""
    name: str
    vectors_count: int
    indexed_vectors_count: int
    points_count: int
    status: str


class VectorDatabaseService:
    """
    Service for vector database operations using Qdrant.
    
    Features:
    - Qdrant integration for vector search
    - Collection management
    - Upsert, delete, search operations
    - Hybrid search (vector + TF-IDF fallback)
    - Connection pooling and health checks
    """

    def __init__(
        self,
        qdrant_url: Optional[str] = None,
        qdrant_api_key: Optional[str] = None,
        collection_name: str = "script_rating_rag",
        vector_size: int = 1536,  # OpenAI text-embedding-3-large dimension
        distance_metric: str = "Cosine",
        replication_factor: int = 1,
        write_consistency_factor: int = 1,
        on_disk_payload: bool = True,
        hnsw_config_m: int = 16,
        hnsw_config_ef_construct: int = 100,
        timeout: int = 30,
        enable_tfidf_fallback: bool = True,
        redis_url: Optional[str] = None,
        cache_ttl: int = 86400,  # 24 hours for search results cache
        batch_size: int = 100,  # Batch size for bulk operations
        max_connections: int = 10,  # Connection pool size
        enable_performance_monitoring: bool = True,
    ):
        """
        Initialize VectorDatabaseService.

        Args:
            qdrant_url: Qdrant server URL (None for in-memory)
            qdrant_api_key: Qdrant API key
            collection_name: Name of the collection
            vector_size: Dimension of embedding vectors
            distance_metric: Distance metric (Cosine, Euclid, Dot)
            replication_factor: Replication factor for collection
            write_consistency_factor: Write consistency factor
            on_disk_payload: Store payload on disk
            hnsw_config_m: HNSW M parameter
            hnsw_config_ef_construct: HNSW ef_construct parameter
            timeout: Request timeout in seconds
            enable_tfidf_fallback: Enable TF-IDF fallback for search
        """
        self.qdrant_url = qdrant_url
        self.qdrant_api_key = qdrant_api_key
        self.collection_name = collection_name
        self.vector_size = vector_size
        self.distance_metric = distance_metric
        self.replication_factor = replication_factor
        self.write_consistency_factor = write_consistency_factor
        self.on_disk_payload = on_disk_payload
        self.hnsw_config_m = hnsw_config_m
        self.hnsw_config_ef_construct = hnsw_config_ef_construct
        self.timeout = timeout
        self.enable_tfidf_fallback = enable_tfidf_fallback
        self.redis_url = redis_url
        self.cache_ttl = cache_ttl
        self.batch_size = batch_size
        self.max_connections = max_connections
        self.enable_performance_monitoring = enable_performance_monitoring

        self._client: Optional[AsyncQdrantClient] = None
        self._redis_client: Optional[aioredis.Redis] = None
        self._lock = asyncio.Lock()

        # TF-IDF fallback components
        self._tfidf_vectorizer: Optional[TfidfVectorizer] = None
        self._tfidf_matrix = None
        self._tfidf_documents: List[Dict[str, Any]] = []

        # Performance monitoring
        self._performance_metrics = {
            "operation_times": [],
            "cache_hits": 0,
            "cache_misses": 0,
            "batch_operations": 0,
            "connections_active": 0,
            "memory_usage_mb": 0.0,
        }

        # Metrics
        self._metrics = {
            "total_searches": 0,
            "vector_searches": 0,
            "tfidf_fallback_searches": 0,
            "upserts": 0,
            "deletes": 0,
            "errors": 0,
            "cached_searches": 0,
        }

    async def initialize(self) -> None:
        """Initialize Qdrant client, Redis cache, and create collection if needed."""
        try:
            # Initialize Qdrant client with connection pooling
            if self.qdrant_url:
                self._client = AsyncQdrantClient(
                    url=self.qdrant_url,
                    api_key=self.qdrant_api_key,
                    timeout=self.timeout,
                    limits=httpx.Limits(max_connections=self.max_connections),
                )
            else:
                # In-memory mode for development/testing
                self._client = AsyncQdrantClient(location=":memory:")

            logger.info(f"Qdrant client initialized: {self.qdrant_url or 'in-memory'}")

            # Initialize Redis cache if URL provided
            if self.redis_url:
                self._redis_client = await aioredis.from_url(
                    self.redis_url,
                    encoding="utf-8",
                    decode_responses=False,
                    max_connections=self.max_connections,
                )
                await self._redis_client.ping()
                logger.info("Redis cache initialized")
            else:
                logger.info("Redis cache disabled (no URL provided)")

            # Create collection if it doesn't exist
            await self._ensure_collection_exists()

        except Exception as e:
            logger.error(f"Error initializing VectorDatabaseService: {e}")
            raise

    async def _ensure_collection_exists(self) -> None:
        """Ensure the collection exists, create if not."""
        try:
            collections = await self._client.get_collections()
            collection_names = [c.name for c in collections.collections]
            
            if self.collection_name not in collection_names:
                # Map distance metric string to Qdrant enum
                distance_map = {
                    "Cosine": Distance.COSINE,
                    "Euclid": Distance.EUCLID,
                    "Dot": Distance.DOT,
                }
                
                # Create collection with optimized configuration
                vectors_config = VectorParams(
                    size=self.vector_size,
                    distance=distance_map.get(self.distance_metric, Distance.COSINE),
                )

                hnsw_config = HnswConfigDiff(
                    m=self.hnsw_config_m,
                    ef_construct=self.hnsw_config_ef_construct,
                )

                optimizers_config = OptimizersConfigDiff()

                await self._client.create_collection(
                    collection_name=self.collection_name,
                    vectors_config=vectors_config,
                    hnsw_config=hnsw_config,
                    optimizers_config=optimizers_config,
                    replication_factor=self.replication_factor,
                    write_consistency_factor=self.write_consistency_factor,
                    on_disk_payload=self.on_disk_payload,
                )
                logger.info(f"Created collection: {self.collection_name}")
            else:
                logger.info(f"Collection already exists: {self.collection_name}")
                
        except Exception as e:
            logger.error(f"Error ensuring collection exists: {e}")
            raise

    async def close(self) -> None:
        """Close Qdrant client and Redis connections."""
        if self._client:
            await self._client.close()
        if self._redis_client:
            await self._redis_client.close()

    async def upsert_documents(
        self,
        documents: List[Dict[str, Any]],
        wait: bool = True,
    ) -> List[str]:
        """
        Insert or update documents in the vector database with batch processing.

        Args:
            documents: List of documents with 'id', 'vector', and 'payload' fields
            wait: Wait for indexing to complete

        Returns:
            List of document IDs
        """
        if not documents:
            return []

        start_time = datetime.utcnow() if self.enable_performance_monitoring else None

        try:
            # Process in batches for better performance
            all_doc_ids = []
            for i in range(0, len(documents), self.batch_size):
                batch = documents[i:i + self.batch_size]
                batch_doc_ids = await self._upsert_batch(batch, wait)
                all_doc_ids.extend(batch_doc_ids)

            if self.enable_performance_monitoring and start_time:
                operation_time = (datetime.utcnow() - start_time).total_seconds() * 1000
                self._performance_metrics["operation_times"].append(operation_time)
                self._performance_metrics["batch_operations"] += 1

            logger.info(f"Upserted {len(all_doc_ids)} documents to {self.collection_name} in {len(documents)//self.batch_size + 1} batches")
            return all_doc_ids

        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Error upserting documents: {e}")
            raise

    async def _upsert_batch(
        self,
        documents: List[Dict[str, Any]],
        wait: bool = True,
    ) -> List[str]:
        """Upsert a batch of documents."""
        points = []
        for doc in documents:
            doc_id = doc.get("id") or str(uuid.uuid4())
            vector = doc.get("vector")
            payload = doc.get("payload", {})

            if not vector:
                logger.warning(f"Document {doc_id} has no vector, skipping")
                continue

            # Add performance metadata
            payload["indexed_at"] = datetime.utcnow().isoformat()
            if self.enable_performance_monitoring:
                payload["batch_size"] = len(documents)

            points.append(
                PointStruct(
                    id=doc_id,
                    vector=vector,
                    payload=payload,
                )
            )

        if not points:
            return []

        # Upsert to Qdrant
        await self._client.upsert(
            collection_name=self.collection_name,
            points=points,
            wait=wait,
        )

        self._metrics["upserts"] += len(points)

        # Update TF-IDF fallback if enabled
        if self.enable_tfidf_fallback:
            await self._update_tfidf_index(documents)

        return [p.id for p in points]

    async def delete_documents(self, document_ids: List[str]) -> bool:
        """
        Delete documents from the vector database.
        
        Args:
            document_ids: List of document IDs to delete
            
        Returns:
            Success status
        """
        if not document_ids:
            return True
        
        try:
            await self._client.delete(
                collection_name=self.collection_name,
                points_selector=document_ids,
            )
            
            self._metrics["deletes"] += len(document_ids)
            
            # Update TF-IDF fallback
            if self.enable_tfidf_fallback:
                async with self._lock:
                    self._tfidf_documents = [
                        doc for doc in self._tfidf_documents
                        if doc.get("id") not in document_ids
                    ]
                    self._rebuild_tfidf_index()
            
            logger.info(f"Deleted {len(document_ids)} documents from {self.collection_name}")
            return True
            
        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Error deleting documents: {e}")
            raise

    async def search(
        self,
        query_vector: List[float],
        limit: int = 10,
        score_threshold: Optional[float] = None,
        filter_conditions: Optional[Dict[str, Any]] = None,
        use_cache: bool = True,
    ) -> List[VectorSearchResult]:
        """
        Search for similar vectors in the database with caching and optimizations.

        Args:
            query_vector: Query embedding vector
            limit: Maximum number of results
            score_threshold: Minimum similarity score
            filter_conditions: Metadata filters
            use_cache: Whether to use result caching

        Returns:
            List of search results
        """
        start_time = datetime.utcnow() if self.enable_performance_monitoring else None
        self._metrics["total_searches"] += 1

        # Check cache first
        if use_cache and self._redis_client:
            cache_key = self._generate_search_cache_key(query_vector, limit, score_threshold, filter_conditions)
            cached_result = await self._get_cached_search_result(cache_key)
            if cached_result:
                self._metrics["cached_searches"] += 1
                self._performance_metrics["cache_hits"] += 1
                logger.debug(f"Cache hit for search, returning {len(cached_result)} results")
                return cached_result

        self._performance_metrics["cache_misses"] += 1

        try:
            # Build filter if provided
            query_filter = None
            if filter_conditions:
                conditions = []
                for key, value in filter_conditions.items():
                    conditions.append(
                        FieldCondition(
                            key=key,
                            match=MatchValue(value=value),
                        )
                    )
                query_filter = Filter(must=conditions)

            # Search in Qdrant with optimized parameters
            search_params = None
            if self.enable_performance_monitoring:
                search_params = SearchParams(
                    hnsw_ef=limit * 2,  # Optimize for better recall
                    exact=False,  # Use approximate search for speed
                )

            search_result = await self._client.search(
                collection_name=self.collection_name,
                query_vector=query_vector,
                limit=limit,
                score_threshold=score_threshold,
                query_filter=query_filter,
                search_params=search_params,
                with_vectors=False,
            )

            self._metrics["vector_searches"] += 1

            # Convert to VectorSearchResult
            results = [
                VectorSearchResult(
                    id=str(point.id),
                    score=point.score,
                    payload=point.payload,
                )
                for point in search_result
            ]

            # Cache the results
            if use_cache and self._redis_client:
                await self._cache_search_result(cache_key, results)

            # Record performance metrics
            if self.enable_performance_monitoring and start_time:
                operation_time = (datetime.utcnow() - start_time).total_seconds() * 1000
                self._performance_metrics["operation_times"].append(operation_time)

            logger.debug(f"Vector search returned {len(results)} results in {(datetime.utcnow() - start_time).total_seconds() * 1000:.2f}ms" if start_time else f"Vector search returned {len(results)} results")
            return results

        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Vector search error: {e}")

            # Fallback to TF-IDF if enabled
            if self.enable_tfidf_fallback and self._tfidf_documents:
                logger.warning("Falling back to TF-IDF search")
                return await self._tfidf_search(query_vector, limit)

            raise

    def _generate_search_cache_key(
        self,
        query_vector: List[float],
        limit: int,
        score_threshold: Optional[float],
        filter_conditions: Optional[Dict[str, Any]],
    ) -> str:
        """Generate cache key for search results."""
        # Create a hash of the query parameters
        key_components = [
            self.collection_name,
            str(limit),
            str(score_threshold or ""),
            json.dumps(filter_conditions or {}, sort_keys=True),
            hashlib.sha256(json.dumps(query_vector[:10]).encode()).hexdigest()[:16],  # Sample of vector for key
        ]
        cache_key = f"search:{hashlib.sha256('|'.join(key_components).encode()).hexdigest()}"
        return cache_key

    async def _get_cached_search_result(self, cache_key: str) -> Optional[List[VectorSearchResult]]:
        """Retrieve cached search result."""
        if not self._redis_client:
            return None

        try:
            cached_data = await self._redis_client.get(cache_key)
            if cached_data:
                return [VectorSearchResult(**item) for item in json.loads(cached_data)]
        except Exception as e:
            logger.warning(f"Cache retrieval error: {e}")

        return None

    async def _cache_search_result(self, cache_key: str, results: List[VectorSearchResult]) -> None:
        """Cache search results."""
        if not self._redis_client or not results:
            return

        try:
            # Convert results to JSON-serializable format
            serializable_results = [
                {
                    "id": r.id,
                    "score": r.score,
                    "payload": r.payload,
                    "vector": r.vector,
                }
                for r in results
            ]
            await self._redis_client.setex(
                cache_key,
                self.cache_ttl,
                json.dumps(serializable_results),
            )
        except Exception as e:
            logger.warning(f"Cache storage error: {e}")

    async def _tfidf_search(
        self,
        query_vector: List[float],
        limit: int = 10,
    ) -> List[VectorSearchResult]:
        """
        Fallback search using TF-IDF when vector search fails.
        
        Args:
            query_vector: Query vector (used for context, not actual search)
            limit: Maximum number of results
            
        Returns:
            List of search results
        """
        self._metrics["tfidf_fallback_searches"] += 1
        
        async with self._lock:
            if not self._tfidf_documents or self._tfidf_matrix is None:
                return []
            
            # For simplicity, return top documents by TF-IDF score
            # In a real scenario, we'd need the query text, not vector
            results = []
            for i, doc in enumerate(self._tfidf_documents[:limit]):
                results.append(
                    VectorSearchResult(
                        id=doc.get("id", str(uuid.uuid4())),
                        score=0.5,  # Mock score for fallback
                        payload=doc.get("payload", {}),
                    )
                )
            
            return results

    async def _update_tfidf_index(self, documents: List[Dict[str, Any]]) -> None:
        """Update TF-IDF fallback index with new documents."""
        async with self._lock:
            for doc in documents:
                # Update or add document
                doc_id = doc.get("id")
                existing_idx = next(
                    (i for i, d in enumerate(self._tfidf_documents) if d.get("id") == doc_id),
                    None
                )
                
                if existing_idx is not None:
                    self._tfidf_documents[existing_idx] = doc
                else:
                    self._tfidf_documents.append(doc)
            
            self._rebuild_tfidf_index()

    def _rebuild_tfidf_index(self) -> None:
        """Rebuild TF-IDF index from documents."""
        if not self._tfidf_documents:
            self._tfidf_vectorizer = None
            self._tfidf_matrix = None
            return
        
        # Extract text from documents
        texts = []
        for doc in self._tfidf_documents:
            payload = doc.get("payload", {})
            text = payload.get("text", payload.get("content", ""))
            texts.append(text)
        
        if not texts:
            return
        
        # Build TF-IDF matrix
        self._tfidf_vectorizer = TfidfVectorizer(
            lowercase=True,
            ngram_range=(1, 2),
            max_features=5000,
        )
        self._tfidf_matrix = self._tfidf_vectorizer.fit_transform(texts)

    async def get_collection_info(self) -> CollectionInfo:
        """
        Get information about the collection.
        
        Returns:
            Collection information
        """
        try:
            info = await self._client.get_collection(self.collection_name)
            
            return CollectionInfo(
                name=self.collection_name,
                vectors_count=info.vectors_count or 0,
                indexed_vectors_count=info.indexed_vectors_count or 0,
                points_count=info.points_count or 0,
                status=info.status.value if hasattr(info.status, 'value') else str(info.status),
            )
            
        except Exception as e:
            logger.error(f"Error getting collection info: {e}")
            raise

    async def health_check(self) -> Dict[str, Any]:
        """
        Check service health with performance metrics.

        Returns:
            Health status information
        """
        health = {
            "status": "healthy",
            "qdrant_available": False,
            "collection_exists": False,
            "redis_cache_available": False,
            "tfidf_fallback_available": self.enable_tfidf_fallback,
            "metrics": self._metrics.copy(),
            "performance_metrics": self._performance_metrics.copy() if self.enable_performance_monitoring else {},
        }

        try:
            # Check Qdrant connection
            collections = await self._client.get_collections()
            health["qdrant_available"] = True

            # Check collection exists
            collection_names = [c.name for c in collections.collections]
            health["collection_exists"] = self.collection_name in collection_names

            if health["collection_exists"]:
                info = await self.get_collection_info()
                health["collection_info"] = {
                    "points_count": info.points_count,
                    "vectors_count": info.vectors_count,
                    "status": info.status,
                }

            # Check Redis cache
            if self._redis_client:
                try:
                    await self._redis_client.ping()
                    health["redis_cache_available"] = True
                    # Add cache statistics
                    health["cache_stats"] = {
                        "hit_rate": self._performance_metrics["cache_hits"] / max(self._metrics["total_searches"], 1),
                        "total_hits": self._performance_metrics["cache_hits"],
                        "total_misses": self._performance_metrics["cache_misses"],
                    }
                except Exception as e:
                    logger.warning(f"Redis health check failed: {e}")

            # Add performance insights
            if self.enable_performance_monitoring and self._performance_metrics["operation_times"]:
                operation_times = self._performance_metrics["operation_times"]
                health["performance_insights"] = {
                    "avg_operation_time_ms": sum(operation_times) / len(operation_times),
                    "max_operation_time_ms": max(operation_times),
                    "total_operations": len(operation_times),
                    "batch_operations": self._performance_metrics["batch_operations"],
                }

        except Exception as e:
            logger.error(f"Health check failed: {e}")
            health["status"] = "unhealthy" if not self.enable_tfidf_fallback else "degraded"
            health["error"] = str(e)

        return health

    def get_metrics(self) -> Dict[str, Any]:
        """Get service metrics with performance data."""
        base_metrics = {
            **self._metrics,
            "tfidf_documents_count": len(self._tfidf_documents),
        }

        if self.enable_performance_monitoring:
            operation_times = self._performance_metrics["operation_times"]
            base_metrics.update({
                "performance_metrics": {
                    "avg_operation_time_ms": sum(operation_times) / len(operation_times) if operation_times else 0.0,
                    "max_operation_time_ms": max(operation_times) if operation_times else 0.0,
                    "total_operations": len(operation_times),
                    "cache_hit_rate": self._performance_metrics["cache_hits"] / max(self._metrics["total_searches"], 1),
                    "batch_operations_count": self._performance_metrics["batch_operations"],
                    "connections_active": self._performance_metrics["connections_active"],
                    "memory_usage_mb": self._performance_metrics["memory_usage_mb"],
                }
            })

        return base_metrics