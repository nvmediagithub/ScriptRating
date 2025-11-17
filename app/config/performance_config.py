"""
Performance optimization configuration for vector search system.

This module provides centralized configuration for all performance optimizations,
including caching, batching, connection pooling, and monitoring settings.
"""

from typing import Dict, Any
from pydantic_settings import BaseSettings


class PerformanceConfig(BaseSettings):
    """Performance optimization configuration."""

    # Redis Caching Settings
    redis_cache_enabled: bool = True
    redis_cache_ttl_seconds: int = 86400  # 24 hours
    redis_max_connections: int = 10
    redis_cache_key_prefix: str = "vector_search"

    # Batch Processing Settings
    batch_indexing_size: int = 50
    batch_search_size: int = 100
    max_concurrent_batches: int = 3

    # Connection Pooling Settings
    qdrant_max_connections: int = 10
    embedding_service_max_connections: int = 5
    connection_pool_timeout: float = 30.0

    # Performance Monitoring Settings
    enable_performance_monitoring: bool = True
    metrics_collection_interval: int = 60  # seconds
    performance_log_level: str = "INFO"
    slow_query_threshold_ms: float = 1000.0

    # Query Optimization Settings
    enable_query_expansion: bool = True
    max_query_expansions: int = 3
    enable_result_reranking: bool = True
    query_cache_enabled: bool = True

    # Resource Management Settings
    max_memory_usage_mb: int = 1024
    cleanup_interval_seconds: int = 300
    resource_check_interval: int = 60

    # Benchmark Settings
    benchmark_enabled: bool = False
    benchmark_iterations: int = 100
    benchmark_warmup_iterations: int = 10
    benchmark_output_file: str = "performance_benchmark.json"

    class Config:
        env_prefix = "PERFORMANCE_"
        case_sensitive = False

    def get_cache_config(self) -> Dict[str, Any]:
        """Get Redis cache configuration."""
        return {
            "enabled": self.redis_cache_enabled,
            "ttl_seconds": self.redis_cache_ttl_seconds,
            "max_connections": self.redis_max_connections,
            "key_prefix": self.redis_cache_key_prefix,
        }

    def get_batch_config(self) -> Dict[str, Any]:
        """Get batch processing configuration."""
        return {
            "indexing_size": self.batch_indexing_size,
            "search_size": self.batch_search_size,
            "max_concurrent": self.max_concurrent_batches,
        }

    def get_connection_pool_config(self) -> Dict[str, Any]:
        """Get connection pool configuration."""
        return {
            "qdrant_max_connections": self.qdrant_max_connections,
            "embedding_max_connections": self.embedding_service_max_connections,
            "timeout": self.connection_pool_timeout,
        }

    def get_query_optimization_config(self) -> Dict[str, Any]:
        """Get query optimization configuration."""
        return {
            "query_expansion_enabled": self.enable_query_expansion,
            "max_expansions": self.max_query_expansions,
            "reranking_enabled": self.enable_result_reranking,
            "query_cache_enabled": self.query_cache_enabled,
        }

    def get_monitoring_config(self) -> Dict[str, Any]:
        """Get performance monitoring configuration."""
        return {
            "enabled": self.enable_performance_monitoring,
            "collection_interval": self.metrics_collection_interval,
            "log_level": self.performance_log_level,
            "slow_query_threshold_ms": self.slow_query_threshold_ms,
        }

    def get_resource_management_config(self) -> Dict[str, Any]:
        """Get resource management configuration."""
        return {
            "max_memory_mb": self.max_memory_usage_mb,
            "cleanup_interval": self.cleanup_interval_seconds,
            "check_interval": self.resource_check_interval,
        }

    def get_benchmark_config(self) -> Dict[str, Any]:
        """Get benchmark configuration."""
        return {
            "enabled": self.benchmark_enabled,
            "iterations": self.benchmark_iterations,
            "warmup_iterations": self.benchmark_warmup_iterations,
            "output_file": self.benchmark_output_file,
        }


# Global performance configuration instance
performance_config = PerformanceConfig()