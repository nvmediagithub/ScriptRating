# History Manager Module

## Detailed Description
The History Manager maintains records of all script analyses, user actions, and generated reports. It provides version control, audit trails, and efficient querying for analysis history, enabling comparison between different analysis runs and tracking user corrections.

### Input
- Analysis results to store (complete or incremental updates)
- User action logs from Feedback Processor
- Report metadata and file paths
- Query parameters for history retrieval

### Output
- Analysis history records with full metadata
- Comparison reports between analysis versions
- Exportable history summaries
- Audit trails for compliance requirements

## Internal Workflow Diagram
```mermaid
flowchart TD
    A[Receive Analysis Data] --> B[Create Analysis Record]
    B --> C[Generate Unique Analysis ID]
    C --> D[Store in SQLite Database]
    D --> E[Link Report Files]
    E --> F[Log User Actions]
    F --> G[Update Version History]
    G --> H[Handle Query Requests]
    H --> I[Retrieve Analysis Records]
    I --> J[Generate Comparison Reports]
    J --> K[Export History Data]
```

## Database Schema
```mermaid
erDiagram
    ANALYSES ||--o{ ISSUES : contains
    ANALYSES ||--o{ USER_ACTIONS : tracks
    ANALYSES {
        id INTEGER PK
        filename TEXT
        created_at DATETIME
        final_rating TEXT
        categories_json TEXT
        report_path TEXT
        target_rating TEXT
        model_profile TEXT
    }
    ISSUES {
        id INTEGER PK
        analysis_id INTEGER FK
        scene_number INTEGER
        category TEXT
        severity TEXT
        description TEXT
        recommendation TEXT
        source TEXT
    }
    USER_ACTIONS {
        id INTEGER PK
        analysis_id INTEGER FK
        action_type TEXT
        payload_json TEXT
        created_at DATETIME
    }
```

## Integration Points
- **Input from**: All analysis modules (results storage), Feedback Processor (action logging)
- **Output to**: Flutter UI (history display), Report Generator (comparison data)
- **Dependencies**: SQLite database, file system for report storage

## Key Design Decisions
- Use SQLite for portability and offline operation requirements
- Implement versioning to track analysis evolution with user corrections
- Maintain comprehensive audit trails for regulatory compliance
- Support efficient querying and filtering of historical data
- Enable report archiving and cleanup of old analyses