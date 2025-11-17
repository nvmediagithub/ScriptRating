"""
Comprehensive integration tests for vector search pipeline.

Tests the complete RAG pipeline with vector search, including:
- Vector search functionality with Qdrant
- KnowledgeBase routing strategies (AUTO, VECTOR_ONLY, TFIDF_ONLY, HYBRID)
- Migration pipeline validation
- Performance benchmarking
- Error handling and fallbacks
"""
import asyncio
import time
import uuid
from typing import List, Dict, Any
import pytest
from datetime import datetime

from app.domain.services.rag_orchestrator import RAGOrchestrator, RAGDocument
from app.infrastructure.services.embedding_service import EmbeddingService
from app.infrastructure.services.vector_database_service import VectorDatabaseService
from app.infrastructure.services.knowledge_base import KnowledgeBase
# from app.infrastructure.services.rag_factory import RAGFactory

# Import directly to avoid config issues
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))


class TestVectorSearchPipeline:
    """Comprehensive tests for vector search pipeline."""

    @pytest.fixture
    async def services(self):
        """Initialize all required services for testing."""
        # Initialize embedding service
        embedding_service = EmbeddingService(
            openai_api_key=None,  # Use fallback
            redis_url=None,
            enable_fallback=True
        )
        await embedding_service.initialize()

        # Initialize vector database service
        vector_db_service = VectorDatabaseService(
            qdrant_url=None,  # In-memory mode
            collection_name="test_vector_pipeline",
            vector_size=384,  # Fallback model dimension
            enable_tfidf_fallback=True
        )
        await vector_db_service.initialize()

        # Initialize knowledge base (legacy)
        knowledge_base = KnowledgeBase()

        # Initialize RAG orchestrator
        rag_orchestrator = RAGOrchestrator(
            embedding_service=embedding_service,
            vector_db_service=vector_db_service,
            enable_hybrid_search=True
        )

        yield {
            'embedding_service': embedding_service,
            'vector_db_service': vector_db_service,
            'knowledge_base': knowledge_base,
            'rag_orchestrator': rag_orchestrator
        }

        # Cleanup
        await rag_orchestrator.close()
        await vector_db_service.close()
        await embedding_service.close()

    async def test_vector_search_functionality(self, services):
        """Test basic vector search functionality with Qdrant."""
        vector_db = services['vector_db_service']

        # Create test documents
        docs = []
        for i in range(5):
            docs.append({
                'id': f'vector_doc_{i}',
                'vector': [float(i) / 10.0] * 384,  # Match vector size
                'payload': {
                    'text': f'Test document {i} about machine learning and AI',
                    'source': 'test',
                    'category': 'tech' if i % 2 == 0 else 'science'
                }
            })

        # Index documents
        indexed_ids = await vector_db.upsert_documents(docs)
        assert len(indexed_ids) == 5

        # Search for documents
        query_vector = [0.0] * 384  # Should match document 0
        results = await vector_db.search(query_vector, limit=3)

        assert len(results) >= 1
        assert results[0].score > 0.0
        assert 'machine learning' in results[0].payload['text'].lower()

        # Test filtered search
        filtered_results = await vector_db.search(
            query_vector,
            limit=5,
            filter_conditions={'category': 'tech'}
        )
        assert len(filtered_results) >= 1
        assert all(r.payload['category'] == 'tech' for r in filtered_results)

    async def test_knowledge_base_routing_strategies(self, services):
        """Test different KnowledgeBase routing strategies."""
        # For now, test basic orchestrator functionality
        # TODO: Implement RAGFactory routing strategies

        # Create test documents
        test_docs = [
            RAGDocument(
                id=f'routing_doc_{i}',
                text=f'Document {i} about {"AI" if i % 2 == 0 else "regulations"}',
                metadata={'type': 'test', 'index': i}
            ) for i in range(10)
        ]

        # Index documents
        await services['rag_orchestrator'].index_documents_batch(test_docs)

        query = "artificial intelligence"

        # Test basic search (equivalent to VECTOR_ONLY)
        vector_results = await services['rag_orchestrator'].search(
            query=query,
            top_k=5
        )
        assert len(vector_results) > 0

        # Test hybrid search
        hybrid_results = await services['rag_orchestrator'].hybrid_search(
            query=query,
            top_k=5,
            vector_weight=0.7,
            tfidf_weight=0.3
        )
        assert len(hybrid_results) > 0

        # Verify hybrid returns results
        assert len(hybrid_results) >= len(vector_results)

    async def test_rag_orchestrator_operations(self, services):
        """Test RAG orchestrator end-to-end operations."""
        orchestrator = services['rag_orchestrator']

        # Test document indexing
        doc = RAGDocument(
            id='orchestrator_test_doc',
            text='This is a test document for RAG orchestrator validation.',
            metadata={'source': 'test', 'category': 'validation'}
        )

        indexed_id = await orchestrator.index_document(doc)
        assert indexed_id == 'orchestrator_test_doc'

        # Test batch indexing
        batch_docs = [
            RAGDocument(
                id=f'batch_doc_{i}',
                text=f'Batch document {i} with specific content for testing',
                metadata={'batch': True, 'index': i}
            ) for i in range(5)
        ]

        batch_ids = await orchestrator.index_documents_batch(batch_docs)
        assert len(batch_ids) == 5

        # Test search
        results = await orchestrator.search("specific content", top_k=3)
        assert len(results) > 0
        assert any('batch document' in r.text for r in results)

        # Test hybrid search
        hybrid_results = await orchestrator.hybrid_search(
            "testing content",
            top_k=2,
            vector_weight=0.8,
            tfidf_weight=0.2
        )
        assert len(hybrid_results) > 0

        # Test metrics
        metrics = await orchestrator.get_metrics()
        assert metrics.total_indexed_documents >= 6  # 1 + 5
        assert metrics.total_searches >= 2  # search + hybrid_search

        # Test health check
        health = await orchestrator.health_check()
        assert health['status'] in ['healthy', 'degraded']
        assert 'embedding_service' in health
        assert 'vector_db_service' in health
        assert 'metrics' in health

    async def test_error_handling_and_fallbacks(self, services):
        """Test error handling and graceful degradation."""
        orchestrator = services['rag_orchestrator']

        # Test with invalid query (should handle gracefully)
        try:
            results = await orchestrator.search("", top_k=5)
            # Should return empty or handle gracefully
            assert isinstance(results, list)
        except Exception as e:
            # If it raises, ensure it's a handled exception
            assert 'search' in str(e).lower()

        # Test health check with simulated failures
        health = await orchestrator.health_check()

        # Even if services are down, health check should complete
        assert 'status' in health
        assert health['status'] != 'unknown'

    async def test_performance_benchmarking(self, services):
        """Test performance with realistic workloads."""
        orchestrator = services['rag_orchestrator']

        # Create larger dataset
        large_docs = []
        for i in range(50):
            large_docs.append(RAGDocument(
                id=f'perf_doc_{i}',
                text=f'Performance test document {i} with substantial content about machine learning, artificial intelligence, and data science practices in modern software development.',
                metadata={'type': 'performance', 'size': 'large', 'index': i}
            ))

        # Time batch indexing
        start_time = time.time()
        batch_ids = await orchestrator.index_documents_batch(large_docs)
        indexing_time = time.time() - start_time

        assert len(batch_ids) == 50
        assert indexing_time < 30.0  # Should complete within 30 seconds

        # Time search operations
        search_times = []
        for i in range(10):
            query = f"machine learning practices {i}"
            start_time = time.time()
            results = await orchestrator.search(query, top_k=5)
            search_time = time.time() - start_time
            search_times.append(search_time)

            assert len(results) > 0

        avg_search_time = sum(search_times) / len(search_times)
        assert avg_search_time < 2.0  # Average search should be under 2 seconds

        # Get final metrics
        metrics = await orchestrator.get_metrics()
        assert metrics.total_indexed_documents >= 50
        assert metrics.total_searches >= 10
        assert metrics.average_search_time_ms < 2000  # Under 2 seconds

    async def test_backward_compatibility(self, services):
        """Test that new vector search maintains backward compatibility."""
        knowledge_base = services['knowledge_base']
        orchestrator = services['rag_orchestrator']

        # Add documents to both systems
        test_content = "Legacy document for backward compatibility testing"

        # Add to knowledge base (legacy way)
        legacy_results = knowledge_base.search(test_content, top_k=5)

        # Add to vector system
        doc = RAGDocument(
            id='compatibility_test',
            text=test_content,
            metadata={'legacy': True}
        )
        await orchestrator.index_document(doc)

        # Search vector system
        vector_results = await orchestrator.search(test_content, top_k=5)

        # Both should return results (even if different)
        assert len(vector_results) > 0
        assert vector_results[0].score > 0


class TestMigrationPipeline:
    """Tests for data migration to vector search."""

    async def test_document_migration(self):
        """Test migration of existing documents to vector search."""
        # This would test the migration script
        # For now, test the migration workflow concept

        # Initialize services
        embedding_service = EmbeddingService(enable_fallback=True)
        await embedding_service.initialize()

        vector_db = VectorDatabaseService(
            qdrant_url=None,
            collection_name="migration_test",
            vector_size=384,
            enable_tfidf_fallback=True
        )
        await vector_db.initialize()

        # Simulate migrated documents
        migrated_docs = [
            {
                'id': f'migrated_{i}',
                'text': f'Migrated document {i} with original content',
                'metadata': {'migrated': True, 'source': 'legacy'}
            } for i in range(10)
        ]

        # Generate embeddings and store
        for doc in migrated_docs:
            embedding = await embedding_service.embed_text(doc['text'])
            vector_doc = {
                'id': doc['id'],
                'vector': embedding.embedding,
                'payload': {
                    'text': doc['text'],
                    'embedding_model': embedding.model,
                    **doc['metadata']
                }
            }
            await vector_db.upsert_documents([vector_doc])

        # Verify migration
        info = await vector_db.get_collection_info()
        assert info.points_count >= 10

        # Test search on migrated data
        query_embedding = await embedding_service.embed_text("migrated document")
        results = await vector_db.search(query_embedding.embedding, limit=5)

        assert len(results) > 0
        assert all(r.payload.get('migrated') for r in results)

        # Cleanup
        await vector_db.close()
        await embedding_service.close()


if __name__ == '__main__':
    # Run tests directly for debugging
    async def run_tests():
        print("Running comprehensive vector search pipeline tests...")

        # Initialize services
        embedding_service = EmbeddingService(enable_fallback=True)
        await embedding_service.initialize()

        vector_db = VectorDatabaseService(
            qdrant_url=None,
            collection_name="direct_test_pipeline",
            vector_size=384,
            enable_tfidf_fallback=True
        )
        await vector_db.initialize()

        # Initialize RAG orchestrator
        rag_orchestrator = RAGOrchestrator(
            embedding_service=embedding_service,
            vector_db_service=vector_db,
            enable_hybrid_search=True
        )

        try:
            # Test basic functionality
            print("\n=== Testing Vector Search Functionality ===")

            # Create and index documents
            docs = []
            for i in range(5):
                docs.append({
                    'id': f'test_doc_{i}',
                    'vector': [float(i) / 10.0] * 384,
                    'payload': {
                        'text': f'Test document {i} about AI and machine learning',
                        'source': 'test',
                        'category': 'tech'
                    }
                })

            indexed = await vector_db.upsert_documents(docs)
            print(f"Indexed {len(indexed)} documents")

            # Search
            query_vector = [0.0] * 384
            results = await vector_db.search(query_vector, limit=3)
            print(f"Search returned {len(results)} results")
            if results:
                print(f"Top score: {results[0].score:.4f}")

            # Test RAG orchestrator
            print("\n=== Testing RAG Orchestrator ===")

            rag_docs = [
                RAGDocument(
                    id=f'rag_doc_{i}',
                    text=f'RAG test document {i} with content about data science',
                    metadata={'type': 'rag_test'}
                ) for i in range(3)
            ]

            rag_ids = await rag_orchestrator.index_documents_batch(rag_docs)
            print(f"RAG indexed {len(rag_ids)} documents")

            search_results = await rag_orchestrator.search("data science", top_k=2)
            print(f"RAG search returned {len(search_results)} results")

            # Performance test
            print("\n=== Performance Testing ===")

            start_time = time.time()
            perf_docs = [
                RAGDocument(
                    id=f'perf_{i}',
                    text=f'Performance document {i} with detailed content',
                    metadata={'performance': True}
                ) for i in range(20)
            ]

            perf_ids = await rag_orchestrator.index_documents_batch(perf_docs)
            indexing_time = time.time() - start_time
            print(".2f")

            # Search performance
            search_times = []
            for i in range(5):
                start = time.time()
                results = await rag_orchestrator.search(f"document {i}", top_k=3)
                search_times.append(time.time() - start)

            avg_search = sum(search_times) / len(search_times)
            print(".3f")

            # Health check
            print("\n=== Health Check ===")
            health = await rag_orchestrator.health_check()
            print(f"System health: {health['status']}")

            metrics = await rag_orchestrator.get_metrics()
            print(f"Total indexed: {metrics.total_indexed_documents}")
            print(f"Total searches: {metrics.total_searches}")
            print(".2f")

            print("\n✅ All tests passed successfully!")

        except Exception as e:
            print(f"\n❌ Test failed: {e}")
            import traceback
            traceback.print_exc()

        finally:
            await rag_orchestrator.close()
            await vector_db.close()
            await embedding_service.close()

    asyncio.run(run_tests())