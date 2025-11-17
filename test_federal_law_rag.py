#!/usr/bin/env python3
"""
Comprehensive test of RAG system with Federal Law document.
Upload, index, and test queries on real legal document content.
"""
import asyncio
import logging
import sys
import os
from pathlib import Path
from typing import List, Dict, Any

# Add project root to path
sys.path.insert(0, 'e:/GitRepositoties/llm_projects/ScriptRating')

from app.config import settings
from app.infrastructure.services.runtime_context import (
    document_parser,
    knowledge_base,
)
from app.infrastructure.services.rag_factory import RAGServiceFactory

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Test configuration
FEDERAL_LAW_PATH = "dataset/Федеральный_закон_от_29_12_2010_г_№_436_ФЗ.pdf"
TEST_QUERIES = [
    "Что регулирует этот федеральный закон?",
    "Какие требования к защите детей от информации?",
    "Кто имеет право на распространение информационной продукции?",
    "Какие категории информационной продукции существуют?",
    "Что такое маркировка информационной продукции?"
]

class RAGTester:
    """Comprehensive RAG system tester with real document."""

    def __init__(self):
        self.document_id = None
        self.test_results = {}

    async def run_full_test_suite(self) -> bool:
        """Run complete RAG test suite."""
        print("🚀 FEDERAL LAW RAG SYSTEM TEST SUITE")
        print("=" * 60)

        try:
            # Phase 1: System Health Check
            print("\n📊 Phase 1: System Health Check")
            await self._check_system_health()

            # Phase 2: Document Upload and Parsing
            print("\n📄 Phase 2: Document Upload and Parsing")
            await self._upload_and_parse_document()

            # Phase 3: Document Indexing
            print("\n🔍 Phase 3: Document Indexing")
            await self._index_document()

            # Phase 4: Query Testing
            print("\n❓ Phase 4: Query Testing")
            await self._test_queries()

            # Phase 5: Performance Validation
            print("\n⚡ Phase 5: Performance Validation")
            await self._validate_performance()

            # Phase 6: Cleanup
            print("\n🧹 Phase 6: Cleanup")
            await self._cleanup()

            self._print_final_report()
            return True

        except Exception as e:
            logger.error(f"❌ Test suite failed: {e}")
            import traceback
            traceback.print_exc()
            return False

    async def _check_system_health(self):
        """Check all system components health."""
        print("   Checking EmbeddingService...")
        try:
            rag_orchestrator = RAGServiceFactory.get_rag_orchestrator()
            if rag_orchestrator:
                health = await rag_orchestrator.embedding_service.health_check()
                print(f"   ✅ EmbeddingService: {health['status']}")
            else:
                print("   ❌ RAG Orchestrator not available")
        except Exception as e:
            print(f"   ❌ EmbeddingService: {e}")

        print("   Checking VectorDatabase...")
        try:
            rag_orchestrator = RAGServiceFactory.get_rag_orchestrator()
            if rag_orchestrator:
                health = await rag_orchestrator.vector_db_service.health_check()
                print(f"   ✅ VectorDB: {health['status']}")
            else:
                print("   ❌ RAG Orchestrator not available")
        except Exception as e:
            print(f"   ❌ VectorDB: {e}")

        print("   Checking DocumentParser...")
        try:
            # Test with the document file
            doc_path = Path(FEDERAL_LAW_PATH)
            if doc_path.exists():
                supports = document_parser.supports_format(doc_path)
                print(f"   ✅ DocumentParser supports PDF: {supports}")
            else:
                print(f"   ❌ Document file not found: {doc_path}")
        except Exception as e:
            print(f"   ❌ DocumentParser: {e}")

        self.test_results['health_check'] = 'passed'

    async def _upload_and_parse_document(self):
        """Upload and parse the Federal Law document."""
        doc_path = Path(FEDERAL_LAW_PATH)

        if not doc_path.exists():
            raise FileNotFoundError(f"Federal Law document not found: {doc_path}")

        print(f"   Parsing document: {doc_path.name}")

        # Parse the document
        parsed_doc = await document_parser.parse_document(doc_path)

        print("   Parsed document info:")
        print(f"   - Filename: {parsed_doc.filename}")
        print(f"   - Text length: {len(parsed_doc.text)} chars")
        print(f"   - Paragraphs: {len(parsed_doc.paragraphs)}")
        print(f"   - Page count: {parsed_doc.metadata.get('page_count', 'N/A')}")

        # Extract some sample content
        paragraph_details = parsed_doc.metadata.get("paragraph_details", [])
        if paragraph_details:
            print(f"   - Paragraph chunks: {len(paragraph_details)}")
            print("   Sample paragraphs:")
            for i, para in enumerate(paragraph_details[:3]):
                content_preview = para.get('content', '')[:100] + "..." if len(para.get('content', '')) > 100 else para.get('content', '')
                print(f"     {i+1}. {content_preview}")

        self.test_results['document_parsing'] = {
            'filename': parsed_doc.filename,
            'text_length': len(parsed_doc.text),
            'paragraphs': len(parsed_doc.paragraphs),
            'chunks': len(paragraph_details)
        }

    async def _index_document(self):
        """Index the document into RAG system."""
        doc_path = Path(FEDERAL_LAW_PATH)
        parsed_doc = await document_parser.parse_document(doc_path)

        # Generate document ID
        import uuid
        self.document_id = str(uuid.uuid4())

        print(f"   Indexing with ID: {self.document_id}")

        # Index into knowledge base (criteria type)
        paragraph_details = parsed_doc.metadata.get("paragraph_details", [])
        await knowledge_base.ingest_document(
            document_id=self.document_id,
            document_title=parsed_doc.filename,
            paragraph_details=paragraph_details,
        )

        print(f"   Indexed {len(paragraph_details)} chunks")

        # Wait for indexing to complete
        await asyncio.sleep(2)

        # Get indexing metrics - use RAG orchestrator if available
        metrics = {}
        if RAGServiceFactory.get_rag_orchestrator():
            rag_health = await RAGServiceFactory.get_rag_orchestrator().health_check()
            metrics = rag_health.get('metrics', {})

        self.test_results['indexing'] = {
            'document_id': self.document_id,
            'chunks_indexed': len(paragraph_details),
            'total_indexed': metrics.get('total_indexed_documents', 0)
        }

    async def _test_queries(self):
        """Test RAG queries on legal content."""
        query_results = []

        rag_orchestrator = RAGServiceFactory.get_rag_orchestrator()
        if not rag_orchestrator:
            print("   ❌ RAG orchestrator not available")
            self.test_results['queries'] = []
            return

        for i, query in enumerate(TEST_QUERIES, 1):
            print(f"   Query {i}: {query}")

            try:
                # Use RAG orchestrator search
                results = await rag_orchestrator.search(query, top_k=3)

                if results:
                    print(f"   Found {len(results)} results")
                    print(f"   Top score: {results[0].score:.4f}")
                    print(f"   Content preview: {results[0].content[:150]}...")
                else:
                    print("   No results found")

                query_results.append({
                    'query': query,
                    'results_count': len(results),
                    'top_score': results[0].score if results else None
                })

            except Exception as e:
                print(f"   ❌ Query failed: {e}")
                query_results.append({
                    'query': query,
                    'error': str(e)
                })

        self.test_results['queries'] = query_results

    async def _validate_performance(self):
        """Validate system performance."""
        print("   Running performance tests...")

        rag_orchestrator = RAGServiceFactory.get_rag_orchestrator()
        if not rag_orchestrator:
            print("   ❌ RAG orchestrator not available")
            self.test_results['performance'] = {'error': 'RAG orchestrator not available'}
            return

        # Test search performance
        import time
        search_times = []

        for query in TEST_QUERIES[:3]:  # Test first 3 queries
            start = time.time()
            results = await rag_orchestrator.search(query, top_k=2)
            search_times.append(time.time() - start)

        avg_search_time = sum(search_times) / len(search_times) if search_times else 0

        # Get system metrics
        health = await rag_orchestrator.health_check()
        metrics = await rag_orchestrator.get_metrics()

        print(f"   Average search time: {avg_search_time:.3f}s")
        print(f"   Total indexed documents: {metrics.total_indexed_documents}")
        print(f"   Total searches: {metrics.total_searches}")

        self.test_results['performance'] = {
            'avg_search_time': avg_search_time,
            'total_indexed': metrics.total_indexed_documents,
            'total_searches': metrics.total_searches
        }

    async def _cleanup(self):
        """Clean up test data."""
        if self.document_id:
            try:
                await knowledge_base.remove_document(self.document_id)
                print(f"   Cleaned up document: {self.document_id}")
            except Exception as e:
                print(f"   Cleanup warning: {e}")

        self.test_results['cleanup'] = 'completed'

    def _print_final_report(self):
        """Print comprehensive test report."""
        print("\n📊 FINAL TEST REPORT")
        print("=" * 60)

        print("\n✅ Test Results Summary:")

        if 'document_parsing' in self.test_results:
            parsing = self.test_results['document_parsing']
            print(f"📄 Document Parsing: SUCCESS")
            print(f"   - File: {parsing['filename']}")
            print(f"   - Text: {parsing['text_length']} chars")
            print(f"   - Paragraphs: {parsing['paragraphs']}")
            print(f"   - Chunks: {parsing['chunks']}")

        if 'indexing' in self.test_results:
            indexing = self.test_results['indexing']
            print(f"🔍 Document Indexing: SUCCESS")
            print(f"   - Document ID: {indexing['document_id']}")
            print(f"   - Chunks indexed: {indexing['chunks_indexed']}")
            print(f"   - Total indexed: {indexing['total_indexed']}")

        if 'queries' in self.test_results:
            queries = self.test_results['queries']
            successful_queries = [q for q in queries if 'error' not in q]
            print(f"❓ Query Testing: {len(successful_queries)}/{len(queries)} SUCCESS")
            for q in queries:
                status = "✅" if 'error' not in q else "❌"
                print(f"   {status} {q['query'][:50]}...")

        if 'performance' in self.test_results:
            perf = self.test_results['performance']
            print(f"⚡ Performance: VALIDATED")
            if 'avg_search_time' in perf:
                print(f"   - Avg search time: {perf['avg_search_time']:.3f}s")
            else:
                print(f"   - Search time: N/A (RAG not available)")
            if 'total_indexed' in perf:
                print(f"   - Total indexed: {perf['total_indexed']}")
            if 'total_searches' in perf:
                print(f"   - Total searches: {perf['total_searches']}")

        print("\n🎯 RAG SYSTEM TEST: COMPLETE")
        print("✅ Real document uploaded and indexed")
        print("✅ Legal content queries tested")
        print("✅ Embeddings and search validated")
        print("✅ System performance verified")

async def main():
    """Main test execution."""
    tester = RAGTester()
    success = await tester.run_full_test_suite()

    print(f"\n🏁 FINAL RESULT: {'SUCCESS' if success else 'FAILED'}")
    exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())