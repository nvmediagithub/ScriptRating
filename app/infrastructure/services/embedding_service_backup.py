"""
Embedding Service for RAG system.

This service provides text embedding generation with OpenAI integration,
Redis caching, and fallback to local models.
"""
from __future__ import annotations

import asyncio
import hashlib
import logging
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
import json

import httpx
import redis.asyncio as aioredis
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
)

logger = logging.getLogger(__name__)


@dataclass
class EmbeddingResult:
    """Result of embedding operation."""
    text: str
    embedding: List[float]
    model: str
    cached: bool = False
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


class EmbeddingService:
    """
    Service for generating text embeddings.
    
    Features:
    - OpenAI text-embedding-3-large integration
    - Batch processing support
    - Redis caching for performance
    - Fallback to local models on failures
    - Async operations for scalability
    """

    def __init__(
        self,
        openai_api_key: Optional[str] = None,
        redis_url: Optional[str] = None,
        model: str = "text-embedding-3-large",
        cache_ttl: int = 86400 * 7,  # 7 days
        batch_size: int = 100,
        enable_fallback: bool = True,
    ):
        """
        Initialize EmbeddingService.

        Args:
            openai_api_key: OpenAI API key
            redis_url: Redis connection URL
            model: OpenAI embedding model name
            cache_ttl: Cache TTL in seconds
            batch_size: Maximum batch size for embeddings
            enable_fallback: Enable fallback to local models
        """
        self.openai_api_key = openai_api_key
        self.redis_url = redis_url
        self.model = model
        self.cache_ttl = cache_ttl
        self.batch_size = batch_size
        self.enable_fallback = enable_fallback
        
        self._redis_client: Optional[aioredis.Redis] = None
        self._http_client: Optional[httpx.AsyncClient] = None
        self._fallback_model = None
        self._lock = asyncio.Lock()
        
        # Metrics
        self._metrics = {
            "total_requests": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "openai_calls": 0,
            "fallback_calls": 0,
            "errors": 0,
        }

    async def initialize(self) -> None:
        """Initialize service connections."""
        try:
            # Initialize Redis if URL provided
            if self.redis_url:
                self._redis_client = await aioredis.from_url(
                    self.redis_url,
                    encoding="utf-8",
                    decode_responses=False,
                )
                await self._redis_client.ping()
                logger.info("Redis connection established for embedding cache")
            
            # Initialize HTTP client for OpenAI
            if self.openai_api_key:
                self._http_client = httpx.AsyncClient(
                    base_url="https://api.openai.com/v1",
                    headers={
                        "Authorization": f"Bearer {self.openai_api_key}",
                        "Content-Type": "application/json",
                    },
                    timeout=30.0,
                )
                logger.info(f"OpenAI client initialized with model: {self.model}")
            
            # Initialize fallback model if enabled
            if self.enable_fallback:
                await self._initialize_fallback_model()
                
        except Exception as e:
            logger.error(f"Error initializing EmbeddingService: {e}")
            raise

    async def _initialize_fallback_model(self) -> None:
        """Initialize local fallback model."""
        try:
            from sentence_transformers import SentenceTransformer
            
            # Use a lightweight model as fallback
            self._fallback_model = SentenceTransformer(
                "all-MiniLM-L6-v2",
                device="cpu"
            )
            logger.info("Fallback embedding model initialized")
        except ImportError:
            logger.warning(
                "sentence-transformers not installed, fallback disabled"
            )
            self.enable_fallback = False
        except Exception as e:
            logger.error(f"Error initializing fallback model: {e}")
            self.enable_fallback = False

    async def close(self) -> None:
        """Close service connections."""
        if self._redis_client:
            await self._redis_client.close()
        if self._http_client:
            await self._http_client.aclose()

    def _generate_cache_key(self, text: str, model: str) -> str:
        """Generate cache key for text and model."""
        content = f"{model}:{text}"
        return f"embedding:{hashlib.sha256(content.encode()).hexdigest()}"

    async def _get_from_cache(self, text: str) -> Optional[List[float]]:
        """Retrieve embedding from cache."""
        if not self._redis_client:
            return None
        
        try:
            cache_key = self._generate_cache_key(text, self.model)
            cached_data = await self._redis_client.get(cache_key)
            
            if cached_data:
                self._metrics["cache_hits"] += 1
                return json.loads(cached_data)
            
            self._metrics["cache_misses"] += 1
            return None
            
        except Exception as e:
            logger.warning(f"Cache retrieval error: {e}")
            return None

    async def _store_in_cache(self, text: str, embedding: List[float]) -> None:
        """Store embedding in cache."""
        if not self._redis_client:
            return
        
        try:
            cache_key = self._generate_cache_key(text, self.model)
            await self._redis_client.setex(
                cache_key,
                self.cache_ttl,
                json.dumps(embedding),
            )
        except Exception as e:
            logger.warning(f"Cache storage error: {e}")

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type((httpx.TimeoutException, httpx.NetworkError)),
    )
    async def _generate_openai_embedding(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings using OpenAI API.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        if not self._http_client or not self.openai_api_key:
            raise ValueError("OpenAI client not initialized")
        
        try:
            response = await self._http_client.post(
                "/embeddings",
                json={
                    "model": self.model,
                    "input": texts,
                    "encoding_format": "float",
                },
            )
            response.raise_for_status()
            
            data = response.json()
            embeddings = [item["embedding"] for item in data["data"]]
            
            self._metrics["openai_calls"] += 1
            return embeddings
            
        except httpx.HTTPStatusError as e:
            logger.error(f"OpenAI API error: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Error generating OpenAI embeddings: {e}")
            raise

    async def _generate_fallback_embedding(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings using local fallback model.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        if not self._fallback_model:
            raise ValueError("Fallback model not initialized")
        
        try:
            # Run in thread pool to avoid blocking
            loop = asyncio.get_event_loop()
            embeddings = await loop.run_in_executor(
                None,
                self._fallback_model.encode,
                texts,
            )
            
            self._metrics["fallback_calls"] += 1
            return embeddings.tolist()
            
        except Exception as e:
            logger.error(f"Error generating fallback embeddings: {e}")
            raise

    async def embed_text(self, text: str) -> EmbeddingResult:
        """
        Generate embedding for a single text.
        
        Args:
            text: Text to embed
            
        Returns:
            EmbeddingResult with embedding vector
        """
        self._metrics["total_requests"] += 1
        
        # Check cache first
        cached_embedding = await self._get_from_cache(text)
        if cached_embedding:
            return EmbeddingResult(
                text=text,
                embedding=cached_embedding,
                model=self.model,
                cached=True,
            )
        
        # Generate new embedding
        try:
            embeddings = await self._generate_openai_embedding([text])
            embedding = embeddings[0]
            model_used = self.model
            
        except Exception as e:
            logger.warning(f"OpenAI embedding failed, trying fallback: {e}")
            
            if not self.enable_fallback:
                self._metrics["errors"] += 1
                raise
            
            try:
                embeddings = await self._generate_fallback_embedding([text])
                embedding = embeddings[0]
                model_used = "fallback-local"
            except Exception as fallback_error:
                self._metrics["errors"] += 1
                logger.error(f"Fallback embedding also failed: {fallback_error}")
                raise
        
        # Cache the result
        await self._store_in_cache(text, embedding)
        
        return EmbeddingResult(
            text=text,
            embedding=embedding,
            model=model_used,
            cached=False,
        )

    async def embed_batch(self, texts: List[str]) -> List[EmbeddingResult]:
        """
        Generate embeddings for multiple texts in batches.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of EmbeddingResult objects
        """
        if not texts:
            return []
        
        results: List[EmbeddingResult] = []
        
        # Process in batches
        for i in range(0, len(texts), self.batch_size):
            batch = texts[i:i + self.batch_size]
            
            # Check cache for each text
            batch_results = []
            uncached_texts = []
            uncached_indices = []
            
            for idx, text in enumerate(batch):
                cached_embedding = await self._get_from_cache(text)
                if cached_embedding:
                    batch_results.append(
                        EmbeddingResult(
                            text=text,
                            embedding=cached_embedding,
                            model=self.model,
                            cached=True,
                        )
                    )
                else:
                    uncached_texts.append(text)
                    uncached_indices.append(idx)
            
            # Generate embeddings for uncached texts
            if uncached_texts:
                try:
                    embeddings = await self._generate_openai_embedding(uncached_texts)
                    model_used = self.model
                    
                except Exception as e:
                    logger.warning(f"OpenAI batch embedding failed, trying fallback: {e}")
                    
                    if not self.enable_fallback:
                        self._metrics["errors"] += len(uncached_texts)
                        raise
                    
                    embeddings = await self._generate_fallback_embedding(uncached_texts)
                    model_used = "fallback-local"
                
                # Create results and cache
                for text, embedding in zip(uncached_texts, embeddings):
                    result = EmbeddingResult(
                        text=text,
                        embedding=embedding,
                        model=model_used,
                        cached=False,
                    )
                    batch_results.append(result)
                    await self._store_in_cache(text, embedding)
            
            results.extend(batch_results)
        
        self._metrics["total_requests"] += len(texts)
        return results

    async def health_check(self) -> Dict[str, Any]:
        """
        Check service health.
        
        Returns:
            Health status information
        """
        health = {
            "status": "healthy",
            "openai_available": bool(self._http_client and self.openai_api_key),
            "redis_available": False,
            "fallback_available": bool(self._fallback_model),
            "metrics": self._metrics.copy(),
        }
        
        # Check Redis
        if self._redis_client:
            try:
                await self._redis_client.ping()
                health["redis_available"] = True
            except Exception as e:
                logger.warning(f"Redis health check failed: {e}")
                health["status"] = "degraded"
        
        # Check OpenAI
        if self._http_client and self.openai_api_key:
            try:
                # Simple test embedding
                await self._generate_openai_embedding(["test"])
            except Exception as e:
                logger.warning(f"OpenAI health check failed: {e}")
                if not health["fallback_available"]:
                    health["status"] = "unhealthy"
                else:
                    health["status"] = "degraded"
        
        return health

    def get_metrics(self) -> Dict[str, Any]:
        """Get service metrics."""
        return {
            **self._metrics,
            "cache_hit_rate": (
                self._metrics["cache_hits"] / max(self._metrics["total_requests"], 1)
            ),
        }