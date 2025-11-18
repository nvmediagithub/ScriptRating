#!/usr/bin/env python3
"""Test VectorDatabaseService initialization and fallbacks."""

import asyncio
import sys
import os
import uuid

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from infrastructure.services.vector_database_service import VectorDatabaseService

async def test_vector_service():
    """Test VectorDatabaseService with fallback logic."""
    print("Testing VectorDatabaseService...")

    service = None
    try:
        service = VectorDatabaseService()
        print("Initializing service...")

        await service.initialize()
        print("✓ Service initialized successfully")

        # Test health check
        health = await service.health_check()
        print("Health check result:")
        print(f"  Status: {health['status']}")
        print(f"  Qdrant available: {health['qdrant_available']}")
        print(f"  Collection exists: {health['collection_exists']}")
        print(f"  TF-IDF fallback available: {health['tfidf_fallback_available']}")

        if health['collection_exists'] and 'collection_info' in health:
            info = health['collection_info']
            print(f"  Points count: {info['points_count']}")
            print(f"  Vectors count: {info['vectors_count']}")

        # Test basic operations
        print("\nTesting basic operations...")

        # Test upsert
        test_docs = [
            {
                "id": str(uuid.uuid4()),  # Use proper UUID
                "vector": [0.1] * 1536,  # OpenAI embedding size
                "payload": {
                    "text": "This is a test document for RAG system",
                    "source": "test",
                    "timestamp": "2024-01-01T00:00:00Z"
                }
            }
        ]

        doc_ids = await service.upsert_documents(test_docs)
        print(f"✓ Upserted {len(doc_ids)} documents: {doc_ids}")

        # Test search
        search_results = await service.search([0.1] * 1536, limit=5)
        print(f"✓ Search returned {len(search_results)} results")

        if search_results:
            print(f"  Top result score: {search_results[0].score:.4f}")
            print(f"  Top result payload keys: {list(search_results[0].payload.keys())}")

        print("\n✓ All tests passed! RAG system should work now.")

    except Exception as e:
        print(f"✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if service:
            await service.close()

if __name__ == "__main__":
    asyncio.run(test_vector_service())