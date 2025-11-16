# Детальный план реализации улучшения RAG системы

## 📊 Анализ текущей архитектуры

### Обнаруженные проблемы:

1. **Mock embeddings в `rag.py` (строки 67, 161)**:
   ```python
   "embedding": [0.1 * i for i in range(384)],  # Mock embedding vector
   ```
   - Не несут семантической информации
   - Создают псевдо-релевантность

2. **TF-IDF в `knowledge_base.py`**:
   - Базовый keyword-based поиск
   - Не понимает семантику русского языка
   - Плохо работает с синонимами и контекстом

3. **Отсутствие векторной базы данных**:
   - Нет специализированного векторного поиска
   - Медленный поиск по большому корпусу

## 🎯 Выбор оптимального решения

### Embedding модели (приоритет):
1. **OpenAI text-embedding-3-large** ⭐ **ВЫБРАНО**
   - Лучшее качество для русского языка
   - 3072 измерения, высокое качество
   - Стабильное API
   - Хорошая документация

### Vector Database (приоритет):
1. **Qdrant** ⭐ **ВЫБРАНО**
   - Отличная производительность
   - Простая интеграция с Python
   - Встроенная поддержка фильтрации
   - Docker контейнер
   - HTTP API для простоты

### Резервный стек:
- Embedding: `sentence-transformers/all-MiniLM-L6-v2`
- Vector DB: Chroma (python-native, простая интеграция)

## 🏗️ План реализации

### Фаза 1: Базовая инфраструктура (Неделя 1)

#### 1.1 Создание новых сервисов

**`app/infrastructure/services/embedding_service.py`**:
```python
from openai import OpenAI
from typing import List
import numpy as np

class EmbeddingService:
    def __init__(self):
        self.client = OpenAI()
        self.model = "text-embedding-3-large"
        self.dimension = 3072
    
    async def embed_text(self, text: str) -> List[float]:
        """Создать embedding для текста"""
        response = self.client.embeddings.create(
            model=self.model,
            input=text,
            encoding_format="float"
        )
        return response.data[0].embedding
    
    async def embed_documents(self, texts: List[str]) -> List[List[float]]:
        """Batch embedding для нескольких текстов"""
        # TODO: Реализовать batch processing
        pass
```

**`app/infrastructure/services/vector_database_service.py`**:
```python
from qdrant_client import QdrantClient
from qdrant_client.http import models
from typing import List, Dict, Any

class VectorDatabaseService:
    def __init__(self, collection_name="rag_corpus"):
        self.client = QdrantClient(":memory:")  # Для разработки
        self.collection_name = collection_name
        self._ensure_collection()
    
    def _ensure_collection(self):
        """Создать коллекцию если не существует"""
        # TODO: Создать коллекцию с оптимальными настройками
        pass
    
    async def upsert_documents(self, documents: List[Dict[str, Any]]):
        """Добавить/обновить документы в коллекции"""
        # TODO: Реализовать upsert с embeddings
        pass
    
    async def search(self, query_embedding: List[float], limit: int = 5):
        """Поиск по векторному сходству"""
        # TODO: Реализовать векторный поиск
        pass
```

#### 1.2 Обновление RAG оркестратора

**`app/infrastructure/services/rag_orchestrator.py`**:
```python
from app.infrastructure.services.embedding_service import EmbeddingService
from app.infrastructure.services.vector_database_service import VectorDatabaseService

class RAGOrchestrator:
    def __init__(self):
        self.embedding_service = EmbeddingService()
        self.vector_db = VectorDatabaseService()
        # Сохранить существующий TF-IDF как fallback
        self.tfidf_fallback = KnowledgeBase()
    
    async def add_to_corpus(self, content: str, metadata: Dict[str, Any]):
        """Добавить документ в векторную БД"""
        embedding = await self.embedding_service.embed_text(content)
        await self.vector_db.upsert_documents([{
            "content": content,
            "embedding": embedding,
            "metadata": metadata
        }])
    
    async def search(self, query: str, limit: int = 5):
        """Векторный поиск с fallback"""
        try:
            query_embedding = await self.embedding_service.embed_text(query)
            return await self.vector_db.search(query_embedding, limit)
        except Exception as e:
            # Fallback к TF-IDF при ошибках
            return await self.tfidf_fallback.query(query, limit)
```

#### 1.3 Конфигурация

**`.env`**:
```env
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Qdrant Configuration  
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_COLLECTION_NAME=script_rating_rag

# Embedding Configuration
EMBEDDING_MODEL=text-embedding-3-large
EMBEDDING_BATCH_SIZE=100
EMBEDDING_MAX_TOKENS=8191
```

### Фаза 2: Интеграция с существующим API (Неделя 1-2)

#### 2.1 Обновление RAG routes

**Модификация `app/presentation/api/routes/rag.py`**:

```python
# Замена mock embeddings на реальные
@router.post("/corpus/update")
async def update_corpus(request: CorpusUpdateRequest) -> CorpusUpdateResponse:
    # Создать embedding для контента
    rag_orchestrator = RAGOrchestrator()
    await rag_orchestrator.add_to_corpus(
        content=request.content,
        metadata={
            "category": request.category.value,
            "source_title": request.source_title,
            "source_metadata": request.source_metadata
        }
    )
    
    # Генерировать content hash
    content_hash = str(hash(request.content))[:16]
    doc_id = str(uuid.uuid4())
    
    return CorpusUpdateResponse(
        update_id=doc_id,
        content_hash=content_hash,
        updated_at=datetime.utcnow()
    )

@router.post("/query")
async def query_rag(request: RAGQueryRequest) -> RAGQueryResponse:
    # Использовать векторный поиск
    rag_orchestrator = RAGOrchestrator()
    results = await rag_orchestrator.search(request.query, request.top_k)
    
    # Форматировать результаты
    formatted_results = []
    for result in results:
        formatted_results.append(RAGResult(
            content=result["content"],
            relevance_score=result.get("score", 0.0),
            source=CitationSource(**result["metadata"]["source"]),
            category=Category(result["metadata"]["category"])
        ))
    
    return RAGQueryResponse(
        query=request.query,
        results=formatted_results,
        total_found=len(formatted_results)
    )
```

#### 2.2 Docker конфигурация

**`docker-compose.yml` (добавить)**:
```yaml
services:
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage
    environment:
      - QDRANT__SERVICE__HTTP_PORT=6333
      - QDRANT__SERVICE__GRPC_PORT=6334

volumes:
  qdrant_data:
```

### Фаза 3: Оптимизация и мониторинг (Неделя 2)

#### 3.1 Кэширование

**`app/infrastructure/services/cache_service.py`**:
```python
from functools import lru_cache
from typing import Dict, Any
import hashlib
import json

class EmbeddingCache:
    def __init__(self, max_size: int = 10000):
        self.cache: Dict[str, List[float]] = {}
        self.max_size = max_size
    
    def _get_cache_key(self, text: str) -> str:
        """Генерировать ключ кэша для текста"""
        return hashlib.md5(text.encode()).hexdigest()
    
    def get(self, text: str) -> List[float] | None:
        """Получить embedding из кэша"""
        return self.cache.get(self._get_cache_key(text))
    
    def set(self, text: str, embedding: List[float]):
        """Сохранить embedding в кэш"""
        if len(self.cache) >= self.max_size:
            # Удалить самый старый элемент
            oldest_key = next(iter(self.cache))
            del self.cache[oldest_key]
        
        self.cache[self._get_cache_key(text)] = embedding
```

#### 3.2 Мониторинг и метрики

**`app/infrastructure/services/metrics_service.py`**:
```python
from dataclasses import dataclass
from datetime import datetime
from typing import List

@dataclass
class RAGMetrics:
    query_count: int = 0
    avg_response_time: float = 0.0
    cache_hit_rate: float = 0.0
    embedding_generation_time: float = 0.0
    vector_search_time: float = 0.0

class RAGMetricsService:
    def __init__(self):
        self.metrics = RAGMetrics()
    
    def track_query(self, response_time: float):
        """Отследить время ответа запроса"""
        self.metrics.query_count += 1
        # Обновить среднее время ответа
        self.metrics.avg_response_time = (
            (self.metrics.avg_response_time * (self.metrics.query_count - 1) + response_time) /
            self.metrics.query_count
        )
    
    def get_report(self) -> dict:
        """Получить отчет по метрикам"""
        return {
            "total_queries": self.metrics.query_count,
            "avg_response_time_ms": round(self.metrics.avg_response_time * 1000, 2),
            "cache_hit_rate": round(self.metrics.cache_hit_rate * 100, 2),
            "embedding_time_ms": round(self.metrics.embedding_generation_time * 1000, 2),
            "vector_search_time_ms": round(self.metrics.vector_search_time * 1000, 2)
        }
```

### Фаза 4: Тестирование и развертывание (Неделя 2-3)

#### 4.1 Тесты

**`tests/test_rag_improvements.py`**:
```python
import pytest
import asyncio
from app.infrastructure.services.rag_orchestrator import RAGOrchestrator

class TestRAGImprovements:
    @pytest.fixture
    async def rag_orchestrator(self):
        return RAGOrchestrator()
    
    async def test_embedding_quality(self, rag_orchestrator):
        """Тест качества embeddings"""
        # Тест семантической близости
        text1 = "насилие в фильмах"
        text2 = "жестокие сцены"
        text3 = "цветок в саду"
        
        embedding1 = await rag_orchestrator.embedding_service.embed_text(text1)
        embedding2 = await rag_orchestrator.embedding_service.embed_text(text2)
        embedding3 = await rag_orchestrator.embedding_service.embed_text(text3)
        
        # Проверить что text1 ближе к text2 чем к text3
        from sklearn.metrics.pairwise import cosine_similarity
        sim_12 = cosine_similarity([embedding1], [embedding2])[0][0]
        sim_13 = cosine_similarity([embedding1], [embedding3])[0][0]
        
        assert sim_12 > sim_13, "Semantic similarity test failed"
    
    async def test_vector_search_performance(self, rag_orchestrator):
        """Тест производительности векторного поиска"""
        # Добавить тестовые документы
        test_docs = [
            {"content": "насилие в фильмах", "metadata": {"category": "violence"}},
            {"content": "сексуальный контент", "metadata": {"category": "sexual"}},
            {"content": "нецензурная лексика", "metadata": {"category": "language"}}
        ]
        
        for doc in test_docs:
            await rag_orchestrator.add_to_corpus(doc["content"], doc["metadata"])
        
        # Тест поиска
        results = await rag_orchestrator.search("жестокие сцены", limit=1)
        assert len(results) > 0
        assert "насилие" in results[0]["content"]
    
    async def test_fallback_mechanism(self, rag_orchestrator):
        """Тест fallback механизма"""
        # TODO: Тест fallback к TF-IDF при недоступности векторной БД
        pass
```

#### 4.2 Load тестирование

**`tests/load/test_rag_load.py`**:
```python
import asyncio
import time
import statistics
from app.infrastructure.services.rag_orchestrator import RAGOrchestrator

async def test_concurrent_searches():
    """Тест конкурентных запросов к RAG системе"""
    rag_orchestrator = RAGOrchestrator()
    
    queries = [
        "насилие в фильмах",
        "сексуальный контент", 
        "нецензурная лексика",
        "возрастные ограничения",
        "классификация контента"
    ] * 20  # 100 запросов
    
    start_time = time.time()
    
    async def single_query(query):
        start = time.time()
        await rag_orchestrator.search(query, limit=5)
        return time.time() - start
    
    # Запустить все запросы параллельно
    tasks = [single_query(query) for query in queries]
    response_times = await asyncio.gather(*tasks)
    
    total_time = time.time() - start_time
    
    print(f"Время обработки {len(queries)} запросов: {total_time:.2f}s")
    print(f"Среднее время запроса: {statistics.mean(response_times):.3f}s")
    print(f"Медианное время запроса: {statistics.median(response_times):.3f}s")
    print(f"95-й перцентиль: {statistics.quantiles(response_times, n=20)[18]:.3f}s")
```

## 🔧 Технические детали реализации

### Структура новых сервисов:

```
app/infrastructure/services/
├── embedding_service.py          # OpenAI embeddings
├── vector_database_service.py    # Qdrant интеграция
├── rag_orchestrator.py          # Основной оркестратор
├── cache_service.py             # Кэширование embeddings
└── metrics_service.py           # Мониторинг
```

### API изменения:

1. **Обратная совместимость**: Сохранить все существующие endpoints
2. **Новые метрики**: Добавить `/rag/stats` с детальной статистикой
3. **Прогрессивная миграция**: TF-IDF как fallback при проблемах

### Конфигурация:

```python
# config/rag_config.py
class RAGConfig:
    EMBEDDING_MODEL = "text-embedding-3-large"
    EMBEDDING_BATCH_SIZE = 100
    VECTOR_DB_HOST = "localhost"
    VECTOR_DB_PORT = 6333
    CACHE_SIZE = 10000
    MAX_QUERY_LENGTH = 8191
    DEFAULT_TOP_K = 5
    SIMILARITY_THRESHOLD = 0.7
```

## 🚀 Стратегия внедрения

### Этап 1: MVP (1 неделя)
- Базовая интеграция с OpenAI + Qdrant
- Сохранение TF-IDF как fallback
- Простые тесты

### Этап 2: Оптимизация (1 неделя)  
- Кэширование embeddings
- Batch processing
- Мониторинг

### Этап 3: Production (1 неделя)
- Load тестирование
- Мониторинг в продакшн
- Оптимизация производительности

## 📊 Ожидаемые результаты

### Улучшения производительности:
- **Точность поиска**: +40-60% (семантический vs keyword поиск)
- **Время ответа**: +20-30% (при кэшировании)
- **Качество релевантности**: значительное улучшение

### Метрики успеха:
- Средняя релевантность результатов: >0.8
- Время ответа API: <2s для 95% запросов
- Cache hit rate: >70%
- Accuracy improvement vs TF-IDF: >50%

## 🔄 Rollback план

Если что-то пойдет не так:

1. **Отключить новые сервисы** через feature flags
2. **Вернуться к TF-IDF** в knowledge_base.py
3. **Отключить Qdrant** в docker-compose.yml
4. **Вернуть mock embeddings** в rag.py
5. **Откатить конфигурацию** в .env

Все изменения будут обратимыми через конфигурацию без изменения кода.

## 💡 Дополнительные возможности

### Будущие улучшения:
- **Hybrid search**: Комбинация vector + keyword поиска
- **Reranking**: LLM-based reranking результатов  
- **Personalization**: Пользовательские предпочтения
- **Multi-modal**: Поддержка изображений и видео
- **Real-time**: Streaming embeddings для больших документов

### Интеграции:
- **Weaviate**: Альтернативная векторная БД
- **Chroma**: Локальная векторная БД для приватности
- **Local embeddings**: sentence-transformers для экономии API

Этот план обеспечивает постепенное, безопасное улучшение RAG системы с возможностью быстрого rollback при необходимости.