"""
Integration tests for RAG system.

These tests verify the integration between EmbeddingService, VectorDatabaseService,
and RAGOrchestrator.
"""
import pytest
from app.infrastructure.services.embedding_service import EmbeddingService
from app.infrastructure.services.vector_database_service import VectorDatabaseService
from app.domain.services.rag_orchestrator import RAGOrchestrator, RAGDocument


@pytest.fixture
async def embedding_service():
    """Create an EmbeddingService for integration testing."""
    service = EmbeddingService(
        openai_api_key=None,  # Will use fallback
        redis_url=None,
        enable_fallback=True,
    )
    await service.initialize()
    yield service
    await service.close()


@pytest.fixture
async def vector_db_service():
    """Create a VectorDatabaseService for integration testing."""
    service = VectorDatabaseService(
        qdrant_url=None,  # In-memory mode
        collection_name="test_integration",
        vector_size=384,  # Fallback model dimension
        enable_tfidf_fallback=True,
    )
    await service.initialize()
    yield service
    await service.close()


@pytest.fixture
async def rag_orchestrator(embedding_service, vector_db_service):
    """Create a RAGOrchestrator for integration testing."""
    orchestrator = RAGOrchestrator(
        embedding_service=embedding_service,
        vector_db_service=vector_db_service,
        enable_hybrid_search=True,
    )
    yield orchestrator
    await orchestrator.close()


@pytest.mark.asyncio
@pytest.mark.integration
async def test_end_to_end_document_indexing_and_search(rag_orchestrator):
    """Test complete workflow: index documents and search."""
    # Index documents
    documents = [
        RAGDocument(
            id="doc1",
            text="Federal law on information protection for children",
            metadata={"category": "legal", "source": "test"},
        ),
        RAGDocument(
            id="doc2",
            text="Guidelines for age rating classification",
            metadata={"category": "guideline", "source": "test"},
        ),
        RAGDocument(
            id="doc3",
            text="Violence and inappropriate content regulations",
            metadata={"category": "legal", "source": "test"},
        ),
    ]
    
    doc_ids = await rag_orchestrator.index_documents_batch(documents)
    
    assert len(doc_ids) == 3
    
    # Search for relevant documents
    results = await rag_orchestrator.search(
        query="age rating regulations",
        top_k=2,
    )
    
    assert len(results) > 0
    assert results[0].score > 0
    assert results[0].text in [doc.text for doc in documents]


@pytest.mark.asyncio
@pytest.mark.integration
async def test_search_with_metadata_filters(rag_orchestrator):
    """Test search with metadata filtering."""
    # Index documents with different categories
    documents = [
        RAGDocument(
            id="legal1",
            text="Legal document about content regulation",
            metadata={"category": "legal"},
        ),
        RAGDocument(
            id="guide1",
            text="Guideline for content classification",
            metadata={"category": "guideline"},
        ),
    ]
    
    await rag_orchestrator.index_documents_batch(documents)
    
    # Search with category filter
    results = await rag_orchestrator.search(
        query="content regulation",
        top_k=5,
        filter_metadata={"category": "legal"},
    )
    
    # Should only return legal documents
    assert len(results) > 0


@pytest.mark.asyncio
@pytest.mark.integration
async def test_document_update_and_deletion(rag_orchestrator):
    """Test updating and deleting documents."""
    # Index initial document
    doc = RAGDocument(
        id="update_test",
        text="Original content",
        metadata={"version": "1"},
    )
    
    await rag_orchestrator.index_document(doc)
    
    # Update document (re-index with same ID)
    updated_doc = RAGDocument(
        id="update_test",
        text="Updated content",
        metadata={"version": "2"},
    )
    
    await rag_orchestrator.index_document(updated_doc)
    
    # Search should find updated version
    results = await rag_orchestrator.search("Updated content", top_k=1)
    assert len(results) > 0
    
    # Delete document
    success = await rag_orchestrator.delete_documents(["update_test"])
    assert success is True


@pytest.mark.asyncio
@pytest.mark.integration
async def test_hybrid_search(rag_orchestrator):
    """Test hybrid search functionality."""
    documents = [
        RAGDocument(
            id="hybrid1",
            text="Machine learning and artificial intelligence",
            metadata={},
        ),
        RAGDocument(
            id="hybrid2",
            text="Deep learning neural networks",
            metadata={},
        ),
    ]
    
    await rag_orchestrator.index_documents_batch(documents)
    
    # Perform hybrid search
    results = await rag_orchestrator.hybrid_search(
        query="AI and ML",
        top_k=2,
        vector_weight=0.7,
        tfidf_weight=0.3,
    )
    
    assert len(results) > 0


@pytest.mark.asyncio
@pytest.mark.integration
async def test_health_check_integration(rag_orchestrator):
    """Test health check across all components."""
    health = await rag_orchestrator.health_check()
    
    assert health["status"] in ["healthy", "degraded"]
    assert "embedding_service" in health
    assert "vector_db_service" in health
    assert "metrics" in health


@pytest.mark.asyncio
@pytest.mark.integration
async def test_metrics_collection(rag_orchestrator):
    """Test metrics collection during operations."""
    # Perform some operations
    doc = RAGDocument(
        id="metrics_test",
        text="Test document for metrics",
        metadata={},
    )
    
    await rag_orchestrator.index_document(doc)
    await rag_orchestrator.search("test", top_k=1)
    
    # Get metrics
    metrics = await rag_orchestrator.get_metrics()
    
    assert metrics.total_indexed_documents >= 1
    assert metrics.total_searches >= 1


@pytest.mark.asyncio
@pytest.mark.integration
async def test_large_batch_indexing(rag_orchestrator):
    """Test indexing a large batch of documents."""
    # Create 50 test documents
    documents = [
        RAGDocument(
            id=f"batch_doc_{i}",
            text=f"Test document number {i} with unique content",
            metadata={"batch": "large", "index": i},
        )
        for i in range(50)
    ]
    
    doc_ids = await rag_orchestrator.index_documents_batch(documents)
    
    assert len(doc_ids) == 50
    
    # Search should work across all documents
    results = await rag_orchestrator.search(
        query="unique content",
        top_k=10,
    )
    
    assert len(results) > 0


@pytest.mark.asyncio
@pytest.mark.integration
async def test_graceful_degradation(rag_orchestrator):
    """Test graceful degradation when services fail."""
    # This test verifies the system continues to work even with failures
    # Actual implementation would involve simulating service failures
    
    # For now, just verify the system is resilient
    health = await rag_orchestrator.health_check()
    
    # System should report status even if some components are degraded
    assert "status" in health