#!/usr/bin/env python3
"""
Test script to validate RAG integration with real EmbeddingService.
"""
import asyncio
import logging
from app.infrastructure.services.embedding_service import EmbeddingService

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_rag_integration():
    """Test RAG integration with EmbeddingService."""
    print("🧪 Testing RAG integration with EmbeddingService...")

    try:
        # Create EmbeddingService
        print("🔧 Creating EmbeddingService...")
        embedding_service = EmbeddingService(primary_provider="mock")  # Use mock for testing

        # Initialize service
        print("🚀 Initializing EmbeddingService...")
        await embedding_service.initialize()

        # Test embedding generation
        test_text = "Это тестовый текст для проверки интеграции с RAG."
        print(f"🧮 Generating embedding for: {test_text}")

        result = await embedding_service.embed_text(test_text)

        print("✅ Embedding generated successfully!")
        print(f"   Provider: {result.provider}")
        print(f"   Model: {result.model}")
        print(f"   Dimensions: {len(result.embedding)}")
        print(f"   Cached: {result.cached}")
        print(f"   First 5 values: {result.embedding[:5]}")

        # Test batch embeddings
        print("\n📦 Testing batch embeddings...")
        batch_texts = [
            "Насилие в фильмах для детей недопустимо.",
            "Фильмы должны иметь возрастные ограничения.",
            "Классификация по категориям: 0+, 6+, 12+, 16+, 18+."
        ]

        batch_results = await embedding_service.embed_batch(batch_texts)

        print(f"✅ Batch embeddings generated: {len(batch_results)}")
        for i, result in enumerate(batch_results):
            print(f"   {i+1}. {result.provider} - {len(result.embedding)} dims")

        # Test health check
        print("\n🏥 Testing health check...")
        health = await embedding_service.health_check()
        print(f"✅ Health status: {health['status']}")

        # Close service
        print("\n🔒 Closing EmbeddingService...")
        await embedding_service.close()

        print("\n🎉 RAG integration test completed successfully!")
        return True

    except Exception as e:
        logger.error(f"❌ RAG integration test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(test_rag_integration())
    exit(0 if success else 1)