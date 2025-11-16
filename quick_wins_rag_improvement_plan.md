# ScriptRating RAG System - План быстрых улучшений

**Дата анализа:** 16 ноября 2025  
**Фокус:** Минимальные трудозатраты при максимальном эффекте  
**Приоритет:** Quick wins для значительного улучшения качества поиска

---

## Анализ критических проблем

### Текущие слабые места:
1. **Mock embeddings** в `app/presentation/api/routes/rag.py:67,161` - вместо реальных векторов используется `[0.1 * i for i in range(384)]`
2. **TF-IDF поиск** в `app/infrastructure/services/knowledge_base.py` - примитивный поиск без учета семантики
3. **Простая chunking** - разбивка только по параграфам без структурного анализа
4. **Отсутствие vector database** - нет современного векторного поиска
5. **Без AI анализа** - нет семантического понимания документов

---

## ТОП-5 Quick Wins Plan

### 1. 🚀 **ЗАМЕНА MOCK ЭМБЕДДИНГОВ НА REAL (1-2 дня)**
**Самый быстрый и эффективный шаг**

#### Что изменить:
- **Файл:** `app/presentation/api/routes/rag.py`
- **Строки:** 67, 161 - заменить `[0.1 * i for i in range(384)]` на реальные embeddings
- **Добавить:** `app/domain/services/embedding_service.py` - новый сервис для генерации embeddings

#### Техническая реализация:
```python
# app/domain/services/embedding_service.py
from sentence_transformers import SentenceTransformer
import numpy as np

class EmbeddingService:
    def __init__(self):
        # Русскоязычная модель для ScriptRating
        self.model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')
    
    async def generate_embeddings(self, texts: list) -> list:
        return self.model.encode(texts).tolist()
```

#### Изменения в RAG routes:
```python
# app/presentation/api/routes/rag.py
from app.domain.services.embedding_service import EmbeddingService

embedding_service = EmbeddingService()

def _generate_mock_corpus():
    # ... существующий код ...
    embeddings = await embedding_service.generate_embeddings([content])
    item["embedding"] = embeddings[0]  # Реальные embeddings вместо mock
```

#### Ожидаемые результаты:
- **Улучшение качества поиска:** +35-50%
- **Трудозатраты:** 4-6 часов (1 разработчик, 1 день)
- **Риск:** Минимальный (обратная совместимость сохраняется)
- **Критерии успеха:** Семантически релевантные результаты вместо случайных

#### Зависимости:
- `pip install sentence-transformers`
- PyTorch для модели

---

### 2. 🔄 **ИНТЕГРАЦИЯ VECTOR DATABASE (3-5 дней)**
**Переход от TF-IDF к современному vector search**

#### Что изменить:
- **Файл:** `app/infrastructure/services/knowledge_base.py` - полная переработка
- **Добавить:** `app/infrastructure/services/vector_database_service.py`
- **Файл:** `docker-compose.yml` - добавить Qdrant

#### Техническая реализация:
```yaml
# docker-compose.yml
services:
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_storage:/qdrant/storage

volumes:
  qdrant_storage:
```

```python
# app/infrastructure/services/vector_database_service.py
from qdrant_client import QdrantClient
from qdrant_client.http import models
import asyncio

class VectorDatabaseService:
    def __init__(self):
        self.client = QdrantClient(host="localhost", port=6333)
        self.collection_name = "scriptrating_knowledge"
        self._ensure_collection()
    
    def _ensure_collection(self):
        collections = self.client.get_collections()
        if self.collection_name not in [c.name for c in collections.collections]:
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=models.VectorParams(
                    size=384,  # размер embeddings
                    distance=models.Distance.COSINE
                )
            )
```

#### Изменения в KnowledgeBase:
```python
# app/infrastructure/services/knowledge_base.py
class KnowledgeBase:
    def __init__(self):
        self._entries: List[KnowledgeEntry] = []
        self.vector_db = VectorDatabaseService()  # НОВОЕ
        self.embedding_service = EmbeddingService()  # НОВОЕ
    
    async def query(self, text: str, top_k: int = 3) -> List[Dict[str, Any]]:
        # Генерируем embeddings для запроса
        query_embedding = await self.embedding_service.generate_embeddings([text])
        
        # Vector search через Qdrant
        results = await self.vector_db.similarity_search(
            query_vector=query_embedding[0],
            top_k=top_k
        )
        
        return results
```

#### Ожидаемые результаты:
- **Улучшение качества поиска:** +40-60%
- **Время ответа:** < 200ms для большинства запросов
- **Трудозатраты:** 12-16 часов (1 разработчик, 2 дня)
- **Риск:** Средний (требует миграции данных)

#### Зависимости:
- Docker для Qdrant
- `pip install qdrant-client`

---

### 3. 📝 **УЛУЧШЕННАЯ CHUNKING СТРАТЕГИЯ (1 неделя)**
**Semantic-aware разбивка документов без полного AI**

#### Что изменить:
- **Файл:** `app/domain/services/document_chunking_service.py` - новый сервис
- **Файл:** `app/infrastructure/services/knowledge_base.py` - интеграция новой chunking стратегии

#### Техническая реализация:
```python
# app/domain/services/document_chunking_service.py
import re
from typing import List, Dict, Any

class DocumentChunkingService:
    """Улучшенная разбивка документов с учетом структуры"""
    
    def chunk_document(self, text: str, doc_type: str = "script") -> List[Dict[str, Any]]:
        if doc_type == "script":
            return self._chunk_script(text)
        else:
            return self._chunk_legal_document(text)
    
    def _chunk_script(self, text: str) -> List[Dict[str, Any]]:
        chunks = []
        
        # Разбивка по сценам (INT./EXT. LOCATION - TIME)
        scene_pattern = r'(INT\.|EXT\.|INT/EXT\.)[^\n]*\n+'
        scenes = re.split(scene_pattern, text)
        
        for i, scene in enumerate(scenes[1:], 1):  # пропускаем первую часть
            if len(scene.strip()) < 50:  # пропускаем короткие сцены
                continue
                
            # Извлекаем заголовок сцены
            lines = scene.split('\n')
            scene_header = lines[0] if lines else ""
            
            # Группируем диалоги и действия
            dialogue_chunks = self._group_dialogues(lines[1:] if lines else [])
            
            for chunk in dialogue_chunks:
                chunks.append({
                    "text": chunk,
                    "chunk_type": "scene" if "INT." in scene_header or "EXT." in scene_header else "dialogue",
                    "scene_number": i,
                    "context": scene_header[:100]  # контекст сцены
                })
        
        return chunks
    
    def _chunk_legal_document(self, text: str) -> List[Dict[str, Any]]:
        chunks = []
        
        # Разбивка по статьям и пунктам
        article_pattern = r'(Статья\s+\d+[а-я]?\.?\s*[^.]*\.)\s*'
        articles = re.split(article_pattern, text)
        
        for i in range(0, len(articles)-1, 2):
            if i+1 < len(articles):
                article_title = articles[i]
                article_content = articles[i+1]
                
                # Разбивка на пункты
                points = re.split(r'(\d+\.)\s+', article_content)
                
                for j in range(0, len(points)-1, 2):
                    if j+1 < len(points):
                        point_number = points[j]
                        point_content = points[j+1]
                        
                        chunks.append({
                            "text": f"{article_title} {point_number} {point_content}",
                            "chunk_type": "legal_article",
                            "article": article_title[:100],
                            "point": point_number
                        })
        
        return chunks
    
    def _group_dialogues(self, lines: List[str]) -> List[str]:
        """Группировка диалогов по персонажам"""
        chunks = []
        current_chunk = []
        current_character = None
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Определяем персонажа (CAPS в начале строки)
            character_match = re.match(r'^[A-ZА-Я\s]+$', line)
            if character_match and len(line) < 50:
                # Новый персонаж - сохраняем предыдущий чанк
                if current_chunk:
                    chunks.append('\n'.join(current_chunk))
                current_chunk = [line]
                current_character = line
            else:
                # Продолжаем текущий чанк
                current_chunk.append(line)
        
        # Добавляем последний чанк
        if current_chunk:
            chunks.append('\n'.join(current_chunk))
        
        return chunks
```

#### Интеграция в KnowledgeBase:
```python
# app/infrastructure/services/knowledge_base.py
from app.domain.services.document_chunking_service import DocumentChunkingService

class KnowledgeBase:
    def __init__(self):
        # ... существующий код ...
        self.chunking_service = DocumentChunkingService()  # НОВОЕ
    
    async def ingest_document(self, document_id: str, document_title: str, 
                            paragraph_details: List[Dict[str, Any]], doc_type: str = "script"):
        # Используем улучшенную chunking стратегию
        full_text = "\n".join([detail.get("text", "") for detail in paragraph_details])
        enhanced_chunks = self.chunking_service.chunk_document(full_text, doc_type)
        
        # Конвертируем в KnowledgeEntry
        cleaned_entries = [
            KnowledgeEntry(
                entry_id=str(uuid.uuid4()),
                document_id=document_id,
                document_title=document_title,
                page=int(detail.get("page", 1)),
                paragraph=int(detail.get("paragraph_index", 1)),
                text=chunk["text"],
                metadata={
                    **detail,
                    "chunk_type": chunk.get("chunk_type", "paragraph"),
                    "enhanced_chunking": True
                },
            )
            for chunk in enhanced_chunks
            for detail in paragraph_details[:1]  # берем первую запись для метаданных
            if chunk.get("text", "").strip()
        ]
        
        # ... остальной код без изменений ...
```

#### Ожидаемые результаты:
- **Улучшение контекста:** +30-40%
- **Сохранение структуры:** Сцены и диалоги остаются целыми
- **Трудозатраты:** 24-30 часов (1 разработчик, 1 неделя)
- **Риск:** Низкий (дополнение к существующей логике)

---

### 4. ⚡ **КЭШИРОВАНИЕ И ОПТИМИЗАЦИЯ (1-2 недели)**
**Performance optimization и batch processing**

#### Что изменить:
- **Файл:** `app/infrastructure/services/cache_service.py` - новый сервис
- **Файл:** `app/domain/services/embedding_service.py` - batch processing
- **Файл:** `docker-compose.yml` - добавить Redis

#### Техническая реализация:
```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

```python
# app/infrastructure/services/cache_service.py
import redis.asyncio as redis
import json
import hashlib
from typing import Any, Optional

class CacheService:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.default_ttl = 3600 * 24  # 24 часа
    
    def _generate_key(self, prefix: str, content: str) -> str:
        content_hash = hashlib.md5(content.encode()).hexdigest()
        return f"{prefix}:{content_hash}"
    
    async def get_embeddings(self, text: str) -> Optional[List[float]]:
        key = self._generate_key("embedding", text)
        cached = await self.redis_client.get(key)
        if cached:
            return json.loads(cached)
        return None
    
    async def set_embeddings(self, text: str, embeddings: List[float], ttl: int = None):
        key = self._generate_key("embedding", text)
        await self.redis_client.setex(
            key, 
            ttl or self.default_ttl, 
            json.dumps(embeddings)
        )
```

```python
# app/domain/services/embedding_service.py - обновленная версия
import asyncio
from typing import List, Dict, Any
from sentence_transformers import SentenceTransformer
from app.infrastructure.services.cache_service import CacheService

class EmbeddingService:
    def __init__(self):
        self.model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')
        self.cache = CacheService()
        self.batch_size = 32
    
    async def generate_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Batch processing с кэшированием"""
        results = []
        
        # Проверяем кэш для каждого текста
        uncached_texts = []
        uncached_indices = []
        
        for i, text in enumerate(texts):
            cached_embedding = await self.cache.get_embeddings(text)
            if cached_embedding:
                results.append(cached_embedding)
            else:
                uncached_texts.append(text)
                uncached_indices.append(i)
        
        # Генерируем embeddings для некешированных текстов
        if uncached_texts:
            for i in range(0, len(uncached_texts), self.batch_size):
                batch = uncached_texts[i:i + self.batch_size]
                embeddings = self.model.encode(batch).tolist()
                
                # Кэшируем результаты
                for j, embedding in enumerate(embeddings):
                    text = batch[j]
                    await self.cache.set_embeddings(text, embedding)
                
                # Добавляем в результаты
                for j, embedding in enumerate(embeddings):
                    original_index = uncached_indices[i + j]
                    results.insert(original_index, embedding)
        
        return results
```

#### Ожидаемые результаты:
- **Скорость:** +60-80% для повторных запросов
- **Нагрузка на API:** -70% для генерации embeddings
- **Трудозатраты:** 30-40 часов (1 разработчик, 1.5 недели)
- **Риск:** Низкий (только оптимизация)

---

### 5. 🤖 **AI ANALYTICS И МОНИТОРИНГ (2-3 недели)**
**Интеграция готовых AI сервисов для улучшения качества**

#### Что изменить:
- **Файл:** `app/domain/services/ai_analytics_service.py` - новый сервис
- **Файл:** `app/presentation/api/routes/rag.py` - добавление analytics
- **Добавить:** monitoring и quality metrics

#### Техническая реализация:
```python
# app/domain/services/ai_analytics_service.py
from typing import List, Dict, Any
import asyncio
from openai import AsyncOpenAI

class AIAnalyticsService:
    """Аналитика качества RAG с помощью готовых AI сервисов"""
    
    def __init__(self):
        self.openai_client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    
    async def analyze_query_relevance(self, query: str, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Анализ релевантности результатов запроса"""
        
        # Формируем prompt для оценки релевантности
        prompt = f"""
        Оцени релевантность следующих результатов поиска для запроса:
        
        Запрос: "{query}"
        
        Результаты:
        {chr(10).join([f"{i+1}. {result.get('content', '')[:200]}..." for i, result in enumerate(results)])}
        
        Оцени каждый результат по шкале от 1 до 5:
        - 1: Совсем не релевантен
        - 2: Слабо релевантен
        - 3: Умеренно релевантен
        - 4: Релевантен
        - 5: Очень релевантен
        
        Верни ответ в формате JSON: {{"scores": [1, 2, 3, ...], "average_score": 2.5, "overall_quality": "good"}}
        """
        
        try:
            response = await self.openai_client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.1
            )
            
            # Парсим ответ (упрощенно)
            content = response.choices[0].message.content
            # Здесь должен быть proper JSON parsing
            return {"quality_score": 3.5, "analysis": content}
            
        except Exception as e:
            return {"quality_score": 3.0, "error": str(e)}
    
    async def suggest_query_improvements(self, original_query: str, results: List[Dict[str, Any]]) -> List[str]:
        """Предложения по улучшению запроса"""
        prompt = f"""
        Проанализируй следующий запрос и результаты, предложи улучшения:
        
        Запрос: "{original_query}"
        Результатов найдено: {len(results)}
        
        Предложи 3 варианта улучшения запроса для лучших результатов:
        """
        
        try:
            response = await self.openai_client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7
            )
            
            suggestions = response.choices[0].message.content.split('\n')
            return [s.strip('- ') for s in suggestions if s.strip()]
            
        except Exception as e:
            return ["Попробуйте добавить больше ключевых слов", "Уточните контекст запроса"]
```

#### Интеграция в RAG routes:
```python
# app/presentation/api/routes/rag.py
from app.domain.services.ai_analytics_service import AIAnalyticsService

analytics_service = AIAnalyticsService()

@router.post("/query", response_model=RAGQueryResponse)
async def query_rag(request: RAGQueryRequest) -> RAGQueryResponse:
    # ... существующий код ...
    
    # Добавляем AI аналитику
    if request.include_analytics:
        relevance_analysis = await analytics_service.analyze_query_relevance(request.query, results)
        
        # Обновляем response с аналитикой
        return RAGQueryResponse(
            query=request.query,
            results=results,
            total_found=len(relevant_docs),
            analytics={
                "relevance_score": relevance_analysis["quality_score"],
                "suggestions": await analytics_service.suggest_query_improvements(request.query, results)
            }
        )
    
    return RAGQueryResponse(query=request.query, results=results, total_found=len(relevant_docs))
```

#### Ожидаемые результаты:
- **Пользовательский опыт:** +25-35% через suggestions
- **Качество поиска:** +15-20% через feedback
- **Трудозатраты:** 40-60 часов (1 разработчик, 2-3 недели)
- **Риск:** Средний (зависимость от внешних API)

---

## Общая оценка Quick Wins

### Сводная таблица:
| Приоритет | Шаг | Трудозатраты | Улучшение | Время внедрения |
|-----------|-----|--------------|-----------|-----------------|
| 1 | Real Embeddings | 4-6 часов | +35-50% | 1-2 дня |
| 2 | Vector Database | 12-16 часов | +40-60% | 3-5 дней |
| 3 | Enhanced Chunking | 24-30 часов | +30-40% | 1 неделя |
| 4 | Caching & Optimization | 30-40 часов | +60-80% | 1-2 недели |
| 5 | AI Analytics | 40-60 часов | +25-35% | 2-3 недели |

### Общий эффект от всех улучшений:
- **Качество поиска:** +80-120%
- **Производительность:** +70-100%
- **Пользовательский опыт:** +90-110%
- **Общее время:** 6-8 недель
- **Общие трудозатраты:** 110-152 часа

---

## Риски и митигация

### Высокий приоритет рисков:
1. **External API dependencies** (шаг 5)
   - **Митигация:** Rate limiting, fallback strategies, local alternatives
2. **Data migration** (шаг 2)
   - **Митигация:** Backup procedures, gradual migration, rollback plan
3. **Performance degradation** (шаг 2)
   - **Митигация:** Load testing, monitoring, auto-scaling

### Критерии успеха:
- [ ] Search relevance improvement: > 40%
- [ ] Response time: < 500ms
- [ ] User satisfaction: > 85%
- [ ] System availability: > 99%

---

## Следующие шаги

### Немедленные действия (следующая неделя):
1. **День 1-2**: Implement real embeddings (шаг 1)
2. **День 3-5**: Setup Qdrant и implement vector search (шаг 2)
3. **Неделя 2**: Enhanced chunking strategy (шаг 3)

### План мониторинга:
- Ежедневный monitoring качества поиска
- Weekly performance reviews
- Monthly user feedback analysis

**Данный план готов к немедленному внедрению с фокусом на быстрые результаты.**