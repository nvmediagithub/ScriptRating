#!/usr/bin/env python3
"""Test document upload with RAG indexing to reproduce the connection error."""

import asyncio
import sys
import os
import tempfile
from pathlib import Path

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.infrastructure.services.runtime_context import get_knowledge_base
from app.domain.services.rag_orchestrator import RAGDocument

async def test_document_upload_rag():
    """Test document upload with RAG indexing."""
    print("Testing document upload with RAG indexing...")

    # Get initialized knowledge base
    kb = await get_knowledge_base()
    print("✓ KnowledgeBase retrieved")

    # Check RAG status
    rag_status = await kb.get_rag_status()
    print(f"RAG status: {rag_status}")

    # Test if RAG orchestrator is available
    if hasattr(kb, '_rag_orchestrator') and kb._rag_orchestrator:
        print("✓ RAG orchestrator is attached to KnowledgeBase")

        # Try to index a test document using RAG
        test_rag_docs = [
            RAGDocument(
                id="test_doc_1",
                text="This is a test document for RAG indexing. It contains information about script rating and content analysis.",
                metadata={
                    "document_id": "test_criteria",
                    "document_title": "Test Criteria Document",
                    "page": 1,
                    "paragraph_index": 1,
                }
            )
        ]

        try:
            print("Attempting RAG indexing...")
            indexing_result = await kb._rag_orchestrator.index_documents_batch(
                test_rag_docs,
                wait_for_indexing=True
            )
            print(f"✓ RAG indexing successful: {indexing_result}")
        except Exception as e:
            print(f"✗ RAG indexing failed: {e}")
            import traceback
            traceback.print_exc()

    else:
        print("✗ RAG orchestrator not available")

    # Test legacy knowledge base indexing
    print("\nTesting legacy KnowledgeBase indexing...")
    try:
        paragraph_details = [
            {
                "page": 1,
                "paragraph_index": 1,
                "text": "This is a test paragraph for legacy indexing."
            }
        ]

        await kb.ingest_document(
            document_id="test_legacy_doc",
            document_title="Test Legacy Document",
            paragraph_details=paragraph_details
        )
        print("✓ Legacy indexing successful")
    except Exception as e:
        print(f"✗ Legacy indexing failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_document_upload_rag())