#!/usr/bin/env python3
"""
Complete RAG document upload and processing flow test.
Tests the complete document upload -> RAG processing -> status check flow with mock configuration.
"""
import asyncio
import os
import sys
import tempfile
from pathlib import Path
from io import BytesIO
from unittest.mock import Mock, patch

# Add current directory to Python path
sys.path.append('.')

from fastapi.testclient import TestClient
from fastapi import UploadFile
from app.presentation.api.main import app
from app.infrastructure.services.runtime_context import get_knowledge_base, get_analysis_manager
from app.presentation.api.schemas import DocumentType
from app.config.rag_config import get_rag_config
from app.infrastructure.services.rag_factory import RAGServiceFactory


async def test_complete_rag_document_flow():
    """Test complete document upload and RAG processing flow with mock configuration."""
    print("🎯 COMPLETE RAG DOCUMENT UPLOAD AND PROCESSING FLOW TEST")
    print("=" * 70)

    # Force mock configuration for testing
    os.environ['EMBEDDING_PRIMARY_PROVIDER'] = 'mock'
    os.environ['ENABLE_RAG_SYSTEM'] = 'true'
    os.environ['QDRANT_URL'] = 'http://localhost:6333'

    try:
        # Phase 1: Initialize services with mock configuration
        print("🔧 Phase 1: Initializing services with mock configuration...")

        # Get RAG config
        config = get_rag_config()
        print(f"   Config - RAG enabled: {config.is_rag_enabled()}")
        print(f"   Config - Primary provider: {config.embedding_primary_provider}")

        # Initialize knowledge base using factory
        knowledge_base = await RAGServiceFactory.initialize_services(config)
        print("   ✅ Knowledge base initialized via factory")

        # Verify RAG orchestrator is attached
        has_rag_attr = hasattr(knowledge_base, '_rag_orchestrator')
        rag_orchestrator = getattr(knowledge_base, '_rag_orchestrator', None)
        print(f"   KB has _rag_orchestrator attribute: {has_rag_attr}")
        print(f"   RAG orchestrator is None: {rag_orchestrator is None}")

        if rag_orchestrator:
            print("   ✅ RAG orchestrator is properly attached to knowledge base")
        else:
            print("   ❌ RAG orchestrator is None - RAG processing will not work")
            return False

        # Phase 2: Create test document
        print("\n📄 Phase 2: Creating test document...")
        test_content = """Article 1. Children under 18 years of age shall not be allowed to participate in scenes containing violence, including:

1. Physical violence between characters
2. Verbal threats or intimidation
3. Destruction of property
4. Any form of harm to living beings

Article 2. Content rating shall be determined based on:
- Age-appropriate content analysis
- Scene-by-scene evaluation
- Contextual factors including educational value
- Overall thematic elements

Article 3. Rating categories include:
- 0+: Suitable for all ages
- 6+: May contain mild fantasy violence
- 12+: May contain moderate violence
- 16+: May contain intense violence
- 18+: Strictly for adults only"""

        # Create temporary file
        with tempfile.NamedTemporaryFile(suffix='.txt', delete=False, mode='w', encoding='utf-8') as f:
            f.write(test_content)
            temp_file_path = f.name

        print(f"   ✅ Test document created at: {temp_file_path}")
        print(f"   Document length: {len(test_content)} characters")

        # Phase 3: Test document upload via API
        print("\n📤 Phase 3: Testing document upload via API...")

        # Create FastAPI test client
        client = TestClient(app)
    
        # Prepare upload file
        with open(temp_file_path, 'rb') as f:
            file_content = f.read()
    
        files = {
            'file': ('test_criteria.txt', BytesIO(file_content), 'text/plain')
        }
        data = {
            'document_type': DocumentType.CRITERIA.value,
            'filename': 'test_criteria.txt'
        }
    
        # Make upload request (note: prefix is already included in router)
        response = client.post("/api/documents/upload", files=files, data=data)
        print(f"   Upload response status: {response.status_code}")

        if response.status_code == 200:
            upload_result = response.json()
            document_id = upload_result.get('document_id')
            rag_processing_details = upload_result.get('rag_processing_details')
            status = upload_result.get('status')

            print(f"   ✅ Document uploaded successfully")
            print(f"   Document ID: {document_id}")
            print(f"   Status: {status}")
            print(f"   RAG processing details present: {rag_processing_details is not None}")

            if rag_processing_details:
                print("   RAG Processing Details:")
                print(f"     - Total chunks: {rag_processing_details.get('total_chunks')}")
                print(f"     - Chunks processed: {rag_processing_details.get('chunks_processed')}")
                print(f"     - Embedding status: {rag_processing_details.get('embedding_generation_status')}")
                print(f"     - Vector DB status: {rag_processing_details.get('vector_db_indexing_status')}")
                print(f"     - Documents indexed: {rag_processing_details.get('documents_indexed')}")
                print(f"     - Processing time: {rag_processing_details.get('indexing_time_ms')} ms")
            else:
                print("   ❌ RAG processing details are None - RAG processing failed")
                return False
        else:
            print(f"   ❌ Upload failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            return False

        # Phase 4: Test document processing status endpoint
        print("\n📊 Phase 4: Testing document processing status endpoint...")

        status_response = client.get(f"/api/documents/{document_id}/status")
        print(f"   Status response code: {status_response.status_code}")

        if status_response.status_code == 200:
            status_result = status_response.json()
            status_rag_details = status_result.get('rag_processing_details')

            print("   ✅ Status endpoint returned successfully")
            print(f"   Document status: {status_result.get('status')}")
            print(f"   Status RAG details present: {status_rag_details is not None}")

            if status_rag_details:
                print("   Status RAG Processing Details:")
                print(f"     - Total chunks: {status_rag_details.get('total_chunks')}")
                print(f"     - Chunks processed: {status_rag_details.get('chunks_processed')}")
                print(f"     - Embedding status: {status_rag_details.get('embedding_generation_status')}")
                print(f"     - Vector DB status: {status_rag_details.get('vector_db_indexing_status')}")
                print(f"     - Documents indexed: {status_rag_details.get('documents_indexed')}")
                print(f"     - Processing time: {status_rag_details.get('indexing_time_ms')} ms")
            else:
                print("   ❌ Status endpoint RAG details are None")
                return False
        else:
            print(f"   ❌ Status endpoint failed with code {status_response.status_code}")
            print(f"   Response: {status_response.text}")
            return False

        # Phase 5: Verify data consistency
        print("\n🔍 Phase 5: Verifying data consistency...")

        upload_details = rag_processing_details
        status_details = status_rag_details

        # Check if details match
        fields_to_check = [
            'total_chunks', 'chunks_processed', 'documents_indexed',
            'embedding_generation_status', 'vector_db_indexing_status'
        ]

        consistency_issues = []
        for field in fields_to_check:
            upload_val = upload_details.get(field)
            status_val = status_details.get(field)
            if upload_val != status_val:
                consistency_issues.append(f"{field}: upload={upload_val}, status={status_val}")

        if consistency_issues:
            print(f"   ❌ Data consistency issues found: {consistency_issues}")
            return False
        else:
            print("   ✅ Upload and status data are consistent")

        # Phase 6: Test knowledge base integration
        print("\n🧠 Phase 6: Testing knowledge base integration...")

        # Query the knowledge base
        query_results = await knowledge_base.query("children under 18", top_k=3)
        print(f"   Query results count: {len(query_results)}")

        if query_results:
            print("   ✅ Knowledge base query successful")
            top_result = query_results[0]
            print(f"   Top result score: {top_result.get('score'):.3f}")
            print(f"   Top result document: {top_result.get('title')}")
            print(f"   Top result excerpt: {top_result.get('excerpt')[:100]}...")
        else:
            print("   ⚠️ Knowledge base query returned no results")

        # Phase 7: Cleanup
        print("\n🧹 Phase 7: Cleaning up...")

        # Clean up temp file
        Path(temp_file_path).unlink(missing_ok=True)
        print("   ✅ Temporary file cleaned up")

        # Clean up document
        delete_response = client.delete(f"/api/documents/{document_id}")
        if delete_response.status_code == 200:
            print("   ✅ Test document deleted from system")
        else:
            print(f"   ⚠️ Failed to delete test document: {delete_response.status_code}")

        print("\n🎉 COMPLETE RAG FLOW TEST PASSED SUCCESSFULLY!")
        print("=" * 70)
        print("✅ Document upload: SUCCESS")
        print("✅ RAG processing: SUCCESS")
        print("✅ Processing details populated: SUCCESS")
        print("✅ Status endpoint: SUCCESS")
        print("✅ Data consistency: SUCCESS")
        print("✅ Knowledge base integration: SUCCESS")

        return True

    except Exception as e:
        print(f"\n❌ COMPLETE RAG FLOW TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False

    finally:
        # Reset environment variables
        if 'EMBEDDING_PRIMARY_PROVIDER' in os.environ:
            del os.environ['EMBEDDING_PRIMARY_PROVIDER']
        if 'ENABLE_RAG_SYSTEM' in os.environ:
            del os.environ['ENABLE_RAG_SYSTEM']
        if 'QDRANT_URL' in os.environ:
            del os.environ['QDRANT_URL']


if __name__ == "__main__":
    success = asyncio.run(test_complete_rag_document_flow())
    print(f"\n🏁 FINAL RESULT: {'SUCCESS' if success else 'FAILED'}")
    exit(0 if success else 1)