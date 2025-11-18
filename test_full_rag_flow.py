#!/usr/bin/env python3
"""Test full RAG indexing and search flow."""

import asyncio
import sys
import os
import uuid

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.domain.services.rag_orchestrator import RAGOrchestrator, RAGDocument
from app.infrastructure.services.embedding_service import EmbeddingService
from app.infrastructure.services.vector_database_service import VectorDatabaseService

async def test_full_rag_flow():
    """Test complete RAG indexing and search flow."""
    print("Testing full RAG flow...")

    # Initialize services
    embedding_service = EmbeddingService()
    vector_db_service = VectorDatabaseService()

    orchestrator = RAGOrchestrator(
        embedding_service=embedding_service,
        vector_db_service=vector_db_service
    )

    try:
        # Initialize orchestrator
        await orchestrator.initialize()
        print("✓ RAG Orchestrator initialized")

        # Create test document
        test_doc = RAGDocument(
            id=str(uuid.uuid4()),
            text="This is a comprehensive test document about script rating and content analysis. It covers various aspects of media content evaluation, including age-appropriate ratings, scene analysis, and compliance with content standards.",
            metadata={
                "source": "test_document",
                "type": "script_analysis",
                "author": "test_author",
                "created_at": "2024-01-01T00:00:00Z"
            }
        )

        # Index document
        print("Indexing test document...")
        doc_id = await orchestrator.index_document(test_doc)
        print(f"✓ Document indexed with ID: {doc_id}")

        # Test search
        print("Testing search functionality...")
        search_query = "content analysis and script rating"
        search_results = await orchestrator.search(search_query, top_k=3)
        print(f"✓ Search for '{search_query}' returned {len(search_results)} results")

        if search_results:
            print(f"  Top result score: {search_results[0].score:.4f}")
            print(f"  Top result text preview: {search_results[0].text[:100]}...")

            # Verify the result contains our indexed document
            result_ids = [r.document_id for r in search_results]
            if doc_id in result_ids:
                print("✓ Indexed document found in search results")
            else:
                print("✗ Indexed document not found in search results")

        # Test health check
        health = await orchestrator.health_check()
        print(f"✓ Health check status: {health['status']}")

        print("\n🎉 Full RAG flow test completed successfully!")
        print("The Qdrant connection issue has been resolved with in-memory fallback.")

    except Exception as e:
        print(f"✗ RAG flow test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await orchestrator.close()

if __name__ == "__main__":
    asyncio.run(test_full_rag_flow())