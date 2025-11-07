import 'package:dio/dio.dart';

import '../models/llm_models.dart';

class LlmService {
  final Dio _dio;

  LlmService(this._dio) {
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = 'http://localhost:8000/api/v1';
    }
    _dio.options.headers['Content-Type'] ??= 'application/json';
  }

  Future<LLMConfigResponse> getConfig() async {
    final response = await _dio.get('/llm/config');
    return LLMConfigResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<LLMStatusResponse>> getStatuses() async {
    final response = await _dio.get('/llm/status');
    final list = response.data as List<dynamic>;
    return list
        .map(
          (item) => LLMStatusResponse.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<LocalModelsListResponse> getLocalModels() async {
    final response = await _dio.get('/llm/local/models');
    return LocalModelsListResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

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
}
