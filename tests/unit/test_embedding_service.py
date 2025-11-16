"""
Unit tests for EmbeddingService.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.infrastructure.services.embedding_service import EmbeddingService, EmbeddingResult


@pytest.fixture
async def embedding_service():
    """Create an EmbeddingService instance for testing."""
    service = EmbeddingService(
        openai_api_key="test-key",
        redis_url=None,  # Disable Redis for unit tests
        model="text-embedding-3-large",
        enable_fallback=False,  # Disable fallback for unit tests
    )
    await service.initialize()
    yield service
    await service.close()


@pytest.mark.asyncio
async def test_embedding_service_initialization():
    """Test EmbeddingService initialization."""
    service = EmbeddingService(
        openai_api_key="test-key",
        redis_url=None,
        model="text-embedding-3-large",
    )
    
    await service.initialize()
    
    assert service.openai_api_key == "test-key"
    assert service.model == "text-embedding-3-large"
    assert service._http_client is not None
    
    await service.close()


@pytest.mark.asyncio
async def test_embed_text_success(embedding_service):
    """Test successful text embedding."""
    test_text = "This is a test text"
    mock_embedding = [0.1] * 1536
    
    with patch.object(
        embedding_service,
        '_generate_openai_embedding',
        new_callable=AsyncMock,
        return_value=[mock_embedding]
    ):
        result = await embedding_service.embed_text(test_text)
        
        assert isinstance(result, EmbeddingResult)
        assert result.text == test_text
        assert result.embedding == mock_embedding
        assert result.model == "text-embedding-3-large"
        assert result.cached is False


@pytest.mark.asyncio
async def test_embed_batch_success(embedding_service):
    """Test successful batch embedding."""
    test_texts = ["Text 1", "Text 2", "Text 3"]
    mock_embeddings = [[0.1] * 1536, [0.2] * 1536, [0.3] * 1536]
    
    with patch.object(
        embedding_service,
        '_generate_openai_embedding',
        new_callable=AsyncMock,
        return_value=mock_embeddings
    ):
        results = await embedding_service.embed_batch(test_texts)
        
        assert len(results) == 3
        for i, result in enumerate(results):
            assert isinstance(result, EmbeddingResult)
            assert result.text == test_texts[i]
            assert result.embedding == mock_embeddings[i]


@pytest.mark.asyncio
async def test_cache_key_generation(embedding_service):
    """Test cache key generation."""
    text = "Test text"
    key1 = embedding_service._generate_cache_key(text, "model1")
    key2 = embedding_service._generate_cache_key(text, "model1")
    key3 = embedding_service._generate_cache_key(text, "model2")
    
    assert key1 == key2  # Same text and model
    assert key1 != key3  # Different model


@pytest.mark.asyncio
async def test_metrics_tracking(embedding_service):
    """Test metrics tracking."""
    test_text = "Test text"
    mock_embedding = [0.1] * 1536
    
    initial_requests = embedding_service._metrics["total_requests"]
    
    with patch.object(
        embedding_service,
        '_generate_openai_embedding',
        new_callable=AsyncMock,
        return_value=[mock_embedding]
    ):
        await embedding_service.embed_text(test_text)
    
    assert embedding_service._metrics["total_requests"] == initial_requests + 1


@pytest.mark.asyncio
async def test_health_check(embedding_service):
    """Test health check."""
    health = await embedding_service.health_check()
    
    assert "status" in health
    assert "openai_available" in health
    assert "metrics" in health
    assert health["openai_available"] is True


@pytest.mark.asyncio
async def test_get_metrics(embedding_service):
    """Test get_metrics method."""
    metrics = embedding_service.get_metrics()
    
    assert "total_requests" in metrics
    assert "cache_hits" in metrics
    assert "cache_misses" in metrics
    assert "cache_hit_rate" in metrics