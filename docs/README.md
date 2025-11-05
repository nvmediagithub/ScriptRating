# ScriptRating Documentation

This documentation provides comprehensive architectural details and module specifications for the ScriptRating system.

## Documentation Structure

### Architecture Overview
- [Main Architecture Document](architecture.md) - High-level system architecture, functional modules, and technological decisions

### Module Documentation
Detailed specifications for each core module:

1. **[Document Parser](modules/document_parser.md)** - PDF/DOCX text extraction and normalization
2. **[Scene Segmenter](modules/scene_segmenter.md)** - Script segmentation into scenes and dialogues
3. **[Rule-Based Filter](modules/rule_based_filter.md)** - Fast pre-screening for content violations
4. **[LLM Classifier](modules/llm_classifier.md)** - AI-powered content classification with RAG augmentation
5. **[Rating Engine](modules/rating_engine.md)** - Age rating calculation following FZ-436 rules
6. **[Justification Builder](modules/justification_builder.md)** - Detailed explanations with legal citations
7. **[Report Generator](modules/report_generator.md)** - Multi-format report generation (PDF/DOCX/JSON)
8. **[RAG Orchestrator](modules/rag_orchestrator.md)** - Retrieval Augmented Generation coordination
9. **[Feedback Processor](modules/feedback_processor.md)** - User correction handling and learning
10. **[History Manager](modules/history_manager.md)** - Analysis history and audit trails
11. **[Flutter UI](modules/flutter_ui.md)** - Cross-platform user interface

### Architectural Diagrams
System-level visualizations:

- **[Overall Data Flow](diagrams/overall_data_flow.md)** - Complete data flow through the system
- **[RAG Pipeline](diagrams/rag_pipeline.md)** - Retrieval Augmented Generation workflow
- **[Clean Architecture Layers](diagrams/clean_architecture_layers.md)** - Layered architecture with dependencies

## Key Features Documented

- **Modular Architecture**: Clean separation of concerns with well-defined interfaces
- **RAG Integration**: Legal corpus integration for explainable AI classifications
- **Multi-format Support**: PDF/DOCX script processing with structure preservation
- **Offline Operation**: Local LLM models for privacy and performance
- **Interactive UI**: Flutter-based interface with real-time feedback
- **Comprehensive Reporting**: Parents Guide-style reports with legal citations
- **Learning System**: User feedback incorporation for continuous improvement

## Navigation

Each module document follows a consistent structure:
- Detailed description with input/output specifications
- Internal workflow diagrams
- Integration points with other modules
- Key design decisions and rationale

The diagrams provide visual understanding of complex workflows and architectural relationships.