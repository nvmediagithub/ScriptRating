import 'dart:io';
import 'package:dio/dio.dart';
import '../models/llm_provider.dart';
import '../models/llm_provider_settings.dart';
import '../models/llm_model_config.dart';
import '../models/llm_config_response.dart';
import '../models/llm_status_response.dart';
import '../models/llm_test_response.dart';
import '../models/openrouter_models.dart';

class LlmService {
  final Dio _dio;
  static const String _basePath = '/api/v1/llm';

  LlmService(this._dio) {
    _dio.options.baseUrl = 'http://localhost:8000/api/v1';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  // Configuration Management
  Future<LLMConfigResponse> getLLMConfig() async {
    try {
      final response = await _dio.get('$_basePath/config');
      return LLMConfigResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError('Failed to get LLM configuration', e);
    }
  }

  Future<LLMConfigResponse> updateLLMConfig({
    LLMProvider? provider,
    String? modelName,
    LLMProviderSettings? settings,
    LLMModelConfig? modelConfig,
  }) async {
    try {
      final requestData = <String, dynamic>{};

      if (provider != null) {
        requestData['provider'] = provider.value;
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

      final response = await _dio.put('$_basePath/config', data: requestData);
      return LLMConfigResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError('Failed to update LLM configuration', e);
    }
  }

  // Provider Management
  Future<Map<LLMProvider, LLMProviderSettings>> getLLMProviders() async {
    try {
      final config = await getLLMConfig();
      return config.providers;
    } catch (e) {
      throw _handleError('Failed to get LLM providers', e);
    }
  }

  Future<LLMProvider> getActiveProvider() async {
    try {
      final config = await getLLMConfig();
      return config.activeProvider;
    } catch (e) {
      throw _handleError('Failed to get active provider', e);
    }
  }

  Future<void> setActiveProvider(LLMProvider provider) async {
    try {
      await updateLLMConfig(provider: provider);
    } catch (e) {
      throw _handleError('Failed to set active provider', e);
    }
  }

  // Model Management
  Future<Map<String, LLMModelConfig>> getLLMModels() async {
    try {
      final config = await getLLMConfig();
      return config.models;
    } catch (e) {
      throw _handleError('Failed to get LLM models', e);
    }
  }

  Future<String> getActiveModel() async {
    try {
      final config = await getLLMConfig();
      return config.activeModel;
    } catch (e) {
      throw _handleError('Failed to get active model', e);
    }
  }

  Future<void> setActiveModel(String modelName, {LLMProvider? provider}) async {
    try {
      await updateLLMConfig(modelName: modelName, provider: provider);
    } catch (e) {
      throw _handleError('Failed to set active model', e);
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
      final response = await _dio.get('$_basePath/status/${provider.value}');
      return LLMStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError('Failed to get provider status for ${provider.value}', e);
    }
  }

  Future<List<LLMStatusResponse>> getAllProvidersStatus() async {
    try {
      final response = await _dio.get('$_basePath/status');
      return (response.data as List).map((json) => LLMStatusResponse.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError('Failed to get all providers status', e);
    }
  }

  Future<Map<LLMProvider, bool>> checkProvidersHealth() async {
    try {
      final statuses = await getAllProvidersStatus();
      return {for (final status in statuses) status.provider: status.healthy};
    } catch (e) {
      throw _handleError('Failed to check providers health', e);
    }
  }

  // Testing and Validation
  Future<LLMTestResponse> testLLM(String prompt, {String? modelName}) async {
    try {
      final requestData = {'prompt': prompt, if (modelName != null) 'model_name': modelName};

      final response = await _dio.post('$_basePath/test', data: requestData);
      return LLMTestResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError('Failed to test LLM', e);
    }
  }

  // OpenRouter Specific Operations
  Future<OpenRouterModelsListResponse> getOpenRouterModels() async {
    try {
      final response = await _dio.get('$_basePath/openrouter/models');
      return OpenRouterModelsListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError('Failed to get OpenRouter models', e);
    }
  }

  Future<OpenRouterStatusResponse> getOpenRouterStatus() async {
    try {
      final response = await _dio.get('$_basePath/openrouter/status');
      return OpenRouterStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError('Failed to get OpenRouter status', e);
    }
  }

  Future<OpenRouterCallResponse> callOpenRouter({
    required String model,
    required String prompt,
    int maxTokens = 100,
    double temperature = 0.7,
  }) async {
    try {
      final request = OpenRouterCallRequest(
        model: model,
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );

      final response = await _dio.post('$_basePath/openrouter/call', data: request.toJson());

      return OpenRouterCallResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError('Failed to call OpenRouter', e);
    }
  }

  // Provider Settings Management
  Future<void> updateProviderSettings(LLMProviderSettings settings) async {
    try {
      await updateLLMConfig(settings: settings);
    } catch (e) {
      throw _handleError('Failed to update provider settings', e);
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
      throw _handleError('Failed to configure OpenRouter', e);
    }
  }

  // Connection Testing
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

  // Error Handling and Logging
  Exception _handleError(String message, dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('$message: Connection timeout');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;
          return Exception('$message: HTTP $statusCode - $responseData');
        case DioExceptionType.cancel:
          return Exception('$message: Request cancelled');
        case DioExceptionType.connectionError:
          return Exception('$message: Connection error - ${error.message}');
        case DioExceptionType.unknown:
        default:
          return Exception('$message: ${error.message}');
      }
    }

    if (error is SocketException) {
      return Exception('$message: Network error - ${error.message}');
    }

    return Exception('$message: ${error.toString()}');
  }

  // Performance Monitoring
  Future<Map<String, dynamic>> getProviderMetrics(LLMProvider provider) async {
    try {
      final response = await _dio.get('$_basePath/performance/${provider.value}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('Failed to get provider metrics for ${provider.value}', e);
    }
  }

  Future<Map<String, dynamic>> getAllProvidersMetrics() async {
    try {
      final response = await _dio.get('$_basePath/performance');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('Failed to get all providers metrics', e);
    }
  }

  // Health Check
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await _dio.get('$_basePath/config/health');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('Failed to get system health', e);
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
}
