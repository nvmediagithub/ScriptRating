#!/usr/bin/env python3
"""
Тестовый скрипт для проверки обновленного EmbeddingService.
"""
import asyncio
import logging
import os
import sys

# Добавляем путь к проекту
sys.path.append('/Users/user/Documents/Repositories/ScriptRating')

from app.infrastructure.services.embedding_service import EmbeddingService
from config.settings import Settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def test_embedding_service():
    """Тестирование обновленного EmbeddingService."""
    print("🧪 Начинаю тестирование обновленного EmbeddingService...\n")
    
    # Настройки из config
    settings = Settings()
    config = settings.get_embedding_config()
    
    print("📋 Конфигурация EmbeddingService:")
    for key, value in config.items():
        print(f"   {key}: {value}")
    print()
    
    # Создаем сервис с минимальными настройками для тестирования
    embedding_service = EmbeddingService(
        # Не указываем API ключи для тестирования fallback'ов
        primary_provider="local",  # Используем локальную модель по умолчанию
        local_model="all-MiniLM-L6-v2",
        cache_ttl=3600,  # 1 час для тестирования
        batch_size=10,
    )
    
    try:
        # Инициализация сервиса
        print("🚀 Инициализация EmbeddingService...")
        await embedding_service.initialize()
        
        # Тест здоровья сервиса
        print("\n💓 Проверка здоровья сервиса...")
        health = await embedding_service.health_check()
        print(f"Статус: {health['status']}")
        print(f"Доступные провайдеры: {list(health['providers'].keys())}")
        print(f"Fallback chain: {' -> '.join(health['fallback_chain'])}")
        
        # Тест локального provider'а
        if 'local' in health['providers']:
            local_status = health['providers']['local']
            print(f"✅ Локальный провайдер: {local_status['status']}")
            if local_status['status'] == 'healthy':
                info = local_status['info']
                print(f"   - Модель: {info['name']}")
                print(f"   - Размерность: {info['dimensions']}")
        
        # Тест одиночного embedding
        print("\n🔤 Тест одиночного embedding...")
        test_text = "Привет, мир! Это тестовое предложение для проверки embeddings."
        
        try:
            result = await embedding_service.embed_text(test_text)
            print(f"✅ Успешно создан embedding:")
            print(f"   - Провайдер: {result.provider}")
            print(f"   - Модель: {result.model}")
            print(f"   - Размерность: {len(result.embedding)}")
            print(f"   - Из кэша: {result.cached}")
            print(f"   - Первые 5 элементов: {result.embedding[:5]}")
        except Exception as e:
            print(f"❌ Ошибка при создании embedding: {e}")
        
        # Тест batch embedding
        print("\n📦 Тест batch embedding...")
        test_texts = [
            "Первое предложение для тестирования.",
            "Второе предложение с другим содержанием.",
            "Третье предложение на русском языке.",
            "Fourth sentence in English for multilingual testing.",
            "Пятое предложение для проверки batch processing."
        ]
        
        try:
            batch_results = await embedding_service.embed_batch(test_texts)
            print(f"✅ Успешно обработан batch из {len(batch_results)} текстов:")
            
            providers_used = {}
            for i, result in enumerate(batch_results):
                providers_used[result.provider] = providers_used.get(result.provider, 0) + 1
                print(f"   {i+1}. {result.provider} (cached: {result.cached}) - dims: {len(result.embedding)}")
            
            print(f"📊 Использование провайдеров: {providers_used}")
            
        except Exception as e:
            print(f"❌ Ошибка при batch processing: {e}")
        
        # Получение метрик
        print("\n📈 Метрики сервиса...")
        metrics = embedding_service.get_metrics()
        print(f"Всего запросов: {metrics['total_requests']}")
        print(f"Попадания в кэш: {metrics['cache_hits']}")
        print(f"Промахи кэша: {metrics['cache_misses']}")
        print(f"Коэффициент попаданий в кэш: {metrics.get('cache_hit_rate', 0):.2%}")
        print(f"Использование провайдеров:")
        for provider, count in metrics['provider_usage'].items():
            if count > 0:
                print(f"   - {provider}: {count}")
        
        print("\n🎉 Тестирование завершено успешно!")
        
    except Exception as e:
        print(f"❌ Критическая ошибка при тестировании: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Закрытие сервиса
        print("\n🔒 Закрытие EmbeddingService...")
        await embedding_service.close()
        print("✅ Сервис закрыт")


async def test_fallback_chain():
    """Тестирование цепочки fallback'ов."""
    print("\n\n🔄 Тестирование fallback chain...")
    
    # Создаем сервис только с mock провайдером
    embedding_service = EmbeddingService(
        primary_provider="mock",  # Будет fallback на mock
        local_model="all-MiniLM-L6-v2"
    )
    
    try:
        await embedding_service.initialize()
        
        # Проверяем fallback chain
        health = await embedding_service.health_check()
        print(f"Fallback chain: {' -> '.join(health['fallback_chain'])}")
        
        # Тестируем с текстом
        test_result = await embedding_service.embed_text("Test text for fallback")
        print(f"✅ Fallback работает: провайдер = {test_result.provider}")
        
    finally:
        await embedding_service.close()


async def main():
    """Главная функция тестирования."""
    print("=" * 80)
    print("🔬 ТЕСТИРОВАНИЕ ОБНОВЛЕННОГО EMBEDDINGSERVICE")
    print("=" * 80)
    
    # Основное тестирование
    await test_embedding_service()
    
    # Тестирование fallback
    await test_fallback_chain()
    
    print("\n" + "=" * 80)
    print("✅ ВСЕ ТЕСТЫ ЗАВЕРШЕНЫ")
    print("=" * 80)


if __name__ == "__main__":
    asyncio.run(main())