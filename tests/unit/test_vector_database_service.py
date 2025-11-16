"""
Unit tests for VectorDatabaseService.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.infrastructure.services.vector_database_service import (
    VectorDatabaseService,
    VectorSearchResult,
    CollectionInfo,
)


@pytest.fixture
async def vector_db_service():
    """Create a VectorDatabaseService instance for testing."""
    service = VectorDatabaseService(
        qdrant_url=None,  # Use in-memory mode for tests
        collection_name="test_collection",
        vector_size=1536,
        enable_tfidf_fallback=False,  # Disable for unit tests
    )
    await service.initialize()
    yield service
    await service.close()


@pytest.mark.asyncio
async def test_vector_db_initialization():
    """Test VectorDatabaseService initialization."""
    service = VectorDatabaseService(
        qdrant_url=None,
        collection_name="test_collection",
        vector_size=1536,
    )
    
    await service.initialize()
    
    assert service.collection_name == "test_collection"
    assert service.vector_size == 1536
    assert service._client is not None
    
    await service.close()


@pytest.mark.asyncio
async def test_upsert_documents(vector_db_service):
    """Test document upsert."""
    documents = [
        {
            "id": "doc1",
            "vector": [0.1] * 1536,
            "payload": {"text": "Test document 1", "category": "test"},
        },
        {
            "id": "doc2",
            "vector": [0.2] * 1536,
            "payload": {"text": "Test document 2", "category": "test"},
        },
    ]
    
    doc_ids = await vector_db_service.upsert_documents(documents)
    
    assert len(doc_ids) == 2
    assert "doc1" in doc_ids
    assert "doc2" in doc_ids
    assert vector_db_service._metrics["upserts"] == 2


@pytest.mark.asyncio
async def test_search_documents(vector_db_service):
    """Test document search."""
    # First, upsert some documents
    documents = [
        {
            "id": "doc1",
            "vector": [0.1] * 1536,
            "payload": {"text": "Test document 1"},
        },
    ]
    await vector_db_service.upsert_documents(documents)
    
    # Search for similar documents
    query_vector = [0.1] * 1536
    results = await vector_db_service.search(query_vector, limit=5)
    
    assert isinstance(results, list)
    assert vector_db_service._metrics["vector_searches"] >= 1


@pytest.mark.asyncio
async def test_delete_documents(vector_db_service):
    """Test document deletion."""
    # Upsert a document
    documents = [
        {
            "id": "doc_to_delete",
            "vector": [0.1] * 1536,
            "payload": {"text": "Document to delete"},
        },
    ]
    await vector_db_service.upsert_documents(documents)
    
    # Delete it
    success = await vector_db_service.delete_documents(["doc_to_delete"])
    
    assert success is True
    assert vector_db_service._metrics["deletes"] == 1


@pytest.mark.asyncio
async def test_get_collection_info(vector_db_service):
    """Test getting collection info."""
    info = await vector_db_service.get_collection_info()
    
    assert isinstance(info, CollectionInfo)
    assert info.name == "test_collection"
    assert info.points_count >= 0


@pytest.mark.asyncio
async def test_health_check(vector_db_service):
    """Test health check."""
    health = await vector_db_service.health_check()
    
    assert "status" in health
    assert "qdrant_available" in health
    assert "collection_exists" in health
    assert "metrics" in health


@pytest.mark.asyncio
async def test_get_metrics(vector_db_service):
    """Test get_metrics method."""
    metrics = vector_db_service.get_metrics()
    
    assert "total_searches" in metrics
    assert "upserts" in metrics
    assert "deletes" in metrics
    assert "errors" in metrics


@pytest.mark.asyncio
async def test_empty_documents_upsert(vector_db_service):
    """Test upserting empty document list."""
    doc_ids = await vector_db_service.upsert_documents([])
    
    assert doc_ids == []


@pytest.mark.asyncio
async def test_search_with_filters(vector_db_service):
    """Test search with metadata filters."""
    # Upsert documents with metadata
    documents = [
        {
            "id": "doc1",
            "vector": [0.1] * 1536,
            "payload": {"text": "Test 1", "category": "A"},
        },
        {
            "id": "doc2",
            "vector": [0.2] * 1536,
            "payload": {"text": "Test 2", "category": "B"},
        },
    ]
    await vector_db_service.upsert_documents(documents)
    
    # Search with filter
    query_vector = [0.1] * 1536
    results = await vector_db_service.search(
        query_vector,
        limit=5,
        filter_conditions={"category": "A"}
    )
    
    assert isinstance(results, list)