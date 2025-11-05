# ScriptRating: Autonomous Script Analysis for FZ-436 Compliance

[![License](https://img.shields.io/badge/license-Private-red.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/flutter-3.19+-02569B.svg)](https://flutter.dev/)

ScriptRating is an autonomous offline system for analyzing cinematographic scripts against Russian FZ-436 age rating requirements. It automatically segments uploaded PDF/DOCX scripts, classifies content across five key categories (violence, sexual content, language, substances, frightening scenes), calculates final age ratings (0+/6+/12+/16+/18+), and generates comprehensive reports with legal justifications.

## 🎯 Project Overview and Goals

### Mission
To provide scriptwriters, producers, and content reviewers with an autonomous, offline-capable tool for FZ-436 compliance assessment, combining AI-powered analysis with legal corpus integration for transparent, explainable rating decisions.

### Core Objectives
- **FZ-436 Compliance**: Automated classification following Russian Federal Law №436-FZ rating criteria
- **Offline Operation**: Local LLM/ML models ensuring privacy and independence from external services
- **Autonomous Analysis**: End-to-end pipeline from document upload to report generation
- **Interactive Feedback**: Real-time user corrections with learning system for continuous improvement
- **Legal Transparency**: RAG-augmented justifications linking violations to specific regulatory articles

## ✨ Key Features

### Document Processing
- **Multi-format Support**: Native PDF/DOCX parsing with structure preservation
- **Intelligent Segmentation**: Automatic scene/dialogue extraction with screenplay format recognition
- **Content Normalization**: Text cleaning while maintaining critical formatting cues

### AI-Powered Analysis
- **Hybrid Classification**: Rule-based pre-screening + LLM assessment across 5 categories:
  - Violence (насилие)
  - Sexual Content (сексуальный контент)
  - Language (лексика)
  - Substances (вещества)
  - Frightening Scenes (пугающие сцены)
- **Severity Assessment**: None/Mild/Moderate/Severe ratings per category
- **RAG Integration**: Retrieval-augmented generation using legal corpus for explainable decisions

### Rating Calculation
- **FZ-436 Rules**: Automated rating assignment (0+/6+/12+/16+/18+) based on content severity
- **Target Rating Support**: Optional user-specified target rating with discrepancy highlighting
- **Problem Scene Identification**: Detailed violation mapping with scene numbers and categories

### Interactive Flutter UI
- **Cross-Platform**: Single codebase for web/desktop/mobile deployment
- **Visual Timeline**: Color-coded scene timeline with violation overlays
- **Real-time Editor**: Post-analysis script editing with instant re-analysis
- **Comprehensive History**: Analysis versioning with comparison capabilities
- **Feedback Interface**: One-click false positive marking and violation addition

### Reporting & Export
- **Multi-format Generation**: PDF/DOCX/JSON reports with professional formatting
- **Parents Guide Style**: Detailed scene-by-scene breakdowns with recommendations
- **Legal Citations**: Direct references to FZ-436 articles and regulatory sources
- **Visual Analytics**: Charts and timelines for content distribution analysis

### Learning System
- **User Corrections**: Interactive feedback incorporation into RAG knowledge base
- **Continuous Improvement**: Vector store updates from validated user inputs
- **Audit Trail**: Complete history of analysis versions and modifications
- **Offline Learning**: Local model fine-tuning from accumulated corrections

## 🏗️ Architecture

### High-Level Architecture
```mermaid
flowchart TB
    subgraph "Presentation Layer<br/>Flutter UI"
        UI1[Upload Screen]
        UI2[Results Timeline]
        UI3[Scene Editor]
        UI4[History View]
    end

    subgraph "Interface Adapters<br/>FastAPI Backend"
        API1[Analysis API]
        API2[Feedback API]
        API3[Report API]
        API4[WebSocket Updates]
    end

    subgraph "Application Layer<br/>Use Cases"
        UC1[Analysis Orchestrator]
        UC2[Feedback Processor]
        UC3[Report Builder]
        UC4[History Manager]
    end

    subgraph "Domain Layer<br/>Business Logic"
        DM1[Rating Engine<br/>FZ-436 Rules]
        DM2[Scene Classifier]
        DM3[Justification Builder]
        DM4[RAG Coordinator]
    end

    subgraph "Infrastructure Layer<br/>External Systems"
        INF1[Document Parser<br/>PyMuPDF, python-docx]
        INF2[Vector Store<br/>FAISS/Qdrant]
        INF3[LLM Models<br/>LLaMA, RuBERT]
        INF4[SQLite Database]
        INF5[File Storage]
    end

    UI1 --> API1
    API1 --> UC1 --> DM1 --> INF1
    DM2 --> INF2
    DM2 --> INF3
    UC3 --> INF5
    UC4 --> INF4

    style UI1 fill:#e3f2fd
    style API1 fill:#f3e5f5
    style UC1 fill:#fff3e0
    style DM1 fill:#e8f5e8
    style INF1 fill:#fce4ec
```

### Clean Architecture Layers
The system follows Clean Architecture principles with strict dependency inversion:

- **Presentation Layer**: Flutter UI with Riverpod state management
- **Interface Adapters**: FastAPI controllers with Pydantic DTOs
- **Application Layer**: Use case orchestration with Celery background tasks
- **Domain Layer**: Pure business logic with FZ-436 rating rules
- **Infrastructure Layer**: External dependencies (models, databases, file systems)

### Data Flow Pipeline
```mermaid
flowchart LR
    A[Upload PDF/DOCX] --> B[Document Parser]
    B --> C[Scene Segmenter]
    C --> D[Rule-Based Filter]
    D --> E[LLM Classifier + RAG]
    E --> F[Rating Engine]
    F --> G[Justification Builder]
    G --> H[Report Generator]
    H --> I[Flutter UI Display]
    I --> J[User Feedback]
    J --> D
```

For detailed architectural documentation, see:
- [`docs/architecture.md`](docs/architecture.md) - Complete system architecture
- [`docs/diagrams/clean_architecture_layers.md`](docs/diagrams/clean_architecture_layers.md) - Layered architecture breakdown
- [`docs/diagrams/overall_data_flow.md`](docs/diagrams/overall_data_flow.md) - System data flow
- [`docs/diagrams/rag_pipeline.md`](docs/diagrams/rag_pipeline.md) - RAG integration details

## 🚀 Getting Started

This comprehensive guide will help you set up and run the ScriptRating system. The application consists of a FastAPI backend for script analysis and a Flutter frontend for user interaction.

### Prerequisites

#### System Requirements
- **Operating System**: Windows 10+, macOS 10.15+, or Linux (Ubuntu 18.04+)
- **CPU**: Intel/AMD x64 or ARM64 processor (GPU recommended for better performance)
- **RAM**: Minimum 8GB (16GB+ recommended for large script analysis)
- **Storage**: 10GB+ free space for models and data

#### Backend Prerequisites
- **Python**: 3.9 or higher (3.11 recommended)
- **Git**: For cloning the repository
- **PostgreSQL** (optional): For production database (SQLite used by default for development)
- **Redis** (optional): For background task queuing

#### Frontend Prerequisites
- **Flutter SDK**: 3.9.2 or higher
- **Dart**: Included with Flutter SDK
- **Android Studio** (for Android development, optional)
- **Xcode** (for iOS development on macOS, optional)

#### Development Tools
- **VS Code** or preferred IDE with Python and Dart extensions
- **Docker** and **Docker Compose** (optional, for containerized deployment)

### Quick Start

#### Option 1: Full Development Environment (Recommended)
```bash
# Clone repository and setup complete environment
git clone <repository-url>
cd script-rating
make full-setup

# Start both backend and frontend
make dev
```

#### Option 2: Manual Setup

**Backend Setup:**
```bash
# Install Python dependencies
pip install -e .[dev]

# Copy environment configuration
cp .env.example .env

# Run database migrations (if using PostgreSQL)
alembic upgrade head

# Start development server
uvicorn app.presentation.api.main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend Setup:**
```bash
# Install Flutter dependencies
cd flutter
flutter pub get

# Run development server
flutter run -d chrome  # or flutter run for native app
```

### Detailed Setup Instructions

#### Backend Configuration

1. **Environment Variables**
   Copy `.env.example` to `.env` and configure:
   ```bash
   cp .env.example .env
   ```

   Key settings to review:
   - `DATABASE_URL`: Database connection string
   - `DEBUG`: Set to `False` for production
   - `API_HOST` and `API_PORT`: Server binding
   - `CORS_ORIGINS`: Allowed frontend origins

2. **Database Setup**
   - **SQLite (Development)**: No additional setup required
   - **PostgreSQL (Production)**:
     ```bash
     # Install PostgreSQL and create database
     createdb script_rating

     # Update .env with PostgreSQL connection
     DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/script_rating

     # Run migrations
     alembic upgrade head
     ```

#### Frontend Configuration

1. **Flutter Setup**
   ```bash
   # Verify Flutter installation
   flutter doctor

   # Install dependencies
   cd flutter && flutter pub get

   # Generate code (for JSON serialization)
   flutter pub run build_runner build
   ```

2. **Platform-Specific Setup**

   **Web Deployment:**
   ```bash
   flutter build web --release
   # Serve with any static file server
   ```

   **Desktop (Windows/macOS/Linux):**
   ```bash
   flutter build windows --release  # or macos/linux
   ```

   **Mobile (Android/iOS):**
   ```bash
   # Android
   flutter build apk --release

   # iOS (macOS only)
   flutter build ios --release
   ```

### Run Modes

#### Development Mode
Run both services simultaneously with hot reload:
```bash
make dev
```
- Backend: http://localhost:8000 (with auto-reload)
- Frontend: Opens in browser/native window
- Full debugging capabilities enabled

#### Production Mode

**Docker Deployment:**
```bash
# Build and run with Docker Compose
docker-compose up --build -d
```

**Manual Production:**
```bash
# Backend (production)
export DEBUG=False
uvicorn app.presentation.api.main:app --host 0.0.0.0 --port 8000 --workers 4

# Frontend (serve built files)
cd flutter/build/web && python -m http.server 8080
```

#### Individual Services

**Backend Only:**
```bash
make run-backend
# Or: uvicorn app.presentation.api.main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend Only:**
```bash
make run-frontend
# Or: cd flutter && flutter run
```

**Database Only (with Docker):**
```bash
docker-compose up db -d
```

### Testing

#### Backend Testing
```bash
# Run all tests
make test-backend
# Or: pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html

# Run specific test file
pytest tests/test_analysis.py -v
```

#### Frontend Testing
```bash
# Run unit tests
make test-frontend
# Or: cd flutter && flutter test

# Run integration tests
cd flutter && flutter test integration_test/
```

### Code Quality

#### Backend Code Quality
```bash
# Lint code
make lint-backend
# Or: flake8 app/ tests/ && mypy app/

# Format code
make format-backend
# Or: black app/ tests/ && isort app/ tests/

# Run all quality checks
make lint-backend && make test-backend
```

#### Frontend Code Quality
```bash
# Analyze code
make analyze-frontend
# Or: cd flutter && flutter analyze

# Format code
make format-frontend
# Or: cd flutter && dart format .

# Run all quality checks
cd flutter && flutter analyze && flutter test
```

### Troubleshooting

#### Common Backend Issues

**Port Already in Use:**
```bash
# Find process using port 8000
netstat -tulpn | grep :8000
# Kill the process or change port in .env
```

**Database Connection Failed:**
- Verify DATABASE_URL in .env
- Ensure PostgreSQL is running: `pg_isready -h localhost -p 5432`
- Check database exists: `psql -l`

**Import Errors:**
```bash
# Reinstall dependencies
pip install -e .[dev] --force-reinstall
```

**Model Download Issues:**
- Check internet connection
- Verify Hugging Face access (if using external models)
- Use local models for offline operation

#### Common Frontend Issues

**Flutter Doctor Issues:**
```bash
flutter doctor --android-licenses  # Android setup
flutter doctor --ios-licenses      # iOS setup
```

**Build Failures:**
```bash
# Clean and rebuild
cd flutter && flutter clean && flutter pub get && flutter build
```

**Hot Reload Not Working:**
- Restart development server
- Check for syntax errors in console
- Clear IDE cache

#### Docker Issues

**Container Won't Start:**
```bash
# Check logs
docker-compose logs backend

# Rebuild without cache
docker-compose build --no-cache
```

**Permission Denied:**
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
```

**Port Conflicts:**
```bash
# Change ports in docker-compose.yml
# Or stop conflicting services
```

#### Performance Issues

**Slow Analysis:**
- Enable GPU acceleration (CUDA for PyTorch)
- Use smaller models for testing
- Increase RAM allocation

**UI Freezes:**
- Check for infinite loops in state management
- Monitor memory usage
- Enable Flutter DevTools

#### Getting Help

1. **Check Documentation:**
   - [`docs/README.md`](docs/README.md) - Complete technical documentation
   - Individual module docs in [`docs/modules/`](docs/modules/)

2. **Debug Mode:**
   - Enable DEBUG=True in .env
   - Check application logs
   - Use browser DevTools for frontend

3. **Community Support:**
   - Create GitHub issue with full error logs
   - Include system information and reproduction steps

### Next Steps

Once everything is running:
1. Visit http://localhost:8000/docs for API documentation
2. Upload a sample script (PDF/DOCX) for testing
3. Review analysis results and provide feedback
4. Check [`docs/architecture.md`](docs/architecture.md) for advanced configuration

## 📖 Usage Guide

### Basic Workflow

1. **Launch Application**
   ```bash
   # Start backend
   uvicorn app.main:app --host 0.0.0.0 --port 8000

   # Serve Flutter web app (or run native)
   cd flutter && flutter run -d chrome
   ```

2. **Upload Script**
   - Drag & drop PDF/DOCX file
   - Optional: Specify target rating (0+/6+/12+/16+/18+)
   - Select analysis model profile (fast/accurate/balanced)

3. **Analysis Process**
   - Real-time progress updates via WebSocket
   - Automatic scene segmentation and classification
   - RAG-enhanced justifications with legal citations

4. **Review Results**
   - Interactive timeline with color-coded violations
   - Category breakdown with severity indicators
   - Detailed scene-by-scene analysis

5. **Provide Feedback**
   - Mark false positives (automatically ignored in re-rating)
   - Add missed violations
   - Edit scene text for re-analysis

6. **Export Report**
   - Download PDF/DOCX report
   - JSON data for integration
   - Includes legal citations and recommendations

### Advanced Features

#### Target Rating Analysis
Specify desired rating to identify content that prevents achieving target:
```bash
curl -X POST http://localhost:8000/analyze \
  -F "file=@script.pdf" \
  -F "target_rating=12+"
```

#### Interactive Editing
Modify problematic scenes and instantly re-analyze:
- Direct text editing in Flutter UI
- Automatic diff detection
- Incremental re-classification

#### History Management
- Version comparison between analyses
- Correction tracking over time
- Bulk export of analysis history

## 📚 Module Documentation

Detailed technical specifications for each system component:

### Core Processing Pipeline
1. **[Document Parser](docs/modules/document_parser.md)** - PDF/DOCX extraction with structure preservation
2. **[Scene Segmenter](docs/modules/scene_segmenter.md)** - Intelligent screenplay segmentation
3. **[Rule-Based Filter](docs/modules/rule_based_filter.md)** - Fast pre-screening for violations
4. **[LLM Classifier](docs/modules/llm_classifier.md)** - AI content classification with RAG augmentation
5. **[Rating Engine](docs/modules/rating_engine.md)** - FZ-436 compliant rating calculation

### Output Generation
6. **[Justification Builder](docs/modules/justification_builder.md)** - Detailed explanations with citations
7. **[Report Generator](docs/modules/report_generator.md)** - Multi-format report creation
8. **[History Manager](docs/modules/history_manager.md)** - Analysis versioning and audit trails

### Advanced Features
9. **[RAG Orchestrator](docs/modules/rag_orchestrator.md)** - Vector database and retrieval management
10. **[Feedback Processor](docs/modules/feedback_processor.md)** - User correction integration
11. **[Flutter UI](docs/modules/flutter_ui.md)** - Cross-platform user interface

## 🤝 Contributing

### Development Setup
1. Follow the architecture guidelines in [`docs/architecture.md`](docs/architecture.md)
2. Implement new features using Clean Architecture principles
3. Add comprehensive tests for all modules
4. Update documentation for any architectural changes

### Code Standards
- **Python**: PEP 8 with type hints, async/await patterns
- **Flutter**: Effective Dart guidelines, Riverpod for state management
- **Documentation**: Clear module interfaces, Mermaid diagrams for workflows
- **Testing**: Unit tests + integration tests, focus on offline operation

### Pull Request Process
1. Create feature branch from `develop`
2. Implement with comprehensive tests
3. Update relevant documentation
4. Ensure offline functionality remains intact
5. Request review from architecture team

## 🗺️ Roadmap

### Phase 1: MVP (Current)
- ✅ Core analysis pipeline (parser → classifier → rating)
- ✅ Basic Flutter UI with timeline visualization
- ✅ RAG integration with legal corpus
- ✅ PDF/DOCX report generation
- ✅ SQLite history management

### Phase 2: Enhanced Features (Q2 2025)
- 🔄 Advanced scene editor with collaborative features
- 🔄 Real-time multi-user analysis sessions
- 🔄 Enhanced RAG with user feedback learning
- 🔄 Mobile app optimization
- 🔄 Bulk analysis capabilities

### Phase 3: Enterprise Features (Q3 2025)
- 📋 Integration APIs for production pipelines
- 📋 Advanced analytics dashboard
- 📋 Custom rule sets for different markets
- 📋 Automated compliance workflows
- 📋 Multi-language script support

### Phase 4: AI Advancement (Q4 2025)
- 🤖 Fine-tuned models for Russian content
- 🤖 Advanced multimodal analysis (images, audio cues)
- 🤖 Predictive rating suggestions
- 🤖 Automated content modification recommendations

## 📄 License

All rights reserved. This project contains proprietary intellectual property for automated content rating systems. Redistribution and commercial use require explicit permission from the copyright holder.

## 📞 Support

For technical documentation, see [`docs/README.md`](docs/README.md). For implementation details, refer to individual module documentation linked above.

