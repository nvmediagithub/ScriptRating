"""
Unit tests for RAGOrchestrator.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.domain.services.rag_orchestrator import (
    RAGOrchestrator,
    RAGDocument,
    RAGSearchResult,
    RAGMetrics,
)
from app.infrastructure.services.embedding_service import EmbeddingService, EmbeddingResult
from app.infrastructure.services.vector_database_service import (
    VectorDatabaseService,
    VectorSearchResult,
)


@pytest.fixture
def mock_embedding_service():
    """Create a mock EmbeddingService."""
    service = AsyncMock(spec=EmbeddingService)
    service.embed_text = AsyncMock(return_value=EmbeddingResult(
        text="test",
        embedding=[0.1] * 1536,
        model="test-model",
        cached=False,
    ))
    service.embed_batch = AsyncMock(return_value=[
        EmbeddingResult(text="text1", embedding=[0.1] * 1536, model="test-model"),
        EmbeddingResult(text="text2", embedding=[0.2] * 1536, model="test-model"),
    ])
    service.health_check = AsyncMock(return_value={"status": "healthy"})
    service.get_metrics = MagicMock(return_value={"cache_hit_rate": 0.5})
    service.close = AsyncMock()
    return service


@pytest.fixture
def mock_vector_db_service():
    """Create a mock VectorDatabaseService."""
    service = AsyncMock(spec=VectorDatabaseService)
    service.upsert_documents = AsyncMock(return_value=["doc1", "doc2"])
    service.delete_documents = AsyncMock(return_value=True)
    service.search = AsyncMock(return_value=[
        VectorSearchResult(
            id="doc1",
            score=0.95,
            payload={"text": "Test result", "category": "test"},
        )
    ])
    service.health_check = AsyncMock(return_value={"status": "healthy"})
    service.close = AsyncMock()
    return service


@pytest.fixture
async def rag_orchestrator(mock_embedding_service, mock_vector_db_service):
    """Create a RAGOrchestrator instance for testing."""
    orchestrator = RAGOrchestrator(
        embedding_service=mock_embedding_service,
        vector_db_service=mock_vector_db_service,
        enable_hybrid_search=True,
        search_timeout=5.0,
    )
    yield orchestrator
    await orchestrator.close()


@pytest.mark.asyncio
async def test_rag_orchestrator_initialization(mock_embedding_service, mock_vector_db_service):
    """Test RAGOrchestrator initialization."""
    orchestrator = RAGOrchestrator(
        embedding_service=mock_embedding_service,
        vector_db_service=mock_vector_db_service,
    )
    
    assert orchestrator.embedding_service is mock_embedding_service
    assert orchestrator.vector_db_service is mock_vector_db_service
    assert orchestrator.enable_hybrid_search is True


@pytest.mark.asyncio
async def test_index_single_document(rag_orchestrator):
    """Test indexing a single document."""
    document = RAGDocument(
        id="test_doc_1",
        text="This is a test document",
        metadata={"category": "test", "source": "unit_test"},
    )
    
    doc_id = await rag_orchestrator.index_document(document)
    
    assert doc_id is not None
    assert rag_orchestrator._metrics["indexed_documents"] == 1
    rag_orchestrator.embedding_service.embed_text.assert_called_once()
    rag_orchestrator.vector_db_service.upsert_documents.assert_called_once()


@pytest.mark.asyncio
async def test_index_documents_batch(rag_orchestrator):
    """Test batch document indexing."""
    documents = [
        RAGDocument(id="doc1", text="Text 1", metadata={}),
        RAGDocument(id="doc2", text="Text 2", metadata={}),
    ]
    
    doc_ids = await rag_orchestrator.index_documents_batch(documents)
    
    assert len(doc_ids) == 2
    assert rag_orchestrator._metrics["indexed_documents"] == 2
    rag_orchestrator.embedding_service.embed_batch.assert_called_once()


@pytest.mark.asyncio
async def test_delete_documents(rag_orchestrator):
    """Test document deletion."""
    document_ids = ["doc1", "doc2"]
    
    result = await rag_orchestrator.delete_documents(document_ids)
    
    assert result is True
    rag_orchestrator.vector_db_service.delete_documents.assert_called_once_with(document_ids)


@pytest.mark.asyncio
async def test_search(rag_orchestrator):
    """Test search functionality."""
    query = "test query"
    
    results = await rag_orchestrator.search(query, top_k=5)
    
    assert isinstance(results, list)
    assert len(results) > 0
    assert isinstance(results[0], RAGSearchResult)
    assert results[0].document_id == "doc1"
    assert results[0].score == 0.95
    assert rag_orchestrator._metrics["total_searches"] == 1
    assert rag_orchestrator._metrics["successful_searches"] == 1


@pytest.mark.asyncio
async def test_search_with_filters(rag_orchestrator):
    """Test search with metadata filters."""
    query = "test query"
    filters = {"category": "test"}
    
    results = await rag_orchestrator.search(
        query,
        top_k=5,
        filter_metadata=filters,
    )
    
    assert isinstance(results, list)
    rag_orchestrator.vector_db_service.search.assert_called_once()


@pytest.mark.asyncio
async def test_hybrid_search(rag_orchestrator):
    """Test hybrid search."""
    query = "test query"
    
    results = await rag_orchestrator.hybrid_search(
        query,
        top_k=5,
        vector_weight=0.7,
        tfidf_weight=0.3,
    )
    
    assert isinstance(results, list)


@pytest.mark.asyncio
async def test_get_metrics(rag_orchestrator):
    """Test getting metrics."""
    metrics = await rag_orchestrator.get_metrics()
    
    assert isinstance(metrics, RAGMetrics)
    assert metrics.total_indexed_documents == 0
    assert metrics.total_searches == 0
    assert metrics.average_search_time_ms == 0.0


@pytest.mark.asyncio
async def test_health_check(rag_orchestrator):
    """Test health check."""
    health = await rag_orchestrator.health_check()
    
    assert "status" in health
    assert "embedding_service" in health
    assert "vector_db_service" in health
    assert "metrics" in health
    assert health["status"] == "healthy"


@pytest.mark.asyncio
async def test_search_error_handling(rag_orchestrator):
    """Test error handling in search."""
    # Make embedding service raise an error
    rag_orchestrator.embedding_service.embed_text = AsyncMock(
        side_effect=Exception("Embedding error")
    )
    
    # Should return empty results due to graceful degradation
    results = await rag_orchestrator.search("test query")
    
    assert results == []
    assert rag_orchestrator._metrics["failed_searches"] == 1
    assert rag_orchestrator._metrics["errors"] == 1