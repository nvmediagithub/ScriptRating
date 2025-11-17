#!/usr/bin/env python3
"""
Test script for the migration pipeline.

This script creates sample data and tests the complete migration pipeline
including validation and rollback functionality.
"""

import asyncio
import json
import logging
import sys
import tempfile
import shutil
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.infrastructure.services.knowledge_base import KnowledgeBase, KnowledgeEntry
from app.domain.services.rag_orchestrator import RAGOrchestrator, RAGDocument
from app.infrastructure.services.vector_database_service import VectorDatabaseService
from app.infrastructure.services.embedding_service import EmbeddingService
from app.infrastructure.services.rag_factory import RAGFactory
from app.config.settings import Settings
from scripts.migrate_to_vector_search import MigrationManager, MigrationConfig


# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


async def create_sample_documents(knowledge_base: KnowledgeBase, num_docs: int = 20) -> None:
    """Create sample documents for testing."""
    logger.info(f"Creating {num_docs} sample documents...")

    sample_texts = [
        "The film contains scenes of violence including physical fights and weapons usage.",
        "Characters engage in romantic relationships with emotional dialogue and intimate moments.",
        "The storyline involves family dynamics and generational conflicts.",
        "There are comedic elements with humorous situations and character interactions.",
        "The movie explores themes of redemption and personal growth.",
        "Supporting characters provide background and context to the main narrative.",
        "The plot includes mystery elements with clues and revelations.",
        "Musical sequences appear throughout the film with original songs.",
        "The cinematography captures beautiful landscapes and cityscapes.",
        "Character development shows psychological depth and internal struggles.",
        "The script uses metaphor and symbolism to convey deeper meanings.",
        "Dialogue reveals character motivations and backstory information.",
        "Visual effects create fantastical elements in the story world.",
        "The pacing builds tension through carefully structured scenes.",
        "Cultural references provide context for character backgrounds.",
        "Sound design enhances emotional impact of key scenes.",
        "Costume design reflects character personalities and time periods.",
        "The narrative structure uses flashbacks to reveal plot information.",
        "Character arcs show transformation over the course of the story.",
        "The ending provides resolution while leaving some questions open.",
    ]

    for i in range(num_docs):
        document_id = f"test_doc_{i:03d}"
        document_title = f"Sample Script Document {i:03d}"

        # Create paragraphs for this document
        paragraphs = []
        for j in range(3):  # 3 paragraphs per document
            text_index = (i * 3 + j) % len(sample_texts)
            paragraphs.append({
                "text": sample_texts[text_index],
                "page": j + 1,
                "paragraph_index": j + 1,
                "metadata": {
                    "source": "test_migration",
                    "created_by": "test_script",
                    "confidence_score": 0.85 + (j * 0.05)
                }
            })

        await knowledge_base.ingest_document(
            document_id=document_id,
            document_title=document_title,
            paragraph_details=paragraphs
        )

    logger.info(f"Created {num_docs} sample documents with {num_docs * 3} total paragraphs")


async def test_search_functionality(knowledge_base: KnowledgeBase, rag_orchestrator: RAGOrchestrator) -> dict:
    """Test search functionality before and after migration."""
    logger.info("Testing search functionality...")

    test_queries = [
        "violence in films",
        "romantic relationships",
        "character development",
        "musical elements"
    ]

    results = {
        "tfidf_searches": 0,
        "rag_searches": 0,
        "search_quality_comparison": []
    }

    for query in test_queries:
        # Test TF-IDF search
        tfidf_results = await knowledge_base.query(query, top_k=3)
        results["tfidf_searches"] += 1

        # Test RAG search
        rag_results = await rag_orchestrator.search(query, top_k=3)
        results["rag_searches"] += 1

        # Compare results
        comparison = {
            "query": query,
            "tfidf_results_count": len(tfidf_results),
            "rag_results_count": len(rag_results),
            "tfidf_top_score": tfidf_results[0]["score"] if tfidf_results else 0,
            "rag_top_score": rag_results[0].score if rag_results else 0
        }
        results["search_quality_comparison"].append(comparison)

    return results


async def run_migration_test():
    """Run the complete migration test pipeline."""
    logger.info("Starting migration pipeline test...")

    # Create temporary directory for test
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Override config files for testing
        test_status_file = temp_path / "test_migration_status.json"
        test_backup_file = temp_path / "test_knowledge_base_backup.json"

        try:
            # Initialize settings and services
            settings = Settings()

            # Create RAG orchestrator
            rag_factory = RAGFactory(settings)
            rag_orchestrator = await rag_factory.create_orchestrator()

            # Create KnowledgeBase with RAG integration
            knowledge_base = KnowledgeBase(rag_orchestrator=rag_orchestrator)
            await knowledge_base.initialize()

            # Create sample data
            await create_sample_documents(knowledge_base, num_docs=10)

            # Test search before migration
            logger.info("Testing search functionality before migration...")
            pre_migration_search = await test_search_functionality(knowledge_base, rag_orchestrator)

            # Configure migration
            config = MigrationConfig(
                batch_size=5,
                enable_dry_run=False,
                skip_validation=False,
                status_file=str(test_status_file),
                backup_file=str(test_backup_file)
            )

            # Create migration manager
            migration_manager = MigrationManager(knowledge_base, rag_orchestrator, config)

            # Run migration
            logger.info("Running migration...")
            migration_status = await migration_manager.migrate()

            # Test search after migration
            logger.info("Testing search functionality after migration...")
            post_migration_search = await test_search_functionality(knowledge_base, rag_orchestrator)

            # Validate migration
            logger.info("Validating migration results...")

            # Check that documents exist in vector DB
            health = await rag_orchestrator.health_check()
            vector_count = 0
            if "vector_db_service" in health and "collection_info" in health["vector_db_service"]:
                vector_count = health["vector_db_service"]["collection_info"].get("points_count", 0)

            # Check that knowledge base still works
            kb_stats = await knowledge_base.get_document_stats()

            # Test rollback
            logger.info("Testing rollback functionality...")
            rollback_success = await migration_manager.rollback()

            # Verify rollback
            post_rollback_health = await rag_orchestrator.health_check()
            rollback_vector_count = 0
            if "vector_db_service" in post_rollback_health and "collection_info" in post_rollback_health["vector_db_service"]:
                rollback_vector_count = post_rollback_health["vector_db_service"]["collection_info"].get("points_count", 0)

            # Test search after rollback
            logger.info("Testing search functionality after rollback...")
            post_rollback_search = await test_search_functionality(knowledge_base, rag_orchestrator)

            # Compile test results
            test_results = {
                "success": True,
                "pre_migration": {
                    "documents_created": 10,
                    "paragraphs_created": 30,
                    "search_tests": pre_migration_search
                },
                "migration_results": {
                    "status": migration_status.status,
                    "documents_processed": migration_status.processed_documents,
                    "documents_migrated": migration_status.migrated_documents,
                    "documents_failed": migration_status.failed_documents,
                    "duration": f"{migration_status.start_time} to {migration_status.end_time or 'ongoing'}",
                    "validation_results": migration_status.validation_results
                },
                "post_migration": {
                    "vector_db_count": vector_count,
                    "knowledge_base_docs": len(kb_stats),
                    "search_tests": post_migration_search
                },
                "rollback_results": {
                    "rollback_success": rollback_success,
                    "post_rollback_vector_count": rollback_vector_count,
                    "search_tests": post_rollback_search
                },
                "validation_checks": [
                    {
                        "check": "migration_completed",
                        "passed": migration_status.status == "completed",
                        "details": f"Migration status: {migration_status.status}"
                    },
                    {
                        "check": "documents_migrated",
                        "passed": migration_status.migrated_documents > 0,
                        "details": f"Migrated: {migration_status.migrated_documents}/{migration_status.total_documents}"
                    },
                    {
                        "check": "vector_search_available",
                        "passed": vector_count > 0,
                        "details": f"Vector DB contains {vector_count} documents"
                    },
                    {
                        "check": "knowledge_base_preserved",
                        "passed": len(kb_stats) > 0,
                        "details": f"KnowledgeBase has {len(kb_stats)} documents"
                    },
                    {
                        "check": "rollback_successful",
                        "passed": rollback_success and rollback_vector_count == 0,
                        "details": f"Rollback success: {rollback_success}, Vector count after rollback: {rollback_vector_count}"
                    }
                ]
            }

            # Check overall success
            all_checks_passed = all(check["passed"] for check in test_results["validation_checks"])
            test_results["success"] = all_checks_passed

            # Print results
            print("\n" + "="*60)
            print("MIGRATION PIPELINE TEST RESULTS")
            print("="*60)

            print(f"\n✅ Test Status: {'PASSED' if test_results['success'] else 'FAILED'}")

            print("
📊 Pre-Migration:"            print(f"  Documents created: {test_results['pre_migration']['documents_created']}")
            print(f"  Paragraphs created: {test_results['pre_migration']['paragraphs_created']}")

            print("
🔄 Migration:"            print(f"  Status: {test_results['migration_results']['status']}")
            print(f"  Documents processed: {test_results['migration_results']['documents_processed']}")
            print(f"  Documents migrated: {test_results['migration_results']['documents_migrated']}")
            print(f"  Documents failed: {test_results['migration_results']['documents_failed']}")

            print("
📈 Post-Migration:"            print(f"  Vector DB count: {test_results['post_migration']['vector_db_count']}")
            print(f"  KnowledgeBase docs: {test_results['post_migration']['knowledge_base_docs']}")

            print("
↩️  Rollback:"            print(f"  Rollback successful: {test_results['rollback_results']['rollback_success']}")
            print(f"  Post-rollback vector count: {test_results['rollback_results']['post_rollback_vector_count']}")

            print("
🔍 Validation Checks:"            for check in test_results["validation_checks"]:
                status = "✅" if check["passed"] else "❌"
                print(f"  {status} {check['check']}: {check['details']}")

            # Save detailed results
            results_file = Path("migration_test_results.json")
            with open(results_file, 'w') as f:
                json.dump(test_results, f, indent=2, default=str)

            print(f"\n📄 Detailed results saved to: {results_file}")

            if test_results["success"]:
                print("\n🎉 Migration pipeline test completed successfully!")
                return True
            else:
                print("\n⚠️  Migration pipeline test found issues!")
                return False

        except Exception as e:
            logger.error(f"Test failed with error: {e}")
            print(f"\n❌ Test failed: {e}")
            return False
        finally:
            # Cleanup
            if 'rag_orchestrator' in locals():
                await rag_orchestrator.close()


async def main():
    """Main test execution."""
    print("🧪 Testing migration pipeline with sample data...")

    success = await run_migration_test()

    if success:
        print("\n✅ All migration tests passed!")
        sys.exit(0)
    else:
        print("\n❌ Migration tests failed!")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())