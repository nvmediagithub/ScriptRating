# LLM Components Full Architecture Documentation for SecurityOrchestrator

## 1. SYSTEM ARCHITECTURE OVERVIEW

### 1.1 High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│  LLM Dashboard Screen (UI Layer)                                │
│  ├── Provider Configuration Card                                │
│  ├── Model Selection Card                                       │
│  ├── Status Monitoring Card                                     │
│  ├── Test Interface Card                                        │
│  └── Overview Card                                              │
├─────────────────────────────────────────────────────────────────┤
│  State Management (Riverpod)                                    │
│  ├── LlmDashboardProvider (StateNotifier)                       │
│  ├── LlmServiceProvider (Service Injection)                     │
│  └── AsyncValue State Handling                                  │
├─────────────────────────────────────────────────────────────────┤
│  Service Layer                                                  │
│  ├── LlmService (HTTP Client + Business Logic)                 │
│  ├── ApiService (General API Operations)                        │
│  └── Dio HTTP Client (Network Layer)                            │
├─────────────────────────────────────────────────────────────────┤
│  Data Models                                                    │
│  ├── LLMConfigResponse, LLMStatusResponse                       │
│  ├── LLMModelConfig, LLMProviderSettings                        │
│  ├── LocalModelInfo, PerformanceMetrics                         │
│  └── LLMProvider Enum                                           │
├─────────────────────────────────────────────────────────────────┤
│  Backend API (FastAPI)                                          │
│  ├── /api/v1/llm/config                                         │
│  ├── /api/v1/llm/status                                         │
│  ├── /api/v1/llm/local/models                                   │
│  ├── /api/v1/llm/openrouter/*                                   │
│  └── /api/v1/llm/test                                           │
└─────────────────────────────────────────────────────────────────┘
```

## 2. DETAILED COMPONENT ANALYSIS

### 2.1 LLM Service Implementation
**File**: `flutter/lib/services/llm_service.dart` (334 lines)

**Core Architecture**:
- **HTTP Client**: Dio with baseUrl 'http://localhost:8000/api/v1'
- **Error Handling**: Comprehensive exception handling with user-friendly messages
- **Provider Support**: Local and OpenRouter providers
- **Model Management**: Load/unload local models, configure parameters
- **Monitoring**: Status checking, health summaries, performance metrics

**Key Methods**:
```dart
// Configuration Management
Future<LLMConfigResponse> getConfig() // GET /llm/config
Future<LLMConfigResponse> updateConfig(...) // PUT /llm/config

// Provider Management
Future<Map<LLMProvider, LLMProviderSettings>> getLLMProviders()
Future<LLMProvider> getActiveProvider()
Future<void> setActiveProvider(LLMProvider provider)

// Model Management  
Future<Map<String, LLMModelConfig>> getLLMModels()
Future<String> getActiveModel()
Future<void> setActiveModel(String modelName)

// Local Models
Future<LocalModelsListResponse> getLocalModels()
Future<LocalModelInfo> loadLocalModel(String modelName)
Future<LocalModelInfo> unloadLocalModel(String modelName)

// Status & Testing
Future<LLMStatusResponse> getProviderStatus(LLMProvider provider)
Future<LLMTestResponse> testLLM(String prompt)
Future<LLMHealthSummary> getHealthSummary()
```

### 2.2 Data Models Architecture
**Files**: `llm_models.dart`, `llm_provider.dart`, `llm_dashboard_state.dart`

**Model Hierarchy**:
```dart
enum LLMProvider {
  local('local'),
  openrouter('openrouter');
}

class LLMProviderSettings {
  final LLMProvider provider;
  final String? apiKey;
  final String? baseUrl;
  final int timeout;
  final int maxRetries;
}

class LLMModelConfig {
  final String modelName;
  final LLMProvider provider;
  final int contextWindow;
  final int maxTokens;
  final double temperature;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
}

class LLMConfigResponse {
  final LLMProvider activeProvider;
  final String activeModel;
  final Map<LLMProvider, LLMProviderSettings> providers;
  final Map<String, LLMModelConfig> models;
}
```

### 2.3 State Management with Riverpod
**File**: `flutter/lib/providers/llm_dashboard_provider.dart`

**Architecture**:
```dart
final llmDashboardProvider = 
    StateNotifierProvider<LlmDashboardNotifier, AsyncValue<LlmDashboardState>>(
      (ref) => LlmDashboardNotifier(ref.watch(llmServiceProvider))
    );

class LlmDashboardNotifier extends StateNotifier<AsyncValue<LlmDashboardState>> {
  final LlmService _service;
  
  // Methods: refresh(), switchActiveModel(), loadLocalModel(), unloadLocalModel()
}
```

**Features**:
- AsyncValue for loading/error states
- Optimistic updates with rollback
- Service dependency injection
- Immutable state updates

### 2.4 UI Components Structure
**File**: `flutter/lib/screens/llm_dashboard_screen.dart` (903 lines)

**Component Layout**:
```
LlmDashboardScreen
├── AppBar (Title + Refresh Button)
├── Loading/Error States
└── Main Content (SingleChildScrollView)
    ├── Overview Card (System Status)
    ├── Provider Configuration Card
    │   ├── OpenRouter Configuration (Expandable)
    │   │   ├── Status Indicator
    │   │   ├── API Key Input (with validation)
    │   │   ├── Base URL Input
    │   │   ├── Configure Button
    │   │   └── Help Link
    │   └── Provider List (Local + OpenRouter)
    ├── Model Selection Card
    │   ├── Model Dropdown
    │   └── Configuration Display
    ├── Status Monitoring Card
    │   └── Provider Status List
    └── Test Interface Card
        ├── Prompt Input Field
        ├── Test Button
        └── Response Display
```

**UI Features**:
- Card-based responsive layout
- Real-time status indicators (green/orange/red)
- Form validation with visual feedback
- Loading states with progress indicators
- Error messages with recovery actions
- Provider-specific configuration flows

## 3. API INTEGRATION PATTERNS

### 3.1 HTTP Client Configuration
```dart
class LlmService {
  final Dio _dio;
  
  LlmService(this._dio) {
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = 'http://localhost:8000/api/v1';
    }
    _dio.options.headers['Content-Type'] ??= 'application/json';
  }
}
```

### 3.2 API Endpoints Reference
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/llm/config` | Get current LLM configuration |
| PUT | `/llm/config` | Update LLM configuration |
| GET | `/llm/status` | Get all providers status |
| GET | `/llm/status/{provider}` | Get specific provider status |
| GET | `/llm/local/models` | List available local models |
| POST | `/llm/local/models/load` | Load a local model |
| POST | `/llm/local/models/unload` | Unload a local model |
| GET | `/llm/openrouter/status` | OpenRouter connection status |
| GET | `/llm/openrouter/models` | List OpenRouter models |
| POST | `/llm/test` | Test LLM with prompt |
| GET | `/llm/config/health` | System health summary |

### 3.3 Error Handling Strategy
**Hierarchical Approach**:
1. **Network Level**: DioException with retry logic
2. **API Level**: HTTP status interpretation
3. **Business Level**: Context-specific messages
4. **UI Level**: User-friendly displays with actions

## 4. IMPLEMENTATION FOR SECURITYORCHESTRATOR

### 4.1 File Structure Replication
```
security_orchestrator_frontend/lib/
├── services/
│   ├── llm_service.dart (adapt from ScriptRating)
│   └── api_service.dart (extend existing)
├── models/
│   ├── llm_models.dart
│   ├── llm_provider.dart
│   └── llm_dashboard_state.dart
├── providers/
│   └── llm_dashboard_provider.dart
├── screens/
│   └── llm_dashboard_screen.dart
└── main.dart (add LLM routes)
```

### 4.2 Dependencies Required
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  dio: ^5.3.2
  go_router: ^12.1.3
  equatable: ^2.0.5
```

### 4.3 SecurityOrchestrator Adaptations

**Extended LLM Provider Enum**:
```dart
enum LLMProvider {
  local('local'),
  openrouter('openrouter'),
  security_analyzer('security_analyzer'), // SecurityOrchestrator specific
  threat_detector('threat_detector'),
  vulnerability_scanner('vulnerability_scanner');
}
```

**Security-Enhanced Configuration**:
```dart
class SecurityOrchestratorLLMConfig extends LLMConfigResponse {
  final String securityProfile;
  final List<String> securityPolicies;
  final bool auditEnabled;
  final bool complianceMode;
  
  // Extended configuration for SecurityOrchestrator needs
}
```

## 5. MIGRATION CHECKLIST

### 5.1 Pre-Migration Tasks
- [ ] Analyze existing SecurityOrchestrator architecture
- [ ] Identify integration points with current services
- [ ] Plan dependency additions to pubspec.yaml
- [ ] Design SecurityOrchestrator-specific model adaptations

### 5.2 Core Migration Steps
- [ ] Copy and adapt `llm_service.dart` for SecurityOrchestrator API
- [ ] Create SecurityOrchestrator-specific data models
- [ ] Integrate with existing state management (if different from Riverpod)
- [ ] Create adapted `llm_dashboard_screen.dart`
- [ ] Add LLM routes to existing navigation system
- [ ] Configure service locator/dependency injection

### 5.3 SecurityOrchestrator Enhancements
- [ ] Add security-specific LLM providers
- [ ] Implement audit logging for LLM usage
- [ ] Add compliance mode configuration
- [ ] Integrate with SecurityOrchestrator's security policies
- [ ] Add threat detection LLM integration

### 5.4 Testing & Validation
- [ ] Unit tests for service layer
- [ ] Integration tests for API calls
- [ ] UI tests for dashboard functionality
- [ ] Security validation tests
- [ ] Performance testing with multiple providers

## 6. CODE TEMPLATES FOR SECURITYORCHESTRATOR

### 6.1 Service Integration Template
```dart
class SecurityOrchestratorLlmService extends LlmService {
  SecurityOrchestratorLlmService(Dio dio) : super(dio) {
    // SecurityOrchestrator-specific configuration
    _dio.options.baseUrl = 'http://localhost:8080/api/v1';
  }
  
  // Add SecurityOrchestrator-specific methods
  Future<void> configureSecurityAnalyzer({
    required String apiKey,
    required String modelName,
    SecurityLevel securityLevel = SecurityLevel.medium,
  }) async {
    // Implementation for security analyzer configuration
  }
  
  Future<SecurityAnalysisResult> analyzeSecurityPrompt(String prompt) async {
    // Implementation for security-specific LLM analysis
  }
}
```

### 6.2 UI Component Template
```dart
class SecurityOrchestratorLlmDashboard extends StatelessWidget {
  const SecurityOrchestratorLlmDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security LLM Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
      body: const LlmDashboardScreen(), // Use adapted screen
    );
  }
}
```

## 7. CONCLUSION

The LLM management system in ScriptRating provides a production-ready, well-architected foundation for LLM integration. Key success factors for SecurityOrchestrator migration:

1. **Architectural Fidelity**: Maintain the clean separation of concerns
2. **State Management**: Preserve the Riverpod/AsyncValue pattern
3. **Error Handling**: Keep the comprehensive error handling strategy
4. **UI/UX Quality**: Retain the user-friendly interface patterns
5. **Security Enhancements**: Add SecurityOrchestrator-specific security features
6. **Testing Coverage**: Implement comprehensive testing strategy

The modular design ensures easy maintenance and extension for SecurityOrchestrator's specific requirements while maintaining compatibility with the proven patterns from ScriptRating.