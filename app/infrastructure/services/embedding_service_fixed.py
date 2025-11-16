"""
Enhanced Embedding Service for RAG system.

This service provides text embedding generation with multiple provider support:
- OpenAI API (primary)
- OpenRouter API (free alternative)
- Local sentence-transformers models (fallback)
- HuggingFace Inference API (free cloud option)

Features:
- Multi-provider support with intelligent fallback
- OpenRouter integration for free embeddings
- Real local model loading (no more mocks)
- Redis caching for performance
- Async operations for scalability
"""
from __future__ import annotations

import asyncio
import hashlib
import logging
from typing import List, Optional, Dict, Any, Union
from dataclasses import dataclass
import json
import os

import httpx
import redis.asyncio as aioredis

logger = logging.getLogger(__name__)


@dataclass
class EmbeddingResult:
    """Result of embedding operation."""
    text: str
    embedding: List[float]
    model: str
    provider: str  # "openai", "openrouter", "local", "mock"
    cached: bool = False
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


class EmbeddingProvider:
    """Base class for embedding providers."""
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for texts."""
        raise NotImplementedError
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get provider model information."""
        return {"name": "Unknown", "dimensions": 0, "provider": "unknown"}


class OpenAIProvider(EmbeddingProvider):
    """OpenAI embedding provider."""
    
    def __init__(self, api_key: str, model: str = "text-embedding-3-large"):
        self.api_key = api_key
        self.model = model
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
                timeout=30.0,
            )
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
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
    
    def get_model_info(self) -> Dict[str, Any]:
        return {
            "name": self.model,
            "dimensions": 3072 if self.model == "text-embedding-3-large" else 1536,
            "provider": "openai"
        }


class OpenRouterProvider(EmbeddingProvider):
    """OpenRouter embedding provider."""
    
    def __init__(self, api_key: str, base_url: str = "https://openrouter.ai/api/v1"):
        self.api_key = api_key
        self.base_url = base_url
        self._http_client = None
        
        # Free embedding models on OpenRouter
        self.embedding_models = [
            "openai/text-embedding-3-small",
            "openai/text-embedding-3-large", 
            "cohere/embed-multilingual-v3.0"
        ]
    
    async def _ensure_client(self):
        """Ensure HTTP client is initialized."""
        if not self._http_client:
            self._http_client = httpx.AsyncClient(
                base_url=self.base_url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://scriptrating.com",
                    "X-Title": "ScriptRating"
                },
                timeout=30.0,
            )
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using OpenRouter API."""
        await self._ensure_client()
        
        # Try different models in order of preference
        for model in self.embedding_models:
            try:
                logger.info(f"Trying OpenRouter model: {model}")
                
                response = await self._http_client.post(
                    "/embeddings",
                    json={
                        "model": model,
                        "input": texts,
                        "encoding_format": "float",
                    },
                )
                
                if response.status_code == 200:
                    data = response.json()
                    embeddings = [item["embedding"] for item in data["data"]]
                    logger.info(f"Successfully generated embeddings with {model}")
                    return embeddings
                elif response.status_code == 400:
                    # Model not available, try next
                    logger.warning(f"Model {model} not available, trying next")
                    continue
                else:
                    response.raise_for_status()
                    
            except Exception as e:
                logger.warning(f"Failed with model {model}: {e}")
                continue
        
        raise Exception("All OpenRouter embedding models failed")
    
    def get_model_info(self) -> Dict[str, Any]:
        return {
            "name": "OpenRouter-Embeddings",
            "dimensions": 1536,  # Default for most models
            "provider": "openrouter",
            "available_models": self.embedding_models
        }


class LocalProvider(EmbeddingProvider):
    """Local sentence-transformers provider."""
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.model_name = model_name
        self._model = None
        self._model_loaded = False
        self._loading_task = None
    
    def _load_model_sync(self):
        """Load model synchronously."""
        try:
            from sentence_transformers import SentenceTransformer
            
            logger.info(f"Loading local embedding model: {self.model_name}")
            self._model = SentenceTransformer(self.model_name, "cpu")
            logger.info(f"Successfully loaded {self.model_name}")
            self._model_loaded = True
            
        except ImportError:
            logger.error("sentence-transformers not installed")
            raise Exception("sentence-transformers package required")
        except Exception as e:
            logger.error(f"Failed to load model {self.model_name}: {e}")
            raise
    
    async def _ensure_model_loaded(self):
        """Ensure local model is loaded."""
        if not self._model_loaded and not self._loading_task:
            # Start loading task if not already running
            self._loading_task = asyncio.create_task(self._load_model())
    
    async def _load_model(self):
        """Load model asynchronously."""
        try:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, self._load_model_sync)
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise
        finally:
            self._loading_task = None
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using local model."""
        await self._ensure_model_loaded()
        
        # Wait for model to be loaded if it's still loading
        if self._loading_task:
            await self._loading_task
        
        if not self._model_loaded:
            raise Exception("Model failed to load")
        
        try:
            # Run encoding in thread pool
            loop = asyncio.get_event_loop()
            embeddings = await loop.run_in_executor(
                None,
                self._model.encode,
                texts
            )
            return embeddings.tolist()
            
        except Exception as e:
            logger.error(f"Local embedding error: {e}")
            raise
    
    def get_model_info(self) -> Dict[str, Any]:
        # Get dimensions from model configuration if available
        dimensions = 384  # Default for all-MiniLM-L6-v2
        if self._model and hasattr(self._model, 'get_sentence_embedding_dimension'):
            dimensions = self._model.get_sentence_embedding_dimension()
        
        return {
            "name": self.model_name,
            "dimensions": dimensions,
            "provider": "local"
        }


class HuggingFaceProvider(EmbeddingProvider):
    """HuggingFace Inference API provider."""
    
    def __init__(self, api_token: str = None):
        self.api_token = api_token or os.getenv("HUGGINGFACE_API_TOKEN")
        self.base_url = "https://api-inference.huggingface.co/pipeline/feature-extraction"
        self.model = "sentence-transformers/all-MiniLM-L6-v2"
        self._http_client = None
    
    async def _ensure_client(self):
        """Ensure HTTP client is initialized."""
        if not self._http_client:
            headers = {"Content-Type": "application/json"}
            if self.api_token:
                headers["Authorization"] = f"Bearer {self.api_token}"
            
            self._http_client = httpx.AsyncClient(
                base_url=self.base_url,
                headers=headers,
                timeout=30.0,
            )
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using HuggingFace API."""
        await self._ensure_client()
        
        try:
            response = await self._http_client.post(
                f"/{self.model}",
                json={"inputs": texts}
            )
            
            if response.status_code == 200:
                embeddings = response.json()
                # If single text, wrap in list
                if not isinstance(embeddings[0], list):
                    embeddings = [embeddings]
                return embeddings
            else:
                response.raise_for_status()
                
        except Exception as e:
            logger.error(f"HuggingFace embedding error: {e}")
            raise
    
    def get_model_info(self) -> Dict[str, Any]:
        return {
            "name": self.model,
            "dimensions": 384,
            "provider": "huggingface"
        }


class MockProvider(EmbeddingProvider):
    """Mock provider for fallback."""
    
    def __init__(self, dimensions: int = 384):
        self.dimensions = dimensions
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate mock embeddings."""
        embeddings = []
        for i, text in enumerate(texts):
            # Create deterministic mock embedding based on text
            hash_val = hash(text) % 10000
            embedding = [0.1 * (hash_val % 100 + i) for _ in range(self.dimensions)]
            embeddings.append(embedding)
        return embeddings
    
    def get_model_info(self) -> Dict[str, Any]:
        return {
            "name": "Mock-Embeddings",
            "dimensions": self.dimensions,
            "provider": "mock"
        }


class EmbeddingService:
    """
    Enhanced Embedding Service with multi-provider support.
    
    Features:
    - OpenAI API (primary, paid)
    - OpenRouter API (free alternative)
    - Local sentence-transformers models (free, offline)
    - HuggingFace Inference API (free cloud)
    - Mock fallback (always available)
    - Redis caching for performance
    - Automatic fallback chain
    """

    def __init__(
        self,
        openai_api_key: Optional[str] = None,
        openrouter_api_key: Optional[str] = None,
        huggingface_api_token: Optional[str] = None,
        redis_url: Optional[str] = None,
        primary_provider: str = "local",  # "openai", "openrouter", "local", "huggingface"
        local_model: str = "all-MiniLM-L6-v2",
        cache_ttl: int = 86400 * 7,  # 7 days
        batch_size: int = 100,
    ):
        """
        Initialize Enhanced EmbeddingService.

        Args:
            openai_api_key: OpenAI API key
            openrouter_api_key: OpenRouter API key
            huggingface_api_token: HuggingFace API token
            redis_url: Redis connection URL
            primary_provider: Primary embedding provider
            local_model: Local model name for sentence-transformers
            cache_ttl: Cache TTL in seconds
            batch_size: Maximum batch size for embeddings
        """
        self.openai_api_key = openai_api_key
        self.openrouter_api_key = openrouter_api_key
        self.huggingface_api_token = huggingface_api_token
        self.redis_url = redis_url
        self.primary_provider = primary_provider
        self.local_model = local_model
        self.cache_ttl = cache_ttl
        self.batch_size = batch_size
        
        self._redis_client: Optional[aioredis.Redis] = None
        self._providers: Dict[str, EmbeddingProvider] = {}
        self._fallback_chain: List[str] = []
        
        # Metrics
        self._metrics = {
            "total_requests": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "provider_usage": {
                "openai": 0,
                "openrouter": 0,
                "local": 0,
                "huggingface": 0,
                "mock": 0
            },
            "errors": 0,
        }

    async def initialize(self) -> None:
        """Initialize service and providers."""
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
            
            # Initialize providers
            await self._initialize_providers()
            
            # Build fallback chain
            self._build_fallback_chain()
            
            logger.info(f"EmbeddingService initialized with providers: {list(self._providers.keys())}")
            
        except Exception as e:
            logger.error(f"Error initializing EmbeddingService: {e}")
            raise

    async def _initialize_providers(self):
        """Initialize all available providers."""
        # OpenAI Provider
        if self.openai_api_key:
            self._providers["openai"] = OpenAIProvider(self.openai_api_key)
            logger.info("OpenAI provider initialized")
        
        # OpenRouter Provider
        if self.openrouter_api_key:
            self._providers["openrouter"] = OpenRouterProvider(self.openrouter_api_key)
            logger.info("OpenRouter provider initialized")
        
        # Local Provider (always available)
        try:
            self._providers["local"] = LocalProvider(self.local_model)
            logger.info("Local provider initialized")
        except Exception as e:
            logger.warning(f"Local provider failed to initialize: {e}")
        
        # HuggingFace Provider
        if self.huggingface_api_token or os.getenv("HUGGINGFACE_API_TOKEN"):
            self._providers["huggingface"] = HuggingFaceProvider(self.huggingface_api_token)
            logger.info("HuggingFace provider initialized")
        
        # Mock Provider (always available fallback)
        self._providers["mock"] = MockProvider()

    def _build_fallback_chain(self):
        """Build intelligent fallback chain based on available providers."""
        self._fallback_chain = []
        
        # Start with primary provider
        if self.primary_provider in self._providers:
            self._fallback_chain.append(self.primary_provider)
        
        # Add other available providers in order of preference
        preferred_order = ["openai", "openrouter", "huggingface", "local", "mock"]
        for provider in preferred_order:
            if provider in self._providers and provider not in self._fallback_chain:
                self._fallback_chain.append(provider)
        
        logger.info(f"Fallback chain: {' -> '.join(self._fallback_chain)}")

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

    async def _try_provider(self, provider_name: str, texts: List[str]) -> List[List[float]]:
        """Try embedding with specific provider."""
        provider = self._providers.get(provider_name)
        if not provider:
            raise ValueError(f"Provider {provider_name} not available")
        
        return await provider.embed(texts)

    async def embed_text(self, text: str) -> EmbeddingResult:
        """
        Generate embedding for a single text with intelligent fallback.
        
        Args:
            text: Text to embed
            
        Returns:
            EmbeddingResult with embedding vector and metadata
        """
        self._metrics["total_requests"] += 1
        
        # Check cache for each provider in fallback chain
        for provider_name in self._fallback_chain:
            cached_embedding = await self._get_from_cache(text, provider_name)
            if cached_embedding:
                return EmbeddingResult(
                    text=text,
                    embedding=cached_embedding,
                    model=self._providers[provider_name].get_model_info()["name"],
                    provider=provider_name,
                    cached=True,
                )
        
        # Generate new embedding using fallback chain
        last_error = None
        for provider_name in self._fallback_chain:
            try:
                logger.info(f"Trying provider: {provider_name}")
                embeddings = await self._try_provider(provider_name, [text])
                embedding = embeddings[0]
                
                # Cache the result
                await self._store_in_cache(text, embedding, provider_name)
                
                # Update metrics
                self._metrics["provider_usage"][provider_name] += 1
                
                return EmbeddingResult(
                    text=text,
                    embedding=embedding,
                    model=self._providers[provider_name].get_model_info()["name"],
                    provider=provider_name,
                    cached=False,
                )
                
            except Exception as e:
                last_error = e
                logger.warning(f"Provider {provider_name} failed: {e}")
                continue
        
        # All providers failed, use mock as absolute fallback
        self._metrics["errors"] += 1
        self._metrics["provider_usage"]["mock"] += 1
        
        mock_provider = self._providers["mock"]
        mock_embedding = await mock_provider.embed([text])[0]
        
        return EmbeddingResult(
            text=text,
            embedding=mock_embedding,
            model="Mock-Embeddings",
            provider="mock",
            cached=False,
            metadata={"error": str(last_error)}
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
                # Check cache across all providers
                for provider_name in self._fallback_chain:
                    cached_embedding = await self._get_from_cache(text, provider_name)
                    if cached_embedding:
                        batch_results.append(
                            EmbeddingResult(
                                text=text,
                                embedding=cached_embedding,
                                model=self._providers[provider_name].get_model_info()["name"],
                                provider=provider_name,
                                cached=True,
                            )
                        )
                        break
                else:
                    uncached_texts.append(text)
                    uncached_indices.append(idx)
            
            # Generate embeddings for uncached texts
            if uncached_texts:
                # Try providers in order
                for provider_name in self._fallback_chain:
                    try:
                        embeddings = await self._try_provider(provider_name, uncached_texts)
                        
                        # Create results and cache
                        for text, embedding in zip(uncached_texts, embeddings):
                            result = EmbeddingResult(
                                text=text,
                                embedding=embedding,
                                model=self._providers[provider_name].get_model_info()["name"],
                                provider=provider_name,
                                cached=False,
                            )
                            batch_results.append(result)
                            await self._store_in_cache(text, embedding, provider_name)
                        
                        # Update metrics
                        self._metrics["provider_usage"][provider_name] += len(uncached_texts)
                        break
                        
                    except Exception as e:
                        logger.warning(f"Provider {provider_name} failed for batch: {e}")
                        continue
                
                else:
                    # All providers failed, use mock
                    mock_embeddings = await self._providers["mock"].embed(uncached_texts)
                    self._metrics["provider_usage"]["mock"] += len(uncached_texts)
                    
                    for text, embedding in zip(uncached_texts, mock_embeddings):
                        batch_results.append(
                            EmbeddingResult(
                                text=text,
                                embedding=embedding,
                                model="Mock-Embeddings",
                                provider="mock",
                                cached=False,
                                metadata={"error": "All providers failed"}
                            )
                        )
            
            results.extend(batch_results)
        
        self._metrics["total_requests"] += len(texts)
        return results

    async def health_check(self) -> Dict[str, Any]:
        """
        Check service health and provider status.
        
        Returns:
            Health status information for all providers
        """
        health = {
            "status": "healthy",
            "providers": {},
            "metrics": self._metrics.copy(),
            "fallback_chain": self._fallback_chain
        }
        
        # Check Redis
        if self._redis_client:
            try:
                await self._redis_client.ping()
                health["redis_available"] = True
            except Exception as e:
                logger.warning(f"Redis health check failed: {e}")
                health["redis_available"] = False
                health["status"] = "degraded"
        
        # Check each provider
        for provider_name, provider in self._providers.items():
            try:
                provider_info = provider.get_model_info()
                
                # Test embedding generation
                if provider_name == "mock":
                    # Mock provider always works
                    test_embeddings = await provider.embed(["test"])
                    health["providers"][provider_name] = {
                        "status": "healthy",
                        "info": provider_info
                    }
                else:
                    # Test with real providers
                    test_embeddings = await provider.embed(["health check"])
                    health["providers"][provider_name] = {
                        "status": "healthy",
                        "info": provider_info
                    }
                    
            except Exception as e:
                health["providers"][provider_name] = {
                    "status": "unhealthy",
                    "error": str(e),
                    "info": provider.get_model_info()
                }
                logger.warning(f"Provider {provider_name} health check failed: {e}")
        
        # Determine overall health
        healthy_providers = sum(1 for p in health["providers"].values() if p["status"] == "healthy")
        if healthy_providers == 0:
            health["status"] = "unhealthy"
        elif healthy_providers < len(self._providers) / 2:
            health["status"] = "degraded"
        
        return health

    def get_metrics(self) -> Dict[str, Any]:
        """Get comprehensive service metrics."""
        total_requests = self._metrics["total_requests"]
        cache_hit_rate = (
            self._metrics["cache_hits"] / max(total_requests, 1)
        )
        
        return {
            **self._metrics,
            "cache_hit_rate": cache_hit_rate,
            "available_providers": list(self._providers.keys()),
            "primary_provider": self.primary_provider,
            "fallback_chain_length": len(self._fallback_chain)
        }

    async def close(self) -> None:
        """Close service connections."""
        if self._redis_client:
            await self._redis_client.close()
        # HTTP clients will be closed automatically