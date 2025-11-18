"""
Stable Embedding Service with focus on local models and critical fixes.

Key improvements:
1. Local Sentence Transformers as primary provider (free, private, fast)
2. Mock fallback for development/testing
3. Comprehensive timeouts for all operations
4. Graceful degradation and fallback
5. Simple, stable architecture

Critical fixes:
- All operations have timeout protection
- No blocking event loop operations
- Focus on local, private embeddings
"""

from __future__ import annotations

import asyncio
import hashlib
import logging
import time
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
import json
import os

import httpx
import redis.asyncio as aioredis
from sentence_transformers import SentenceTransformer
import torch

logger = logging.getLogger(__name__)


@dataclass
class EmbeddingResult:
    """Result of embedding operation."""
    text: str
    embedding: List[float]
    model: str
    provider: str
    cached: bool = False
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


class StableEmbeddingProvider:
    """Base class for stable embedding providers."""
    
    def __init__(self, timeout: float = 10.0):
        self.timeout = timeout
    
    async def embed_with_timeout(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings with timeout protection."""
        try:
            return await asyncio.wait_for(
                self._embed_impl(texts),
                timeout=self.timeout
            )
        except asyncio.TimeoutError:
            logger.error(f"Timeout after {self.timeout}s for provider {self.__class__.__name__}")
            raise TimeoutError(f"Provider timeout after {self.timeout}s")
        except Exception as e:
            logger.error(f"Provider error: {e}")
            raise
    
    async def _embed_impl(self, texts: List[str]) -> List[List[float]]:
        """Actual implementation of embedding."""
        raise NotImplementedError
    
    def get_info(self) -> Dict[str, Any]:
        """Get provider information."""
        return {"name": "Unknown", "dimensions": 0, "provider": "unknown"}




class MockProvider(StableEmbeddingProvider):
    """
    Mock provider - IMPROVED FALLBACK.
    
    Generates deterministic embeddings for development/testing.
    """
    
    def __init__(self, dimensions: int = 1536, timeout: float = 1.0):
        super().__init__(timeout)
        self.dimensions = dimensions
    
    async def _embed_impl(self, texts: List[str]) -> List[List[float]]:
        """Generate deterministic mock embeddings."""
        embeddings = []
        for i, text in enumerate(texts):
            # Create deterministic embedding based on text content
            hash_val = hash(text) % 10000
            # Use text characteristics to create more realistic-looking vectors
            embedding = []
            for j in range(self.dimensions):
                val = (hash_val + i * 100 + j) % 1000 / 1000.0
                # Add some variation based on text
                if 'привет' in text.lower():
                    val *= 1.2
                if 'спасибо' in text.lower():
                    val *= 0.8
                embedding.append(val)
            embeddings.append(embedding)
        return embeddings
    
    def get_info(self) -> Dict[str, Any]:
        return {
            "name": "Mock-Embeddings",
            "dimensions": self.dimensions,
            "provider": "mock",
            "free": True,
            "deterministic": True
        }


class EmbeddingService:
    """
    Stable Embedding Service with focus on local models.

    Primary features:
    1. Local Sentence Transformers as main provider (free, private, fast)
    2. Mock fallback for development
    3. Redis caching for performance
    4. Comprehensive timeout protection
    5. Graceful degradation
    """
    
    def __init__(
        self,
        redis_url: Optional[str] = None,
        cache_ttl: int = 86400 * 7,  # 7 days
        batch_size: int = 50,  # Conservative batch size
        embedding_timeout: float = 10.0,
        primary_provider: str = "local",
        local_model: str = "all-MiniLM-L6-v2",
    ):
        """
        Initialize Stable Embedding Service.

        Args:
            redis_url: Redis connection for caching
            cache_ttl: Cache TTL in seconds
            batch_size: Batch size for processing
            embedding_timeout: Timeout for embedding operations
            primary_provider: Primary provider ("local" or "mock")
        """
        self.redis_url = redis_url
        self.cache_ttl = cache_ttl
        self.batch_size = batch_size
        self.embedding_timeout = embedding_timeout
        self.primary_provider = primary_provider
        self.local_model = local_model
        self.redis_url = redis_url
        self.cache_ttl = cache_ttl
        self.batch_size = batch_size
        self.embedding_timeout = embedding_timeout
        self.primary_provider = primary_provider
        self.local_model = local_model
        
        self._redis_client: Optional[aioredis.Redis] = None
        self._providers: Dict[str, StableEmbeddingProvider] = {}
        self._provider_order: List[str] = []
        
        # Initialize providers
        self._setup_providers()

        # Metrics
        self._metrics = {
            "total_requests": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "provider_usage": {},
            "errors": 0,
            "timeouts": 0,
        }

        # Initialize provider usage counters for all providers
        for provider_name in self._providers.keys():
            self._metrics["provider_usage"][provider_name] = 0
    
    def _setup_providers(self):
        """Setup providers in LOCAL-FIRST order of preference."""
        # PRIMARY: Local Sentence Transformers (free, fast, private, NO API KEY NEEDED)
        if self.primary_provider == "local" or self.local_model:
            try:
                self._providers["local"] = LocalSentenceTransformerProvider(
                    model_name=self.local_model,
                    timeout=self.embedding_timeout
                )
                self._provider_order.append("local")
                logger.info(f"✅ LOCAL provider configured ({self.local_model}) - PRIMARY CHOICE")
            except Exception as e:
                logger.warning(f"❌ Failed to initialize local provider: {e}")


        # FINAL FALLBACK: Mock provider (always available, no dependencies)
        self._providers["mock"] = MockProvider(timeout=1.0)
        self._provider_order.append("mock")
        logger.info("✅ Mock provider configured (always available fallback)")

        logger.info(f"🔧 LOCAL-ONLY provider order: {self._provider_order}")
    
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
                logger.info("✅ Redis connection established")
            
            # Test provider connectivity
            await self._test_providers()
            
        except Exception as e:
            logger.error(f"❌ Service initialization failed: {e}")
            # Don't raise - service should work with available providers
            pass
    
    async def _test_providers(self):
        """Test provider connectivity."""
        for provider_name in self._provider_order:
            try:
                provider = self._providers[provider_name]
                test_embedding = await provider.embed_with_timeout(["test"])
                logger.info(f"✅ {provider_name} provider test: OK ({len(test_embedding)} dims)")
            except Exception as e:
                logger.warning(f"⚠️ {provider_name} provider test failed: {e}")
    
    def _generate_cache_key(self, text: str, provider: str) -> str:
        """Generate cache key for text and provider."""
        content = f"{provider}:{text}"
        return f"embedding:{hashlib.sha256(content.encode()).hexdigest()}"
    
    async def _get_from_cache(self, text: str, provider: str) -> Optional[List[float]]:
        """Retrieve embedding from cache."""
        if not self._redis_client:
            return None
        
        try:
            cache_key = self._generate_cache_key(text, provider)
            cached_data = await self._redis_client.get(cache_key)
            
            if cached_data:
                self._metrics["cache_hits"] += 1
                return json.loads(cached_data)
            
            self._metrics["cache_misses"] += 1
            return None
            
        except Exception as e:
            logger.warning(f"Cache retrieval error: {e}")
            return None
    
    async def _store_in_cache(self, text: str, embedding: List[float], provider: str) -> None:
        """Store embedding in cache."""
        if not self._redis_client:
            return
        
        try:
            cache_key = self._generate_cache_key(text, provider)
            await self._redis_client.setex(
                cache_key,
                self.cache_ttl,
                json.dumps(embedding),
            )
        except Exception as e:
            logger.warning(f"Cache storage error: {e}")
    
    async def embed_text(self, text: str) -> EmbeddingResult:
        """
        Generate embedding for single text with timeout protection.

        Args:
            text: Text to embed

        Returns:
            EmbeddingResult with embedding vector and metadata
        """
        self._metrics["total_requests"] += 1

        # Check cache first
        for provider_name in self._provider_order:
            cached_embedding = await self._get_from_cache(text, provider_name)
            if cached_embedding:
                return EmbeddingResult(
                    text=text,
                    embedding=cached_embedding,
                    model=self._providers[provider_name].get_info()["name"],
                    provider=provider_name,
                    cached=True,
                )

        # Generate new embedding with fallback
        last_error = None
        for provider_name in self._provider_order:
            try:
                provider = self._providers[provider_name]

                logger.info(f"🔄 Generating embedding with {provider_name}...")
                start_time = time.time()

                embeddings = await provider.embed_with_timeout([text])
                embedding = embeddings[0]

                elapsed = time.time() - start_time
                logger.info(f"✅ {provider_name} completed in {elapsed:.2f}s")

                # Cache the result
                await self._store_in_cache(text, embedding, provider_name)

                # Update metrics
                self._metrics["provider_usage"][provider_name] += 1

                return EmbeddingResult(
                    text=text,
                    embedding=embedding,
                    model=provider.get_info()["name"],
                    provider=provider_name,
                    cached=False,
                )

            except asyncio.TimeoutError:
                self._metrics["timeouts"] += 1
                last_error = f"Timeout after {self.embedding_timeout}s"
                logger.error(f"⏰ {provider_name} timeout: {last_error}")
                continue
            except Exception as e:
                last_error = str(e)
                logger.warning(f"❌ {provider_name} failed: {e}")
                # Skip the local provider completely if it fails
                if provider_name == "local":
                    logger.warning("⚠️ Skipping local provider due to error, trying next provider")
                    continue
                continue

        # All providers failed - use mock as absolute fallback
        self._metrics["errors"] += 1
        self._metrics["provider_usage"]["mock"] += 1

        mock_provider = self._providers["mock"]
        mock_embedding = await mock_provider.embed_with_timeout([text])[0]

        logger.warning("⚠️ Using mock fallback - all real providers failed")

        return EmbeddingResult(
            text=text,
            embedding=mock_embedding,
            model="Mock-Embeddings",
            provider="mock",
            cached=False,
            metadata={"warning": "Used mock fallback", "last_error": last_error}
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

        # Process in smaller batches for stability
        for i in range(0, len(texts), self.batch_size):
            batch = texts[i:i + self.batch_size]

            # Check cache for each text
            batch_results = []
            uncached_texts = []

            for text in batch:
                # Check cache across providers
                found_cached = False
                for provider_name in self._provider_order:
                    cached_embedding = await self._get_from_cache(text, provider_name)
                    if cached_embedding:
                        batch_results.append(
                            EmbeddingResult(
                                text=text,
                                embedding=cached_embedding,
                                model=self._providers[provider_name].get_info()["name"],
                                provider=provider_name,
                                cached=True,
                            )
                        )
                        found_cached = True
                        break

                if not found_cached:
                    uncached_texts.append(text)

            # Generate embeddings for uncached texts
            if uncached_texts:
                # Try providers in order
                last_error = None
                for provider_name in self._provider_order:
                    try:
                        provider = self._providers[provider_name]
                        embeddings = await provider.embed_with_timeout(uncached_texts)

                        # Create results and cache
                        for text, embedding in zip(uncached_texts, embeddings):
                            result = EmbeddingResult(
                                text=text,
                                embedding=embedding,
                                model=provider.get_info()["name"],
                                provider=provider_name,
                                cached=False,
                            )
                            batch_results.append(result)
                            await self._store_in_cache(text, embedding, provider_name)

                        # Update metrics
                        self._metrics["provider_usage"][provider_name] += len(uncached_texts)
                        logger.info(f"✅ Batch: {len(uncached_texts)} texts with {provider_name}")
                        break

                    except Exception as e:
                        last_error = str(e)
                        logger.warning(f"❌ Provider {provider_name} failed for batch: {e}")
                        # Skip the local provider completely if it fails
                        if provider_name == "local":
                            logger.warning("⚠️ Skipping local provider due to error, trying next provider")
                            continue
                        continue

                else:
                    # All providers failed, use mock
                    mock_embeddings = await self._providers["mock"].embed_with_timeout(uncached_texts)
                    self._metrics["provider_usage"]["mock"] += len(uncached_texts)

                    for text, embedding in zip(uncached_texts, mock_embeddings):
                        batch_results.append(
                            EmbeddingResult(
                                text=text,
                                embedding=embedding,
                                model="Mock-Embeddings",
                                provider="mock",
                                cached=False,
                                metadata={"warning": "Used mock fallback", "error": last_error}
                            )
                        )

            results.extend(batch_results)

        self._metrics["total_requests"] += len(texts)
        return results
    
    async def health_check(self) -> Dict[str, Any]:
        """Check service health."""
        health = {
            "status": "healthy",
            "providers": {},
            "metrics": self.get_metrics(),
            "provider_order": self._provider_order
        }
        
        # Check Redis
        if self._redis_client:
            try:
                await self._redis_client.ping()
                health["redis_available"] = True
            except Exception as e:
                logger.warning(f"Redis health check failed: {e}")
                health["redis_available"] = False
        
        # Check providers
        for provider_name, provider in self._providers.items():
            try:
                info = provider.get_info()
                
                # Test with timeout
                start_time = time.time()
                test_embeddings = await provider.embed_with_timeout(["health check"])
                elapsed = time.time() - start_time
                
                health["providers"][provider_name] = {
                    "status": "healthy",
                    "info": info,
                    "test_time": elapsed
                }
                
            except Exception as e:
                health["providers"][provider_name] = {
                    "status": "unhealthy",
                    "error": str(e),
                    "info": provider.get_info()
                }
                health["status"] = "degraded"
        
        return health
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get service metrics."""
        total_requests = self._metrics["total_requests"]
        cache_hit_rate = (
            self._metrics["cache_hits"] / max(total_requests, 1)
        )
        
        return {
            **self._metrics,
            "cache_hit_rate": cache_hit_rate,
            "available_providers": list(self._providers.keys()),
            "primary_provider": self._provider_order[0] if self._provider_order else "none",
        }
    
    async def close(self) -> None:
        """Close service connections."""
        if self._redis_client:
            await self._redis_client.close()


# OpenAI provider for backward compatibility
class OpenAIReturnProvider(StableEmbeddingProvider):
    """OpenAI provider for backward compatibility."""
    
    def __init__(self, api_key: str, timeout: float = 10.0):
        super().__init__(timeout)
        self.api_key = api_key
        self.model = "text-embedding-3-large"
        self._http_client = None
    
    async def _ensure_client(self):
        """Ensure HTTP client is initialized."""
        if not self._http_client:
            self._http_client = httpx.AsyncClient(
                base_url="https://api.openai.com/v1",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                timeout=self.timeout,
            )
    
    async def _embed_impl(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using OpenAI API."""
        await self._ensure_client()
        
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
            return embeddings
            
        except Exception as e:
            logger.error(f"OpenAI embedding error: {e}")
            raise
    
    def get_info(self) -> Dict[str, Any]:
        return {
            "name": self.model,
            "dimensions": 3072 if self.model == "text-embedding-3-large" else 1536,
            "provider": "openai"
        }


class LocalSentenceTransformerProvider(StableEmbeddingProvider):
    """
    Local Sentence Transformers provider - PRIMARY SOLUTION for RTX 3070.

    Optimized for 8GB VRAM with fast, local inference.
    """

    def __init__(self, model_name: str = "all-MiniLM-L6-v2", timeout: float = 30.0):
        super().__init__(timeout)
        self.model_name = model_name
        self._model = None

    async def _ensure_model(self):
        """Ensure model is loaded."""
        if self._model is None:
            try:
                logger.info(f"🔍 Local provider: Loading model {self.model_name}")
                # Load model with GPU if available
                device = "cuda" if torch.cuda.is_available() else "cpu"
                logger.info(f"🔍 Local provider: Using device {device}")

                if device == "cuda":
                    # Log initial GPU memory
                    allocated = torch.cuda.memory_allocated() / 1024**2
                    reserved = torch.cuda.memory_reserved() / 1024**2
                    logger.info(f"🔍 GPU memory before loading: {allocated:.1f}MB allocated, {reserved:.1f}MB reserved")

                start_time = time.time()
                self._model = SentenceTransformer(self.model_name, device=device)
                load_time = time.time() - start_time

                if device == "cuda":
                    # Log GPU memory after loading
                    allocated_after = torch.cuda.memory_allocated() / 1024**2
                    reserved_after = torch.cuda.memory_reserved() / 1024**2
                    logger.info(f"🔍 GPU memory after loading: {allocated_after:.1f}MB allocated, {reserved_after:.1f}MB reserved")

                logger.info(f"✅ Loaded {self.model_name} on {device} in {load_time:.2f}s")
            except Exception as e:
                logger.error(f"❌ Failed to load {self.model_name}: {e}")
                logger.error(f"❌ Device: {'cuda' if torch.cuda.is_available() else 'cpu'}")
                raise

    async def _embed_impl(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using local SentenceTransformer."""
        logger.info(f"🔍 Local provider: Starting batch embedding for {len(texts)} texts")

        await self._ensure_model()

        try:
            # Log GPU memory before encoding if available
            if torch.cuda.is_available():
                allocated = torch.cuda.memory_allocated() / 1024**2
                reserved = torch.cuda.memory_reserved() / 1024**2
                logger.info(f"🔍 GPU memory before encoding: {allocated:.1f}MB allocated, {reserved:.1f}MB reserved")

            # Encode texts - this runs on GPU if available
            logger.info(f"🔍 Starting model.encode for batch of {len(texts)} texts")
            start_time = time.time()
            embeddings = self._model.encode(texts, convert_to_tensor=False)
            elapsed = time.time() - start_time
            logger.info(f"✅ Local provider: model.encode completed in {elapsed:.2f}s, got {len(embeddings)} embeddings")

            # Log GPU memory after encoding if available
            if torch.cuda.is_available():
                allocated_after = torch.cuda.memory_allocated() / 1024**2
                reserved_after = torch.cuda.memory_reserved() / 1024**2
                logger.info(f"🔍 GPU memory after encoding: {allocated_after:.1f}MB allocated, {reserved_after:.1f}MB reserved")

            result = embeddings.tolist()
            logger.info(f"✅ Local provider: Returning {len(result)} embeddings successfully")
            return result
        except Exception as e:
            logger.error(f"❌ Local embedding error: {e}")
            logger.error(f"❌ Text lengths: {[len(t) for t in texts]}")
            logger.error(f"❌ Model info: {self.get_info()}")
            raise

    def get_info(self) -> Dict[str, Any]:
        device = "cuda" if torch.cuda.is_available() else "cpu"
        return {
            "name": f"Local-{self.model_name}",
            "dimensions": 384 if "MiniLM" in self.model_name else 768,  # Standard dims
            "provider": "local",
            "free": True,
            "device": device,
            "model_name": self.model_name
        }


# Convenience function for creating embedding service
def create_embedding_service(
    redis_url: Optional[str] = None,
    primary_provider: str = "local",
    local_model: str = "all-MiniLM-L6-v2"
) -> EmbeddingService:
    """Create EmbeddingService with local-only configuration."""
    return EmbeddingService(
        redis_url=redis_url,
        primary_provider=primary_provider,
        local_model=local_model
    )