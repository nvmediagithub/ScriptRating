# Flutter UI Module

## Detailed Description
The Flutter UI provides a cross-platform interface for script analysis, featuring drag-and-drop file uploads, interactive timelines, editable scripts, and comprehensive result visualization. It serves as the primary user interface for scriptwriters, producers, and content reviewers.

### Input
- REST/WebSocket API responses from FastAPI backend
- User interactions (file uploads, edits, corrections)
- Analysis results and report data

### Output
- API requests for analysis operations
- User corrections and feedback
- Report download requests

## Internal Workflow Diagram
```mermaid
flowchart TD
    A[User Uploads Script] --> B[File Processing State]
    B --> C[Analysis Progress Display]
    C --> D[Results Visualization]
    D --> E[Interactive Timeline]
    E --> F[Scene Detail View]
    F --> G[User Feedback Actions]
    G --> H{Action Type}
    H -->|Edit Scene| I[Editor Mode]
    H -->|Mark False Positive| J[Feedback API Call]
    H -->|Add Violation| K[Feedback API Call]
    I --> L[Re-analysis Trigger]
    J --> M[Rating Recalculation]
    K --> M
    L --> N[Updated Results Display]
    M --> N
```

## Screen Architecture
```mermaid
stateDiagram-v2
    [*] --> UploadScreen
    UploadScreen --> ProgressScreen : File Selected
    ProgressScreen --> ResultsScreen : Analysis Complete
    ResultsScreen --> EditorScreen : Edit Scene
    ResultsScreen --> HistoryScreen : View History
    EditorScreen --> ProgressScreen : Save Changes
    HistoryScreen --> ResultsScreen : Select Analysis
    ResultsScreen --> [*] : Export Report
```

## Integration Points
- **Input from**: FastAPI Backend (analysis results, progress updates)
- **Output to**: FastAPI Backend (analysis requests, feedback)
- **Dependencies**: Riverpod/BLoC for state management, syncfusion_flutter packages

## Key Design Decisions
- Implement single codebase approach for web/desktop/mobile deployment
- Use Riverpod for reactive state management across screens
- Provide real-time progress updates during analysis
- Enable collaborative editing with backend synchronization
- Support offline analysis queue with local model integration