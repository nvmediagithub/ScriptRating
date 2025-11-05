# Overall Data Flow Diagram

## System-Level Data Flow

```mermaid
flowchart TD
    subgraph "User Input"
        A1[Upload Script File<br/>PDF/DOCX]
        A2[Target Rating<br/>Optional]
        A3[User Corrections<br/>Feedback]
    end

    subgraph "Document Processing Pipeline"
        B1[Document Parser<br/>→ RawScript]
        B2[Scene Segmenter<br/>→ ScriptStructure]
        B3[Rule-Based Filter<br/>→ FlaggedScenes]
    end

    subgraph "Analysis Pipeline"
        C1[LLM Classifier<br/>→ SceneAssessments]
        C2[Rating Engine<br/>→ RatingResult]
        C3[Justification Builder<br/>→ Justifications]
    end

    subgraph "RAG System"
        D1[(Legal Corpus<br/>Vector Store)]
        D2[RAG Orchestrator<br/>Context Retrieval]
        D3[Corpus Updates<br/>from Feedback]
    end

    subgraph "Output Generation"
        E1[Report Generator<br/>→ PDF/DOCX/JSON]
        E2[History Manager<br/>→ SQLite Storage]
    end

    subgraph "User Interface"
        F1[Flutter UI<br/>Display Results]
        F2[Interactive Timeline]
        F3[Scene Editor]
        F4[Feedback Interface]
    end

    A1 --> B1
    A2 --> C2
    A3 --> D3

    B1 --> B2 --> B3 --> C1
    C1 --> C2 --> C3 --> E1
    C1 --> E2

    D1 --> D2 --> C1
    D2 --> C3

    E1 --> F1
    E2 --> F1
    F1 --> F2
    F1 --> F3
    F1 --> F4
    F4 --> A3

    style A1 fill:#e1f5fe
    style A2 fill:#e1f5fe
    style A3 fill:#e1f5fe
    style F1 fill:#f3e5f5
    style F2 fill:#f3e5f5
    style F3 fill:#f3e5f5
    style F4 fill:#f3e5f5
```

## Data Object Flow

```mermaid
flowchart LR
    RawScript --> ScriptStructure --> FlaggedScenes --> SceneAssessments --> RatingResult --> AnalysisReport --> ReportFiles
    RawScript --> ScriptStructure
    ScriptStructure --> AnalysisReport
    SceneAssessments --> AnalysisReport
    RatingResult --> AnalysisReport
    UserActions --> RatingResult
    UserActions --> RAGUpdates
    LegalPassages --> SceneAssessments
    LegalPassages --> Justifications
```

## Key Data Transformations

| Stage | Input Data | Processing | Output Data |
|-------|------------|------------|-------------|
| **Document Processing** | PDF/DOCX file | Text extraction, structure preservation | RawScript (text, pages, paragraphs) |
| **Scene Segmentation** | RawScript | Regex parsing, style analysis | ScriptStructure (scenes, dialogues) |
| **Rule Filtering** | ScriptStructure | Dictionary matching, pattern detection | FlaggedScenes (potential violations) |
| **LLM Classification** | FlaggedScenes + RAG context | Model inference with legal context | SceneAssessments (severity ratings) |
| **Rating Aggregation** | SceneAssessments | Rule-based rating calculation | RatingResult (final rating, reasons) |
| **Justification Building** | RatingResult + ScriptStructure | Citation linking, explanation generation | Justifications (detailed explanations) |
| **Report Generation** | AnalysisReport | Template formatting, visualization | ReportFiles (PDF/DOCX/JSON) |
| **Feedback Processing** | User corrections | Rating recalculation, corpus updates | Updated RatingResult + RAGUpdates |

## Data Persistence Points

- **Analysis Results**: SQLite database (analyses, issues, user_actions tables)
- **Reports**: File system storage (reports/ directory)
- **RAG Corpus**: Vector database (FAISS/Qdrant with embeddings)
- **Models**: Local storage for quantized LLaMA/RuBERT models
- **Configuration**: Settings for rule dictionaries, model profiles