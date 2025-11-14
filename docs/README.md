# ScriptRating Documentation

This documentation provides comprehensive architectural details, module specifications, and implementation reports for the ScriptRating system. The documentation is organized into logical sections to facilitate easy navigation and understanding.

## 📖 Documentation Navigation

### 🏗️ Architecture Overview
- **[Main Architecture](architecture.md)** - High-level system architecture, functional modules, and technological decisions
- **[LLM Analysis & Implementation Plan](llm_analysis_and_implementation_plan.md)** - AI integration strategy and implementation roadmap
- **[OpenRouter Integration Test Report](openrouter_integration_test_report.md)** - External API integration testing results
- **[Real-time Chat Implementation Plan](real_time_chat_implementation_plan.md)** - Real-time communication features planning

### 🧩 Module Documentation (`modules/`)
Detailed specifications for each core system component:

**Core Processing Pipeline:**
1. **[Document Parser](modules/document_parser.md)** - PDF/DOCX text extraction and normalization
2. **[Scene Segmenter](modules/scene_segmenter.md)** - Script segmentation into scenes and dialogues
3. **[Rule-Based Filter](modules/rule_based_filter.md)** - Fast pre-screening for content violations
4. **[LLM Classifier](modules/llm_classifier.md)** - AI-powered content classification with RAG augmentation
5. **[Rating Engine](modules/rating_engine.md)** - Age rating calculation following FZ-436 rules

**Output & Feedback Systems:**
6. **[Justification Builder](modules/justification_builder.md)** - Detailed explanations with legal citations
7. **[Report Generator](modules/report_generator.md)** - Multi-format report generation (PDF/DOCX/JSON)
8. **[RAG Orchestrator](modules/rag_orchestrator.md)** - Retrieval Augmented Generation coordination
9. **[Feedback Processor](modules/feedback_processor.md)** - User correction handling and learning
10. **[History Manager](modules/history_manager.md)** - Analysis history and audit trails

**Frontend & UI:**
11. **[Flutter UI](modules/flutter_ui.md)** - Cross-platform user interface architecture

### 🏛️ System Diagrams (`diagrams/`)
Visual documentation for complex system workflows:

- **[Overall Data Flow](diagrams/overall_data_flow.md)** - Complete data flow through the system
- **[RAG Pipeline](diagrams/rag_pipeline.md)** - Retrieval Augmented Generation workflow
- **[Clean Architecture Layers](diagrams/clean_architecture_layers.md)** - Layered architecture with dependencies

### 📊 Implementation Reports (`reports/`)
Development progress, testing results, and technical reports:

**Backend Development:**
- [Backend Chat Implementation Final Report](reports/BACKEND_CHAT_IMPLEMENTATION_FINAL_REPORT.md)
- [Backend Chat Testing Report](reports/BACKEND_CHAT_TESTING_REPORT.md)
- [Chat System Simplification Report](reports/CHAT_SYSTEM_SIMPLIFICATION_REPORT.md)
- [CORS Fix Implementation Report](reports/CORS_FIX_IMPLEMENTATION_REPORT.md)
- [Import Structure Fix Report](reports/IMPORT_STRUCTURE_FIX_REPORT.md)

**Frontend Development:**
- [Flutter Text Selection Implementation Report](reports/FLUTTER_TEXT_SELECTION_IMPLEMENTATION_REPORT.md)
- [Flutter Text Selection Test Report](reports/FLUTTER_TEXT_SELECTION_TEST_REPORT.md)
- [Flutter Dropdown Assertion Error Fix Report](reports/FLUTTER_DROPDOWN_ASSERTION_ERROR_FIX_REPORT.md)

**Integration & Testing:**
- [Category Naming Fix Report](reports/CATEGORY_NAMING_FIX_REPORT.md)
- [DOCX Content Type Fix Report](reports/DOCX_CONTENT_TYPE_FIX_REPORT.md)
- [Final E2E Test Report](reports/FINAL_E2E_TEST_REPORT.md)
- [OpenRouter Chat Integration Testing Report](reports/OPENROUTER_CHAT_INTEGRATION_TESTING_REPORT.md)
- [Real-time Chat Interface Testing Report](reports/REAL_TIME_CHAT_INTERFACE_TESTING_REPORT.md)

### 🔍 Analysis Reports (`analysis/`)
Debugging documentation and problem-solving investigations:

- [Browser Console Error Analysis Report](analysis/BROWSER_CONSOLE_ERROR_ANALYSIS_REPORT.md)
- [DOCX Runtime Error Debug Report](analysis/DOCX_RUNTIME_ERROR_DEBUG_REPORT.md)
- [Final Browser Console Debug Report](analysis/FINAL_BROWSER_CONSOLE_DEBUG_REPORT.md)
- [Python Main Debug Report](analysis/PYTHON_MAIN_DEBUG_REPORT.md)

### 🛠️ Feature Documentation (`features/`)
Detailed feature specifications and workflows:

- [Age Rating Workflow](features/age_rating_workflow.md) - Complete FZ-436 compliance workflow

### 🧪 Testing Documentation
- **[Test Documentation](../docs/test_documentation.md)** - Comprehensive testing guide and organization
  - Backend test suite organization (`tests/`)
  - Frontend test suite organization (`flutter/test/`)
  - Testing strategies and best practices

## 🎯 Quick Reference

### For Developers
- **New to Project**: Start with [`architecture.md`](architecture.md) and [Project Organization section in main README](../README.md#-project-organization)
- **Working on Backend**: Focus on [`modules/`](modules/) and [`reports/`](reports/)
- **Working on Frontend**: Check [`modules/flutter_ui.md`](modules/flutter_ui.md) and Flutter test documentation
- **Debugging Issues**: Refer to [`analysis/`](analysis/) reports for similar problems

### For Contributors
- **Architecture Changes**: Update both [`architecture.md`](architecture.md) and relevant [`diagrams/`](diagrams/)
- **New Features**: Create documentation in [`features/`](features/) and [`modules/`](modules/)
- **Bug Fixes**: Document findings in [`analysis/`](analysis/) and update [`reports/`](reports/)

### For Maintainers
- **Documentation Updates**: Ensure all sections stay current with code changes
- **Test Coverage**: Monitor [`test_documentation.md`](test_documentation.md) for coverage updates
- **API Changes**: Update architectural diagrams and module specifications

## 📋 Documentation Standards

### Module Documentation Structure
Each module document follows a consistent format:
- **Purpose & Overview**: What the module does and why it exists
- **Input/Output Specifications**: Expected inputs and generated outputs
- **Internal Workflow**: Step-by-step processing logic
- **Integration Points**: How it connects with other modules
- **Dependencies**: External libraries and internal modules
- **Design Decisions**: Key architectural choices and rationale

### Report Documentation Structure
Implementation reports follow this template:
- **Executive Summary**: High-level overview and results
- **Problem Statement**: What issue was being addressed
- **Solution Approach**: How the problem was solved
- **Implementation Details**: Technical specifics
- **Testing Results**: Verification and validation
- **Lessons Learned**: Insights for future development

### Visual Documentation
All diagrams use Mermaid syntax for consistency and easy editing:
- Flowcharts for process workflows
- Sequence diagrams for API interactions
- Component diagrams for system architecture
- Class diagrams for data models

## 🔗 Cross-References

Documentation sections are extensively cross-referenced for easy navigation:
- Module docs link to related architectural diagrams
- Implementation reports reference affected modules
- Analysis reports connect to relevant test cases
- Feature docs reference required modules and APIs

This interconnected structure helps developers understand the full context of any change or feature.