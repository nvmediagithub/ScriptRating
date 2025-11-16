# Архитектура AI-группировки смысловых блоков документов

## 1. Анализ текущей реализации

### 1.1 Текущие подходы к разбивке документов

#### RAG Document (`app/domain/entities/rag_document.py`)
```python
def get_content_chunks(self, chunk_size: int = 1000) -> List[str]:
    # Простой word-based chunking
    if len(self.content) <= chunk_size:
        return [self.content]
    
    chunks = []
    words = self.content.split()
    current_chunk = ""
    
    for word in words:
        if len(current_chunk) + len(word) + 1 <= chunk_size:
            current_chunk += " " + word if current_chunk else word
        else:
            if current_chunk:
                chunks.append(current_chunk)
            current_chunk = word
    
    if current_chunk:
        chunks.append(current_chunk)
    
    return chunks
```

**Проблемы:**
- Фиксированный размер чанка (1000 символов)
- Разрывает семантические связи между словами
- Не учитывает структуру документа
- Не сохраняет контекстную связанность

#### File System Document Parser (`app/infrastructure/repositories/file_system_document_parser.py`)

**Реализация paragraph-level разбивки:**
- PDF: Разбивка по двойным переносам строк (`\n\n`)
- DOCX: Разбивка по параграфам документа
- TXT: Разбивка по непустым строкам

**Метаданные:**
```python
paragraph_details = [
    {
        "page": page_index + 1,
        "paragraph_index": paragraph_index,
        "text": paragraph,
    }
]
```

### 1.2 Анализ структуры документов

#### Типы документов в системе:

1. **Нормативные критерии** (criteria)
   - Короткие тексты с правовыми ссылками
   - Структура: заголовок, определения, ссылки на ФЗ
   - Пример: ФЗ-436 "О защите детей от информации"

2. **Киносценарии** (script)
   - Сложная структурированная документация
   - Элементы: сцены (ИНТ./НАТ.), персонажи, диалоги, действия
   - Пример: сценарий "Васильки" (3946 строк)
   - Специфика: временные переходы, описания, ремарки

#### Проблемы текущего paragraph-level подхода:

1. **Разрыв смысловых блоков**
   - Диалог персонажа разбивается на отдельные чанки
   - Описание сцены теряет связь с репликами
   - Переходы между временными пластами не учитываются

2. **Потеря структурной информации**
   - Игнорируются заголовки и подзаголовки
   - Не сохраняется иерархия документа
   - Теряется контекст персонажей и локаций

3. **Неэффективность для поиска**
   - Релевантная информация может быть разбросана по разным чанкам
   - Контекст для понимания смысла теряется

## 2. Концепция Semantic Chunking

### 2.1 Основные принципы

**Semantic Chunking** - интеллектуальная разбивка документов на смысловые блоки с сохранением:
- Семантической целостности
- Структурной иерархии
- Контекстной связанности
- Метаданных для поиска и анализа

### 2.2 Стратегии группировки смысловых блоков

#### Для киносценариев:
1. **Сценарные блоки**
   - Каждая сцена как отдельный семантический блок
   - Группировка связанных сцен (act-based)
   - Сохранение диалогов и описаний в рамках одной сцены

2. **Персонажно-центричные блоки**
   - Группировка всех реплик и действий персонажа
   - Создание "биографических" чанков для ключевых персонажей

3. **Тематические блоки**
   - Группировка по сюжетным линиям
   - Временные переходы (flashback/flashforward)

#### Для нормативных документов:
1. **Статейно-ориентированные блоки**
   - Каждая статья/пункт как семантическая единица
   - Группировка связанных статей

2. **Концептуальные блоки**
   - Определения и их применение
   - Примеры и исключения

### 2.3 Алгоритм AI-группировки

#### Этап 1: Структурный анализ
```python
class SemanticChunkingEngine:
    def analyze_document_structure(self, raw_script: RawScript) -> DocumentStructure:
        # Определение типа документа
        doc_type = self.detect_document_type(raw_script.content)
        
        # Извлечение структурных элементов
        if doc_type == DocumentType.SCRIPT:
            return self.parse_script_structure(raw_script)
        elif doc_type == DocumentType.LEGAL:
            return self.parse_legal_structure(raw_script)
        
    def parse_script_structure(self, raw_script: RawScript) -> ScriptStructure:
        return {
            "scenes": self.extract_scenes(raw_script.content),
            "characters": self.extract_characters(raw_script.content),
            "dialogues": self.extract_dialogues(raw_script.content),
            "actions": self.extract_actions(raw_script.content),
            "time_transitions": self.extract_time_transitions(raw_script.content)
        }
```

#### Этап 2: Семантическая группировка
```python
class SemanticGrouper:
    def group_content(self, structure: DocumentStructure) -> List[SemanticChunk]:
        if isinstance(structure, ScriptStructure):
            return self.group_script_content(structure)
        elif isinstance(structure, LegalStructure):
            return self.group_legal_content(structure)
    
    def group_script_content(self, script_structure: ScriptStructure) -> List[SemanticChunk]:
        chunks = []
        
        # Группировка по сценам
        for scene in script_structure.scenes:
            scene_chunk = self.create_scene_chunk(scene, script_structure)
            chunks.append(scene_chunk)
        
        # Группировка диалогов персонажа
        character_dialogues = self.group_character_dialogues(script_structure)
        chunks.extend(character_dialogues)
        
        # Тематические блоки
        thematic_chunks = self.create_thematic_chunks(script_structure)
        chunks.extend(thematic_chunks)
        
        return chunks
```

#### Этап 3: AI-анализ связности
```python
class SemanticAnalyzer:
    def analyze_semantic_coherence(self, chunks: List[SemanticChunk]) -> CoherenceMap:
        # Анализ семантической связанности между чанками
        coherence_scores = {}
        
        for i, chunk1 in enumerate(chunks):
            for j, chunk2 in enumerate(chunks[i+1:], i+1):
                score = self.calculate_semantic_similarity(chunk1, chunk2)
                coherence_scores[(i, j)] = score
        
        return CoherenceMap(coherence_scores)
    
    def calculate_semantic_similarity(self, chunk1: SemanticChunk, chunk2: SemanticChunk) -> float:
        # Использование embeddings для определения семантической близости
        embedding1 = self.get_embedding(chunk1.content)
        embedding2 = self.get_embedding(chunk2.content)
        
        return cosine_similarity(embedding1, embedding2)
```

## 3. Структура метаданных для Semantic Chunks

### 3.1 Расширенная модель SemanticChunk

```python
@dataclass
class SemanticChunk:
    id: str
    content: str
    chunk_type: str  # scene, dialogue, action, article, definition
    original_range: DocumentRange  # page_start, page_end, char_start, char_end
    
    # Структурные метаданные
    document_structure: Dict[str, Any]  # hierarchy_level, section_type, etc.
    
    # Семантические метаданные
    entities: List[Entity]  # персонажи, локации, концепции
    topics: List[str]  # основные темы
    sentiment: float  # эмоциональная окраска
    importance_score: float  # важность для понимания контекста
    
    # Связность
    related_chunks: List[str]  # IDs связанных чанков
    coherence_score: float  # внутренняя связность чанка
    
    # Метаданные для поиска
    keywords: List[str]
    embedding: Optional[List[float]]
    
    # AI-генерированные аннотации
    summary: str
    key_points: List[str]
    questions: List[str]  # вопросы, которые освещает чанк

@dataclass
class Entity:
    name: str
    type: str  # PERSON, LOCATION, CONCEPT, TIME_PERIOD
    confidence: float
    context: str
```

### 3.2 Иерархическая структура

```python
@dataclass
class SemanticHierarchy:
    document_id: str
    root_chunk_id: str
    chunks: Dict[str, SemanticChunk]
    relationships: Dict[str, List[str]]  # parent -> [children]
    cross_references: Dict[str, List[str]]  # chunk_id -> [related_chunk_ids]
```

## 4. AI модели для Semantic Chunking

### 4.1 Рекомендуемые модели

#### Для структурного анализа:
1. **GPT-4/GPT-3.5-turbo**
   - Извлечение структуры документов
   - Определение типов контента
   - Генерация аннотаций

2. **Claude 3 (Sonnet/Opus)**
   - Анализ длинных документов
   - Выявление тематических блоков

#### Для семантического анализа:
1. **Embedding модели:**
   - `text-embedding-3-large` (OpenAI)
   - `sentence-transformers/all-MiniLM-L6-v2`
   - `sentence-transformers/all-mpnet-base-v2`

2. **Специализированные модели:**
   - `BAAI/bge-large-en-v1.5` (для научных текстов)
   - `microsoft/DialoGPT-medium` (для диалогов)

#### Для русскоязычных текстов:
1. **SberCloud RuBERT**
2. **DeepPavlov RuBERT**
3. `sentence-transformers/paraphrase-multilingual-mpnet-base-v2`

### 4.2 Pipeline обработки

```python
class SemanticChunkingPipeline:
    def __init__(self):
        self.structure_analyzer = StructureAnalyzer()
        self.embedding_model = EmbeddingModel()
        self.entity_extractor = EntityExtractor()
        self.semantic_grouper = SemanticGrouper()
    
    async def process_document(self, raw_script: RawScript) -> List[SemanticChunk]:
        # 1. Структурный анализ
        structure = await self.structure_analyzer.analyze(raw_script)
        
        # 2. Извлечение сущностей
        entities = await self.entity_extractor.extract(raw_script.content)
        
        # 3. Создание первичных чанков
        initial_chunks = self.create_initial_chunks(raw_script, structure)
        
        # 4. AI-группировка
        grouped_chunks = await self.semantic_grouper.group(initial_chunks)
        
        # 5. Создание embeddings
        for chunk in grouped_chunks:
            chunk.embedding = await self.embedding_model.encode(chunk.content)
        
        # 6. Постобработка
        final_chunks = self.post_process_chunks(grouped_chunks, entities)
        
        return final_chunks
```

## 5. Интеграция с существующей системой

### 5.1 Совместимость с RAG Document

```python
class RAGDocumentManager:
    def __init__(self, semantic_pipeline: SemanticChunkingPipeline):
        self.semantic_pipeline = semantic_pipeline
        self.legacy_parser = FileSystemDocumentParser()
    
    async def process_document(self, file_path: Path) -> RAGDocument:
        # Используем legacy парсер для базовой структуры
        raw_script = await self.legacy_parser.parse_document(file_path)
        
        # Применяем semantic chunking
        semantic_chunks = await self.semantic_pipeline.process_document(raw_script)
        
        # Конвертируем в RAG документы
        rag_documents = []
        for chunk in semantic_chunks:
            rag_doc = RAGDocument(
                id=f"{raw_script.id}_{chunk.id}",
                title=f"{raw_script.filename} - {chunk.chunk_type}",
                content=chunk.content,
                content_type=raw_script.metadata.get('content_type', 'unknown'),
                source=raw_script.metadata.get('source_path'),
                metadata={
                    **raw_script.metadata,
                    'semantic_chunk_id': chunk.id,
                    'chunk_type': chunk.chunk_type,
                    'entities': [e.name for e in chunk.entities],
                    'topics': chunk.topics,
                    'importance_score': chunk.importance_score,
                    'semantic_hierarchy': chunk.document_structure
                }
            )
            rag_documents.append(rag_doc)
        
        return rag_documents
```

### 5.2 Обратная совместимость

```python
class BackwardCompatibleChunker:
    def __init__(self, semantic_pipeline: SemanticChunkingPipeline):
        self.semantic_pipeline = semantic_pipeline
        self.fallback_legacy = True
    
    async def get_content_chunks(self, document: RAGDocument, 
                                chunk_size: int = 1000,
                                use_legacy: bool = False) -> List[str]:
        
        if use_legacy or not self.semantic_pipeline:
            # Fallback к старому методу
            return self.legacy_get_content_chunks(document, chunk_size)
        
        # Используем semantic chunking
        semantic_chunks = await self.semantic_pipeline.process_by_id(document.id)
        
        # Возвращаем содержимое semantic chunks
        return [chunk.content for chunk in semantic_chunks]
```

## 6. Стратегия определения границ смысловых блоков

### 6.1 Критерии границ для сценариев

#### Жесткие границы:
1. **Переходы между сценами** (`ИНТ.` / `НАТ.`)
2. **Смена времени** (явные указания временных переходов)
3. **Главы/акты** в структурированных документах

#### Гибкие границы (AI-определяемые):
1. **Семантические переходы**
   - Смена темы разговора
   - Переход к другому аспекту сюжета
   - Изменение эмоционального контекста

2. **Длительные паузы в действии**
   - Конец значимого диалога
   - Завершение сюжетного эпизода

### 6.2 Алгоритм определения границ

```python
class BoundaryDetector:
    def detect_boundaries(self, content: str, doc_type: str) -> List[Boundary]:
        boundaries = []
        
        if doc_type == DocumentType.SCRIPT:
            boundaries.extend(self.detect_script_boundaries(content))
        elif doc_type == DocumentType.LEGAL:
            boundaries.extend(self.detect_legal_boundaries(content))
        
        # AI-определение семантических границ
        semantic_boundaries = self.detect_semantic_boundaries(content)
        boundaries.extend(semantic_boundaries)
        
        return self.merge_and_prioritize_boundaries(boundaries)
    
    def detect_script_boundaries(self, content: str) -> List[Boundary]:
        boundaries = []
        
        # Паттерны для сцен
        scene_pattern = r'(\d+-\d+)\.\s*(ИНТ\.|НАТ\.|INT\.|EXT\.)'
        for match in re.finditer(scene_pattern, content):
            boundaries.append(Boundary(
                position=match.start(),
                type='scene_transition',
                confidence=1.0,
                metadata={'scene_number': match.group(1)}
            ))
        
        # Паттерны для временных переходов
        time_patterns = [
            r'СКЛЕЙКА',
            r'Возврат в сцену',
            r'flashback|flashforward'
        ]
        
        for pattern in time_patterns:
            for match in re.finditer(pattern, content, re.IGNORECASE):
                boundaries.append(Boundary(
                    position=match.start(),
                    type='time_transition',
                    confidence=0.9
                ))
        
        return boundaries
    
    def detect_semantic_boundaries(self, content: str) -> List[Boundary]:
        # Использование AI для определения семантических границ
        paragraphs = content.split('\n\n')
        boundaries = []
        
        for i, para in enumerate(paragraphs[:-1]):
            current_embedding = self.embedding_model.encode(para)
            next_embedding = self.embedding_model.encode(paragraphs[i+1])
            
            similarity = cosine_similarity(current_embedding, next_embedding)
            
            # Если схожесть ниже порога - возможная граница
            if similarity < 0.7:  # Порог может быть настраиваемым
                boundaries.append(Boundary(
                    position=content.find(paragraphs[i+1]),
                    type='semantic_transition',
                    confidence=1.0 - similarity,
                    metadata={'similarity_score': similarity}
                ))
        
        return boundaries
```

## 7. Техническая реализация

### 7.1 Компоненты системы

```python
# Новые модули
app/
├── domain/
│   ├── entities/
│   │   ├── semantic_chunk.py          # Новая сущность
│   │   ├── document_structure.py      # Структурная информация
│   │   └── entity.py                  # Извлеченные сущности
│   ├── services/
│   │   ├── semantic_analyzer.py       # Основной сервис
│   │   ├── embedding_service.py       # Генерация embeddings
│   │   └── entity_extraction_service.py # Извлечение сущностей
│   └── use_cases/
│       └── process_document_use_case.py # Бизнес-логика
├── infrastructure/
│   ├── ai/
│   │   ├── openai_client.py           # Клиент для AI API
│   │   ├── embedding_providers.py     # Провайдеры embeddings
│   │   └── semantic_models.py         # Настройки моделей
│   └── repositories/
│       └── enhanced_document_parser.py # Расширенный парсер
```

### 7.2 Конфигурация и настройки

```python
@dataclass
class SemanticChunkingConfig:
    # AI модели
    structure_model: str = "gpt-4"
    embedding_model: str = "text-embedding-3-large"
    entity_model: str = "gpt-4"
    
    # Параметры группировки
    max_chunk_size: int = 2000
    min_chunk_size: int = 100
    similarity_threshold: float = 0.7
    
    # Специфичные настройки
    preserve_dialogue_integrity: bool = True
    merge_short_paragraphs: bool = True
    use_semantic_boundaries: bool = True
    
    # Производительность
    batch_size: int = 32
    enable_parallel_processing: bool = True
    cache_embeddings: bool = True
```

## 8. Заключение

Предложенная архитектура semantic chunking обеспечивает:

1. **Повышение качества поиска** через семантически связанные блоки
2. **Сохранение структуры документа** с богатыми метаданными
3. **Обратную совместимость** с существующей системой
4. **Гибкость настройки** под разные типы документов
5. **Масштабируемость** через AI-powered обработку

Система готова к поэтапному внедрению с возможностью fallback к legacy методам.