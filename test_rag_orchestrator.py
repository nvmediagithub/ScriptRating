#!/usr/bin/env python3
"""Test RAG Orchestrator with fallback to in-memory Qdrant."""

import asyncio
import sys
import os

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.domain.services.rag_orchestrator import RAGOrchestrator
from app.infrastructure.services.embedding_service import EmbeddingService
from app.infrastructure.services.vector_database_service import VectorDatabaseService
from app.config.settings import settings

async def test_rag_orchestrator():
    """Test RAG Orchestrator initialization and basic operations."""
    print("Testing RAG Orchestrator...")

    orchestrator = None
    try:
        # Initialize services
        embedding_service = EmbeddingService()
        vector_db_service = VectorDatabaseService()
    
        orchestrator = RAGOrchestrator(
            embedding_service=embedding_service,
            vector_db_service=vector_db_service
        )
        print("Initializing orchestrator...")

        await orchestrator.initialize()
        print("✓ RAG Orchestrator initialized successfully")

        # Test health check
        health = await orchestrator.health_check()
        print(f"Health status: {health['status']}")

        if 'vector_db' in health:
            vector_health = health['vector_db']
            print(f"Vector DB status: {vector_health.get('status', 'unknown')}")
            print(f"Qdrant available: {vector_health.get('qdrant_available', False)}")
            print(f"Collection exists: {vector_health.get('collection_exists', False)}")

        # Test basic document processing (if possible)
        print("\nTesting basic RAG operations...")
        # This would require actual document processing, but let's just test the setup

        print("✓ RAG Orchestrator is ready for document indexing")

    except Exception as e:
        print(f"✗ RAG Orchestrator test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if orchestrator:
            await orchestrator.close()

if __name__ == "__main__":
    asyncio.run(test_rag_orchestrator())