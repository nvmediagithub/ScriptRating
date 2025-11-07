import 'package:dio/dio.dart';

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
    return LLMConfigResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
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
    return LLMConfigResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
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
      return LLMStatusResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception('Failed to get provider status for ${provider.name}: $e');
    }
  }

  Future<List<LLMStatusResponse>> getStatuses() async {
    try {
      final response = await _dio.get('/llm/status');
      final list = response.data as List<dynamic>;
      return list
          .map(
            (item) => LLMStatusResponse.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
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
    return LocalModelsListResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<LocalModelInfo> loadLocalModel(String modelName) async {
    final response = await _dio.post(
      '/llm/local/models/load',
      data: {'model_name': modelName},
    );
    return LocalModelInfo.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<LocalModelInfo> unloadLocalModel(String modelName) async {
    final response = await _dio.post(
      '/llm/local/models/unload',
      data: {'model_name': modelName},
    );
    return LocalModelInfo.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // OpenRouter Specific Operations
  Future<OpenRouterStatusResponse> getOpenRouterStatus() async {
    final response = await _dio.get('/llm/openrouter/status');
    return OpenRouterStatusResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<OpenRouterModelsListResponse> getOpenRouterModels() async {
    final response = await _dio.get('/llm/openrouter/models');
    return OpenRouterModelsListResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<LLMConfigResponse> switchMode(
    LLMProvider provider,
    String modelName,
  ) async {
    final response = await _dio.put(
      '/llm/config/mode',
      queryParameters: {'provider': provider.name, 'model_name': modelName},
    );
    return LLMConfigResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // Health and Performance
  Future<LLMHealthSummary> getHealthSummary() async {
    final response = await _dio.get('/llm/config/health');
    return LLMHealthSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PerformanceReportResponse>> getPerformanceReports() async {
    final response = await _dio.get('/llm/performance');
    final list = response.data as List<dynamic>;
    return list
        .map(
          (item) => PerformanceReportResponse.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
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
}
