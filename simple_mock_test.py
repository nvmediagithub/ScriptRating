#!/usr/bin/env python3
"""
Упрощенный тест EmbeddingService только с Mock провайдером.
"""
import asyncio
import time
import json

async def test_mock_only():
    """Тест только с Mock провайдером для проверки архитектуры."""
    print("🧪 Тест архитектуры с Mock провайдером...")
    
    try:
        from app.infrastructure.services.embedding_service_fixed import EmbeddingService, MockProvider
        
        # Создаем сервис ТОЛЬКО с Mock провайдером
        service = EmbeddingService(
            primary_provider="mock",
            openai_api_key=None,  # Отключаем все остальное
            openrouter_api_key=None,
            redis_url=None,
            local_model="all-MiniLM-L6-v2"
        )
        
        await service.initialize()
        
        # Health check
        health = await service.health_check()
        print(f"✅ Status: {health['status']}")
        print(f"✅ Providers: {list(health['providers'].keys())}")
        print(f"✅ Fallback chain: {' -> '.join(health['fallback_chain'])}")
        
        # Тест embeddings
        test_text = "Тестовое предложение"
        result = await service.embed_text(test_text)
        
        print(f"✅ Embedding generated:")
        print(f"   Provider: {result.provider}")
        print(f"   Model: {result.model}")
        print(f"   Dimensions: {len(result.embedding)}")
        print(f"   First 5: {result.embedding[:5]}")
        
        # Batch test
        texts = ["Text 1", "Text 2", "Text 3"]
        batch_results = await service.embed_batch(texts)
        print(f"✅ Batch ({len(batch_results)} items):")
        
        for i, r in enumerate(batch_results):
            print(f"   {i+1}. {r.provider} - {len(r.embedding)} dims")
        
        # Metrics
        metrics = service.get_metrics()
        print(f"✅ Metrics:")
        print(f"   Requests: {metrics['total_requests']}")
        print(f"   Cache hit rate: {metrics.get('cache_hit_rate', 0):.2%}")
        
        await service.close()
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

async def main():
    print("="*60)
    print("🚀 УПРОЩЕННЫЙ ТЕСТ EMBEDDINGSERVICE (MOCK ONLY)")
    print("="*60)
    
    success = await test_mock_only()
    
    print("\n" + "="*60)
    if success:
        print("✅ АРХИТЕКТУРА РАБОТАЕТ КОРРЕКТНО")
        print("❌ ЛОКАЛЬНАЯ МОДЕЛЬ НЕ РАБОТАЕТ (ЗАВИСАЕТ)")
    else:
        print("❌ АРХИТЕКТУРА НЕ РАБОТАЕТ")
    print("="*60)
    
    return success

if __name__ == "__main__":
    asyncio.run(main())