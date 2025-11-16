# Детальный план интеграции семантической обработки в RAG систему ScriptRating

## Краткое резюме

План поэтапной интеграции AI-основанного семантического чанкинга в существующую TF-IDF систему ScriptRating с обеспечением обратной совместимости и минимизацией рисков.

**Срок реализации**: 8-10 недель  
**Команда**: 2 backend разработчика, 1 ML engineer, 1 DevOps  
**Бюджет**: $15,000-25,000 (AI API costs + infrastructure)

## 1. Изменения в архитектуре

### 1.1 Модификация существующих компонентов

#### KnowledgeBase (app/infrastructure/services/knowledge_base.py)
```python
# Текущая реализация остается как fallback
class LegacyKnowledgeBase:
    # Существующая TF-IDF реализация
    
class SemanticKnowledgeBase:
    # Новая векторная реализация
    
class HybridKnowledgeBase:
    # Объединяет обе системы с fallback
    async def query(self, text: str, top_k: int = 3) -> List[Dict[str, Any]]:
        try:
            # Сначала пробуем semantic search
            return await self.semantic_base.query(text, top_k)
        except Exception:
            # Fallback к legacy поиску
            return await self.legacy_base.query(text, top_k)
```

#### RAGDocument (app/domain/entities/rag_document.py)
```python
@dataclass
class EnhancedRAGDocument(RAGDocument):
    # Расширенные метаданные для semantic chunking
    semantic_chunks: List['SemanticChunk'] = None
    embedding_model: str = None
    chunking_strategy: str = "semantic"  # "semantic" | "legacy"
    coherence_score: float = None
    entities: List['Entity'] = None
```

### 1.2 Новые сервисы и репозитории

#### Semantic Services (app/domain/services/)
```
app/domain/services/
├── semantic_analyzer.py          # Основной engine
├── embedding_service.py          # Векторные эмбеддинги
├── entity_extraction_service.py  # Извлечение сущностей
├── document_structure_service.py # Анализ структуры
└── coherence_analyzer.py         # Анализ связности
```

#### Infrastructure Services (app/infrastructure/services/)
```
app/infrastructure/services/
├── vector_database.py           # Qdrant/FAISS интеграция
├── ai_client_manager.py         # Управление AI API
├── semantic_cache.py            # Кэширование embeddings
└── migration_service.py         # Миграция данных
```

#### Repositories (app/infrastructure/repositories/)
```
app/infrastructure/repositories/
├── vector_store_repository.py   # Векторное хранилище
├── semantic_document_repository.py # Семантические документы
└── embedding_repository.py      # Управление embeddings
```

### 1.3 Обновление Data Models

#### Новые сущности (app/domain/entities/)
```python
# semantic_chunk.py
@dataclass
class SemanticChunk:
    id: str
    content: str
    chunk_type: str  # "scene", "dialogue", "action", "article"
    summary: str
    key_points: List[str]
    topics: List[str]
    importance_score: float
    coherence_score: float
    entities: List['Entity']
    related_chunks: List[str]
    document_structure: Dict[str, Any]

# document_structure.py  
@dataclass
class DocumentStructure:
    doc_type: str  # "script", "legal", "guideline"
    sections: List['Section']
    characters: List[str] if doc_type == "script" else []
    legal_articles: List[str] if doc_type == "legal" else []
    hierarchical_level: int
```

### 1.4 Изменения в API

#### Обновленные endpoints (app/presentation/api/routes/rag.py)
```python
# Добавляем новые параметры
@dataclass
class RAGQueryRequest:
    query: str
    top_k: int = 3
    chunking_strategy: str = "auto"  # "auto" | "semantic" | "legacy"
    include_metadata: bool = True
    embedding_model: str = "text-embedding-3-large"
    
# Новые endpoints для semantic features
@router.post("/query/semantic")
async def semantic_query(request: SemanticRAGQueryRequest)

@router.post("/corpus/reprocess")
async def reprocess_document(document_id: str, strategy: str)

@router.get("/embeddings/stats")
async def get_embedding_stats()

@router.post("/documents/analyze-structure")
async def analyze_document_structure(file: UploadFile)
```

## 2. Миграция данных

### 2.1 Переход от TF-IDF к векторным эмбеддингам

#### Стратегия миграции
```python
class DataMigrationManager:
    async def migrate_knowledge_base(self):
        # 1. Создаем backup существующих данных
        await self.backup_legacy_data()
        
        # 2. Извлекаем все документы из legacy KB
        legacy_docs = await self.extract_legacy_documents()
        
        # 3. Перепроцессинг с semantic chunking
        for doc in legacy_docs:
            await self.reprocess_with_semantic(doc)
            
        # 4. Валидация и тестирование
        await self.validate_migration_results()
        
        # 5. Активация новой системы
        await self.activate_semantic_system()
```

#### Временная схема миграции
- **Этап 1** (Неделя 1): Backup и подготовка
- **Этап 2** (Недели 2-3): Перепроцессинг документов
- **Этап 3** (Неделя 4): Валидация и A/B тестирование
- **Этап 4** (Неделя 5): Полная активация

### 2.2 Перепроцессинг существующих документов

#### Batch Processing Pipeline
```python
class DocumentReprocessor:
    async def process_document_batch(self, documents: List[str]):
        # Параллельная обработка пакетами по 50 документов
        for batch in self.create_batches(documents, batch_size=50):
            await asyncio.gather(*[
                self.reprocess_single_document(doc_id) 
                for doc_id in batch
            ])
    
    async def reprocess_single_document(self, doc_id: str):
        # 1. Извлекаем контент из legacy KB
        legacy_content = await self.extract_legacy_content(doc_id)
        
        # 2. Semantic chunking
        semantic_chunks = await self.semantic_analyzer.process(legacy_content)
        
        # 3. Генерируем embeddings
        embeddings = await self.embedding_service.generate(semantic_chunks)
        
        # 4. Сохраняем в vector DB
        await self.vector_store.upsert(doc_id, semantic_chunks, embeddings)
```

### 2.3 Стратегия отката

#### Emergency Rollback Plan
```python
class RollbackManager:
    async def emergency_rollback(self):
        # 1. Немедленное переключение на legacy систему
        await self.switch_to_legacy_mode()
        
        # 2. Восстановление из backup
        await self.restore_from_backup()
        
        # 3. Уведомление команды
        await self.notify_team("Emergency rollback executed")
        
        # 4. Анализ причин сбоя
        await self.analyze_failure_reasons()
```

## 3. Совместимость

### 3.1 Сохранение backward compatibility с API

#### Backward Compatibility Layer
```python
class BackwardCompatibleRAGService:
    def __init__(self):
        self.legacy_service = LegacyRAGService()  # TF-IDF
        self.semantic_service = SemanticRAGService()  # Vector
        self.fallback_enabled = True
    
    async def query(self, request: RAGQueryRequest) -> RAGQueryResponse:
        try:
            # Определяем стратегию поиска
            strategy = self.determine_strategy(request)
            
            if strategy == "semantic":
                return await self.semantic_service.query(request)
            else:
                return await self.legacy_service.query(request)
                
        except Exception as e:
            if self.fallback_enabled:
                # Graceful degradation к legacy
                return await self.legacy_service.query(request)
            else:
                raise
```

#### API Versioning Strategy
```python
# v1 - Legacy TF-IDF (deprecated)
@router.get("/v1/rag/query")
async def legacy_query(request: LegacyRAGRequest)

# v2 - Hybrid system (current)  
@router.get("/v2/rag/query")
async def hybrid_query(request: HybridRAGRequest)

# v3 - Semantic-first (future)
@router.get("/v3/rag/query")
async def semantic_query(request: SemanticRAGRequest)
```

### 3.2 Graceful degradation

#### Fallback Mechanisms
```python
class GracefulDegradationHandler:
    async def handle_semantic_failure(self, request: RAGQueryRequest):
        # 1. Логируем ошибку semantic поиска
        await self.log_semantic_failure(request)
        
        # 2. Переключаемся на legacy поиск
        legacy_request = self.convert_to_legacy_request(request)
        legacy_result = await self.legacy_service.query(legacy_request)
        
        # 3. Добавляем метаданные о fallback
        legacy_result.metadata["fallback_used"] = True
        legacy_result.metadata["fallback_reason"] = "semantic_search_failed"
        
        return legacy_result
```

### 3.3 Health checks и мониторинг совместимости

```python
@router.get("/health/compatibility")
async def compatibility_health_check():
    return {
        "legacy_system": await self.check_legacy_health(),
        "semantic_system": await self.check_semantic_health(),
        "fallback_rate": await self.get_fallback_rate(),
        "api_version": "2.0",
        "compatibility_mode": "hybrid"
    }
```

## 4. Инфраструктура

### 4.1 Vector database интеграция (Qdrant/FAISS)

#### Qdrant Integration (Production)
```python
class QdrantVectorStore:
    def __init__(self, host: str, collection_name: str):
        self.client = qdrant.QdrantClient(host=host)
        self.collection_name = collection_name
        self._ensure_collection()
    
    async def upsert_embeddings(self, doc_id: str, chunks: List[SemanticChunk]):
        # Структура коллекции:
        # - doc_id: document identifier
        # - chunk_id: unique chunk identifier  
        # - vector: embedding vector
        # - payload: metadata (content, summary, entities, etc.)
        pass
```

#### FAISS Integration (Development/Testing)
```python
class FAISSVectorStore:
    def __init__(self, dimension: int = 1536):
        self.index = faiss.IndexFlatIP(dimension)  # Inner product
        self.metadata_store = {}  # doc_id -> metadata
    
    async def similarity_search(self, query_vector: List[float], top_k: int):
        scores, indices = self.index.search(np.array([query_vector]), top_k)
        return self.retrieve_metadata(indices[0], scores[0])
```

### 4.2 Embedding model integration

#### Multi-model Support
```python
class EmbeddingService:
    def __init__(self):
        self.models = {
            "text-embedding-3-large": OpenAIEmbeddingModel(),
            "text-embedding-3-small": OpenAIEmbeddingModel(), 
            "sentence-transformers/all-MiniLM-L6-v2": SentenceTransformersModel(),
            "multilingual-e5-large": HuggingFaceModel()
        }
    
    async def generate_embeddings(self, texts: List[str], model: str = "text-embedding-3-large"):
        model_instance = self.models[model]
        return await model_instance.embed(texts)
```

### 4.3 Performance optimization

#### Caching Strategies
```python
class SemanticCache:
    def __init__(self):
        self.embedding_cache = RedisCache(ttl=86400)  # 24 hours
        self.structure_cache = RedisCache(ttl=3600)   # 1 hour
        self.query_cache = RedisCache(ttl=300)        # 5 minutes
    
    async def get_cached_embeddings(self, content_hash: str):
        return await self.embedding_cache.get(content_hash)
    
    async def cache_embeddings(self, content_hash: str, embeddings: List[List[float]]):
        await self.embedding_cache.set(content_hash, embeddings)
```

#### Batch Processing Optimization
```python
class BatchEmbeddingProcessor:
    async def process_batch(self, texts: List[str], batch_size: int = 100):
        # Обработка батчами для снижения API calls
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            embeddings = await self.embedding_service.generate_embeddings(batch)
            await self.vector_store.upsert_batch(batch, embeddings)
```

### 4.4 Caching strategies

#### Multi-level Caching Architecture
```
Level 1: Application Cache (in-memory)
├── Query results cache (5 min TTL)
├── Embedding cache (24 hour TTL)

Level 2: Redis Cache  
├── Document structure cache (1 hour TTL)
├── Entity extraction cache (12 hour TTL)

Level 3: Database Cache
├── Vector index cache (persistent)
└── Metadata cache (persistent)
```

## 5. Тестирование и мониторинг

### 5.1 A/B testing стратегия

#### Test Configuration
```python
class ABTestManager:
    def __init__(self):
        self.experiments = {
            "chunking_strategy": {
                "control": "legacy_chunking",
                "treatment": "semantic_chunking", 
                "traffic_split": 0.5,
                "duration": "4_weeks"
            },
            "embedding_model": {
                "control": "tfidf",
                "treatment": "text-embedding-3-large",
                "traffic_split": 0.3,
                "duration": "2_weeks"
            }
        }
    
    async def assign_user_to_group(self, user_id: str, experiment: str):
        # Hash-based consistent assignment
        hash_value = hash(f"{user_id}_{experiment}") % 100
        return "treatment" if hash_value < 50 else "control"
```

#### Success Metrics
```python
@dataclass
class TestMetrics:
    # Primary metrics
    search_relevance_score: float  # User satisfaction (1-5)
    response_time_ms: int          # Performance
    error_rate: float              # Reliability
    
    # Secondary metrics  
    embedding_generation_time: float
    cache_hit_rate: float
    fallback_usage_rate: float
    user_engagement_time: float
```

### 5.2 Quality metrics

#### Automatic Quality Assessment
```python
class QualityAssessmentService:
    async def evaluate_search_quality(self, query: str, results: List[SearchResult]):
        # 1. Semantic coherence score
        coherence = await self.calculate_coherence_score(results)
        
        # 2. Diversity score (avoid redundant results)
        diversity = await self.calculate_diversity_score(results)
        
        # 3. Relevance distribution
        relevance = await self.calculate_relevance_distribution(results)
        
        # 4. Entity consistency
        entity_consistency = await self.check_entity_consistency(results)
        
        return {
            "overall_score": (coherence + diversity + relevance) / 3,
            "coherence": coherence,
            "diversity": diversity,
            "relevance": relevance,
            "entity_consistency": entity_consistency
        }
```

#### User Feedback Integration
```python
class UserFeedbackProcessor:
    async def process_feedback(self, feedback: UserFeedback):
        # Обновляем модель на основе пользовательских оценок
        if feedback.rating < 3:  # Negative feedback
            await self.analyze_failed_search(query, results, feedback)
            await self.improve_ranking_algorithm(query, results, feedback)
```

### 5.3 Performance benchmarks

#### Benchmark Suite
```python
class PerformanceBenchmark:
    async def run_comprehensive_benchmark(self):
        benchmarks = [
            self.benchmark_search_latency(),
            self.benchmark_embedding_generation(),
            self.benchmark_vector_search(),
            self.benchmark_memory_usage(),
            self.benchmark_concurrent_requests()
        ]
        
        results = await asyncio.gather(*benchmarks)
        return self.format_benchmark_report(results)
    
    async def benchmark_search_latency(self):
        # Тестируем поиск с различными размерами result sets
        test_cases = [
            {"top_k": 3, "expected_ms": 100},
            {"top_k": 10, "expected_ms": 200},
            {"top_k": 50, "expected_ms": 500}
        ]
        
        for case in test_cases:
            start_time = time.time()
            results = await self.semantic_service.query("test query", case["top_k"])
            latency = (time.time() - start_time) * 1000
            
            assert latency < case["expected_ms"], f"Search latency too high: {latency}ms"
```

#### Load Testing Strategy
```python
# Load test scenarios
LOAD_TEST_SCENARIOS = {
    "normal_load": {
        "users": 100,
        "duration": "10m",
        "ramp_up": "2m"
    },
    "peak_load": {
        "users": 500, 
        "duration": "30m",
        "ramp_up": "5m"
    },
    "stress_test": {
        "users": 1000,
        "duration": "15m", 
        "ramp_up": "3m"
    }
}
```

## 6. Deployment strategy

### 6.1 Blue-green deployment

#### Deployment Pipeline
```yaml
# .github/workflows/semantic-rag-deployment.yml
name: Semantic RAG Deployment

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Green Environment
        run: |
          # Развертываем новую версию в green environment
          kubectl apply -f deployments/semantic-rag-green.yml
          
      - name: Run Health Checks
        run: |
          # Проверяем health новой системы
          ./scripts/health-check.sh green
          
      - name: Run Integration Tests
        run: |
          # Запускаем integration tests
          ./scripts/run-integration-tests.sh green
          
      - name: Switch Traffic to Green
        run: |
          # Переключаем 10% трафика
          kubectl patch service semantic-rag-service -p '{"spec":{"selector":{"version":"green"}}}'
          
      - name: Monitor for 1 Hour
        run: |
          # Мониторинг 1 час
          ./scripts/monitor-system.sh --duration=1h
          
      - name: Full Cutover to Green
        if: success()
        run: |
          # Полный переключение на green
          kubectl patch service semantic-rag-service -p '{"spec":{"selector":{"version":"green"}}}'
          
      - name: Decommission Blue Environment
        if: success()
        run: |
          # Удаляем blue environment
          kubectl delete -f deployments/semantic-rag-blue.yml
```

### 6.2 Gradual rollout

#### Traffic Shifting Strategy
```python
class TrafficManager:
    async def gradual_rollout(self):
        phases = [
            {"percentage": 10, "duration": "2h", "conditions": ["error_rate < 1%"]},
            {"percentage": 25, "duration": "4h", "conditions": ["error_rate < 1%", "latency < 500ms"]},
            {"percentage": 50, "duration": "8h", "conditions": ["error_rate < 0.5%", "latency < 300ms"]},
            {"percentage": 75, "duration": "12h", "conditions": ["error_rate < 0.5%", "latency < 200ms"]},
            {"percentage": 100, "duration": "permanent", "conditions": []}
        ]
        
        for phase in phases:
            await self.shift_traffic(phase["percentage"])
            await self.monitor_phase(phase["duration"], phase["conditions"])
            
            if not await self.check_success_criteria(phase["conditions"]):
                await self.rollback_traffic()
                raise RollbackException(f"Phase {phase['percentage']}% failed")
```

### 6.3 Data migration scripts

#### Migration Orchestration
```python
class MigrationOrchestrator:
    async def execute_migration(self):
        migration_plan = [
            "backup_legacy_data",
            "create_vector_collections", 
            "migrate_critical_documents",
            "validate_migration_quality",
            "switch_read_operations",
            "migrate_remaining_documents",
            "switch_write_operations",
            "cleanup_legacy_data"
        ]
        
        for step in migration_plan:
            try:
                await self.execute_migration_step(step)
                await self.validate_step_results(step)
                await self.log_migration_progress(step, "success")
            except Exception as e:
                await self.handle_migration_error(step, e)
                await self.rollback_to_previous_state()
                raise
```

#### Data Consistency Validation
```python
class DataValidator:
    async def validate_migration_integrity(self):
        # Проверяем что все документы корректно мигрированы
        legacy_count = await self.count_legacy_documents()
        semantic_count = await self.count_semantic_documents()
        
        assert legacy_count == semantic_count, f"Document count mismatch: {legacy_count} vs {semantic_count}"
        
        # Проверяем content integrity
        for doc_id in await self.get_all_document_ids():
            legacy_content = await self.get_legacy_content(doc_id)
            semantic_content = await self.get_semantic_content(doc_id)
            
            content_hash_legacy = hashlib.md5(legacy_content.encode()).hexdigest()
            content_hash_semantic = hashlib.md5(semantic_content.encode()).hexdigest()
            
            assert content_hash_legacy == content_hash_semantic, f"Content mismatch for {doc_id}"
```

## 7. Временные рамки и контрольные точки

### 7.1 Детальный timeline

#### Неделя 1-2: Инфраструктура и базовые компоненты
- [ ] Создание новых доменных сущностей
- [ ] Интеграция с vector database (Qdrant)
- [ ] Базовый embedding service
- [ ] Обратная совместимость layer
- [ ] Unit тесты для новых компонентов

#### Неделя 3-4: Semantic chunking engine
- [ ] Document structure analyzer
- [ ] Semantic chunking для сценариев  
- [ ] AI integration (OpenAI/Claude)
- [ ] Entity extraction service
- [ ] Integration тесты

#### Неделя 5-6: Knowledge base migration
- [ ] Data migration scripts
- [ ] Batch processing pipeline
- [ ] Caching implementation
- [ ] Performance optimization
- [ ] Migration validation tools

#### Неделя 7-8: Testing и deployment
- [ ] A/B testing setup
- [ ] Load testing и benchmarking
- [ ] Blue-green deployment
- [ ] Monitoring и alerting
- [ ] Documentation и training

#### Неделя 9-10: Polish и optimization
- [ ] Performance tuning
- [ ] Cost optimization
- [ ] Advanced features (coherence analysis)
- [ ] User feedback integration
- [ ] Go-live и support

### 7.2 Контрольные точки и критерии готовности

#### Gate 1 (Неделя 2): Базовая архитектура
**Критерии:**
- [ ] Все новые сущности созданы и протестированы
- [ ] Vector database настроена и работает
- [ ] Обратная совместимость обеспечена
- [ ] Unit test coverage > 80%

#### Gate 2 (Неделя 4): Semantic processing
**Критерии:**  
- [ ] Semantic chunking работает для сценариев и документов
- [ ] AI интеграция стабильна
- [ ] Entity extraction accuracy > 90%
- [ ] Integration тесты проходят

#### Gate 3 (Неделя 6): Data migration
**Критерии:**
- [ ] Миграция 1000+ документов успешна
- [ ] Data integrity validation 100%
- [ ] Performance benchmarks в пределах нормы
- [ ] Cache hit rate > 80%

#### Gate 4 (Неделя 8): Production readiness
**Критерии:**
- [ ] A/B тесты показывают улучшение
- [ ] Load testing проходит (1000 concurrent users)
- [ ] Blue-green deployment оттестирован
- [ ] Monitoring и alerting настроены

#### Gate 5 (Неделя 10): Go-live
**Критерии:**
- [ ] All success criteria met
- [ ] User acceptance testing completed
- [ ] Documentation и training delivered
- [ ] Support team prepared

## 8. Риски и митигация

### 8.1 Технические риски

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| AI API rate limits | Высокая | Среднее | Batch processing, caching, multiple providers |
| Vector DB performance | Средняя | Высокое | Load testing, indexing optimization, fallback |
| Migration data loss | Низкая | Критическое | Comprehensive backups, validation, rollback |
| Backward compatibility breaking | Средняя | Высокое | Extensive testing, gradual rollout, feature flags |

### 8.2 Операционные риски

| Риск | Митигация |
|------|-----------|
| Cost overruns (AI API) | Usage monitoring, cost alerts, optimization |
| Team capacity constraints | Phased delivery, external consultants if needed |
| User adoption resistance | Training, gradual feature introduction, feedback loops |
| Performance degradation | Continuous monitoring, auto-scaling, optimization |

### 8.3 Compliance и security

- **Data privacy**: Embeddings не содержат PII, encryption at rest
- **API security**: Rate limiting, API key rotation, monitoring
- **Audit trail**: Full logging всех semantic operations
- **Compliance**: GDPR/CCPA compliance для embeddings

## 9. Бюджет и ресурсы

### 9.1 Детальный бюджет

#### Development Costs (8 недель)
```
Backend Developers (2 x 8 weeks): $32,000
ML Engineer (8 weeks): $16,000  
DevOps Engineer (4 weeks): $8,000
Project Manager (8 weeks): $8,000
Total Personnel: $64,000
```

#### Infrastructure Costs (3 месяца)
```
Qdrant Cloud (Production): $1,500/month
Redis Cloud (Caching): $300/month
GPU instances (AI processing): $2,000/month
Monitoring & Logging: $500/month
Total Infrastructure: $13,200/quarter
```

#### AI API Costs (estimated)
```
OpenAI Embeddings (text-embedding-3-large): $0.13/1M tokens
Estimated volume: 10M tokens/month = $1,300/month
Claude/GPT-4 for analysis: $2,000/month
Total AI Costs: $3,300/month
```

#### Total First Year Budget: $105,000

### 9.2 ROI расчет

#### Benefits (annual)
- Improved search relevance: 40% better → 20% time savings → $50,000 value
- Reduced manual processing: 60% automation → $75,000 value  
- Enhanced user satisfaction: 15% retention improvement → $100,000 value
- Infrastructure cost reduction: 30% efficiency → $25,000 value

**Total Annual Benefit: $250,000**  
**ROI: 238% first year**

## 10. Заключение и следующие шаги

### 10.1 Немедленные действия (следующие 2 недели)

1. **Создать проектную команду** и назначить технического лидера
2. **Настроить development environment** с vector database
3. **Создать proof of concept** для semantic chunking
4. **Провести техническое spike** по AI API integration
5. **Подготовить detailed technical design** документ

### 10.2 Ключевые факторы успеха

1. **Постепенное внедрение** с fallback к legacy системе
2. **Comprehensive testing** на каждом этапе
3. **Performance monitoring** с автоматическими алертами
4. **User feedback integration** для continuous improvement
5. **Team training** на новых технологиях

### 10.3 Success criteria

- **Technical**: Search relevance improvement > 40%, response time < 500ms
- **Business**: User satisfaction > 90%, cost efficiency +30%
- **Operational**: System availability > 99.9%, error rate < 0.1%

Данный план обеспечивает безопасную и поэтапную интеграцию семантической обработки в существующую RAG систему ScriptRating с минимальными рисками и максимальной совместимостью.