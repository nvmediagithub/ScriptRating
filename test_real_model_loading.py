#!/usr/bin/env python3
"""
Простой тест для проверки реальной загрузки локальной модели all-MiniLM-L6-v2.
"""
import asyncio
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_local_model_loading():
    """Тест загрузки локальной модели sentence-transformers."""
    print("🚀 Начинаю тест реальной загрузки локальной модели...\n")
    
    start_time = time.time()
    
    try:
        # Импорт sentence-transformers
        print("📦 Проверка импорта sentence-transformers...")
        from sentence_transformers import SentenceTransformer
        print("✅ sentence-transformers импортирован успешно")
        
        # Загрузка модели
        model_name = "all-MiniLM-L6-v2"
        print(f"\n🤖 Загрузка модели: {model_name}")
        
        load_start = time.time()
        model = SentenceTransformer(model_name, "cpu")
        load_end = time.time()
        
        print(f"✅ Модель загружена успешно!")
        print(f"⏱️ Время загрузки: {load_end - load_start:.2f} секунд")
        
        # Проверка информации о модели
        print(f"\n📊 Информация о модели:")
        print(f"   - Название: {model_name}")
        
        if hasattr(model, 'get_sentence_embedding_dimension'):
            dimensions = model.get_sentence_embedding_dimension()
            print(f"   - Размерность: {dimensions}")
        else:
            print(f"   - Размерность: 384 (по умолчанию)")
        
        # Тест генерации embeddings
        print(f"\n🔤 Тест генерации embeddings...")
        
        test_texts = [
            "Привет, мир! Это тестовое предложение.",
            "Hello, world! This is a test sentence.",
            "Тестирование локальной модели sentence-transformers."
        ]
        
        embed_start = time.time()
        embeddings = model.encode(test_texts)
        embed_end = time.time()
        
        print(f"✅ Embeddings сгенерированы успешно!")
        print(f"⏱️ Время генерации: {embed_end - embed_start:.2f} секунд")
        print(f"📊 Формат результата: {embeddings.shape}")
        print(f"📊 Количество текстов: {len(test_texts)}")
        print(f"📊 Размерность каждого embedding: {embeddings.shape[1]}")
        
        # Пример embedding
        print(f"\n🔍 Первые 5 элементов первого embedding:")
        print(f"   {embeddings[0][:5]}")
        
        end_time = time.time()
        total_time = end_time - start_time
        
        print(f"\n🎉 Тест завершен успешно!")
        print(f"⏱️ Общее время: {total_time:.2f} секунд")
        
        # Сохранение результатов
        results = {
            "model_loaded": True,
            "model_name": model_name,
            "load_time": load_end - load_start,
            "embedding_time": embed_end - embed_start,
            "total_time": total_time,
            "dimensions": embeddings.shape[1],
            "texts_processed": len(test_texts),
            "sample_embedding": embeddings[0][:5].tolist()
        }
        
        return results
        
    except ImportError as e:
        print(f"❌ Ошибка импорта: {e}")
        print("💡 Установите sentence-transformers: pip install sentence-transformers")
        return {"model_loaded": False, "error": str(e)}
    
    except Exception as e:
        print(f"❌ Критическая ошибка: {e}")
        import traceback
        traceback.print_exc()
        return {"model_loaded": False, "error": str(e)}

async def test_embedding_service_integration():
    """Тест интеграции с EmbeddingService."""
    print("\n" + "="*60)
    print("🔬 ТЕСТ ИНТЕГРАЦИИ С EMBEDDINGSERVICE")
    print("="*60)
    
    try:
        # Попытка импорта EmbeddingService
        from app.infrastructure.services.embedding_service_fixed import EmbeddingService, LocalProvider
        
        print("✅ EmbeddingService импортирован успешно")
        
        # Создание LocalProvider
        local_provider = LocalProvider("all-MiniLM-L6-v2")
        print("✅ LocalProvider создан")
        
        # Тест health check
        print("\n💓 Тест health check...")
        model_info = local_provider.get_model_info()
        print(f"📊 Информация о модели: {model_info}")
        
        # Тест генерации embeddings
        print("\n🔤 Тест генерации embeddings через EmbeddingService...")
        test_text = "Тестовое предложение для проверки EmbeddingService."
        
        result = await local_provider.embed([test_text])
        print(f"✅ Embedding сгенерирован!")
        print(f"📊 Размерность: {len(result[0])}")
        print(f"🔍 Первые 5 элементов: {result[0][:5]}")
        
        return True
        
    except Exception as e:
        print(f"❌ Ошибка интеграции: {e}")
        import traceback
        traceback.print_exc()
        return False

async def main():
    """Главная функция тестирования."""
    print("="*80)
    print("🧪 ТЕСТИРОВАНИЕ РЕАЛЬНОЙ ЗАГРУЗКИ ЛОКАЛЬНОЙ МОДЕЛИ")
    print("="*80)
    
    # Тест загрузки модели
    results = await test_local_model_loading()
    
    # Тест интеграции
    integration_success = await test_embedding_service_integration()
    
    print("\n" + "="*80)
    print("📋 ИТОГОВЫЙ ОТЧЕТ")
    print("="*80)
    
    if results.get("model_loaded"):
        print("✅ РЕАЛЬНАЯ ЗАГРУЗКА МОДЕЛИ: УСПЕШНО")
        print(f"   - Время загрузки: {results['load_time']:.2f}s")
        print(f"   - Время генерации: {results['embedding_time']:.2f}s")
        print(f"   - Размерность: {results['dimensions']}")
    else:
        print("❌ РЕАЛЬНАЯ ЗАГРУЗКА МОДЕЛИ: НЕУДАЧА")
        print(f"   - Ошибка: {results.get('error')}")
    
    if integration_success:
        print("✅ ИНТЕГРАЦИЯ С EMBEDDINGSERVICE: УСПЕШНО")
    else:
        print("❌ ИНТЕГРАЦИЯ С EMBEDDINGSERVICE: НЕУДАЧА")
    
    print("="*80)

if __name__ == "__main__":
    asyncio.run(main())