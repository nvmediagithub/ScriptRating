# RAG System Implementation Guide

## Overview

This guide documents the implementation of the enhanced RAG (Retrieval Augmented Generation) system for ScriptRating, including OpenAI embeddings, Qdrant vector database, and comprehensive orchestration.

## Architecture

### Components

1. **EmbeddingService** (`app/infrastructure/services/embedding_service.py`)
   - OpenAI text-embedding-3-large integration
   - Redis caching for performance
   - Fallback to local sentence-transformers model
   - Batch processing support
   - Async operations

2. **VectorDatabaseService** (`app/infrastructure/services/vector_database_service.py`)
   - Qdrant vector database integration
   - Collection management
   - CRUD operations (upsert, delete, search)
   - Hybrid search with TF-IDF fallback
   - Connection pooling

3. **RAGOrchestrator** (`app/domain/services/rag_orchestrator.py`)
   - Coordinates embedding and vector services
   - High-level RAG operations
   - Metrics and monitoring
   - Error handling with graceful degradation

4. **KnowledgeBase** (`app/infrastructure/services/knowledge_base.py`)
   - Updated with RAG integration
   - Backward compatibility maintained
   - Automatic sync with RAG orchestrator
   - Graceful fallback to TF-IDF

## Installation

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

Or update your environment:

```bash
pip install openai>=1.3.0 qdrant-client>=1.7.0 sentence-transformers>=2.2.0 tenacity>=8.2.0
```

### 2. Set Up External Services

#### Redis (for caching)

```bash
# Using Docker
docker run -d -p 6379:6379 redis:latest

# Or install locally
# macOS: brew install redis
# Ubuntu: sudo apt-get install redis-server
```

#### Qdrant (vector database)

```bash
# Using Docker
docker run -d -p 6333:6333 qdrant/qdrant:latest

# Or use Qdrant Cloud (recommended for production)
```

### 3. Configure Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:

```bash
# Required: OpenAI API Key
OPENAI_EMBEDDING_API_KEY=your-openai-api-key-here

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Qdrant Configuration
QDRANT_URL=http://localhost:6333
# QDRANT_API_KEY=your-qdrant-api-key  # For Qdrant Cloud

# Feature Flags
ENABLE_RAG_SYSTEM=true
ENABLE_EMBEDDING_CACHE=true
ENABLE_TFIDF_FALLBACK=true
```

## Usage

### Initialization in FastAPI Application

Update `app/presentation/api/main.py`:

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.infrastructure.services.rag_factory import RAGServiceFactory
from app.presentation.api.routes import rag

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize RAG services
    knowledge_base = await RAGServiceFactory.initialize_services()
    
    # Set global instances for API routes
    rag.set_knowledge_base(knowledge_base)
    rag.set_rag_orchestrator(RAGServiceFactory.get_rag_orchestrator())
    
    yield
    
    # Shutdown: Clean up
    await RAGServiceFactory.shutdown_services()

app = FastAPI(lifespan=lifespan)
```

### Using RAG Services

#### Index Documents

```python
from app.domain.services.rag_orchestrator import RAGDocument

# Create document
document = RAGDocument(
    id="doc123",
    text="Federal law on information protection for children...",
    metadata={
        "document_id": "fz436",
        "document_title": "ФЗ-436",
        "page": 1,
        "paragraph": 5,
        "category": "legal"
    }
)

# Index single document
doc_id = await rag_orchestrator.index_document(document)

# Index batch
documents = [doc1, doc2, doc3]
doc_ids = await rag_orchestrator.index_documents_batch(documents)
```

#### Search Documents

```python
# Basic search
results = await rag_orchestrator.search(
    query="age rating regulations",
    top_k=5
)

# Search with filters
results = await rag_orchestrator.search(
    query="violence content",
    top_k=5,
    filter_metadata={"category": "legal"}
)

# Hybrid search
results = await rag_orchestrator.hybrid_search(
    query="content classification",
    top_k=5,
    vector_weight=0.7,
    tfidf_weight=0.3
)
```

## API Endpoints

### Query RAG System

```bash
POST /api/rag/query
Content-Type: application/json

{
  "query": "age rating regulations",
  "top_k": 5,
  "category": "violence"
}
```

### Health Check

```bash
GET /api/rag/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00",
  "components": {
    "knowledge_base": {
      "rag_enabled": true,
      "rag_available": true
    },
    "rag_orchestrator": {
      "status": "healthy",
      "embedding_service": {"status": "healthy"},
      "vector_db_service": {"status": "healthy"}
    }
  }
}
```

### Metrics

```bash
GET /api/rag/metrics
```

Response:
```json
{
  "timestamp": "2024-01-01T00:00:00",
  "rag_orchestrator": {
    "indexed_documents": 1500,
    "total_searches": 3200,
    "average_search_time_ms": 45.2,
    "cache_hit_rate": 0.85
  }
}
```

## Testing

### Run Unit Tests

```bash
# All tests
pytest tests/unit/

# Specific service
pytest tests/unit/test_embedding_service.py
pytest tests/unit/test_vector_database_service.py
pytest tests/unit/test_rag_orchestrator.py
```

### Run Integration Tests

```bash
pytest tests/integration/test_rag_integration.py -m integration
```

## Configuration Options

### EmbeddingService

| Variable | Default | Description |
|----------|---------|-------------|
| OPENAI_EMBEDDING_API_KEY | - | OpenAI API key (required) |
| OPENAI_EMBEDDING_MODEL | text-embedding-3-large | Model name |
| EMBEDDING_BATCH_SIZE | 100 | Batch size |
| EMBEDDING_CACHE_TTL | 604800 | Cache TTL (7 days) |
| ENABLE_FALLBACK_EMBEDDINGS | true | Enable local fallback |

### VectorDatabaseService

| Variable | Default | Description |
|----------|---------|-------------|
| QDRANT_URL | - | Qdrant server URL |
| QDRANT_API_KEY | - | API key (for cloud) |
| QDRANT_COLLECTION_NAME | scriptrating_documents | Collection name |
| QDRANT_VECTOR_SIZE | 1536 | Vector dimension |
| QDRANT_DISTANCE_METRIC | Cosine | Distance metric |

### RAG Features

| Variable | Default | Description |
|----------|---------|-------------|
| ENABLE_RAG_SYSTEM | true | Enable RAG system |
| ENABLE_EMBEDDING_CACHE | true | Enable Redis cache |
| ENABLE_TFIDF_FALLBACK | true | Enable TF-IDF fallback |
| ENABLE_HYBRID_SEARCH | true | Enable hybrid search |
| RAG_SEARCH_TIMEOUT | 5.0 | Search timeout (seconds) |

## Monitoring

### Health Checks

Monitor system health via:
- `/api/rag/health` - Overall RAG health
- `/api/health` - Application health

### Metrics

Track performance via:
- `/api/rag/metrics` - RAG metrics
- Embedding service metrics (cache hit rate, API calls)
- Vector DB metrics (searches, indexed documents)

### Logging

Configure logging level:

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("app.infrastructure.services")
```

## Performance Optimization

### Caching Strategy

1. **Embedding Cache**: Redis stores embeddings for 7 days
2. **Cache Hit Rate**: Monitor via metrics endpoint
3. **Batch Processing**: Use batch operations for multiple documents

### Vector Database

1. **Collection Indexing**: Automatic background indexing
2. **Search Optimization**: Use score thresholds to filter results
3. **Metadata Filtering**: Pre-filter before vector search

### Best Practices

1. **Batch Operations**: Always use batch methods for multiple documents
2. **Async Operations**: All operations are async for scalability
3. **Error Handling**: System degrades gracefully on failures
4. **Monitoring**: Regularly check health and metrics endpoints

## Troubleshooting

### Common Issues

#### 1. OpenAI API Errors

```
Error: OpenAI API error: 401
```

**Solution**: Check OPENAI_EMBEDDING_API_KEY is set correctly

#### 2. Redis Connection Failed

```
Error: Redis connection refused
```

**Solution**: Ensure Redis is running on configured port

#### 3. Qdrant Not Available

```
Error: Qdrant connection failed
```

**Solution**: 
- Check Qdrant is running
- Verify QDRANT_URL is correct
- System will fallback to TF-IDF if enabled

#### 4. Low Cache Hit Rate

**Solution**:
- Increase EMBEDDING_CACHE_TTL
- Check Redis memory limits
- Monitor cache eviction

## Migration from Legacy System

The new RAG system maintains backward compatibility:

1. **Existing KnowledgeBase API**: All methods work as before
2. **Automatic Upgrade**: Enable via `ENABLE_RAG_SYSTEM=true`
3. **Gradual Migration**: Can run both systems in parallel
4. **Fallback**: Automatic fallback to TF-IDF if RAG fails

## Security Considerations

1. **API Keys**: Store in environment variables, never commit
2. **Redis**: Use password authentication in production
3. **Qdrant**: Use API key for cloud deployments
4. **Network**: Restrict access to internal services

## Production Deployment

### Recommended Setup

1. **OpenAI**: Use production API key with rate limits
2. **Redis**: Deploy Redis Cluster for high availability
3. **Qdrant**: Use Qdrant Cloud or self-hosted cluster
4. **Monitoring**: Set up alerts for health check failures
5. **Scaling**: Use horizontal scaling for API servers

### Docker Compose Example

```yaml
version: '3.8'
services:
  redis:
    image: redis:latest
    ports:
      - "6379:6379"
  
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage
  
  app:
    build: .
    environment:
      - OPENAI_EMBEDDING_API_KEY=${OPENAI_EMBEDDING_API_KEY}
      - REDIS_URL=redis://redis:6379/0
      - QDRANT_URL=http://qdrant:6333
    depends_on:
      - redis
      - qdrant

volumes:
  qdrant_data:
```

## Support

For issues or questions:
1. Check logs for detailed error messages
2. Verify configuration in `.env`
3. Run health checks: `/api/rag/health`
4. Review metrics: `/api/rag/metrics`

## Future Enhancements

Planned improvements:
1. Multi-language embedding support
2. Advanced chunking strategies
3. Semantic caching
4. Query expansion
5. Re-ranking models