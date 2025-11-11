// LLM Management Models for Flutter App

import 'llm_provider.dart';

// Helper function to parse provider strings
LLMProvider _parseProvider(String providerString) {
  try {
    if (providerString == 'local' || providerString == 'LOCAL') {
      return LLMProvider.local;
    } else if (providerString == 'openrouter' || providerString == 'OPENROUTER') {
      return LLMProvider.openrouter;
    }
  } catch (e) {
    // Fallback to local if parsing fails
  }
  return LLMProvider.local;
}

class LLMProviderSettings {
  final LLMProvider provider;
  final String? apiKey;
  final String? baseUrl;
  final int timeout;
  final int maxRetries;

  LLMProviderSettings({
    required this.provider,
    this.apiKey,
    this.baseUrl,
    this.timeout = 30,
    this.maxRetries = 3,
  });

  factory LLMProviderSettings.fromJson(Map<String, dynamic> json) {
    return LLMProviderSettings(
      provider: _parseProvider(json['provider'] ?? 'local'),
      apiKey: json['api_key'] ?? json['apiKey'],
      baseUrl: json['base_url'] ?? json['baseUrl'],
      timeout: json['timeout'] ?? 30,
      maxRetries: json['max_retries'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'api_key': apiKey,
      'base_url': baseUrl,
      'timeout': timeout,
      'max_retries': maxRetries,
    };
  }
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

  LLMModelConfig({
    required this.modelName,
    required this.provider,
    this.contextWindow = 4096,
    this.maxTokens = 2048,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
  });

  factory LLMModelConfig.fromJson(Map<String, dynamic> json) {
    return LLMModelConfig(
      modelName: json['model_name'],
      provider: _parseProvider(json['provider'] ?? 'local'),
      contextWindow: json['context_window'] ?? 4096,
      maxTokens: json['max_tokens'] ?? 2048,
      temperature: json['temperature'] ?? 0.7,
      topP: json['top_p'] ?? 0.9,
      frequencyPenalty: json['frequency_penalty'] ?? 0.0,
      presencePenalty: json['presence_penalty'] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_name': modelName,
      'provider': provider.name,
      'context_window': contextWindow,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'top_p': topP,
      'frequency_penalty': frequencyPenalty,
      'presence_penalty': presencePenalty,
    };
  }
}

class LLMStatusResponse {
  final LLMProvider provider;
  final bool available;
  final bool healthy;
  final double? responseTimeMs;
  final String? errorMessage;
  final DateTime lastCheckedAt;

  LLMStatusResponse({
    required this.provider,
    required this.available,
    required this.healthy,
    this.responseTimeMs,
    this.errorMessage,
    required this.lastCheckedAt,
  });

  factory LLMStatusResponse.fromJson(Map<String, dynamic> json) {
    return LLMStatusResponse(
      provider: _parseProvider(json['provider'] ?? 'local'),
      available: json['available'],
      healthy: json['healthy'],
      responseTimeMs: json['response_time_ms']?.toDouble(),
      errorMessage: json['error_message'],
      lastCheckedAt: DateTime.parse(json['last_checked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'available': available,
      'healthy': healthy,
      'response_time_ms': responseTimeMs,
      'error_message': errorMessage,
      'last_checked_at': lastCheckedAt.toIso8601String(),
    };
  }
}

class LLMConfigResponse {
  final LLMProvider activeProvider;
  final String activeModel;
  final Map<LLMProvider, LLMProviderSettings> providers;
  final Map<String, LLMModelConfig> models;

  LLMConfigResponse({
    required this.activeProvider,
    required this.activeModel,
    required this.providers,
    required this.models,
  });

  factory LLMConfigResponse.fromJson(Map<String, dynamic> json) {
    final providersJson = json['providers'] as Map<String, dynamic>;
    final providers = <LLMProvider, LLMProviderSettings>{};
    providersJson.forEach((key, value) {
      final provider = _parseProvider(key);
      providers[provider] = LLMProviderSettings.fromJson(value);
    });

    final modelsJson = json['models'] as Map<String, dynamic>;
    final models = <String, LLMModelConfig>{};
    modelsJson.forEach((key, value) {
      models[key] = LLMModelConfig.fromJson(value);
    });

    return LLMConfigResponse(
      activeProvider: _parseProvider(json['active_provider'] ?? 'local'),
      activeModel: json['active_model'],
      providers: providers,
      models: models,
    );
  }

  Map<String, dynamic> toJson() {
    final providersJson = <String, dynamic>{};
    providers.forEach((key, value) {
      providersJson[key.name] = value.toJson();
    });

    final modelsJson = <String, dynamic>{};
    models.forEach((key, value) {
      modelsJson[key] = value.toJson();
    });

    return {
      'active_provider': activeProvider.name,
      'active_model': activeModel,
      'providers': providersJson,
      'models': modelsJson,
    };
  }

  /// Get the configuration for the active provider
  LLMProviderSettings get activeProviderSettings {
    return providers[activeProvider] ?? LLMProviderSettings(provider: activeProvider);
  }

  /// Get the configuration for the active model
  LLMModelConfig? get activeModelConfig {
    return models[activeModel];
  }

  /// Get all models for a specific provider
  List<String> getModelsByProvider(LLMProvider provider) {
    return models.entries
        .where((entry) => entry.value.provider == provider)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if a provider is available
  bool isProviderAvailable(LLMProvider provider) {
    final settings = providers[provider];
    if (settings == null) return false;

    if (provider == LLMProvider.openrouter) {
      return settings.apiKey != null && settings.apiKey!.isNotEmpty;
    }

    return true; // Local provider is always available if configured
  }
}

class LLMProvidersListResponse {
  final List<LLMProvider> providers;
  final LLMProvider activeProvider;

  LLMProvidersListResponse({required this.providers, required this.activeProvider});

  factory LLMProvidersListResponse.fromJson(Map<String, dynamic> json) {
    return LLMProvidersListResponse(
      providers: (json['providers'] as List<dynamic>).map((e) => _parseProvider(e)).toList(),
      activeProvider: _parseProvider(json['active_provider'] ?? 'local'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providers': providers.map((e) => e.name).toList(),
      'active_provider': activeProvider.name,
    };
  }
}

class LLMModelsListResponse {
  final List<String> models;
  final String activeModel;
  final Map<LLMProvider, List<String>> modelsByProvider;

  LLMModelsListResponse({
    required this.models,
    required this.activeModel,
    required this.modelsByProvider,
  });

  factory LLMModelsListResponse.fromJson(Map<String, dynamic> json) {
    final modelsByProviderJson = json['models_by_provider'] as Map<String, dynamic>;
    final modelsByProvider = <LLMProvider, List<String>>{};
    modelsByProviderJson.forEach((key, value) {
      final provider = _parseProvider(key);
      modelsByProvider[provider] = List<String>.from(value);
    });

    return LLMModelsListResponse(
      models: List<String>.from(json['models']),
      activeModel: json['active_model'],
      modelsByProvider: modelsByProvider,
    );
  }

  Map<String, dynamic> toJson() {
    final modelsByProviderJson = <String, dynamic>{};
    modelsByProvider.forEach((key, value) {
      modelsByProviderJson[key.name] = value;
    });

    return {
      'models': models,
      'active_model': activeModel,
      'models_by_provider': modelsByProviderJson,
    };
  }
}

class LocalModelInfo {
  final String modelName;
  final double sizeGb;
  final bool loaded;
  final int contextWindow;
  final int maxTokens;
  final DateTime? lastUsed;
  bool isLoading = false;

  LocalModelInfo({
    required this.modelName,
    required this.sizeGb,
    required this.loaded,
    required this.contextWindow,
    required this.maxTokens,
    this.lastUsed,
    this.isLoading = false,
  });

  factory LocalModelInfo.fromJson(Map<String, dynamic> json) {
    return LocalModelInfo(
      modelName: json['model_name'],
      sizeGb: json['size_gb'].toDouble(),
      loaded: json['loaded'],
      contextWindow: json['context_window'],
      maxTokens: json['max_tokens'],
      lastUsed: json['last_used'] != null ? DateTime.parse(json['last_used']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_name': modelName,
      'size_gb': sizeGb,
      'loaded': loaded,
      'context_window': contextWindow,
      'max_tokens': maxTokens,
      'last_used': lastUsed?.toIso8601String(),
    };
  }

  LocalModelInfo copyWith({
    String? modelName,
    double? sizeGb,
    bool? loaded,
    int? contextWindow,
    int? maxTokens,
    DateTime? lastUsed,
    bool? isLoading,
  }) {
    return LocalModelInfo(
      modelName: modelName ?? this.modelName,
      sizeGb: sizeGb ?? this.sizeGb,
      loaded: loaded ?? this.loaded,
      contextWindow: contextWindow ?? this.contextWindow,
      maxTokens: maxTokens ?? this.maxTokens,
      lastUsed: lastUsed ?? this.lastUsed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocalModelsListResponse {
  final List<LocalModelInfo> models;
  final List<String> loadedModels;

  LocalModelsListResponse({required this.models, required this.loadedModels});

  factory LocalModelsListResponse.fromJson(Map<String, dynamic> json) {
    return LocalModelsListResponse(
      models: (json['models'] as List<dynamic>).map((e) => LocalModelInfo.fromJson(e)).toList(),
      loadedModels: List<String>.from(json['loaded_models']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'models': models.map((e) => e.toJson()).toList(), 'loaded_models': loadedModels};
  }

  LocalModelsListResponse copyWith({List<LocalModelInfo>? models, List<String>? loadedModels}) {
    return LocalModelsListResponse(
      models: models ?? this.models,
      loadedModels: loadedModels ?? this.loadedModels,
    );
  }
}

class OpenRouterModelsListResponse {
  final List<String> models;
  final int total;

  OpenRouterModelsListResponse({required this.models, required this.total});

  factory OpenRouterModelsListResponse.fromJson(Map<String, dynamic> json) {
    return OpenRouterModelsListResponse(
      models: List<String>.from(json['models']),
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'models': models, 'total': total};
  }
}

class OpenRouterStatusResponse {
  final bool connected;
  final double? creditsRemaining;
  final int? rateLimitRemaining;
  final String? errorMessage;

  OpenRouterStatusResponse({
    required this.connected,
    this.creditsRemaining,
    this.rateLimitRemaining,
    this.errorMessage,
  });

  factory OpenRouterStatusResponse.fromJson(Map<String, dynamic> json) {
    return OpenRouterStatusResponse(
      connected: json['connected'],
      creditsRemaining: json['credits_remaining']?.toDouble(),
      rateLimitRemaining: json['rate_limit_remaining'],
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connected': connected,
      'credits_remaining': creditsRemaining,
      'rate_limit_remaining': rateLimitRemaining,
      'error_message': errorMessage,
    };
  }
}

class PerformanceMetrics {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageResponseTimeMs;
  final int totalTokensUsed;
  final double errorRate;
  final double uptimePercentage;

  PerformanceMetrics({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTimeMs,
    required this.totalTokensUsed,
    required this.errorRate,
    required this.uptimePercentage,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      totalRequests: json['total_requests'],
      successfulRequests: json['successful_requests'],
      failedRequests: json['failed_requests'],
      averageResponseTimeMs: json['average_response_time_ms'].toDouble(),
      totalTokensUsed: json['total_tokens_used'],
      errorRate: json['error_rate'].toDouble(),
      uptimePercentage: json['uptime_percentage'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_requests': totalRequests,
      'successful_requests': successfulRequests,
      'failed_requests': failedRequests,
      'average_response_time_ms': averageResponseTimeMs,
      'total_tokens_used': totalTokensUsed,
      'error_rate': errorRate,
      'uptime_percentage': uptimePercentage,
    };
  }
}

class PerformanceReportResponse {
  final LLMProvider provider;
  final PerformanceMetrics metrics;
  final String timeRange;
  final DateTime generatedAt;

  PerformanceReportResponse({
    required this.provider,
    required this.metrics,
    required this.timeRange,
    required this.generatedAt,
  });

  factory PerformanceReportResponse.fromJson(Map<String, dynamic> json) {
    return PerformanceReportResponse(
      provider: _parseProvider(json['provider'] ?? 'local'),
      metrics: PerformanceMetrics.fromJson(json['metrics']),
      timeRange: json['time_range'],
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'metrics': metrics.toJson(),
      'time_range': timeRange,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class LLMHealthSummary {
  final List<LLMStatusResponse> providersStatus;
  final int localModelsLoaded;
  final int localModelsAvailable;
  final bool openRouterConnected;
  final LLMProvider activeProvider;
  final String activeModel;
  final bool systemHealthy;

  LLMHealthSummary({
    required this.providersStatus,
    required this.localModelsLoaded,
    required this.localModelsAvailable,
    required this.openRouterConnected,
    required this.activeProvider,
    required this.activeModel,
    required this.systemHealthy,
  });

  factory LLMHealthSummary.fromJson(Map<String, dynamic> json) {
    final statusList =
        (json['providers_status'] as List<dynamic>?)
            ?.map((item) => LLMStatusResponse.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList() ??
        <LLMStatusResponse>[];

    return LLMHealthSummary(
      providersStatus: statusList,
      localModelsLoaded: json['local_models_loaded'] ?? 0,
      localModelsAvailable: json['local_models_available'] ?? 0,
      openRouterConnected: json['openrouter_connected'] ?? false,
      activeProvider: _parseProvider(json['active_provider'] ?? 'local'),
      activeModel: json['active_model'] ?? '',
      systemHealthy: json['system_healthy'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providers_status': providersStatus.map((status) => status.toJson()).toList(),
      'local_models_loaded': localModelsLoaded,
      'local_models_available': localModelsAvailable,
      'openrouter_connected': openRouterConnected,
      'active_provider': activeProvider.name,
      'active_model': activeModel,
      'system_healthy': systemHealthy,
    };
  }
}

class LLMTestResponse {
  final String modelName;
  final LLMProvider provider;
  final String prompt;
  final String response;
  final int tokensUsed;
  final double responseTimeMs;
  final bool success;

  const LLMTestResponse({
    required this.modelName,
    required this.provider,
    required this.prompt,
    required this.response,
    required this.tokensUsed,
    required this.responseTimeMs,
    required this.success,
  });

  factory LLMTestResponse.fromJson(Map<String, dynamic> json) {
    return LLMTestResponse(
      modelName: json['model_name'] as String,
      provider: _parseProvider(json['provider'] ?? 'local'),
      prompt: json['prompt'] as String,
      response: json['response'] as String,
      tokensUsed: json['tokens_used'] as int,
      responseTimeMs: (json['response_time_ms'] as num).toDouble(),
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_name': modelName,
      'provider': provider.name,
      'prompt': prompt,
      'response': response,
      'tokens_used': tokensUsed,
      'response_time_ms': responseTimeMs,
      'success': success,
    };
  }
}
