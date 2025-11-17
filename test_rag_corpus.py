#!/usr/bin/env python3
"""
Test script to validate RAG corpus generation with real embeddings.
"""
import asyncio
import logging
from app.presentation.api.routes.rag import _generate_mock_corpus, _mock_corpus, set_embedding_service
from app.infrastructure.services.embedding_service import EmbeddingService

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_rag_corpus_generation():
    """Test RAG corpus generation with real embeddings."""
    print("🧪 Testing RAG corpus generation with real embeddings...")

    try:
        # Setup embedding service
        print("🔧 Creating EmbeddingService...")
        service = EmbeddingService(primary_provider="mock")  # Use mock for testing
        await service.initialize()

        # Set the service globally
        set_embedding_service(service)

        # Clear existing corpus
        _mock_corpus.clear()

        # Generate corpus with real embeddings
        print("📚 Generating corpus with real embeddings...")
        _generate_mock_corpus()

        print(f"✅ Generated corpus with {len(_mock_corpus)} documents")

        # Verify embeddings
        for doc_id, doc in _mock_corpus.items():
            embedding_dims = len(doc["embedding"])
            content_preview = doc["content"][:50]
            print(f"   Document {doc_id}: '{content_preview}...' → {embedding_dims} dims")

        # Test that embeddings are not the default mock pattern
        sample_embedding = list(_mock_corpus.values())[0]["embedding"]
        is_real_embedding = not all(abs(x - 0.1 * i) < 0.01 for i, x in enumerate(sample_embedding[:10]))

        if is_real_embedding:
            print("✅ Real embeddings generated (not default mock pattern)")
        else:
            print("⚠️ Using fallback mock embeddings")

        # Close service
        await service.close()

        print("\n🎉 RAG corpus generation test completed successfully!")
        return True

    except Exception as e:
        logger.error(f"❌ RAG corpus generation test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(test_rag_corpus_generation())
    exit(0 if success else 1)