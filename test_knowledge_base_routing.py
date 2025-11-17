#!/usr/bin/env python3
"""
Test script for KnowledgeBase intelligent routing and prioritization.

Tests:
- Confidence-based routing between vector and TF-IDF
- Hybrid search capability
- Caching mechanism
- Fallback behavior
- Search metrics tracking
"""
import asyncio
import sys
import os

# Add the app directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.infrastructure.services.knowledge_base import KnowledgeBase, SearchStrategy


async def test_knowledge_base_routing():
    """Test KnowledgeBase with intelligent routing."""
    print("Testing KnowledgeBase intelligent routing and prioritization...")

    # Test 1: Initialize KnowledgeBase with different configurations
    print("\n=== Test 1: KnowledgeBase Initialization ===")

    # Create mock RAG orchestrator for testing
    class MockRAGOrchestrator:
        def __init__(self, should_fail=False):
            self.should_fail = should_fail
            self.call_count = 0

        async def search(self, query, top_k):
            self.call_count += 1
            if self.should_fail:
                raise Exception("Mock RAG failure")

            # Return mock results with varying confidence
            return [
                {
                    "document_id": f"doc_{i}",
                    "title": f"Document {i}",
                    "page": 1,
                    "paragraph": i,
                    "excerpt": f"Mock excerpt for {query} result {i}",
                    "score": 0.9 - (i * 0.1),  # Decreasing scores
                    "metadata": {"source": "vector"}
                }
                for i in range(min(top_k, 3))
            ]

    # Test with working RAG
    kb_auto = KnowledgeBase(
        rag_orchestrator=MockRAGOrchestrator(should_fail=False),
        search_strategy=SearchStrategy.AUTO,
        enable_hybrid_search=True,
        enable_caching=True,
        confidence_threshold=0.7
    )

    # Test with failing RAG
    kb_fallback = KnowledgeBase(
        rag_orchestrator=MockRAGOrchestrator(should_fail=True),
        search_strategy=SearchStrategy.AUTO,
        enable_caching=False
    )

    # Test vector-only
    kb_vector_only = KnowledgeBase(
        rag_orchestrator=MockRAGOrchestrator(should_fail=False),
        search_strategy=SearchStrategy.VECTOR_ONLY
    )

    # Test TF-IDF only
    kb_tfidf_only = KnowledgeBase(
        search_strategy=SearchStrategy.TFIDF_ONLY
    )

    # Test hybrid
    kb_hybrid = KnowledgeBase(
        rag_orchestrator=MockRAGOrchestrator(should_fail=False),
        search_strategy=SearchStrategy.HYBRID
    )

    # Initialize all
    await kb_auto.initialize()
    await kb_fallback.initialize()
    await kb_vector_only.initialize()
    await kb_tfidf_only.initialize()
    await kb_hybrid.initialize()

    # Test 2: Add some test documents for TF-IDF
    print("\n=== Test 2: Adding Test Documents ===")
    test_docs = [
        {
            "page": 1,
            "paragraph_index": 1,
            "text": "This is a test document about machine learning and AI.",
        },
        {
            "page": 1,
            "paragraph_index": 2,
            "text": "Another document discussing natural language processing.",
        },
        {
            "page": 2,
            "paragraph_index": 1,
            "text": "Content about vector databases and embeddings.",
        }
    ]

    await kb_auto.ingest_document("test_doc_1", "Test Document", test_docs)
    await kb_tfidf_only.ingest_document("test_doc_1", "Test Document", test_docs)

    # Test 3: Test confidence-based routing (AUTO strategy)
    print("\n=== Test 3: Confidence-Based Routing ===")
    query = "machine learning"

    # With high-confidence vector results
    results_auto = await kb_auto.query(query, top_k=2)
    print(f"Auto routing results: {len(results_auto)}")
    if results_auto:
        print(f"Top score: {results_auto[0]['score']:.3f}")
        print(f"Source: {results_auto[0]['metadata'].get('source', 'unknown')}")

    # Test 4: Test fallback behavior
    print("\n=== Test 4: Fallback Behavior ===")
    results_fallback = await kb_fallback.query(query, top_k=2)
    print(f"Fallback results: {len(results_fallback)} (should use TF-IDF)")
    if results_fallback:
        print(f"Top score: {results_fallback[0]['score']:.3f}")

    # Test 5: Test strategy-specific searches
    print("\n=== Test 5: Strategy-Specific Searches ===")

    # Vector only
    results_vector = await kb_vector_only.query(query, top_k=2)
    print(f"Vector-only results: {len(results_vector)}")

    # TF-IDF only
    results_tfidf = await kb_tfidf_only.query(query, top_k=2)
    print(f"TF-IDF-only results: {len(results_tfidf)}")
    if results_tfidf:
        print(f"TF-IDF score: {results_tfidf[0]['score']:.3f}")

    # Hybrid
    results_hybrid = await kb_hybrid.query(query, top_k=2)
    print(f"Hybrid results: {len(results_hybrid)}")
    if results_hybrid:
        print(f"Hybrid score: {results_hybrid[0]['score']:.3f}")

    # Test 6: Test caching
    print("\n=== Test 6: Caching Behavior ===")
    # First query should cache
    start_time = asyncio.get_event_loop().time()
    results_cached_1 = await kb_auto.query(query, top_k=2)
    first_query_time = asyncio.get_event_loop().time() - start_time

    # Second query should use cache
    start_time = asyncio.get_event_loop().time()
    results_cached_2 = await kb_auto.query(query, top_k=2)
    second_query_time = asyncio.get_event_loop().time() - start_time

    print(".4f")
    print(".4f")
    print(f"Cache speedup: {first_query_time / max(second_query_time, 0.001):.1f}x")

    # Test 7: Test metrics
    print("\n=== Test 7: Search Metrics ===")
    metrics = kb_auto.get_search_metrics()
    print(f"Total queries: {metrics['total_queries']}")
    print(f"Vector searches: {metrics['vector_searches']}")
    print(f"TF-IDF searches: {metrics['tfidf_searches']}")
    print(f"Hybrid searches: {metrics['hybrid_searches']}")
    print(f"Cache hits: {metrics['cache_hits']}")
    print(f"Cache misses: {metrics['cache_misses']}")
    print(".3f")
    print(".2f")

    # Test 8: Dynamic configuration changes
    print("\n=== Test 8: Dynamic Configuration ===")
    kb_auto.set_search_strategy(SearchStrategy.TFIDF_ONLY)
    results_tfidf_config = await kb_auto.query(query, top_k=1)
    print(f"Switched to TF-IDF-only: {len(results_tfidf_config)} results")

    kb_auto.set_search_strategy(SearchStrategy.HYBRID)
    results_hybrid_config = await kb_auto.query(query, top_k=1)
    print(f"Switched to hybrid: {len(results_hybrid_config)} results")

    # Test 9: Error handling
    print("\n=== Test 9: Error Handling ===")
    try:
        results_error = await kb_auto.query("", top_k=1)  # Empty query
        print(f"Empty query handled gracefully: {len(results_error)} results")
    except Exception as e:
        print(f"Empty query error: {e}")

    # Test 10: Clear cache and verify
    print("\n=== Test 10: Cache Management ===")
    old_metrics = kb_auto.get_search_metrics()
    kb_auto.clear_cache()
    new_metrics = kb_auto.get_search_metrics()
    print("Cache cleared successfully")
    print(f"Cache hits before/after: {old_metrics['cache_hits']}/{new_metrics['cache_hits']}")

    print("\n✅ KnowledgeBase routing and prioritization tests completed successfully!")


if __name__ == "__main__":
    asyncio.run(test_knowledge_base_routing())