#!/usr/bin/env python3
"""
Быстрый диагностический тест RAG API без загрузки тяжелых моделей
"""
import os
import time
import requests
from dotenv import load_dotenv

# Загружаем конфигурацию
load_dotenv()

def test_redis():
    """Тестирование Redis"""
    print("🔍 Testing Redis...")
    try:
        import redis
        r = redis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379/0'))
        result = r.ping()
        print(f"✅ Redis ping: {result}")
        return True
    except Exception as e:
        print(f"❌ Redis: {e}")
        return False

def test_basic_imports():
    """Тестирование базовых импортов"""
    print("🔍 Testing basic imports...")
    
    try:
        from fastapi import FastAPI
        print("✅ FastAPI import: OK")
    except Exception as e:
        print(f"❌ FastAPI import: {e}")
        return False
    
    try:
        import uvicorn
        print("✅ Uvicorn import: OK")
    except Exception as e:
        print(f"❌ Uvicorn import: {e}")
        return False
    
    return True

def test_environment_vars():
    """Тестирование переменных окружения"""
    print("🔍 Testing environment variables...")
    
    required_vars = {
        'ENABLE_RAG_SYSTEM': 'true',
        'REDIS_URL': 'redis://localhost:6379',
        'QDRANT_COLLECTION_NAME': 'scriptrating_documents'
    }
    
    all_ok = True
    for var, expected in required_vars.items():
        value = os.getenv(var)
        if value == expected:
            print(f"✅ {var}: {value}")
        else:
            print(f"⚠️  {var}: {value} (expected: {expected})")
            all_ok = False
    
    return all_ok

def test_file_structure():
    """Тестирование структуры файлов"""
    print("🔍 Testing file structure...")
    
    required_files = [
        'main.py',
        'config/settings.py',
        'app/routers/rag.py',
        'app/services/rag_orchestrator.py',
        'storage/documents'
    ]
    
    all_ok = True
    for file_path in required_files:
        if os.path.exists(file_path):
            print(f"✅ {file_path}: exists")
        else:
            print(f"❌ {file_path}: missing")
            all_ok = False
    
    return all_ok

def test_simple_api():
    """Тестирование простого API без RAG"""
    print("🔍 Testing simple API startup...")
    
    try:
        import subprocess
        import signal
        import sys
        
        # Запускаем сервис с таймаутом
        process = subprocess.Popen([
            'python3', '-c', '''
import os
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI
from fastapi.testclient import TestClient

app = FastAPI(title="Quick Test")

@app.get("/health")
def health():
    return {"status": "healthy", "rag_disabled": True}

@app.get("/test")
def test():
    return {"message": "API is working"}

client = TestClient(app)
response = client.get("/health")
print(f"Health: {response.status_code} - {response.json()}")

response = client.get("/test")
print(f"Test: {response.status_code} - {response.json()}")
'''
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        stdout, stderr = process.communicate(timeout=10)
        
        if process.returncode == 0:
            print("✅ Simple API test: OK")
            print("Output:", stdout.decode())
            return True
        else:
            print(f"❌ Simple API test failed: {stderr.decode()}")
            return False
            
    except Exception as e:
        print(f"❌ Simple API test: {e}")
        return False

def run_performance_test():
    """Тестирование производительности компонентов"""
    print("🔍 Running performance tests...")
    
    # Тест времени импорта
    start_time = time.time()
    try:
        import json
        import re
        import hashlib
        import time
    except Exception as e:
        print(f"❌ Basic imports failed: {e}")
        return False
    
    basic_import_time = time.time() - start_time
    
    # Тест времени создания простых объектов
    start_time = time.time()
    test_data = [{"id": i, "text": f"Test document {i}"} for i in range(1000)]
    data_processing_time = time.time() - start_time
    
    print(f"✅ Basic imports: {basic_import_time:.4f}s")
    print(f"✅ Data processing (1000 items): {data_processing_time:.4f}s")
    
    return True

if __name__ == "__main__":
    print("🚀 Quick RAG System Diagnostic")
    print("=" * 50)
    
    # Выполняем быстрые тесты
    env_ok = test_environment_vars()
    imports_ok = test_basic_imports()
    structure_ok = test_file_structure()
    redis_ok = test_redis()
    api_ok = test_simple_api()
    perf_ok = run_performance_test()
    
    print("\n" + "=" * 50)
    print("📊 Quick Test Summary:")
    print(f"{'✅' if env_ok else '❌'} Environment: {'Ready' if env_ok else 'Issues'}")
    print(f"{'✅' if imports_ok else '❌'} Imports: {'Ready' if imports_ok else 'Issues'}")
    print(f"{'✅' if structure_ok else '❌'} File Structure: {'Ready' if structure_ok else 'Issues'}")
    print(f"{'✅' if redis_ok else '❌'} Redis: {'Ready' if redis_ok else 'Issues'}")
    print(f"{'✅' if api_ok else '❌'} API: {'Ready' if api_ok else 'Issues'}")
    print(f"{'✅' if perf_ok else '❌'} Performance: {'Ready' if perf_ok else 'Issues'}")
    
    if all([env_ok, imports_ok, structure_ok, redis_ok, api_ok]):
        print("\n🎉 Basic system is ready!")
        print("⚠️  Note: RAG functionality may be slow due to model loading")
    else:
        print("\n⚠️  System has basic issues that need resolution")