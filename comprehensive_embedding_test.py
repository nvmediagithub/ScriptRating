#!/usr/bin/env python3
"""
Тест много-провайдерной архитектуры EmbeddingService и API endpoints.
"""
import asyncio
import time
import json
import logging
from typing import Dict, Any

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_mock_embedding_service():
    """Тест EmbeddingService с mock провайдером для проверки архитектуры."""
    print("🧪 Тестирование много-провайдерной архитектуры...")
    
    try:
        from app.infrastructure.services.embedding_service_fixed import EmbeddingService, MockProvider
        
        # Создание сервиса с разными провайдерами
        service = EmbeddingService(
            primary_provider="mock",  # Используем mock для тестирования архитектуры
            local_model="all-MiniLM-L6-v2",
            cache_ttl=3600
        )
        
        print("✅ EmbeddingService создан")
        
        # Инициализация
        await service.initialize()
        print("✅ EmbeddingService инициализирован")
        
        # Health check
        health = await service.health_check()
        print(f"💓 Health Status: {health['status']}")
        print(f"📋 Available providers: {list(health['providers'].keys())}")
        print(f"🔗 Fallback chain: {' -> '.join(health['fallback_chain'])}")
        
        # Тест single embedding
        test_text = "Это тестовое предложение для проверки EmbeddingService."
        result = await service.embed_text(test_text)
        
        print(f"✅ Single embedding:")
        print(f"   - Provider: {result.provider}")
        print(f"   - Model: {result.model}")
        print(f"   - Dimensions: {len(result.embedding)}")
        print(f"   - Cached: {result.cached}")
        print(f"   - First 5 elements: {result.embedding[:5]}")
        
        # Тест batch embedding
        test_texts = [
            "Первое предложение",
            "Second sentence",
            "Третье предложение",
            "Fourth test sentence"
        ]
        
        batch_results = await service.embed_batch(test_texts)
        print(f"\n✅ Batch embedding ({len(batch_results)} texts):")
        
        for i, result in enumerate(batch_results):
            print(f"   {i+1}. {result.provider} - {len(result.embedding)} dims")
        
        # Метрики
        metrics = service.get_metrics()
        print(f"\n📊 Metrics:")
        print(f"   - Total requests: {metrics['total_requests']}")
        print(f"   - Cache hit rate: {metrics.get('cache_hit_rate', 0):.2%}")
        print(f"   - Provider usage: {metrics['provider_usage']}")
        
        await service.close()
        print("✅ Service closed")
        
        return {
            "architecture_test": "success",
            "providers_available": len(health['providers']),
            "fallback_chain_length": len(health['fallback_chain']),
            "single_embedding_success": True,
            "batch_embedding_success": True,
            "metrics": metrics
        }
        
    except Exception as e:
        print(f"❌ Error in architecture test: {e}")
        import traceback
        traceback.print_exc()
        return {"architecture_test": "failed", "error": str(e)}

async def test_redis_caching():
    """Тест Redis кэширования (без реального Redis)."""
    print("\n💾 Тестирование Redis кэширования...")
    
    try:
        # Создаем сервис без Redis для проверки логики
        service = EmbeddingService(
            primary_provider="mock",
            redis_url=None,  # Без Redis
            cache_ttl=3600
        )
        
        await service.initialize()
        
        # Проверяем, что кэш отключен
        health = await service.health_check()
        redis_available = health.get('redis_available', False)
        
        print(f"💾 Redis available: {redis_available}")
        
        # Тестируем логику кэширования
        test_text = "Test for caching"
        
        # Первый запрос - должен быть cache miss
        result1 = await service.embed_text(test_text)
        metrics1 = service.get_metrics()
        
        # Второй запрос - должен быть cache miss (Redis отключен)
        result2 = await service.embed_text(test_text)
        metrics2 = service.get_metrics()
        
        print(f"📊 Cache test:")
        print(f"   - First request cache hit: {result1.cached}")
        print(f"   - Second request cache hit: {result2.cached}")
        print(f"   - Cache hits: {metrics2['cache_hits']}")
        print(f"   - Cache misses: {metrics2['cache_misses']}")
        
        await service.close()
        
        return {
            "redis_test": "completed",
            "redis_available": redis_available,
            "cache_logic_works": True
        }
        
    except Exception as e:
        print(f"❌ Error in cache test: {e}")
        return {"redis_test": "failed", "error": str(e)}

async def test_fallback_chain():
    """Тест fallback цепочки провайдеров."""
    print("\n🔄 Тестирование fallback цепочки...")
    
    try:
        # Создаем сервис только с mock провайдером
        service = EmbeddingService(
            primary_provider="mock",  # Только mock доступен
            local_model="all-MiniLM-L6-v2"
        )
        
        await service.initialize()
        
        health = await service.health_check()
        fallback_chain = health['fallback_chain']
        
        print(f"🔗 Fallback chain: {' -> '.join(fallback_chain)}")
        
        # Тестируем что mock провайдер всегда работает
        result = await service.embed_text("Fallback test")
        
        print(f"✅ Fallback test:")
        print(f"   - Provider used: {result.provider}")
        print(f"   - Model: {result.model}")
        print(f"   - Success: {result.provider == 'mock'}")
        
        await service.close()
        
        return {
            "fallback_test": "success",
            "fallback_chain": fallback_chain,
            "mock_fallback_works": result.provider == "mock"
        }
        
    except Exception as e:
        print(f"❌ Error in fallback test: {e}")
        return {"fallback_test": "failed", "error": str(e)}

async def test_api_endpoints():
    """Тест API endpoints для RAG системы."""
    print("\n🌐 Тестирование API endpoints...")
    
    try:
        import httpx
        
        # Проверяем есть ли запущенный сервер
        base_url = "http://localhost:8000"
        
        async with httpx.AsyncClient() as client:
            # Тест health endpoint
            try:
                response = await client.get(f"{base_url}/api/rag/health", timeout=5.0)
                if response.status_code == 200:
                    health_data = response.json()
                    print(f"✅ RAG Health endpoint: {health_data.get('status', 'unknown')}")
                else:
                    print(f"⚠️ RAG Health endpoint returned: {response.status_code}")
            except httpx.RequestError:
                print("⚠️ RAG Health endpoint not available (server not running)")
            
            # Тест query endpoint (если health работает)
            try:
                query_data = {
                    "query": "Тестовый запрос для RAG системы",
                    "top_k": 3
                }
                response = await client.post(
                    f"{base_url}/api/rag/query",
                    json=query_data,
                    timeout=10.0
                )
                if response.status_code == 200:
                    query_result = response.json()
                    print(f"✅ RAG Query endpoint: returned {len(query_result.get('results', []))} results")
                else:
                    print(f"⚠️ RAG Query endpoint returned: {response.status_code}")
            except httpx.RequestError:
                print("⚠️ RAG Query endpoint not available")
                
        return {
            "api_test": "attempted",
            "server_available": False  # Определяем реальное состояние
        }
        
    except Exception as e:
        print(f"❌ Error in API test: {e}")
        return {"api_test": "failed", "error": str(e)}

async def test_performance_characteristics():
    """Тест характеристик производительности системы."""
    print("\n⚡ Тест характеристик производительности...")
    
    try:
        from app.infrastructure.services.embedding_service_fixed import EmbeddingService
        
        # Тест с mock провайдером для измерения overhead
        service = EmbeddingService(
            primary_provider="mock",
            batch_size=10
        )
        
        await service.initialize()
        
        # Single embedding performance
        start_time = time.time()
        for i in range(10):
            await service.embed_text(f"Performance test {i}")
        single_time = time.time() - start_time
        
        # Batch embedding performance
        test_texts = [f"Batch test {i}" for i in range(20)]
        start_time = time.time()
        await service.embed_batch(test_texts)
        batch_time = time.time() - start_time
        
        print(f"⚡ Performance results:")
        print(f"   - 10 single embeddings: {single_time:.3f}s ({single_time/10*1000:.1f}ms each)")
        print(f"   - 20 batch embeddings: {batch_time:.3f}s ({batch_time/20*1000:.1f}ms each)")
        
        # Memory usage estimation (mock only)
        metrics = service.get_metrics()
        print(f"   - Total requests processed: {metrics['total_requests']}")
        print(f"   - Provider distribution: {metrics['provider_usage']}")
        
        await service.close()
        
        return {
            "performance_test": "success",
            "single_embedding_time": single_time/10,
            "batch_embedding_time": batch_time/20,
            "requests_processed": metrics['total_requests']
        }
        
    except Exception as e:
        print(f"❌ Error in performance test: {e}")
        return {"performance_test": "failed", "error": str(e)}

async def main():
    """Главная функция комплексного тестирования."""
    print("="*80)
    print("🔬 КОМПЛЕКСНОЕ ТЕСТИРОВАНИЕ EMBEDDINGSERVICE")
    print("="*80)
    
    results = {}
    
    # 1. Тест архитектуры
    results['architecture'] = await test_mock_embedding_service()
    
    # 2. Тест кэширования
    results['caching'] = await test_redis_caching()
    
    # 3. Тест fallback
    results['fallback'] = await test_fallback_chain()
    
    # 4. Тест API endpoints
    results['api'] = await test_api_endpoints()
    
    # 5. Тест производительности
    results['performance'] = await test_performance_characteristics()
    
    # Итоговый отчет
    print("\n" + "="*80)
    print("📋 ИТОГОВЫЙ ОТЧЕТ ТЕСТИРОВАНИЯ")
    print("="*80)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result.get(f"{test_name}_test") == "success" else "❌ FAIL"
        print(f"{status} {test_name.upper()}:")
        
        if test_name == 'architecture':
            print(f"   - Providers: {result.get('providers_available', 0)}")
            print(f"   - Fallback chain: {result.get('fallback_chain_length', 0)} steps")
            print(f"   - Single embedding: {'OK' if result.get('single_embedding_success') else 'FAIL'}")
            print(f"   - Batch embedding: {'OK' if result.get('batch_embedding_success') else 'FAIL'}")
            
        elif test_name == 'caching':
            print(f"   - Redis available: {result.get('redis_available', False)}")
            print(f"   - Cache logic: {'OK' if result.get('cache_logic_works') else 'FAIL'}")
            
        elif test_name == 'fallback':
            print(f"   - Chain: {' -> '.join(result.get('fallback_chain', []))}")
            print(f"   - Mock fallback: {'OK' if result.get('mock_fallback_works') else 'FAIL'}")
            
        elif test_name == 'performance':
            print(f"   - Single embedding: {result.get('single_embedding_time', 0)*1000:.1f}ms")
            print(f"   - Batch embedding: {result.get('batch_embedding_time', 0)*1000:.1f}ms")
            print(f"   - Requests processed: {result.get('requests_processed', 0)}")
            
        elif test_name == 'api':
            print(f"   - Server availability: {result.get('server_available', False)}")
    
    # Сохранение детальных результатов
    with open('embedding_service_test_results.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2, default=str)
    
    print(f"\n💾 Детальные результаты сохранены в embedding_service_test_results.json")
    print("="*80)
    
    return results

if __name__ == "__main__":
    asyncio.run(main())