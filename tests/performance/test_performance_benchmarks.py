"""
Performance benchmarks and automated testing for vector search optimizations.

This module provides comprehensive performance testing including:
- Latency benchmarks for different operations
- Throughput testing under load
- Cache hit rate validation
- Memory usage monitoring
- Comparative performance analysis
"""

import asyncio
import time
import statistics
import json
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict
import psutil
import os

from app.infrastructure.services.vector_database_service import VectorDatabaseService
from app.infrastructure.services.embedding_service import EmbeddingService
from app.domain.services.rag_orchestrator import RAGOrchestrator, RAGDocument
from app.config.performance_config import performance_config


@dataclass
class PerformanceMetrics:
    """Performance metrics for benchmarking."""
    operation: str
    iterations: int
    total_time: float
    avg_time: float
    min_time: float
    max_time: float
    p50_time: float
    p95_time: float
    p99_time: float
    throughput: float  # operations per second
    memory_usage_mb: float
    cache_hit_rate: float
    timestamp: str

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class BenchmarkResult:
    """Complete benchmark result."""
    test_name: str
    metrics: List[PerformanceMetrics]
    system_info: Dict[str, Any]
    config: Dict[str, Any]
    summary: Dict[str, Any]


class PerformanceBenchmark:
    """Performance benchmarking suite for vector search system."""

    def __init__(
        self,
        embedding_service: EmbeddingService,
        vector_db_service: VectorDatabaseService,
        rag_orchestrator: RAGOrchestrator,
    ):
        self.embedding_service = embedding_service
        self.vector_db_service = vector_db_service
        self.rag_orchestrator = rag_orchestrator

        # Test data
        self.test_documents = self._generate_test_documents(100)
        self.test_queries = [
            "artificial intelligence and machine learning",
            "data science algorithms",
            "neural network architecture",
            "script content analysis",
            "rating evaluation methods",
            "content classification",
            "performance optimization",
            "vector search technology",
            "embedding generation",
            "document indexing"
        ]

    def _generate_test_documents(self, count: int) -> List[RAGDocument]:
        """Generate test documents for benchmarking."""
        documents = []
        topics = [
            "artificial intelligence", "machine learning", "data science",
            "neural networks", "script analysis", "content rating",
            "performance optimization", "vector search", "embeddings"
        ]

        for i in range(count):
            topic = topics[i % len(topics)]
            text = f"This is a comprehensive document about {topic}. It covers various aspects of {topic} including implementation details, best practices, and performance considerations. The document provides detailed information about {topic} concepts, algorithms, and practical applications in real-world scenarios."

            documents.append(RAGDocument(
                id=f"bench_doc_{i}",
                text=text,
                metadata={
                    "topic": topic,
                    "index": i,
                    "length": len(text),
                    "benchmark": True
                }
            ))

        return documents

    def _get_memory_usage(self) -> float:
        """Get current memory usage in MB."""
        process = psutil.Process(os.getpid())
        return process.memory_info().rss / 1024 / 1024

    async def _warmup_system(self):
        """Warm up the system before benchmarking."""
        print("🔄 Warming up system...")

        # Index some documents
        warmup_docs = self.test_documents[:10]
        await self.rag_orchestrator.index_documents_batch(warmup_docs)

        # Perform some searches
        for query in self.test_queries[:3]:
            await self.rag_orchestrator.search(query, top_k=5)

        print("✅ System warmed up")

    async def _run_operation_benchmark(
        self,
        operation_name: str,
        operation_func,
        iterations: int = performance_config.benchmark_iterations,
        warmup_iterations: int = performance_config.benchmark_warmup_iterations
    ) -> PerformanceMetrics:
        """Run benchmark for a specific operation."""
        print(f"🏃 Running {operation_name} benchmark ({iterations} iterations)...")

        # Warmup
        for _ in range(warmup_iterations):
            await operation_func()

        # Benchmark
        times = []
        start_memory = self._get_memory_usage()

        start_time = time.time()
        for i in range(iterations):
            iteration_start = time.time()
            await operation_func()
            iteration_end = time.time()
            times.append(iteration_end - iteration_start)

        total_time = time.time() - start_time
        end_memory = self._get_memory_usage()

        # Calculate statistics
        avg_time = statistics.mean(times)
        min_time = min(times)
        max_time = max(times)
        p50_time = statistics.median(times)
        p95_time = statistics.quantiles(times, n=20)[18]  # 95th percentile
        p99_time = statistics.quantiles(times, n=100)[98]  # 99th percentile
        throughput = iterations / total_time

        # Get cache metrics
        cache_hit_rate = 0.0
        try:
            metrics = await self.rag_orchestrator.get_metrics()
            cache_hit_rate = metrics.cache_hit_rate
        except:
            pass

        return PerformanceMetrics(
            operation=operation_name,
            iterations=iterations,
            total_time=total_time,
            avg_time=avg_time,
            min_time=min_time,
            max_time=max_time,
            p50_time=p50_time,
            p95_time=p95_time,
            p99_time=p99_time,
            throughput=throughput,
            memory_usage_mb=end_memory - start_memory,
            cache_hit_rate=cache_hit_rate,
            timestamp=time.strftime("%Y-%m-%d %H:%M:%S")
        )

    async def benchmark_document_indexing(self) -> PerformanceMetrics:
        """Benchmark document indexing performance."""
        batch_size = 10

        async def index_operation():
            docs = self.test_documents[:batch_size]
            await self.rag_orchestrator.index_documents_batch(docs)

        return await self._run_operation_benchmark(
            "document_indexing",
            index_operation,
            iterations=5  # Fewer iterations for indexing
        )

    async def benchmark_vector_search(self) -> PerformanceMetrics:
        """Benchmark vector search performance."""

        async def search_operation():
            query = self.test_queries[0]  # Use first query
            await self.rag_orchestrator.search(query, top_k=10)

        return await self._run_operation_benchmark(
            "vector_search",
            search_operation
        )

    async def benchmark_embedding_generation(self) -> PerformanceMetrics:
        """Benchmark embedding generation performance."""

        async def embed_operation():
            texts = [doc.text for doc in self.test_documents[:5]]
            await self.embedding_service.embed_batch(texts)

        return await self._run_operation_benchmark(
            "embedding_generation",
            embed_operation
        )

    async def benchmark_hybrid_search(self) -> PerformanceMetrics:
        """Benchmark hybrid search performance."""

        async def hybrid_search_operation():
            query = self.test_queries[0]
            await self.rag_orchestrator.hybrid_search(query, top_k=10)

        return await self._run_operation_benchmark(
            "hybrid_search",
            hybrid_search_operation
        )

    async def benchmark_concurrent_load(self) -> PerformanceMetrics:
        """Benchmark system under concurrent load."""
        semaphore = asyncio.Semaphore(10)  # 10 concurrent operations

        async def concurrent_operation():
            async with semaphore:
                query = self.test_queries[0]
                await self.rag_orchestrator.search(query, top_k=5)

        # Run multiple operations concurrently
        tasks = [concurrent_operation() for _ in range(50)]
        start_time = time.time()

        await asyncio.gather(*tasks)

        total_time = time.time() - start_time

        return PerformanceMetrics(
            operation="concurrent_load",
            iterations=50,
            total_time=total_time,
            avg_time=total_time / 50,
            min_time=0.0,  # Not measured individually
            max_time=0.0,
            p50_time=0.0,
            p95_time=0.0,
            p99_time=0.0,
            throughput=50 / total_time,
            memory_usage_mb=self._get_memory_usage(),
            cache_hit_rate=0.0,
            timestamp=time.strftime("%Y-%m-%d %H:%M:%S")
        )

    async def run_full_benchmark_suite(self) -> BenchmarkResult:
        """Run complete benchmark suite."""
        print("🚀 Starting full performance benchmark suite...")

        # Warm up system
        await self._warmup_system()

        # Run all benchmarks
        metrics = []

        print("\n📊 Running benchmarks...")
        metrics.append(await self.benchmark_document_indexing())
        metrics.append(await self.benchmark_embedding_generation())
        metrics.append(await self.benchmark_vector_search())
        metrics.append(await self.benchmark_hybrid_search())
        metrics.append(await self.benchmark_concurrent_load())

        # Generate summary
        summary = self._generate_summary(metrics)

        # System info
        system_info = {
            "cpu_count": psutil.cpu_count(),
            "memory_total_gb": psutil.virtual_memory().total / 1024 / 1024 / 1024,
            "python_version": f"{os.sys.version_info.major}.{os.sys.version_info.minor}",
            "platform": os.sys.platform
        }

        result = BenchmarkResult(
            test_name="vector_search_performance_benchmark",
            metrics=metrics,
            system_info=system_info,
            config=performance_config.dict(),
            summary=summary
        )

        # Save results
        self._save_results(result)

        print("✅ Benchmark suite completed!")
        print(f"📈 Results saved to {performance_config.benchmark_output_file}")

        return result

    def _generate_summary(self, metrics: List[PerformanceMetrics]) -> Dict[str, Any]:
        """Generate benchmark summary."""
        summary = {
            "total_operations": sum(m.iterations for m in metrics),
            "avg_throughput": statistics.mean(m.throughput for m in metrics),
            "best_performing_operation": max(metrics, key=lambda m: m.throughput).operation,
            "slowest_operation": min(metrics, key=lambda m: m.throughput).operation,
            "cache_performance": {
                "avg_hit_rate": statistics.mean(m.cache_hit_rate for m in metrics if m.cache_hit_rate > 0),
                "max_hit_rate": max(m.cache_hit_rate for m in metrics),
            }
        }

        # Performance improvements assessment
        search_metrics = [m for m in metrics if "search" in m.operation]
        if search_metrics:
            avg_search_time = statistics.mean(m.avg_time for m in search_metrics)
            summary["performance_assessment"] = {
                "avg_search_time_ms": avg_search_time * 1000,
                "target_search_time_ms": 100.0,  # Target: 100ms
                "meets_performance_target": avg_search_time * 1000 < 100.0
            }

        return summary

    def _save_results(self, result: BenchmarkResult):
        """Save benchmark results to file."""
        output_data = {
            "test_name": result.test_name,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "metrics": [m.to_dict() for m in result.metrics],
            "system_info": result.system_info,
            "config": result.config,
            "summary": result.summary
        }

        with open(performance_config.benchmark_output_file, 'w') as f:
            json.dump(output_data, f, indent=2, default=str)


async def run_performance_benchmarks():
    """Run performance benchmarks."""
    print("🏁 Initializing performance benchmarks...")

    # Initialize services (simplified for testing)
    embedding_service = EmbeddingService(enable_fallback=True)
    await embedding_service.initialize()

    vector_db = VectorDatabaseService(
        qdrant_url=None,  # In-memory for testing
        collection_name='benchmark_test',
        vector_size=384,
        enable_tfidf_fallback=True,
        redis_url=None,  # Disable Redis for benchmark
    )
    await vector_db.initialize()

    rag_orchestrator = RAGOrchestrator(
        embedding_service=embedding_service,
        vector_db_service=vector_db,
        enable_hybrid_search=True,
    )

    try:
        # Run benchmarks
        benchmark = PerformanceBenchmark(
            embedding_service,
            vector_db,
            rag_orchestrator
        )

        result = await benchmark.run_full_benchmark_suite()

        # Print summary
        print("\n📊 Benchmark Summary:")
        for metric in result.metrics:
            print(f"  {metric.operation}: {metric.avg_time:.2f}s avg, {metric.throughput:.1f} ops/sec, {metric.cache_hit_rate:.3f} cache hit rate")

        print("\n🎯 Performance Targets:")
        print(f"  - Search time < 100ms: {'✅' if result.summary.get('performance_assessment', {}).get('meets_performance_target', False) else '❌'}")
        print(f"  - Overall throughput: {result.summary['avg_throughput']:.1f} ops/sec")

    finally:
        await rag_orchestrator.close()
        await vector_db.close()
        await embedding_service.close()


if __name__ == "__main__":
    asyncio.run(run_performance_benchmarks())