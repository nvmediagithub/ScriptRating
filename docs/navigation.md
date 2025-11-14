# ScriptRating Documentation Navigation

This quick reference guide helps you navigate the ScriptRating documentation based on your role and specific needs.

## 🎯 Quick Navigation by Role

### For New Developers
1. **Start Here**: [`README.md`](../README.md) → [Project Organization section](#-project-organization)
2. **Architecture Overview**: [`architecture.md`](architecture.md)
3. **Test Setup**: [`test_documentation.md`](test_documentation.md) → [Running Tests section](#-running-tests)

### For Backend Developers
1. **Core Modules**: [`modules/`](modules/)
   - [`document_parser.md`](modules/document_parser.md) - File processing
   - [`llm_classifier.md`](modules/llm_classifier.md) - AI integration
   - [`rating_engine.md`](modules/rating_engine.md) - Business logic
2. **Backend Reports**: [`reports/`](reports/) - Implementation progress
3. **Testing**: [`test_documentation.md`](test_documentation.md) → [Backend Testing](#backend-testing)

### For Frontend Developers
1. **UI Architecture**: [`modules/flutter_ui.md`](modules/flutter_ui.md)
2. **Frontend Reports**: Search `FLUTTER_*` in [`reports/`](reports/)
3. **Flutter Testing**: [`test_documentation.md`](test_documentation.md) → [Frontend Testing](#frontend-testing)

### For QA Engineers
1. **Test Documentation**: [`test_documentation.md`](test_documentation.md)
2. **Test Reports**: [`reports/`](reports/) and [`analysis/`](analysis/)
3. **Bug Analysis**: [`analysis/`](analysis/) - Historical debugging

### For Project Managers
1. **Architecture**: [`architecture.md`](architecture.md)
2. **Implementation Status**: [`reports/`](reports/) (most recent reports)
3. **Project Overview**: [`README.md`](../README.md)

## 📋 Documentation Sections

### 🏗️ Architecture & Design
| Document | Purpose | Audience |
|----------|---------|----------|
| [`architecture.md`](architecture.md) | System architecture overview | All developers |
| [`diagrams/clean_architecture_layers.md`](diagrams/clean_architecture_layers.md) | Clean Architecture implementation | Backend developers |
| [`diagrams/overall_data_flow.md`](diagrams/overall_data_flow.md) | Data flow visualization | All developers |
| [`diagrams/rag_pipeline.md`](diagrams/rag_pipeline.md) | RAG integration workflow | AI/LLM developers |

### 🧩 Module Documentation
| Module | Function | Key Files |
|--------|----------|-----------|
| Document Processing | PDF/DOCX parsing | [`document_parser.md`](modules/document_parser.md) |
| Content Analysis | AI classification | [`llm_classifier.md`](modules/llm_classifier.md) |
| Rating Calculation | FZ-436 compliance | [`rating_engine.md`](modules/rating_engine.md) |
| User Interface | Flutter app | [`flutter_ui.md`](modules/flutter_ui.md) |
| Report Generation | Output creation | [`report_generator.md`](modules/report_generator.md) |

### 📊 Reports & Analysis
| Category | Documents | Purpose |
|----------|-----------|---------|
| **Backend Development** | [`reports/BACKEND_CHAT_IMPLEMENTATION_FINAL_REPORT.md`](reports/BACKEND_CHAT_IMPLEMENTATION_FINAL_REPORT.md) | Backend progress tracking |
| **Frontend Development** | [`reports/FLUTTER_TEXT_SELECTION_IMPLEMENTATION_REPORT.md`](reports/FLUTTER_TEXT_SELECTION_IMPLEMENTATION_REPORT.md) | Flutter feature development |
| **Integration Testing** | [`reports/FINAL_E2E_TEST_REPORT.md`](reports/FINAL_E2E_TEST_REPORT.md) | End-to-end testing results |
| **Debug Analysis** | [`analysis/BROWSER_CONSOLE_ERROR_ANALYSIS_REPORT.md`](analysis/BROWSER_CONSOLE_ERROR_ANALYSIS_REPORT.md) | Problem resolution |

### 🧪 Testing & Quality
| Area | Document | Coverage |
|------|----------|----------|
| **Test Strategy** | [`test_documentation.md`](test_documentation.md) | Complete testing guide |
| **Unit Tests** | `tests/unit/` | Component-level testing |
| **Integration Tests** | `tests/integration/` | Workflow testing |
| **Flutter Tests** | `flutter/test/` | UI and service testing |

## 🔍 Search by Topic

### FZ-436 Compliance
- [`rating_engine.md`](modules/rating_engine.md) - Core rating logic
- [`modules/rule_based_filter.md`](modules/rule_based_filter.md) - Compliance pre-screening
- [`features/age_rating_workflow.md`](features/age_rating_workflow.md) - Complete workflow

### AI & Machine Learning
- [`llm_classifier.md`](modules/llm_classifier.md) - Content classification
- [`rag_orchestrator.md`](modules/rag_orchestrator.md) - AI integration
- [`llm_analysis_and_implementation_plan.md`](llm_analysis_and_implementation_plan.md) - AI strategy

### User Interface
- [`flutter_ui.md`](modules/flutter_ui.md) - UI architecture
- [`history_manager.md`](modules/history_manager.md) - User data management
- Frontend reports in [`reports/`](reports/) - Recent UI development

### API & Integration
- [`openrouter_integration_test_report.md`](openrouter_integration_test_report.md) - External API integration
- CORS and API reports in [`reports/`](reports/)
- Backend API structure in [`architecture.md`](architecture.md)

### File Processing
- [`document_parser.md`](modules/document_parser.md) - Multi-format support
- [`scene_segmenter.md`](modules/scene_segmenter.md) - Script processing
- DOCX-related reports in [`reports/`](reports/)

## 📈 Development Progress

### Recent Updates (Last 30 Days)
Check these files for latest development activity:

1. **Implementation Reports** (most recent first):
   - [`reports/REAL_TIME_CHAT_INTERFACE_TESTING_REPORT.md`](reports/REAL_TIME_CHAT_INTERFACE_TESTING_REPORT.md)
   - [`reports/FLUTTER_TEXT_SELECTION_TEST_REPORT.md`](reports/FLUTTER_TEXT_SELECTION_TEST_REPORT.md)
   - [`reports/BACKEND_CHAT_TESTING_REPORT.md`](reports/BACKEND_CHAT_TESTING_REPORT.md)

2. **Analysis Reports**:
   - [`analysis/FINAL_BROWSER_CONSOLE_DEBUG_REPORT.md`](analysis/FINAL_BROWSER_CONSOLE_DEBUG_REPORT.md)
   - [`analysis/DOCX_RUNTIME_ERROR_DEBUG_REPORT.md`](analysis/DOCX_RUNTIME_ERROR_DEBUG_REPORT.md)

### Ongoing Features
- **Real-time Chat**: Implementation plan in [`real_time_chat_implementation_plan.md`](real_time_chat_implementation_plan.md)
- **Enhanced RAG**: Strategy in [`llm_analysis_and_implementation_plan.md`](llm_analysis_and_implementation_plan.md)

## 🔗 Cross-References

### Module Dependencies
```
Document Parser → Scene Segmenter → Rule-Based Filter → LLM Classifier → Rating Engine
                                    ↓
                              Justification Builder → Report Generator
                                    ↓
                              History Manager + Feedback Processor
```

### Documentation Dependencies
- Architecture docs reference module specifications
- Implementation reports reference affected modules
- Test documentation references both architecture and modules
- Analysis reports reference relevant tests and modules

## 🚨 Common Issues & Solutions

### Can't Find Specific Information?
1. Check [`README.md`](../README.md) → [Module Documentation](#-module-documentation) section
2. Search [`docs/`](.) directory for keywords
3. Review recent [implementation reports](#-implementation-reports)

### Understanding System Architecture?
1. Start with [`architecture.md`](architecture.md)
2. Visualize with [`diagrams/`](diagrams/)
3. Understand modules via [`modules/`](modules/)

### Need to Write Tests?
1. Read [`test_documentation.md`](test_documentation.md)
2. Check existing tests in [`tests/`](tests/) and [`flutter/test/`](flutter/test/)
3. Review test fixtures in [`tests/fixtures/`](tests/fixtures/)

### Debugging Issues?
1. Search [`analysis/`](analysis/) for similar problems
2. Check recent test failures in [`reports/`](reports/)
3. Review relevant module documentation

## 📞 Documentation Support

### Need Help?
- **Technical Questions**: Check module documentation in [`modules/`](modules/)
- **Architecture Questions**: Review [`architecture.md`](architecture.md) and [`diagrams/`](diagrams/)
- **Testing Questions**: Reference [`test_documentation.md`](test_documentation.md)
- **Recent Changes**: Check implementation reports in [`reports/`](reports/)

### Contributing to Documentation
1. **New Features**: Update relevant module docs and create implementation report
2. **Bug Fixes**: Document resolution in [`analysis/`](analysis/)
3. **Architecture Changes**: Update diagrams and main architecture document
4. **Test Updates**: Maintain [`test_documentation.md`](test_documentation.md)

This navigation guide should help you quickly find the information you need, regardless of your role or the specific aspect of the ScriptRating system you're working with.