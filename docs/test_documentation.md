# ScriptRating Test Documentation

This document provides a comprehensive guide to the testing infrastructure, organization, and strategies used in the ScriptRating project. Both backend and frontend testing suites are organized for clarity, maintainability, and comprehensive coverage.

## 🧪 Testing Overview

The ScriptRating project implements a multi-layered testing strategy:

- **Unit Tests**: Individual component and function testing
- **Integration Tests**: End-to-end workflow and module interaction testing
- **Mock Data & Fixtures**: Reusable test data for consistent testing
- **Continuous Integration**: Automated testing pipeline integration

## 📁 Test Organization Structure

### Backend Testing (`tests/`)

The backend test suite is organized following Clean Architecture principles, with clear separation between unit tests, integration tests, and test utilities.

```
tests/
├── 📄 __init__.py                     # Package initialization
├── 📁 fixtures/                       # Reusable test data and mocks
│   ├── 📄 mock_analysis_result.json   # Mock analysis response data
│   ├── 📄 sample_criteria.json        # Sample FZ-436 criteria data
│   └── 📄 sample_script.txt           # Sample script content for testing
├── 📁 integration/                    # End-to-end and integration tests
│   ├── 📄 category_integration_test.py      # Category workflow testing
│   ├── 📄 test_analysis_workflow.py         # Complete analysis pipeline testing
│   └── 📄 test_openrouter_endpoints.py      # External API integration tests
└── 📁 unit/                           # Unit tests for individual components
    ├── 📄 category_naming_test.py           # Category naming logic tests
    └── 📄 test_health.py                    # Health check endpoint tests
```

### Frontend Testing (`flutter/test/`)

The Flutter test suite follows Flutter's recommended testing structure with unit tests, widget tests, and integration tests.

```
flutter/test/
├── 📁 integration/                    # End-to-end Flutter app testing
│   ├── 📄 llm_integration_test.dart          # LLM service integration testing
│   └── 📄 provider_switching_integration_test.dart # State management testing
├── 📁 unit/                           # Unit and widget tests
│   ├── 📁 services/                   # Service layer testing
│   │   ├── 📄 api_service_test.dart          # API communication testing
│   │   └── 📄 llm_service_test.dart          # LLM service testing
│   └── 📁 widgets/                    # Widget and UI component testing
│       ├── 📄 scene_detail_widget_test.dart       # Scene detail UI testing
│       ├── 📄 script_list_item_test.dart          # Script list component testing
│       ├── 📄 settings_panel_dropdown_fix_test.dart # UI interaction testing
│       ├── 📄 test_chat_widget_layout_test.dart    # Layout testing
│       └── 📄 test_chat_widget_test.dart           # Chat widget functionality
```

## 🔧 Test Categories & Strategies

### Backend Test Categories

#### Unit Tests (`tests/unit/`)
**Purpose**: Test individual functions, methods, and small components in isolation.

**Coverage Areas**:
- **Business Logic**: Rating calculations, content classification rules
- **Data Models**: Input validation, transformation functions
- **Utility Functions**: File processing helpers, text normalization
- **Health Checks**: System status verification endpoints

**Example Usage**:
```bash
# Run all unit tests
pytest tests/unit/ -v

# Run specific unit test
pytest tests/unit/test_health.py -v

# Run with coverage
pytest tests/unit/ --cov=app --cov-report=html
```

#### Integration Tests (`tests/integration/`)
**Purpose**: Test complete workflows and module interactions to ensure system components work together correctly.

**Coverage Areas**:
- **Analysis Pipeline**: Full script analysis from upload to rating
- **Category Processing**: End-to-end content categorization
- **External APIs**: OpenRouter integration, model communication
- **Database Operations**: CRUD operations, data persistence
- **File Processing**: Multi-format document handling

**Example Usage**:
```bash
# Run all integration tests
pytest tests/integration/ -v

# Run specific integration test
pytest tests/integration/test_analysis_workflow.py -v

# Run with detailed output
pytest tests/integration/ -v --tb=short
```

#### Test Fixtures (`tests/fixtures/`)
**Purpose**: Provide consistent, reusable test data for all test categories.

**Available Fixtures**:
- **mock_analysis_result.json**: Simulated analysis response with all categories
- **sample_criteria.json**: FZ-436 rating criteria for testing compliance logic
- **sample_script.txt**: Standardized script content for testing segmentation

**Usage in Tests**:
```python
import json
import pytest

@pytest.fixture
def mock_analysis_result():
    with open('tests/fixtures/mock_analysis_result.json') as f:
        return json.load(f)

def test_rating_calculation(mock_analysis_result):
    # Use fixture data for testing
    assert mock_analysis_result['rating'] == '12+'
```

### Frontend Test Categories

#### Service Tests (`flutter/test/unit/services/`)
**Purpose**: Test business logic and data processing in the Flutter app.

**Coverage Areas**:
- **API Communication**: HTTP client functionality, error handling
- **LLM Service**: Model integration, response processing
- **Data Models**: Serialization, validation, transformation
- **Local Storage**: User preferences, analysis history

#### Widget Tests (`flutter/test/unit/widgets/`)
**Purpose**: Test individual UI components and their interactions.

**Coverage Areas**:
- **Component Rendering**: UI element display and styling
- **User Interactions**: Button clicks, form inputs, navigation
- **State Management**: Widget state changes, provider interactions
- **Layout Testing**: Responsive design, screen size adaptation

#### Integration Tests (`flutter/test/integration/`)
**Purpose**: Test complete user workflows and app functionality.

**Coverage Areas**:
- **User Journeys**: Upload → Analysis → Results → Feedback
- **Provider State Management**: Riverpod state consistency
- **Real-time Features**: Live updates, WebSocket communication
- **Cross-platform Compatibility**: iOS, Android, Web consistency

## 🚀 Running Tests

### Backend Testing Commands

#### Quick Test Execution
```bash
# Run all tests
make test-backend

# Run with coverage report
pytest tests/ --cov=app --cov-report=html --cov-report=term

# Run specific test categories
pytest tests/unit/ -v                    # Unit tests only
pytest tests/integration/ -v             # Integration tests only
```

#### Detailed Testing
```bash
# Run with verbose output
pytest tests/ -v --tb=long

# Run and stop on first failure
pytest tests/ -x

# Run tests matching pattern
pytest tests/ -k "test_analysis"         # Tests with 'analysis' in name

# Run specific file
pytest tests/unit/test_health.py -v
```

### Frontend Testing Commands

#### Flutter Test Commands
```bash
cd flutter

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/services/llm_service_test.dart

# Run integration tests
flutter test integration_test/

# Run tests with verbose output
flutter test -v
```

#### Advanced Flutter Testing
```bash
# Run tests on specific device
flutter test -d chrome

# Run tests with specific tags
flutter test --tags=unit

# Generate test report
flutter test --machine > test_results.json
```

## 📊 Test Coverage & Quality

### Coverage Goals
- **Backend**: 90%+ code coverage target
- **Frontend**: 80%+ widget coverage target
- **Critical Paths**: 100% coverage for rating calculations and compliance logic

### Coverage Reports
```bash
# Backend coverage report
pytest tests/ --cov=app --cov-report=html
# Open htmlcov/index.html in browser

# Frontend coverage report
cd flutter && flutter test --coverage
# Open coverage/html/index.html in browser
```

### Quality Metrics
- **Test Maintainability**: Tests should be self-documenting and easy to update
- **Test Reliability**: Tests should consistently pass/fail for the same code
- **Test Performance**: Full test suite should complete within 5 minutes
- **Test Isolation**: Tests should not depend on each other or external state

## 🔍 Test Data Management

### Mock Data Strategy
- **Realistic Scenarios**: Test data reflects actual production use cases
- **Edge Cases**: Include boundary conditions and error scenarios
- **Consistent Format**: All fixtures follow standardized JSON/text formats
- **Version Control**: Test data is tracked alongside test code

### Test Environment Setup
```python
# Example pytest fixture for database setup
@pytest.fixture(scope="session")
def test_db():
    """Create test database for integration tests"""
    db = create_test_database()
    yield db
    db.cleanup()

# Example Flutter test setup
void main() {
  group('LLM Service Tests', () {
    late LLMService llmService;
    
    setUp(() {
      llmService = LLMService();
    });
    
    testWidgets('should process analysis request', (tester) async {
      // Test implementation
    });
  });
}
```

## 🛠️ Writing Effective Tests

### Test Naming Conventions
- **Backend**: `test_[functionality]_[expected_behavior].py`
- **Frontend**: `[Component/Service]_[scenario]_test.dart`

### Test Structure (AAA Pattern)
1. **Arrange**: Set up test data and conditions
2. **Act**: Execute the functionality being tested
3. **Assert**: Verify expected outcomes

### Best Practices

#### For Backend Tests
```python
def test_rating_engine_calculates_correct_age_rating():
    # Arrange
    analysis_result = create_mock_analysis(violence="moderate", sexual="none")
    rating_engine = RatingEngine()
    
    # Act
    final_rating = rating_engine.calculate_rating(analysis_result)
    
    # Assert
    assert final_rating == "12+"
    assert final_rating.severity_score > 0
```

#### For Flutter Tests
```dart
testWidgets('should display analysis results correctly', (tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(
      home: AnalysisResultWidget(results: mockResults),
    ),
  );
  
  // Act
  await tester.tap(find.text('View Details'));
  
  // Assert
  expect(find.byType(SceneDetailWidget), findsOneWidget);
});
```

## 🔄 Continuous Integration

### Automated Testing Pipeline
Tests are automatically executed on:
- **Pull Request Creation**: Full test suite runs
- **Code Commits**: Targeted tests for changed files
- **Nightly Builds**: Comprehensive test coverage analysis

### Test Reporting
- **Real-time Results**: Immediate feedback on test execution
- **Coverage Reports**: Automated generation and tracking
- **Failure Analysis**: Detailed logs for debugging failed tests

## 📚 Testing Resources

### Documentation References
- **[Architecture Documentation](architecture.md)** - Understanding system components for better testing
- **[Module Documentation](../modules/)** - Detailed specifications for testing interfaces
- **[Project README](../README.md)** - Overall project structure and setup

### External Resources
- [pytest Documentation](https://docs.pytest.org/) - Python testing framework
- [Flutter Testing Guide](https://docs.flutter.dev/testing) - Flutter testing best practices
- [Clean Architecture Testing](https://blog.cleancoder.com/uncle-bob/2012/05/15/OpenClosedPrinciple.html) - Testing in Clean Architecture

## 🐛 Debugging Failed Tests

### Common Issues & Solutions

#### Backend Test Failures
```bash
# Debug specific test failure
pytest tests/unit/test_health.py -v -s

# Check for test isolation issues
pytest tests/ --cache-clear

# Verify test environment setup
python -m pytest tests/ --collect-only
```

#### Frontend Test Failures
```bash
# Debug Flutter test
cd flutter && flutter test -v

# Check widget tree for rendering issues
flutter test --debug

# Verify test device setup
flutter doctor
```

### Test Debugging Tips
1. **Check Dependencies**: Ensure all required services are available
2. **Verify Test Data**: Confirm fixtures are loading correctly
3. **Review Logs**: Detailed error messages often contain solution hints
4. **Isolate Issues**: Run individual tests to identify scope of problems

This comprehensive testing documentation ensures all team members can effectively write, run, and maintain tests for the ScriptRating project, contributing to code quality and system reliability.