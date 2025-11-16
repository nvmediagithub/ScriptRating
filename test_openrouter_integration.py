#!/usr/bin/env python3
"""
OpenRouter Real API Integration Test.

This script tests the EmbeddingService with real OpenRouter API
using the actual .env configuration.
"""

import asyncio
import json
import time
import os
from datetime import datetime
from typing import List, Dict, Any

# Add the app directory to the path
import sys
sys.path.append('./app')
sys.path.append('./')  # Add root directory

# Import required modules
from app.infrastructure.services.embedding_service import EmbeddingService, create_embedding_service


class OpenRouterTestRunner:
    """Test runner for OpenRouter API integration."""
    
    def __init__(self):
        self.test_results = []
        self.embedding_service = None
        self.start_time = datetime.now()
    
    def log_test(self, test_name: str, success: bool, details: str = "", duration: float = 0, data: Any = None):
        """Log test result."""
        result = {
            "test_name": test_name,
            "success": success,
            "details": details,
            "duration": duration,
            "timestamp": datetime.now().isoformat(),
            "data": data
        }
        self.test_results.append(result)
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}: {details} ({duration:.2f}s)")
    
    async def test_configuration_loading(self):
        """Test that configuration is loaded correctly from .env."""
        print("\n🔧 Testing Configuration Loading...")
        
        start_time = time.time()
        try:
            # Check if OpenRouter API key is available
            import os
            api_key = os.getenv("OPENROUTER_API_KEY")
            base_model = os.getenv("OPENROUTER_BASE_MODEL")
            
            if api_key and api_key != "your-openai-key":
                self.log_test(
                    "OpenRouter API Key Loading",
                    True,
                    f"API key loaded: {api_key[:20]}...",
                    time.time() - start_time,
                    {"api_key_preview": api_key[:20] + "..."}
                )
            else:
                self.log_test(
                    "OpenRouter API Key Loading",
                    False,
                    "API key not found or invalid",
                    time.time() - start_time
                )
                return False
            
            if base_model:
                self.log_test(
                    "OpenRouter Base Model",
                    True,
                    f"Model: {base_model}",
                    0,
                    {"model": base_model}
                )
            else:
                self.log_test(
                    "OpenRouter Base Model",
                    False,
                    "Base model not configured",
                    0
                )
            
            return True
            
        except Exception as e:
            self.log_test(
                "Configuration Loading",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_embedding_service_creation(self):
        """Test EmbeddingService creation with real configuration."""
        print("\n🚀 Testing EmbeddingService Creation...")
        
        start_time = time.time()
        try:
            import os
            api_key = os.getenv("OPENROUTER_API_KEY")
            
            self.embedding_service = create_embedding_service(
                openrouter_api_key=api_key,
                primary_provider="openrouter"
            )
            
            # Initialize the service
            await self.embedding_service.initialize()
            
            self.log_test(
                "EmbeddingService Creation",
                True,
                "Service created and initialized successfully",
                time.time() - start_time
            )
            
            return True
            
        except Exception as e:
            self.log_test(
                "EmbeddingService Creation",
                False,
                f"Failed to create service: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_single_embedding(self):
        """Test single embedding generation."""
        print("\n📝 Testing Single Embedding Generation...")
        
        if not self.embedding_service:
            self.log_test("Single Embedding", False, "EmbeddingService not initialized", 0)
            return False
        
        start_time = time.time()
        try:
            test_text = "This is a test sentence for embedding generation using OpenRouter API."
            
            result = await self.embedding_service.embed_text(test_text)
            
            duration = time.time() - start_time
            
            if result and result.embedding and len(result.embedding) > 0:
                self.log_test(
                    "Single Embedding Generation",
                    True,
                    f"Generated {len(result.embedding)}-dim embedding with {result.provider}",
                    duration,
                    {
                        "provider": result.provider,
                        "model": result.model,
                        "dimensions": len(result.embedding),
                        "cached": result.cached,
                        "embedding_sample": result.embedding[:5]  # First 5 values for verification
                    }
                )
                return True
            else:
                self.log_test(
                    "Single Embedding Generation",
                    False,
                    "Empty or invalid embedding result",
                    duration
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Single Embedding Generation",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_batch_embeddings(self):
        """Test batch embedding generation."""
        print("\n📚 Testing Batch Embedding Generation...")
        
        if not self.embedding_service:
            self.log_test("Batch Embeddings", False, "EmbeddingService not initialized", 0)
            return False
        
        start_time = time.time()
        try:
            test_texts = [
                "Artificial intelligence is transforming the world.",
                "Machine learning algorithms require large datasets.",
                "Natural language processing enables text understanding.",
                "Deep learning networks can recognize complex patterns.",
                "Neural networks simulate human brain functionality."
            ]
            
            results = await self.embedding_service.embed_batch(test_texts)
            
            duration = time.time() - start_time
            
            if results and len(results) == len(test_texts):
                successful_results = [r for r in results if r.embedding and len(r.embedding) > 0]
                
                self.log_test(
                    "Batch Embedding Generation",
                    True,
                    f"Processed {len(successful_results)}/{len(test_texts)} texts",
                    duration,
                    {
                        "total_texts": len(test_texts),
                        "successful_embeddings": len(successful_results),
                        "providers_used": list(set(r.provider for r in results)),
                        "average_dimensions": sum(len(r.embedding) for r in successful_results) / len(successful_results) if successful_results else 0
                    }
                )
                return True
            else:
                self.log_test(
                    "Batch Embedding Generation",
                    False,
                    f"Expected {len(test_texts)} results, got {len(results) if results else 0}",
                    duration
                )
                return False
                
        except Exception as e:
            self.log_test(
                "Batch Embedding Generation",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_embedding_quality(self):
        """Test embedding quality and semantic similarity."""
        print("\n🎯 Testing Embedding Quality...")
        
        if not self.embedding_service:
            self.log_test("Embedding Quality", False, "EmbeddingService not initialized", 0)
            return False
        
        start_time = time.time()
        try:
            # Test semantic similarity
            similar_texts = [
                "The weather is sunny today.",
                "It's a bright and sunny day outside."
            ]
            
            different_texts = [
                "The weather is sunny today.",
                "I need to buy groceries from the store."
            ]
            
            similar_results = await self.embedding_service.embed_batch(similar_texts)
            different_results = await self.embedding_service.embed_batch(different_texts)
            
            def cosine_similarity(a: List[float], b: List[float]) -> float:
                dot_product = sum(x * y for x, y in zip(a, b))
                norm_a = sum(x * x for x in a) ** 0.5
                norm_b = sum(x * x for x in b) ** 0.5
                return dot_product / (norm_a * norm_b) if norm_a * norm_b != 0 else 0
            
            similar_sim = cosine_similarity(similar_results[0].embedding, similar_results[1].embedding)
            different_sim = cosine_similarity(different_results[0].embedding, different_results[1].embedding)
            
            quality_score = similar_sim - different_sim  # Higher is better
            
            duration = time.time() - start_time
            
            self.log_test(
                "Embedding Quality (Semantic Similarity)",
                quality_score > 0.1,  # Threshold for reasonable semantic understanding
                f"Similarity difference: {quality_score:.3f}",
                duration,
                {
                    "similar_texts_similarity": similar_sim,
                    "different_texts_similarity": different_sim,
                    "quality_score": quality_score,
                    "provider": similar_results[0].provider
                }
            )
            
            return quality_score > 0.1
            
        except Exception as e:
            self.log_test(
                "Embedding Quality",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_caching(self):
        """Test embedding caching functionality."""
        print("\n💾 Testing Embedding Cache...")
        
        if not self.embedding_service:
            self.log_test("Embedding Cache", False, "EmbeddingService not initialized", 0)
            return False
        
        start_time = time.time()
        try:
            test_text = "This text should be cached after the first request."
            
            # First request (should not be cached)
            result1 = await self.embedding_service.embed_text(test_text)
            
            # Second request (should be cached)
            result2 = await self.embedding_service.embed_text(test_text)
            
            duration = time.time() - start_time
            
            # Check if second request was cached
            cached = result2.cached if result2 else False
            
            self.log_test(
                "Embedding Cache",
                cached,
                f"Cache hit: {cached}",
                duration,
                {
                    "first_request_cached": result1.cached if result1 else False,
                    "second_request_cached": result2.cached if result2 else False,
                    "same_embedding": (result1.embedding == result2.embedding) if result1 and result2 else False
                }
            )
            
            return cached
            
        except Exception as e:
            self.log_test(
                "Embedding Cache",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_health_check(self):
        """Test service health check."""
        print("\n🏥 Testing Health Check...")
        
        if not self.embedding_service:
            self.log_test("Health Check", False, "EmbeddingService not initialized", 0)
            return False
        
        start_time = time.time()
        try:
            health = await self.embedding_service.health_check()
            
            duration = time.time() - start_time
            
            # Check if health status is reasonable
            providers_healthy = any(
                provider.get("status") == "healthy" 
                for provider in health.get("providers", {}).values()
            )
            
            self.log_test(
                "Health Check",
                providers_healthy,
                f"Status: {health.get('status', 'unknown')}",
                duration,
                {
                    "overall_status": health.get("status"),
                    "available_providers": list(health.get("providers", {}).keys()),
                    "healthy_providers": [
                        name for name, data in health.get("providers", {}).items() 
                        if data.get("status") == "healthy"
                    ],
                    "metrics": health.get("metrics", {})
                }
            )
            
            return providers_healthy
            
        except Exception as e:
            self.log_test(
                "Health Check",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def cleanup(self):
        """Cleanup resources."""
        if self.embedding_service:
            await self.embedding_service.close()
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate test report."""
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result["success"])
        total_duration = sum(result["duration"] for result in self.test_results)
        
        report = {
            "test_summary": {
                "total_tests": total_tests,
                "passed_tests": passed_tests,
                "failed_tests": total_tests - passed_tests,
                "success_rate": (passed_tests / total_tests) * 100 if total_tests > 0 else 0,
                "total_duration": total_duration,
                "test_session_start": self.start_time.isoformat(),
                "test_session_end": datetime.now().isoformat()
            },
            "test_results": self.test_results,
            "recommendations": []
        }
        
        # Add recommendations based on test results
        if passed_tests < total_tests:
            report["recommendations"].append("Some tests failed - check API key and configuration")
        
        if any("timeout" in result["details"].lower() for result in self.test_results):
            report["recommendations"].append("Consider increasing timeout values for slow API calls")
        
        if not any(result["test_name"] == "Embedding Cache" and result["success"] for result in self.test_results):
            report["recommendations"].append("Cache functionality may not be working - check Redis configuration")
        
        return report


async def main():
    """Main test execution."""
    print("🧪 OpenRouter Real API Integration Test")
    print("=" * 50)
    
    test_runner = OpenRouterTestRunner()
    
    try:
        # Run all tests
        tests = [
            test_runner.test_configuration_loading,
            test_runner.test_embedding_service_creation,
            test_runner.test_single_embedding,
            test_runner.test_batch_embeddings,
            test_runner.test_embedding_quality,
            test_runner.test_caching,
            test_runner.test_health_check,
        ]
        
        for test in tests:
            try:
                await test()
            except Exception as e:
                test_runner.log_test(
                    test.__name__,
                    False,
                    f"Test execution failed: {str(e)}",
                    0
                )
        
        # Generate and save report
        report = test_runner.generate_report()
        
        with open("openrouter_test_results.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        # Print summary
        print("\n" + "=" * 50)
        print("📊 TEST SUMMARY")
        print("=" * 50)
        print(f"Total Tests: {report['test_summary']['total_tests']}")
        print(f"Passed: {report['test_summary']['passed_tests']}")
        print(f"Failed: {report['test_summary']['failed_tests']}")
        print(f"Success Rate: {report['test_summary']['success_rate']:.1f}%")
        print(f"Total Duration: {report['test_summary']['total_duration']:.2f}s")
        
        if report['recommendations']:
            print("\n💡 RECOMMENDATIONS:")
            for rec in report['recommendations']:
                print(f"  • {rec}")
        
        print(f"\n📄 Detailed report saved to: openrouter_test_results.json")
        
    finally:
        await test_runner.cleanup()


if __name__ == "__main__":
    asyncio.run(main())