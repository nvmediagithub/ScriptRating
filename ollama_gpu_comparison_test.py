import time
import psutil
import os
from sentence_transformers import SentenceTransformer
import requests
import json
from typing import List, Dict, Any


class OllamaEmbeddingService:
    def __init__(self, model_name: str = "nomic-embed-text"):
        self.model_name = model_name
        self.base_url = "http://localhost:11434"

    def encode(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using Ollama."""
        embeddings = []
        for text in texts:
            response = requests.post(
                f"{self.base_url}/api/embeddings",
                json={"model": self.model_name, "prompt": text}
            )
            response.raise_for_status()
            embeddings.append(response.json()["embedding"])
        return embeddings


class SentenceTransformerEmbeddingService:
    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2"):
        self.model = SentenceTransformer(model_name)

    def encode(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using SentenceTransformers."""
        return self.model.encode(texts).tolist()


def get_gpu_memory_usage():
    """Get GPU memory usage if available."""
    try:
        import torch
        if torch.cuda.is_available():
            return torch.cuda.memory_allocated() / 1024**3  # GB
        return 0.0
    except ImportError:
        return 0.0


def benchmark_embedding_service(service_name: str, service, test_texts: List[str], num_runs: int = 10) -> Dict[str, Any]:
    """Benchmark embedding service performance and resource usage."""
    results = {
        "service": service_name,
        "runs": []
    }

    print(f"\nBenchmarking {service_name}...")

    for run in range(num_runs):
        print(f"Run {run + 1}/{num_runs}")

        # Measure CPU and memory before
        cpu_before = psutil.cpu_percent(interval=None)
        mem_before = psutil.virtual_memory().percent

        start_time = time.time()

        # Generate embeddings
        embeddings = service.encode(test_texts)

        end_time = time.time()

        # Measure CPU and memory after
        cpu_after = psutil.cpu_percent(interval=None)
        mem_after = psutil.virtual_memory().percent

        gpu_mem = get_gpu_memory_usage()

        run_result = {
            "run": run + 1,
            "time_seconds": end_time - start_time,
            "cpu_usage_percent": (cpu_before + cpu_after) / 2,
            "memory_usage_percent": (mem_before + mem_after) / 2,
            "gpu_memory_gb": gpu_mem,
            "embeddings_count": len(embeddings),
            "embedding_dim": len(embeddings[0]) if embeddings else 0
        }

        results["runs"].append(run_result)
        print(".2f")

    return results


def main():
    """Main benchmarking function."""

    # Test texts - mix of short and long documents
    test_texts = [
        "This is a short test sentence.",
        "This is a longer test document that contains more text and should require more processing time to generate embeddings.",
        "Another document with different content for testing embedding quality and performance."
    ] * 5  # Reduced dataset for testing

    print(f"Testing with {len(test_texts)} text samples")

    # Initialize services
    print("\nInitializing embedding services...")

    try:
        sentence_transformer_service = SentenceTransformerEmbeddingService()
        print("✓ SentenceTransformer service initialized")
    except Exception as e:
        print(f"✗ Failed to initialize SentenceTransformer: {e}")
        return

    try:
        ollama_service = OllamaEmbeddingService()
        print("✓ Ollama service initialized")
    except Exception as e:
        print(f"✗ Failed to initialize Ollama: {e}")
        return

    # Run benchmarks
    num_runs = 3

    sentence_results = benchmark_embedding_service(
        "SentenceTransformer", sentence_transformer_service, test_texts, num_runs
    )

    ollama_results = benchmark_embedding_service(
        "Ollama", ollama_service, test_texts, num_runs
    )

    # Analyze results
    print("\n" + "="*60)
    print("BENCHMARK RESULTS SUMMARY")
    print("="*60)

    def summarize_results(results: Dict[str, Any]) -> Dict[str, float]:
        times = [run["time_seconds"] for run in results["runs"]]
        cpus = [run["cpu_usage_percent"] for run in results["runs"]]
        mems = [run["memory_usage_percent"] for run in results["runs"]]
        gpus = [run["gpu_memory_gb"] for run in results["runs"]]

        return {
            "avg_time": sum(times) / len(times),
            "min_time": min(times),
            "max_time": max(times),
            "avg_cpu": sum(cpus) / len(cpus),
            "avg_memory": sum(mems) / len(mems),
            "avg_gpu_memory": sum(gpus) / len(gpus)
        }

    st_summary = summarize_results(sentence_results)
    ollama_summary = summarize_results(ollama_results)

    print(f"\nSentenceTransformer Results:")
    print(f"  Average time: {st_summary['avg_time']:.2f}s (min: {st_summary['min_time']:.2f}s, max: {st_summary['max_time']:.2f}s)")
    print(f"  Average CPU usage: {st_summary['avg_cpu']:.1f}%")
    print(f"  Average memory usage: {st_summary['avg_memory']:.1f}%")
    print(f"  Average GPU memory: {st_summary['avg_gpu_memory']:.2f} GB")

    print(f"\nOllama Results:")
    print(f"  Average time: {ollama_summary['avg_time']:.2f}s (min: {ollama_summary['min_time']:.2f}s, max: {ollama_summary['max_time']:.2f}s)")
    print(f"  Average CPU usage: {ollama_summary['avg_cpu']:.1f}%")
    print(f"  Average memory usage: {ollama_summary['avg_memory']:.1f}%")
    print(f"  Average GPU memory: {ollama_summary['avg_gpu_memory']:.2f} GB")

    # Performance comparison
    time_ratio = ollama_summary['avg_time'] / st_summary['avg_time']
    print(f"\nPerformance Comparison:")
    print(f"  Ollama is {time_ratio:.2f}x {'faster' if time_ratio < 1 else 'slower'} than SentenceTransformer")
    print(f"  GPU memory usage: Ollama {ollama_summary['avg_gpu_memory']:.2f}GB vs SentenceTransformer {st_summary['avg_gpu_memory']:.2f}GB")

    # Save detailed results
    results = {
        "sentence_transformer": sentence_results,
        "ollama": ollama_results,
        "summary": {
            "sentence_transformer": st_summary,
            "ollama": ollama_summary,
            "comparison": {
                "time_ratio": time_ratio,
                "gpu_memory_ratio": ollama_summary['avg_gpu_memory'] / max(st_summary['avg_gpu_memory'], 0.01)
            }
        }
    }

    with open("ollama_gpu_comparison_results.json", "w") as f:
        json.dump(results, f, indent=2)

    print(f"\nDetailed results saved to ollama_gpu_comparison_results.json")


if __name__ == "__main__":
    main()