import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/llm_models.dart';
import '../models/llm_provider.dart';

class LlmService {
  final Dio _dio;

  LlmService(this._dio) {
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = 'http://localhost:8000/api';
    }
    _dio.options.headers['Content-Type'] ??= 'application/json';
  }

  // Simplified Configuration Management
  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get('/llm/config');
    return response.data as Map<String, dynamic>;
  }

  /// Alias for getConfig() to maintain compatibility with existing code
  Future<Map<String, dynamic>> getLLMConfig() async {
    return getConfig();
  }

  Future<Map<String, dynamic>> updateConfig({String? provider, String? modelName}) async {
    final requestData = <String, dynamic>{};

    if (provider != null) {
      requestData['provider'] = provider;
    }

    if (modelName != null) {
      requestData['model_name'] = modelName;
    }

    final response = await _dio.put('/llm/config', data: requestData);
    return response.data as Map<String, dynamic>;
  }

  // Simplified Provider Management
  Future<Map<String, dynamic>> getLLMProviders() async {
    try {
      final config = await getConfig();
      return config['providers'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get LLM providers: $e');
    }
  }

  Future<String> getActiveProvider() async {
    try {
      final config = await getConfig();
      return config['active_provider'] as String;
    } catch (e) {
      throw Exception('Failed to get active provider: $e');
    }
  }

  Future<void> setActiveProvider(String provider) async {
    try {
      // Simple provider switch - will use default model for the provider
      await switchMode(provider);
    } catch (e) {
      throw Exception('Failed to set active provider: $e');
    }
  }

  // Simplified Model Management
  Future<Map<String, dynamic>> getLLMModels() async {
    try {
      final config = await getConfig();
      return config['models'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get LLM models: $e');
    }
  }

  Future<String> getActiveModel() async {
    try {
      final config = await getConfig();
      return config['active_model'] as String;
    } catch (e) {
      throw Exception('Failed to get active model: $e');
    }
  }

  Future<void> setActiveModel(String modelName, {String? provider}) async {
    try {
      await updateConfig(modelName: modelName, provider: provider);
    } catch (e) {
      throw Exception('Failed to set active model: $e');
    }
  }

  // Simplified Status Monitoring
  Future<Map<String, dynamic>> getProviderStatus(String provider) async {
    try {
      final response = await _dio.get('/llm/status/$provider');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get provider status for $provider: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStatuses() async {
    try {
      final response = await _dio.get('/llm/status');
      final list = response.data as List<dynamic>;
      return list.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw Exception('Failed to get all providers status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllProvidersStatus() async {
    return getStatuses();
  }

  Future<Map<String, bool>> checkProvidersHealth() async {
    try {
      final statuses = await getAllProvidersStatus();
      return {
        for (final status in statuses) status['provider'] as String: status['healthy'] as bool,
      };
    } catch (e) {
      throw Exception('Failed to check providers health: $e');
    }
  }

  // Simplified Local Models Management
  Future<Map<String, dynamic>> getLocalModels() async {
    final response = await _dio.get('/llm/local/models');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loadLocalModel(String modelName) async {
    final response = await _dio.post('/llm/local/models/load', data: {'model_name': modelName});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unloadLocalModel(String modelName) async {
    final response = await _dio.post('/llm/local/models/unload', data: {'model_name': modelName});
    return response.data as Map<String, dynamic>;
  }

  // Simplified OpenRouter Operations
  Future<Map<String, dynamic>> getOpenRouterStatus() async {
    final response = await _dio.get('/llm/openrouter/status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOpenRouterModels() async {
    try {
      // Get models and filter for OpenRouter
      final allModels = await getLLMModels();
      final openRouterModels = <String>[];

      for (final entry in allModels.entries) {
        final model = entry.value as Map<String, dynamic>;
        if (model['provider'] == 'openrouter') {
          openRouterModels.add(entry.key);
        }
      }

      return {'models': openRouterModels, 'total': openRouterModels.length};
    } catch (e) {
      // Fallback to empty response if models endpoint fails
      return {'models': <String>[], 'total': 0};
    }
  }

  Future<Map<String, dynamic>> switchMode(String provider, [String? modelName]) async {
    debugPrint('Switching LLM mode to provider: $provider, model: $modelName');
    final queryParameters = <String, String>{'provider': provider};
    if (modelName != null) {
      queryParameters['model_name'] = modelName;
    }

    final response = await _dio.put('/llm/config/mode', queryParameters: queryParameters);
    debugPrint('Switch response: ${response.data}');
    return response.data as Map<String, dynamic>;
  }

  // Simplified Health and Performance
  Future<Map<String, dynamic>> getHealthSummary() async {
    final response = await _dio.get('/llm/config/health');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await _dio.get('/llm/config/health');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get system health: $e');
    }
  }

  // Simplified Testing
  Future<Map<String, dynamic>> testLLM(String prompt, {String? modelName}) async {
    try {
      final requestData = {'prompt': prompt, if (modelName != null) 'model_name': modelName};

      final response = await _dio.post('/llm/test', data: requestData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to test LLM: $e');
    }
  }

  // Simplified OpenRouter Configuration (no longer needed - reads from .env)
  bool get isOpenRouterConfigured => true; // Always true, backend checks .env

  Future<void> configureOpenRouter() async {
    // No longer needed - OpenRouter reads from .env automatically
    return;
  }

  // Simplified Connection Testing
  Future<bool> testConnection(String provider) async {
    try {
      final status = await getProviderStatus(provider);
      return status['healthy'] as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> testOpenRouterConnection() async {
    try {
      final status = await getOpenRouterStatus();
      return status['connected'] as bool;
    } catch (e) {
      return false;
    }
  }

  // Initialize and Cleanup
  Future<void> initialize() async {
    // Initialize the LLM service
    // This could include loading saved settings, checking connectivity, etc.
  }

  Future<void> dispose() async {
    // Cleanup resources if needed
  }

  // Simplified Provider connectivity and testing methods
  Future<bool> testProviderConnectivity(String provider, {String? modelName}) async {
    try {
      await testLLM('Test connectivity', modelName: modelName);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Real-time status monitoring (simplified)
  Stream<Map<String, Map<String, dynamic>>> monitorProvidersStatus() async* {
    while (true) {
      try {
        final statuses = await getAllProvidersStatus();
        final statusMap = <String, Map<String, dynamic>>{};
        for (final status in statuses) {
          statusMap[status['provider'] as String] = status;
        }
        yield statusMap;
      } catch (e) {
        // Continue monitoring even if there's an error
        debugPrint('Error monitoring provider status: $e');
      }
      await Future.delayed(const Duration(seconds: 5)); // Update every 5 seconds
    }
  }

  // Chat-specific methods (simplified)
  Future<ChatSession> createChatSession({
    required String title,
    required String provider,
    required String model,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _dio.post(
        '/chats',
        data: {
          'title': title,
          'llm_provider': provider,
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
      final response = await _dio.get('/chats');
      final list = response.data as List<dynamic>;
      return list.map((item) => ChatSession.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      // Fallback to mock for development if backend not available
      debugPrint('Failed to get chat sessions from backend, using mock: $e');
      return _getMockChatSessions();
    }
  }

  Future<ChatSession> getChatSession(String sessionId) async {
    try {
      final response = await _dio.get('/chats/$sessionId');
      return ChatSession.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get chat session: $e');
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    try {
      await _dio.delete('/chats/$sessionId');
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
        '/chats/$sessionId/messages',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final list = response.data as List<dynamic>;
      return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      // Fallback to mock for development if backend not available
      debugPrint('Failed to get chat messages from backend, using mock: $e');
      return _getMockChatMessages(sessionId);
    }
  }

  Future<ChatMessage> sendChatMessage(String sessionId, String content) async {
    try {
      final response = await _dio.post('/chats/$sessionId/messages', data: {'content': content});
      return ChatMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to send chat message: $e');
    }
  }

  // Mock implementations for development/testing (fallback only)
  Future<List<ChatSession>> mockGetChatSessions() async {
    return _getMockChatSessions();
  }

  Future<List<ChatMessage>> mockGetChatMessages(String sessionId) async {
    return _getMockChatMessages(sessionId);
  }

  List<ChatSession> _getMockChatSessions() {
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
        llmModel: 'minimax/minimax-m2:free',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        messageCount: 5,
      ),
    ];
  }

  List<ChatMessage> _getMockChatMessages(String sessionId) {
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

  // Simplified Usage statistics
  Future<Map<String, dynamic>> getSystemUsageStats({String? timeRange}) async {
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) {
        queryParams['time_range'] = timeRange;
      }

      final response = await _dio.get('/llm/usage', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get system usage stats: $e');
    }
  }
}
