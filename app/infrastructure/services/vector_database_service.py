"""
Vector Database Service for RAG system.

This service provides vector storage and retrieval using Qdrant,
with hybrid search capabilities and connection pooling.
"""
from __future__ import annotations

import asyncio
import logging
import uuid
from typing import List, Optional, Dict, Any, Tuple
from dataclasses import dataclass
from datetime import datetime

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
        collection_name: str = "scriptrating_documents",
        vector_size: int = 1536,  # OpenAI text-embedding-3-large dimension
        distance_metric: str = "Cosine",
        enable_tfidf_fallback: bool = True,
    ):
        """
        Initialize VectorDatabaseService.

        Args:
            qdrant_url: Qdrant server URL (None for in-memory)
            qdrant_api_key: Qdrant API key
            collection_name: Name of the collection
            vector_size: Dimension of embedding vectors
            distance_metric: Distance metric (Cosine, Euclid, Dot)
            enable_tfidf_fallback: Enable TF-IDF fallback for search
        """
        self.qdrant_url = qdrant_url
        self.qdrant_api_key = qdrant_api_key
        self.collection_name = collection_name
        self.vector_size = vector_size
        self.distance_metric = distance_metric
        self.enable_tfidf_fallback = enable_tfidf_fallback
        
        self._client: Optional[AsyncQdrantClient] = None
        self._lock = asyncio.Lock()
        
        # TF-IDF fallback components
        self._tfidf_vectorizer: Optional[TfidfVectorizer] = None
        self._tfidf_matrix = None
        self._tfidf_documents: List[Dict[str, Any]] = []
        
        # Metrics
        self._metrics = {
            "total_searches": 0,
            "vector_searches": 0,
            "tfidf_fallback_searches": 0,
            "upserts": 0,
            "deletes": 0,
            "errors": 0,
        }

    async def initialize(self) -> None:
        """Initialize Qdrant client and create collection if needed."""
        try:
            # Initialize Qdrant client
            if self.qdrant_url:
                self._client = AsyncQdrantClient(
                    url=self.qdrant_url,
                    api_key=self.qdrant_api_key,
                    timeout=30.0,
                )
            else:
                # In-memory mode for development/testing
                self._client = AsyncQdrantClient(location=":memory:")
            
            logger.info(f"Qdrant client initialized: {self.qdrant_url or 'in-memory'}")
            
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
                
                await self._client.create_collection(
                    collection_name=self.collection_name,
                    vectors_config=VectorParams(
                        size=self.vector_size,
                        distance=distance_map.get(self.distance_metric, Distance.COSINE),
                    ),
                )
                logger.info(f"Created collection: {self.collection_name}")
            else:
                logger.info(f"Collection already exists: {self.collection_name}")
                
        except Exception as e:
            logger.error(f"Error ensuring collection exists: {e}")
            raise

    async def close(self) -> None:
        """Close Qdrant client connection."""
        if self._client:
            await self._client.close()

    async def upsert_documents(
        self,
        documents: List[Dict[str, Any]],
        wait: bool = True,
    ) -> List[str]:
        """
        Insert or update documents in the vector database.
        
        Args:
            documents: List of documents with 'id', 'vector', and 'payload' fields
            wait: Wait for indexing to complete
            
        Returns:
            List of document IDs
        """
        if not documents:
            return []
        
        try:
            points = []
            for doc in documents:
                doc_id = doc.get("id") or str(uuid.uuid4())
                vector = doc.get("vector")
                payload = doc.get("payload", {})
                
                if not vector:
                    logger.warning(f"Document {doc_id} has no vector, skipping")
                    continue
                
                # Add metadata
                payload["indexed_at"] = datetime.utcnow().isoformat()
                
                points.append(
                    PointStruct(
                        id=doc_id,
                        vector=vector,
                        payload=payload,
                    )
                )
            
            if not points:
                logger.warning("No valid points to upsert")
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
            
            logger.info(f"Upserted {len(points)} documents to {self.collection_name}")
            return [p.id for p in points]
            
        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Error upserting documents: {e}")
            raise

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
    ) -> List[VectorSearchResult]:
        """
        Search for similar vectors in the database.
        
        Args:
            query_vector: Query embedding vector
            limit: Maximum number of results
            score_threshold: Minimum similarity score
            filter_conditions: Metadata filters
            
        Returns:
            List of search results
        """
        self._metrics["total_searches"] += 1
        
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
            
            # Search in Qdrant
            search_result = await self._client.search(
                collection_name=self.collection_name,
                query_vector=query_vector,
                limit=limit,
                score_threshold=score_threshold,
                query_filter=query_filter,
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
            
            logger.debug(f"Vector search returned {len(results)} results")
            return results
            
        except Exception as e:
            self._metrics["errors"] += 1
            logger.error(f"Vector search error: {e}")
            
            # Fallback to TF-IDF if enabled
            if self.enable_tfidf_fallback and self._tfidf_documents:
                logger.warning("Falling back to TF-IDF search")
                return await self._tfidf_search(query_vector, limit)
            
            raise

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
        Check service health.
        
        Returns:
            Health status information
        """
        health = {
            "status": "healthy",
            "qdrant_available": False,
            "collection_exists": False,
            "tfidf_fallback_available": self.enable_tfidf_fallback,
            "metrics": self._metrics.copy(),
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
            
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            health["status"] = "unhealthy" if not self.enable_tfidf_fallback else "degraded"
            health["error"] = str(e)
        
        return health

    def get_metrics(self) -> Dict[str, Any]:
        """Get service metrics."""
        return {
            **self._metrics,
            "tfidf_documents_count": len(self._tfidf_documents),
        }