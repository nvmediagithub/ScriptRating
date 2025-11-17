"""
RAG System Configuration.

This module loads configuration for the RAG system from environment variables.
Updated to include OpenRouter integration with free embeddings.
"""
import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class RAGConfig(BaseSettings):
    """Configuration for RAG system components."""
    
    # OpenRouter Embeddings (Primary - Free)
    openrouter_api_key: Optional[str] = Field(
        default=None,
        alias="OPENROUTER_API_KEY",
        description="OpenRouter API key for free embeddings"
    )
    openrouter_base_model: Optional[str] = Field(
        default="openai/text-embedding-3-large",
        alias="OPENROUTER_BASE_MODEL",
        description="OpenRouter embedding model name"
    )
    
    # OpenAI Embeddings (Fallback)
    openai_embedding_api_key: Optional[str] = Field(
        default=None,
        alias="OPENAI_EMBEDDING_API_KEY",
        description="OpenAI API key for embeddings (fallback)"
    )
    openai_embedding_model: str = Field(
        default="text-embedding-3-large",
        alias="OPENAI_EMBEDDING_MODEL",
        description="OpenAI embedding model name"
    )
    
    # Embedding Service Settings
    embedding_primary_provider: str = Field(
        default="openrouter",
        alias="EMBEDDING_PRIMARY_PROVIDER",
        description="Primary embedding provider (openrouter, openai, or mock)"
    )
    embedding_batch_size: int = Field(
        default=50,  # Reduced for stability
        alias="EMBEDDING_BATCH_SIZE",
        description="Batch size for embedding generation"
    )
    embedding_cache_ttl: int = Field(
        default=604800,  # 7 days
        alias="EMBEDDING_CACHE_TTL",
        description="Cache TTL in seconds"
    )
    embedding_timeout: float = Field(
        default=10.0,
        alias="EMBEDDING_TIMEOUT",
        description="Timeout for embedding operations"
    )
    
    # Redis Configuration
    redis_url: Optional[str] = Field(
        default=None,
        alias="REDIS_URL",
        description="Redis connection URL"
    )
    redis_max_connections: int = Field(
        default=10,
        alias="REDIS_MAX_CONNECTIONS",
        description="Maximum Redis connections"
    )
    
    # Qdrant Configuration
    qdrant_url: Optional[str] = Field(
        default=None,
        alias="QDRANT_URL",
        description="Qdrant server URL"
    )
    qdrant_api_key: Optional[str] = Field(
        default=None,
        alias="QDRANT_API_KEY",
        description="Qdrant API key"
    )
    qdrant_collection_name: str = Field(
        default="script_rating_rag",
        alias="QDRANT_COLLECTION_NAME",
        description="Qdrant collection name"
    )
    qdrant_vector_size: int = Field(
        default=1536,
        alias="QDRANT_VECTOR_SIZE",
        description="Vector embedding dimension"
    )
    qdrant_distance_metric: str = Field(
        default="Cosine",
        alias="QDRANT_DISTANCE_METRIC",
        description="Distance metric (Cosine, Euclid, Dot)"
    )
    qdrant_replication_factor: int = Field(
        default=1,
        alias="QDRANT_REPLICATION_FACTOR",
        description="Replication factor"
    )
    qdrant_write_consistency_factor: int = Field(
        default=1,
        alias="QDRANT_WRITE_CONSISTENCY_FACTOR",
        description="Write consistency factor"
    )
    qdrant_on_disk_payload: bool = Field(
        default=True,
        alias="QDRANT_ON_DISK_PAYLOAD",
        description="Store payload on disk"
    )
    qdrant_hnsw_config_m: int = Field(
        default=16,
        alias="QDRANT_HNSW_CONFIG_M",
        description="HNSW M parameter"
    )
    qdrant_hnsw_config_ef_construct: int = Field(
        default=100,
        alias="QDRANT_HNSW_CONFIG_EF_CONSTRUCT",
        description="HNSW ef_construct parameter"
    )
    qdrant_timeout: int = Field(
        default=30,
        alias="QDRANT_TIMEOUT",
        description="Qdrant request timeout"
    )
    
    # RAG Features
    enable_rag_system: bool = Field(
        default=True,
        alias="ENABLE_RAG_SYSTEM",
        description="Enable RAG system"
    )
    enable_embedding_cache: bool = Field(
        default=True,
        alias="ENABLE_EMBEDDING_CACHE",
        description="Enable embedding cache"
    )
    enable_tfidf_fallback: bool = Field(
        default=True,
        alias="ENABLE_TFIDF_FALLBACK",
        description="Enable TF-IDF fallback"
    )
    enable_hybrid_search: bool = Field(
        default=True,
        alias="ENABLE_HYBRID_SEARCH",
        description="Enable hybrid search"
    )
    rag_search_timeout: float = Field(
        default=5.0,
        alias="RAG_SEARCH_TIMEOUT",
        description="Search timeout in seconds"
    )
    
    # Fallback Embeddings (kept for backward compatibility)
    fallback_embedding_model: str = Field(
        default="all-MiniLM-L6-v2",
        alias="FALLBACK_EMBEDDING_MODEL",
        description="Fallback embedding model name"
    )
    enable_fallback_embeddings: bool = Field(
        default=True,
        alias="ENABLE_FALLBACK_EMBEDDINGS",
        description="Enable fallback embeddings"
    )
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"
    
    def is_rag_enabled(self) -> bool:
        """Check if RAG system is fully enabled."""
        # RAG is enabled if the primary embedding provider has a valid API key
        if self.embedding_primary_provider == "openrouter":
            return self.enable_rag_system and self.openrouter_api_key is not None
        elif self.embedding_primary_provider == "openai":
            return self.enable_rag_system and self.openai_embedding_api_key is not None
        else:
            # Mock provider is always available
            return self.enable_rag_system
    
    def is_vector_db_enabled(self) -> bool:
        """Check if vector database is enabled."""
        return self.qdrant_url is not None
    
    def is_cache_enabled(self) -> bool:
        """Check if caching is enabled."""
        return (
            self.enable_embedding_cache and
            self.redis_url is not None
        )
    
    def get_embedding_config(self) -> dict:
        """Get complete embedding configuration for EmbeddingService."""
        return {
            "openrouter_api_key": self.openrouter_api_key,
            "openai_api_key": self.openai_embedding_api_key,
            "redis_url": self.redis_url if self.is_cache_enabled() else None,
            "cache_ttl": self.embedding_cache_ttl,
            "batch_size": self.embedding_batch_size,
            "embedding_timeout": self.embedding_timeout,
            "primary_provider": self.embedding_primary_provider,
        }


# Global configuration instance
_config: Optional[RAGConfig] = None


def get_rag_config() -> RAGConfig:
    """Get or create RAG configuration instance."""
    global _config
    if _config is None:
        _config = RAGConfig()
    return _config


def reload_rag_config() -> RAGConfig:
    """Reload RAG configuration from environment."""
    global _config
    _config = RAGConfig()
    return _config