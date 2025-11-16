#!/usr/bin/env python3
"""
Simple OpenRouter API Direct Test.

This script directly tests the OpenRouter API without complex imports.
"""

import asyncio
import json
import time
import os
from datetime import datetime
from typing import List, Dict, Any

import dotenv
import httpx

# Load environment variables from .env file
dotenv.load_dotenv()

class OpenRouterTester:
    """Direct OpenRouter API tester."""
    
    def __init__(self):
        self.api_key = os.getenv("OPENROUTER_API_KEY")
        self.base_url = "https://openrouter.ai/api/v1"
        self.test_results = []
        self.start_time = datetime.now()
        
        if not self.api_key:
            print("❌ Error: OPENROUTER_API_KEY not found in environment variables")
            return
    
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
    
    async def test_api_key_validation(self):
        """Test if API key is valid."""
        print("\n🔑 Testing API Key...")
        
        if not self.api_key:
            self.log_test("API Key Validation", False, "No API key found", 0)
            return False
        
        start_time = time.time()
        
        if self.api_key.startswith("sk-or-") and len(self.api_key) > 40:
            self.log_test(
                "API Key Validation",
                True,
                f"API key format valid: {self.api_key[:20]}...",
                time.time() - start_time,
                {"key_preview": self.api_key[:20] + "..."}
            )
            return True
        else:
            self.log_test(
                "API Key Validation",
                False,
                "Invalid API key format",
                time.time() - start_time
            )
            return False
    
    async def test_api_connection(self):
        """Test connection to OpenRouter API."""
        print("\n🌐 Testing API Connection...")
        
        start_time = time.time()
        
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://scriptrating.com",
                "X-Title": "ScriptRating"
            }
            
            async with httpx.AsyncClient(base_url=self.base_url, headers=headers, timeout=10.0) as client:
                # Test with a simple embedding request
                response = await client.post(
                    "/embeddings",
                    json={
                        "model": "openai/text-embedding-3-small",
                        "input": ["test connection"],
                        "encoding_format": "float"
                    }
                )
                
                duration = time.time() - start_time
                
                if response.status_code == 200:
                    data = response.json()
                    embedding = data["data"][0]["embedding"]
                    
                    self.log_test(
                        "API Connection",
                        True,
                        f"Connection successful, got {len(embedding)}-dim embedding",
                        duration,
                        {
                            "model_used": "openai/text-embedding-3-small",
                            "embedding_dimensions": len(embedding),
                            "response_time": duration
                        }
                    )
                    return True
                else:
                    self.log_test(
                        "API Connection",
                        False,
                        f"API returned status {response.status_code}: {response.text}",
                        duration
                    )
                    return False
                    
        except Exception as e:
            self.log_test(
                "API Connection",
                False,
                f"Connection error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_different_models(self):
        """Test different embedding models."""
        print("\n🤖 Testing Different Models...")
        
        models_to_test = [
            "openai/text-embedding-3-small",
            "openai/text-embedding-3-large",
            "cohere/embed-multilingual-v3.0"
        ]
        
        start_time = time.time()
        successful_models = []
        
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://scriptrating.com",
                "X-Title": "ScriptRating"
            }
            
            async with httpx.AsyncClient(base_url=self.base_url, headers=headers, timeout=10.0) as client:
                for model in models_to_test:
                    try:
                        response = await client.post(
                            "/embeddings",
                            json={
                                "model": model,
                                "input": [f"Test embedding for {model}"],
                                "encoding_format": "float"
                            }
                        )
                        
                        if response.status_code == 200:
                            data = response.json()
                            embedding = data["data"][0]["embedding"]
                            successful_models.append({
                                "model": model,
                                "dimensions": len(embedding),
                                "status": "success"
                            })
                        else:
                            successful_models.append({
                                "model": model,
                                "status": f"failed_{response.status_code}"
                            })
                            
                    except Exception as e:
                        successful_models.append({
                            "model": model,
                            "status": f"error_{str(e)[:50]}"
                        })
            
            duration = time.time() - start_time
            success_count = len([m for m in successful_models if m["status"] == "success"])
            
            self.log_test(
                "Model Testing",
                success_count > 0,
                f"{success_count}/{len(models_to_test)} models working",
                duration,
                {"successful_models": successful_models}
            )
            
            return success_count > 0
            
        except Exception as e:
            self.log_test(
                "Model Testing",
                False,
                f"Error testing models: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_batch_processing(self):
        """Test batch embedding processing."""
        print("\n📦 Testing Batch Processing...")
        
        test_texts = [
            "This is the first test sentence.",
            "Here comes another example text.",
            "Batch processing should handle multiple texts efficiently.",
            "Quality embeddings are important for semantic search.",
            "OpenRouter provides free access to these models."
        ]
        
        start_time = time.time()
        
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://scriptrating.com",
                "X-Title": "ScriptRating"
            }
            
            async with httpx.AsyncClient(base_url=self.base_url, headers=headers, timeout=30.0) as client:
                response = await client.post(
                    "/embeddings",
                    json={
                        "model": "openai/text-embedding-3-large",
                        "input": test_texts,
                        "encoding_format": "float"
                    }
                )
                
                duration = time.time() - start_time
                
                if response.status_code == 200:
                    data = response.json()
                    embeddings = data["data"]
                    
                    self.log_test(
                        "Batch Processing",
                        len(embeddings) == len(test_texts),
                        f"Processed {len(embeddings)}/{len(test_texts)} texts in {duration:.2f}s",
                        duration,
                        {
                            "input_count": len(test_texts),
                            "output_count": len(embeddings),
                            "average_time_per_text": duration / len(test_texts),
                            "embedding_dimensions": len(embeddings[0]["embedding"]) if embeddings else 0
                        }
                    )
                    return len(embeddings) == len(test_texts)
                else:
                    self.log_test(
                        "Batch Processing",
                        False,
                        f"API returned status {response.status_code}",
                        duration
                    )
                    return False
                    
        except Exception as e:
            self.log_test(
                "Batch Processing",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_rate_limits(self):
        """Test rate limiting behavior."""
        print("\n⏱️ Testing Rate Limits...")
        
        start_time = time.time()
        success_count = 0
        
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://scriptrating.com",
                "X-Title": "ScriptRating"
            }
            
            async with httpx.AsyncClient(base_url=self.base_url, headers=headers, timeout=10.0) as client:
                # Make 3 rapid requests
                for i in range(3):
                    try:
                        response = await client.post(
                            "/embeddings",
                            json={
                                "model": "openai/text-embedding-3-small",
                                "input": [f"Rate limit test {i+1}"],
                                "encoding_format": "float"
                            }
                        )
                        
                        if response.status_code == 200:
                            success_count += 1
                        else:
                            print(f"  Request {i+1}: Status {response.status_code}")
                            
                    except Exception as e:
                        print(f"  Request {i+1}: Error {str(e)}")
            
            duration = time.time() - start_time
            
            self.log_test(
                "Rate Limit Testing",
                success_count >= 2,  # At least 2 should succeed
                f"{success_count}/3 requests successful",
                duration,
                {"successful_requests": success_count}
            )
            
            return success_count >= 2
            
        except Exception as e:
            self.log_test(
                "Rate Limit Testing",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    async def test_semantic_quality(self):
        """Test semantic quality of embeddings."""
        print("\n🧠 Testing Semantic Quality...")
        
        start_time = time.time()
        
        try:
            # Test similar and different texts
            similar_pairs = [
                ("The cat sat on the mat.", "A feline rested on the rug."),
                ("It is raining heavily today.", "The precipitation is quite heavy now.")
            ]
            
            different_pairs = [
                ("The cat sat on the mat.", "I need to buy groceries."),
                ("It is raining heavily today.", "The stock market went up.")
            ]
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://scriptrating.com",
                "X-Title": "ScriptRating"
            }
            
            async with httpx.AsyncClient(base_url=self.base_url, headers=headers, timeout=10.0) as client:
                # Test similar pairs
                similar_texts = [pair[0] for pair in similar_pairs] + [pair[1] for pair in similar_pairs]
                response = await client.post(
                    "/embeddings",
                    json={
                        "model": "openai/text-embedding-3-large",
                        "input": similar_texts,
                        "encoding_format": "float"
                    }
                )
                
                if response.status_code != 200:
                    raise Exception(f"Failed to get embeddings: {response.status_code}")
                
                data = response.json()
                embeddings = [item["embedding"] for item in data["data"]]
                
                # Calculate similarities
                def cosine_similarity(a, b):
                    dot_product = sum(x * y for x, y in zip(a, b))
                    norm_a = sum(x * x for x in a) ** 0.5
                    norm_b = sum(x * x for x in b) ** 0.5
                    return dot_product / (norm_a * norm_b) if norm_a * norm_b != 0 else 0
                
                # Similar pairs should have higher similarity
                sim1 = cosine_similarity(embeddings[0], embeddings[1])
                sim2 = cosine_similarity(embeddings[2], embeddings[3])
                avg_similar = (sim1 + sim2) / 2
                
                # Test different pairs
                different_texts = [pair[0] for pair in different_pairs] + [pair[1] for pair in different_pairs]
                response = await client.post(
                    "/embeddings",
                    json={
                        "model": "openai/text-embedding-3-large",
                        "input": different_texts,
                        "encoding_format": "float"
                    }
                )
                
                if response.status_code != 200:
                    raise Exception(f"Failed to get embeddings: {response.status_code}")
                
                data = response.json()
                embeddings = [item["embedding"] for item in data["data"]]
                
                # Different pairs should have lower similarity
                diff1 = cosine_similarity(embeddings[0], embeddings[1])
                diff2 = cosine_similarity(embeddings[2], embeddings[3])
                avg_different = (diff1 + diff2) / 2
                
                quality_score = avg_similar - avg_different
                
            duration = time.time() - start_time
            
            self.log_test(
                "Semantic Quality",
                quality_score > 0.1,  # Threshold for reasonable semantic understanding
                f"Quality score: {quality_score:.3f}",
                duration,
                {
                    "avg_similar_similarity": avg_similar,
                    "avg_different_similarity": avg_different,
                    "quality_score": quality_score
                }
            )
            
            return quality_score > 0.1
            
        except Exception as e:
            self.log_test(
                "Semantic Quality",
                False,
                f"Error: {str(e)}",
                time.time() - start_time
            )
            return False
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate test report."""
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result["success"])
        
        report = {
            "test_summary": {
                "total_tests": total_tests,
                "passed_tests": passed_tests,
                "failed_tests": total_tests - passed_tests,
                "success_rate": (passed_tests / total_tests) * 100 if total_tests > 0 else 0,
                "test_session_start": self.start_time.isoformat(),
                "test_session_end": datetime.now().isoformat(),
                "api_key_used": self.api_key[:20] + "..." if self.api_key else "None"
            },
            "test_results": self.test_results,
            "recommendations": []
        }
        
        # Add recommendations
        if passed_tests < total_tests:
            report["recommendations"].append("Some tests failed - check API key and network connection")
        
        if any("timeout" in result["details"].lower() for result in self.test_results):
            report["recommendations"].append("Consider increasing timeout values for slow API calls")
        
        return report


async def main():
    """Main test execution."""
    print("🧪 OpenRouter Real API Direct Test")
    print("=" * 50)
    
    tester = OpenRouterTester()
    
    if not tester.api_key:
        print("❌ Cannot proceed without OPENROUTER_API_KEY")
        return
    
    try:
        # Run all tests
        tests = [
            tester.test_api_key_validation,
            tester.test_api_connection,
            tester.test_different_models,
            tester.test_batch_processing,
            tester.test_rate_limits,
            tester.test_semantic_quality,
        ]
        
        for test in tests:
            try:
                await test()
            except Exception as e:
                tester.log_test(
                    test.__name__,
                    False,
                    f"Test execution failed: {str(e)}",
                    0
                )
        
        # Generate and save report
        report = tester.generate_report()
        
        with open("openrouter_direct_test_results.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        # Print summary
        print("\n" + "=" * 50)
        print("📊 TEST SUMMARY")
        print("=" * 50)
        print(f"Total Tests: {report['test_summary']['total_tests']}")
        print(f"Passed: {report['test_summary']['passed_tests']}")
        print(f"Failed: {report['test_summary']['failed_tests']}")
        print(f"Success Rate: {report['test_summary']['success_rate']:.1f}%")
        print(f"API Key: {report['test_summary']['api_key_used']}")
        
        if report['recommendations']:
            print("\n💡 RECOMMENDATIONS:")
            for rec in report['recommendations']:
                print(f"  • {rec}")
        
        print(f"\n📄 Detailed report saved to: openrouter_direct_test_results.json")
        
    except Exception as e:
        print(f"❌ Test execution failed: {str(e)}")


if __name__ == "__main__":
    asyncio.run(main())