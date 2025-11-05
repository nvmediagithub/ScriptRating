# RAG Pipeline Diagram

## Complete RAG Workflow

```mermaid
flowchart TD
    subgraph "Corpus Building"
        A1[Legal Documents<br/>FЗ-436, Guidelines]
        A2[Reference Examples<br/>Scene Templates]
        A3[User Corrections<br/>Feedback Data]
        A4[Text Normalization<br/>Lemmatization, Cleaning]
        A5[Embedding Generation<br/>multilingual-e5-large]
        A6[Vector Indexing<br/>FAISS/Qdrant HNSW]
    end

    subgraph "Query Processing"
        B1[Scene Text Input]
        B2[Category Context<br/>violence, profanity, etc.]
        B3[Query Formulation<br/>Scene + Category]
        B4[Query Embedding<br/>Same Model as Corpus]
        B5[Similarity Search<br/>Top-K Retrieval]
        B6[Relevance Filtering<br/>Threshold-based]
    end

    subgraph "Context Augmentation"
        C1[Retrieved Passages<br/>Legal Citations]
        C2[Passage Ranking<br/>By Similarity Score]
        C3[Prompt Construction<br/>Base Prompt + Context]
        C4[Token Limit Enforcement<br/>Truncation if needed]
        C5[Citation Tagging<br/>Source Attribution]
    end

    subgraph "LLM Integration"
        D1[Augmented Prompt<br/>Scene + Legal Context]
        D2[Model Inference<br/>LLaMA/RuBERT]
        D3[Structured Response<br/>Severity Classification]
        D4[Explanation Generation<br/>With Citations]
    end

    subgraph "Output Processing"
        E1[Assessment Result<br/>Rating + Reasoning]
        E2[Citation Extraction<br/>For Report Integration]
        E3[Feedback Loop<br/>User Corrections → Corpus]
    end

    A1 --> A4
    A2 --> A4
    A3 --> A4
    A4 --> A5 --> A6

    B1 --> B3
    B2 --> B3
    B3 --> B4 --> B5 --> B6 --> C1

    C1 --> C2 --> C3 --> C4 --> C5 --> D1

    D1 --> D2 --> D3 --> D4 --> E1

    E1 --> E2
    E2 --> E3
    E3 --> A3

    style A1 fill:#e8f5e8
    style A2 fill:#e8f5e8
    style D1 fill:#fff3e0
    style D2 fill:#fff3e0
    style E1 fill:#fce4ec
    style E2 fill:#fce4ec
```

## RAG Component Interactions

```mermaid
sequenceDiagram
    participant UI as Flutter UI
    participant API as FastAPI
    participant RAG as RAG Orchestrator
    participant VS as Vector Store
    participant LLM as LLM Classifier

    UI->>API: Analyze Scene Request
    API->>RAG: Get Context for Scene
    RAG->>VS: Query Similar Passages
    VS-->>RAG: Return Top-K Results
    RAG-->>API: Augmented Context + Citations
    API->>LLM: Classify with RAG Context
    LLM->>RAG: Additional Context Query (if needed)
    RAG->>VS: Secondary Retrieval
    VS-->>RAG: Additional Passages
    RAG-->>LLM: Extra Context
    LLM-->>API: Assessment with Citations
    API-->>UI: Results with Legal References
```

## Corpus Update Flow

```mermaid
flowchart LR
    A[User Marks False Positive] --> B[Feedback Processor]
    B --> C[Extract Scene Text + Context]
    C --> D[RAG Orchestrator - CorpusBuilder]
    D --> E[Generate Embeddings]
    E --> F[Update Vector Index]
    F --> G[Index Rebuilt/Incremental Update]
    G --> H[Future Queries Include Correction]
```

## RAG Pipeline Workflow (Detailed)

```mermaid
flowchart TD
    subgraph Corpus_Building
        A1[Input Documents<br/>FЗ-436, Scripts, Feedback]
        A2[Text Normalization<br/>Lemmatization, Cleaning]
        A3[Chunking<br/>256-512 Tokens, Overlap]
        A4[Embedding Generation<br/>multilingual-e5-large]
        A5[Vector Indexing<br/>FAISS/Qdrant]
    end

    subgraph Query_Processing
        B1[Scene Text + Category]
        B2[Query Embedding<br/>Prefix 'query:']
        B3[Similarity Search<br/>Top-K with Threshold]
        B4[Re-ranking<br/>Cross-Encoder]
        B5[Metadata Filtering<br/>Source, Severity]
    end

    subgraph Context_Augmentation
        C1[Retrieved Passages<br/>With Scores & Metadata]
        C2[Prompt Construction<br/>Context + Scene Text]
        C3[Token Management<br/>Truncate if Needed]
        C4[Citation Formatting<br/>Source Attribution]
    end

    subgraph LLM_Integration
        D1[Augmented Prompt<br/>Context + Query]
        D2[LLM Inference<br/>Classification + Reasoning]
        D3[Response Parsing<br/>Severity Scores, Citations]
    end

    subgraph Output_Processing
        E1[Assessment Result<br/>Rating, Justifications]
        E2[Citation Storage<br/>For Reports]
        E3[Feedback Loop<br/>Update Corpus]
    end

    A1 --> A2 --> A3 --> A4 --> A5
    B1 --> B2 --> B3 --> B4 --> B5 --> C1
    C1 --> C2 --> C3 --> C4 --> D1 --> D2 --> D3 --> E1 --> E2
    E2 --> E3 --> A1

    style A1 fill:#e8f5e8
    style B1 fill:#fff3e0
    style C1 fill:#e3f2fd
    style D1 fill:#fce4ec
    style E1 fill:#f3e5f5
```

## Vector Database Schema

```mermaid
erDiagram
    VECTOR_INDEX {
        vector_id integer PK
        embedding vector[768] 
        metadata json
    }

    DOCUMENTS {
        doc_id integer PK
        source string
        category string
        severity string
        chunk_id integer
        text string
        embedding_fk integer FK
    }

    QUERIES {
        query_id integer PK
        query_text string
        query_embedding vector[768]
        timestamp datetime
    }

    RETRIEVALS {
        retrieval_id integer PK
        query_fk integer FK
        vector_fk integer FK
        similarity_score float
        rank integer
    }

    VECTOR_INDEX ||--o{ DOCUMENTS : "stores"
    DOCUMENTS ||--o{ RETRIEVALS : "retrieved_in"
    QUERIES ||--o{ RETRIEVALS : "triggers"
```

## Integration Points with LLM Classifier and Justification Builder

```mermaid
sequenceDiagram
    participant UI as Flutter UI
    participant API as FastAPI Backend
    participant RAG as RAG Orchestrator
    participant VS as Vector Store (FAISS/Qdrant)
    participant LLM as LLM Classifier
    participant JB as Justification Builder
    participant RP as Report Generator

    UI->>API: Analyze Scene Request
    API->>RAG: Retrieve Context for Scene
    RAG->>VS: Similarity Search
    VS-->>RAG: Top-K Passages
    RAG-->>API: Augmented Context + Citations

    API->>LLM: Classify with RAG Context
    LLM-->>API: Assessment + Citations

    API->>JB: Build Justifications
    JB->>RAG: Additional Citation Details
    RAG->>VS: Fetch Full Passages
    VS-->>RAG: Detailed Citations
    RAG-->>JB: Formatted Citations

    JB-->>API: Justified Assessment
    API->>RP: Generate Report
    RP->>RAG: Embed Citations
    RAG-->>RP: Citation Objects
    RP-->>API: Final Report
    API-->>UI: Results with Legal References
```

## Key RAG Design Patterns

| Component | Purpose | Implementation | Key Decisions |
|-----------|---------|----------------|---------------|
| **Corpus Builder** | Initialize and maintain knowledge base | Text preprocessing, embedding generation, vector indexing | Multilingual embeddings for Russian legal texts, incremental updates |
| **Retriever** | Find relevant context for queries | Similarity search in vector space, metadata filtering | Top-K retrieval (3-5 passages), similarity thresholds |
| **Prompt Augmentor** | Integrate context into LLM prompts | Structured prompt formatting, citation insertion | Strict token limits, source attribution formatting |
| **Citation Manager** | Track and format legal references | Source mapping, report integration | Maintain traceability to original documents |

## Data Flow in RAG Pipeline

1. **Corpus Ingestion**: Legal texts → Normalization → Embeddings → Vector Index
2. **Query Processing**: Scene text + category → Query embedding → Similarity search → Relevant passages
3. **Context Integration**: Retrieved passages → Prompt augmentation → LLM input with citations
4. **Response Processing**: LLM output → Citation extraction → Assessment with legal backing
5. **Learning Loop**: User feedback → Corpus updates → Improved future retrievals