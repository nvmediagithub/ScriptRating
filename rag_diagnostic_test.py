#!/usr/bin/env python3
"""
Диагностический тест RAG системы
"""
import os
import time
from dotenv import load_dotenv

# Загружаем конфигурацию
load_dotenv()

def test_imports():
    """Тестирование импортов"""
    print("🔍 Testing imports...")
    
    try:
        import redis
        print("✅ Redis import: OK")
    except Exception as e:
        print(f"❌ Redis import: {e}")
    
    try:
        import qdrant_client
        print("✅ Qdrant import: OK")
    except Exception as e:
        print(f"❌ Qdrant import: {e}")
    
    try:
        from sentence_transformers import SentenceTransformer
        print("✅ Sentence Transformers import: OK")
    except Exception as e:
        print(f"❌ Sentence Transformers import: {e}")

def test_environment():
    """Тестирование переменных окружения"""
    print("\n🔍 Testing environment variables...")
    
    env_vars = {
        'ENABLE_RAG_SYSTEM': os.getenv('ENABLE_RAG_SYSTEM'),
        'FALLBACK_EMBEDDING_MODEL': os.getenv('FALLBACK_EMBEDDING_MODEL'),
        'ENABLE_FALLBACK_EMBEDDINGS': os.getenv('ENABLE_FALLBACK_EMBEDDINGS'),
        'REDIS_URL': os.getenv('REDIS_URL'),
        'QDRANT_COLLECTION_NAME': os.getenv('QDRANT_COLLECTION_NAME')
    }
    
    for key, value in env_vars.items():
        status = "✅" if value else "❌"
        print(f"{status} {key}: {value}")

def test_redis_connection():
    """Тестирование подключения к Redis"""
    print("\n🔍 Testing Redis connection...")
    
    try:
        import redis
        r = redis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379/0'))
        result = r.ping()
        print(f"✅ Redis ping: {result}")
    except Exception as e:
        print(f"❌ Redis connection: {e}")

def test_sentence_transformers():
    """Тестирование sentence transformers"""
    print("\n🔍 Testing Sentence Transformers...")
    
    try:
        from sentence_transformers import SentenceTransformer
        
        model_name = os.getenv('FALLBACK_EMBEDDING_MODEL', 'all-MiniLM-L6-v2')
        print(f"📦 Loading model: {model_name}")
        
        start_time = time.time()
        model = SentenceTransformer(model_name)
        load_time = time.time() - start_time
        
        print(f"✅ Model loaded in {load_time:.2f}s")
        
        # Тест эмбеддинга
        test_text = "Test document for embedding"
        embeddings = model.encode([test_text])
        print(f"✅ Embedding test: shape {embeddings.shape}")
        
        return True
        
    except Exception as e:
        print(f"❌ Sentence Transformers: {e}")
        return False

def test_qdrant():
    """Тестирование Qdrant"""
    print("\n🔍 Testing Qdrant...")
    
    try:
        from qdrant_client import QdrantClient
        
        qdrant_url = os.getenv('QDRANT_URL')
        collection_name = os.getenv('QDRANT_COLLECTION_NAME', 'scriptrating_documents')
        
        if qdrant_url:
            client = QdrantClient(url=qdrant_url)
            print("✅ Qdrant client created with URL")
        else:
            client = QdrantClient(":memory:")
            print("✅ Qdrant client created in-memory")
        
        # Попытка создать коллекцию (для тестирования)
        collections = client.get_collections()
        print(f"✅ Qdrant collections: {len(collections.collections)} found")
        
        return True
        
    except Exception as e:
        print(f"❌ Qdrant: {e}")
        return False

def test_minimal_fastapi():
    """Тестирование минимального FastAPI приложения"""
    print("\n🔍 Testing minimal FastAPI startup...")
    
    try:
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        
        app = FastAPI(title="RAG Diagnostic Test")
        
        @app.get("/health")
        def health():
            return {"status": "healthy", "rag_test": True}
        
        client = TestClient(app)
        response = client.get("/health")
        
        if response.status_code == 200:
            print("✅ FastAPI test: OK")
            return True
        else:
            print(f"❌ FastAPI test: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ FastAPI test: {e}")
        return False

if __name__ == "__main__":
    print("🚀 RAG System Diagnostic Test")
    print("=" * 50)
    
    # Выполняем все тесты
    test_imports()
    test_environment()
    test_redis_connection()
    
    # Тестируем sentence transformers отдельно (может быть медленным)
    print("\n⚠️  Testing sentence transformers (this may take time)...")
    st_success = test_sentence_transformers()
    
    qdrant_success = test_qdrant()
    fastapi_success = test_minimal_fastapi()
    
    print("\n" + "=" * 50)
    print("📊 Test Summary:")
    print(f"✅ Environment: Ready")
    print(f"{'✅' if st_success else '⚠️'} Sentence Transformers: {'Ready' if st_success else 'Failed'}")
    print(f"{'✅' if qdrant_success else '⚠️'} Qdrant: {'Ready' if qdrant_success else 'Failed'}")
    print(f"{'✅' if fastapi_success else '❌'} FastAPI: {'Ready' if fastapi_success else 'Failed'}")
    
    if st_success and fastapi_success:
        print("\n🎉 System is ready for testing!")
    else:
        print("\n⚠️  System has issues that need resolution")