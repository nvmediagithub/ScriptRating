import 'package:dio/dio.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/llm_models.dart';
import '../models/llm_provider.dart';

class LlmService {
  final Dio _dio;

  LlmService(this._dio) {
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = 'http://localhost:8000/api/v1';
    }
    _dio.options.headers['Content-Type'] ??= 'application/json';
  }

  // Configuration Management
  Future<LLMConfigResponse> getConfig() async {
    final response = await _dio.get('/llm/config');
    return LLMConfigResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Alias for getConfig() to maintain compatibility with existing code
  Future<LLMConfigResponse> getLLMConfig() async {
    return getConfig();
  }

  Future<LLMConfigResponse> updateConfig({
    LLMProvider? provider,
    String? modelName,
    LLMProviderSettings? settings,
    LLMModelConfig? modelConfig,
  }) async {
    final requestData = <String, dynamic>{};

    if (provider != null) {
      requestData['provider'] = provider.name;
    }

    if (modelName != null) {
      requestData['model_name'] = modelName;
    }

    if (settings != null) {
      requestData['settings'] = settings.toJson();
    }

    if (modelConfig != null) {
      requestData['llm_model_config'] = modelConfig.toJson();
    }

    final response = await _dio.put('/llm/config', data: requestData);
    return LLMConfigResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // Provider Management
  Future<Map<LLMProvider, LLMProviderSettings>> getLLMProviders() async {
    try {
      final config = await getConfig();
      return config.providers;
    } catch (e) {
      throw Exception('Failed to get LLM providers: $e');
    }
  }

  Future<LLMProvider> getActiveProvider() async {
    try {
      final config = await getConfig();
      return config.activeProvider;
    } catch (e) {
      throw Exception('Failed to get active provider: $e');
    }
  }

  Future<void> setActiveProvider(LLMProvider provider) async {
    try {
      await updateConfig(provider: provider);
    } catch (e) {
      throw Exception('Failed to set active provider: $e');
    }
  }

  // Model Management
  Future<Map<String, LLMModelConfig>> getLLMModels() async {
    try {
      final config = await getConfig();
      return config.models;
    } catch (e) {
      throw Exception('Failed to get LLM models: $e');
    }
  }

  Future<String> getActiveModel() async {
    try {
      final config = await getConfig();
      return config.activeModel;
    } catch (e) {
      throw Exception('Failed to get active model: $e');
    }
  }

  Future<void> setActiveModel(String modelName, {LLMProvider? provider}) async {
    try {
      await updateConfig(modelName: modelName, provider: provider);
    } catch (e) {
      throw Exception('Failed to set active model: $e');
    }
  }

  List<String> getModelsByProvider(LLMProvider provider, Map<String, LLMModelConfig> models) {
    return models.entries
        .where((entry) => entry.value.provider == provider)
        .map((entry) => entry.key)
        .toList();
  }

  // Status Monitoring
  Future<LLMStatusResponse> getProviderStatus(LLMProvider provider) async {
    try {
      final response = await _dio.get('/llm/status/${provider.name}');
      return LLMStatusResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception('Failed to get provider status for ${provider.name}: $e');
    }
  }

  Future<List<LLMStatusResponse>> getStatuses() async {
    try {
      final response = await _dio.get('/llm/status');
      final list = response.data as List<dynamic>;
      return list
          .map((item) => LLMStatusResponse.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to get all providers status: $e');
    }
  }

  Future<List<LLMStatusResponse>> getAllProvidersStatus() async {
    return getStatuses();
  }

  Future<Map<LLMProvider, bool>> checkProvidersHealth() async {
    try {
      final statuses = await getAllProvidersStatus();
      return {for (final status in statuses) status.provider: status.healthy};
    } catch (e) {
      throw Exception('Failed to check providers health: $e');
    }
  }

  // Local Models Management
  Future<LocalModelsListResponse> getLocalModels() async {
    final response = await _dio.get('/llm/local/models');
    return LocalModelsListResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<LocalModelInfo> loadLocalModel(String modelName) async {
    final response = await _dio.post('/llm/local/models/load', data: {'model_name': modelName});
    return LocalModelInfo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<LocalModelInfo> unloadLocalModel(String modelName) async {
    final response = await _dio.post('/llm/local/models/unload', data: {'model_name': modelName});
    return LocalModelInfo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // OpenRouter Specific Operations
  Future<OpenRouterStatusResponse> getOpenRouterStatus() async {
    final response = await _dio.get('/llm/openrouter/status');
    return OpenRouterStatusResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<OpenRouterModelsListResponse> getOpenRouterModels() async {
    final response = await _dio.get('/llm/openrouter/models');
    return OpenRouterModelsListResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<LLMConfigResponse> switchMode(LLMProvider provider, String modelName) async {
    final response = await _dio.put(
      '/llm/config/mode',
      queryParameters: {'provider': provider.name, 'model_name': modelName},
    );
    return LLMConfigResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // Health and Performance
  Future<LLMHealthSummary> getHealthSummary() async {
    final response = await _dio.get('/llm/config/health');
    return LLMHealthSummary.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<PerformanceReportResponse>> getPerformanceReports() async {
    final response = await _dio.get('/llm/performance');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => PerformanceReportResponse.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getProviderMetrics(LLMProvider provider) async {
    try {
      final response = await _dio.get('/llm/performance/${provider.name}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get provider metrics for ${provider.name}: $e');
    }
  }

  Future<Map<String, dynamic>> getAllProvidersMetrics() async {
    try {
      final response = await _dio.get('/llm/performance');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get all providers metrics: $e');
    }
  }

  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await _dio.get('/llm/config/health');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get system health: $e');
    }
  }

  // Testing and Validation (keeping original functionality)
  Future<LLMTestResponse> testLLM(String prompt, {String? modelName}) async {
    try {
      final requestData = {'prompt': prompt, if (modelName != null) 'model_name': modelName};

      final response = await _dio.post('/llm/test', data: requestData);
      return LLMTestResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to test LLM: $e');
    }
  }

  // Provider Settings Management (keeping original functionality)
  Future<void> updateProviderSettings(LLMProviderSettings settings) async {
    try {
      await updateConfig(settings: settings);
    } catch (e) {
      throw Exception('Failed to update provider settings: $e');
    }
  }

  Future<void> configureOpenRouter({
    String? apiKey,
    String? baseUrl,
    int? timeout,
    int? maxRetries,
  }) async {
    try {
      final settings = LLMProviderSettings(
        provider: LLMProvider.openrouter,
        apiKey: apiKey,
        baseUrl: baseUrl,
        timeout: timeout ?? 30,
        maxRetries: maxRetries ?? 3,
      );

      await updateProviderSettings(settings);
    } catch (e) {
      throw Exception('Failed to configure OpenRouter: $e');
    }
  }

  // Connection Testing (keeping original functionality)
  Future<bool> testConnection(LLMProvider provider) async {
    try {
      final status = await getProviderStatus(provider);
      return status.healthy;
    } catch (e) {
      return false;
    }
  }

  Future<bool> testOpenRouterConnection() async {
    try {
      final status = await getOpenRouterStatus();
      return status.connected;
    } catch (e) {
      return false;
    }
  }

  // Initialize and Cleanup (keeping original functionality)
  Future<void> initialize() async {
    // Initialize the LLM service
    // This could include loading saved settings, checking connectivity, etc.
  }

  Future<void> dispose() async {
    // Cleanup resources if needed
  }

  // Chat-specific methods
  Future<ChatSession> createChatSession({
    required String title,
    required LLMProvider provider,
    required String model,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/sessions',
        data: {
          'title': title,
          'llm_provider': provider.name,
          'llm_model': model,
          if (settings != null) 'settings': settings,
        },
      );
      return ChatSession.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create chat session: $e');
    }
  }

  Future<List<ChatSession>> getChatSessions() async {
    try {
      final response = await _dio.get('/chat/sessions');
      final list = response.data as List<dynamic>;
      return list.map((item) => ChatSession.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to get chat sessions: $e');
    }
  }

  Future<ChatSession> getChatSession(String sessionId) async {
    try {
      final response = await _dio.get('/chat/sessions/$sessionId');
      return ChatSession.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get chat session: $e');
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    try {
      await _dio.delete('/chat/sessions/$sessionId');
    } on DioException catch (e) {
      throw Exception('Failed to delete chat session: $e');
    }
  }

  Future<List<ChatMessage>> getChatMessages(
    String sessionId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/sessions/$sessionId/messages',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final list = response.data as List<dynamic>;
      return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to get chat messages: $e');
    }
  }

  Future<ChatMessage> sendChatMessage(String sessionId, String content) async {
    try {
      final response = await _dio.post(
        '/chat/sessions/$sessionId/messages',
        data: {'content': content},
      );
      return ChatMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to send chat message: $e');
    }
  }

  // Mock implementations for development/testing
  // These will be replaced with real backend API calls later
  Future<List<ChatSession>> mockGetChatSessions() async {
    return [
      ChatSession(
        id: 'session-1',
        title: 'Test Chat Session',
        userId: 'user-1',
        llmProvider: LLMProvider.local,
        llmModel: 'test-model',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
        messageCount: 3,
      ),
      ChatSession(
        id: 'session-2',
        title: 'OpenRouter Chat',
        userId: 'user-1',
        llmProvider: LLMProvider.openrouter,
        llmModel: 'gpt-3.5-turbo',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        messageCount: 5,
      ),
    ];
  }

  Future<List<ChatMessage>> mockGetChatMessages(String sessionId) async {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'msg-1',
        sessionId: sessionId,
        role: MessageRole.user,
        content: 'Hello, how are you?',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        id: 'msg-2',
        sessionId: sessionId,
        role: MessageRole.assistant,
        content: 'I am doing well, thank you for asking! How can I help you today?',
        createdAt: now.subtract(const Duration(minutes: 29)),
        llmProvider: 'local',
        llmModel: 'test-model',
        responseTimeMs: 1500,
      ),
      ChatMessage(
        id: 'msg-3',
        sessionId: sessionId,
        role: MessageRole.user,
        content: 'Can you help me with a Python script?',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];
  }
}
