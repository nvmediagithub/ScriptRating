#!/usr/bin/env python3
"""Simple test to verify document upload with local RAG processing."""

import os, sys
sys.path.insert(0, 'app')

from app.presentation.api.main import create_app
from app.presentation.api.schemas import DocumentType
from fastapi.testclient import TestClient
from io import BytesIO

def test():
    app = create_app()
    client = TestClient(app)

    print("Testing document upload with local RAG...")
    test_content = "Test document for RAG with local sentence transformers."
    files = {'file': ('test.txt', BytesIO(test_content.encode()), 'text/plain')}
    data = {'document_type': DocumentType.CRITERIA.value, 'filename': 'test.txt'}

    response = client.post('/api/documents/upload', files=files, data=data)
    print(f"Status: {response.status_code}")

    if response.status_code == 200:
        result = response.json()
        print(f"Document ID: {result['document_id']}")
        print(f"Status: {result['status']}")

        if 'rag_processing_details' in result:
            rag = result['rag_processing_details']
            print(f"RAG chunks processed: {rag['chunks_processed']}")
            print(f"Embedding status: {rag['embedding_generation_status']}")
            print(f"Vector DB status: {rag['vector_db_indexing_status']}")
            print("✅ RAG processing successful with local models!")
        else:
            print("❌ No RAG details found")
    else:
        print(f"❌ Error: {response.text}")

    print("\nTesting health check...")
    health_response = client.get('/api/health')
    if health_response.status_code == 200:
        health = health_response.json()
        rag_status = health.get('services', {}).get('rag_orchestrator', {})
        print(f"RAG enabled: {rag_status.get('rag_enabled', False)}")
        print(f"RAG healthy: {rag_status.get('healthy', False)}")

if __name__ == "__main__":
    test()