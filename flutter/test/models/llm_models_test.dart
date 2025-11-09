import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/llm_models.dart';
import 'package:script_rating_app/models/llm_provider.dart';

void main() {
  group('LLMProviderSettings Tests', () {
    test('should create LLMProviderSettings with required parameters', () {
      final settings = LLMProviderSettings(
        provider: LLMProvider.local,
      );

      expect(settings.provider, LLMProvider.local);
      expect(settings.apiKey, null);
      expect(settings.baseUrl, null);
      expect(settings.timeout, 30);
      expect(settings.maxRetries, 3);
    });

    test('should create LLMProviderSettings with all parameters', () {
      final settings = LLMProviderSettings(
        provider: LLMProvider.openrouter,
        apiKey: 'test-api-key',
        baseUrl: 'https://api.example.com',
        timeout: 60,
        maxRetries: 5,
      );

      expect(settings.provider, LLMProvider.openrouter);
      expect(settings.apiKey, 'test-api-key');
      expect(settings.baseUrl, 'https://api.example.com');
      expect(settings.timeout, 60);
      expect(settings.maxRetries, 5);
    });

    test('should serialize to JSON correctly', () {
      final settings = LLMProviderSettings(
        provider: LLMProvider.openrouter,
        apiKey: 'test-api-key',
        baseUrl: 'https://api.example.com',
        timeout: 60,
        maxRetries: 5,
      );

      final json = settings.toJson();
      expect(json['provider'], 'openrouter');
      expect(json['api_key'], 'test-api-key');
      expect(json['base_url'], 'https://api.example.com');
      expect(json['timeout'], 60);
      expect(json['max_retries'], 5);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'provider': 'openrouter',
        'api_key': 'test-api-key',
        'base_url': 'https://api.example.com',
        'timeout': 60,
        'max_retries': 5,
      };

      final settings = LLMProviderSettings.fromJson(json);
      expect(settings.provider, LLMProvider.openrouter);
      expect(settings.apiKey, 'test-api-key');
      expect(settings.baseUrl, 'https://api.example.com');
      expect(settings.timeout, 60);
      expect(settings.maxRetries, 5);
    });

    test('should use default values when JSON fields are missing', () {
      final json = {
        'provider': 'local',
      };

      final settings = LLMProviderSettings.fromJson(json);
      expect(settings.provider, LLMProvider.local);
      expect(settings.timeout, 30);
      expect(settings.maxRetries, 3);
      expect(settings.apiKey, null);
      expect(settings.baseUrl, null);
    });
  });

  group('LLMModelConfig Tests', () {
    test('should create LLMModelConfig with required parameters', () {
      final config = LLMModelConfig(
        modelName: 'test-model',
        provider: LLMProvider.local,
      );

      expect(config.modelName, 'test-model');
      expect(config.provider, LLMProvider.local);
      expect(config.contextWindow, 4096);
      expect(config.maxTokens, 2048);
      expect(config.temperature, 0.7);
      expect(config.topP, 0.9);
      expect(config.frequencyPenalty, 0.0);
      expect(config.presencePenalty, 0.0);
    });

    test('should create LLMModelConfig with all parameters', () {
      final config = LLMModelConfig(
        modelName: 'test-model',
        provider: LLMProvider.openrouter,
        contextWindow: 8192,
        maxTokens: 4096,
        temperature: 0.8,
        topP: 0.95,
        frequencyPenalty: 0.1,
        presencePenalty: 0.2,
      );

      expect(config.modelName, 'test-model');
      expect(config.provider, LLMProvider.openrouter);
      expect(config.contextWindow, 8192);
      expect(config.maxTokens, 4096);
      expect(config.temperature, 0.8);
      expect(config.topP, 0.95);
      expect(config.frequencyPenalty, 0.1);
      expect(config.presencePenalty, 0.2);
    });

    test('should serialize to JSON correctly', () {
      final config = LLMModelConfig(
        modelName: 'test-model',
        provider: LLMProvider.openrouter,
        contextWindow: 8192,
        maxTokens: 4096,
        temperature: 0.8,
        topP: 0.95,
        frequencyPenalty: 0.1,
        presencePenalty: 0.2,
      );

      final json = config.toJson();
      expect(json['model_name'], 'test-model');
      expect(json['provider'], 'openrouter');
      expect(json['context_window'], 8192);
      expect(json['max_tokens'], 4096);
      expect(json['temperature'], 0.8);
      expect(json['top_p'], 0.95);
      expect(json['frequency_penalty'], 0.1);
      expect(json['presence_penalty'], 0.2);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'model_name': 'test-model',
        'provider': 'openrouter',
        'context_window': 8192,
        'max_tokens': 4096,
        'temperature': 0.8,
        'top_p': 0.95,
        'frequency_penalty': 0.1,
        'presence_penalty': 0.2,
      };

      final config = LLMModelConfig.fromJson(json);
      expect(config.modelName, 'test-model');
      expect(config.provider, LLMProvider.openrouter);
      expect(config.contextWindow, 8192);
      expect(config.maxTokens, 4096);
      expect(config.temperature, 0.8);
      expect(config.topP, 0.95);
      expect(config.frequencyPenalty, 0.1);
      expect(config.presencePenalty, 0.2);
    });

    test('should use default values when JSON fields are missing', () {
      final json = {
        'model_name': 'test-model',
        'provider': 'local',
      };

      final config = LLMModelConfig.fromJson(json);
      expect(config.modelName, 'test-model');
      expect(config.provider, LLMProvider.local);
      expect(config.contextWindow, 4096);
      expect(config.maxTokens, 2048);
      expect(config.temperature, 0.7);
      expect(config.topP, 0.9);
      expect(config.frequencyPenalty, 0.0);
      expect(config.presencePenalty, 0.0);
    });
  });

  group('LLMStatusResponse Tests', () {
    test('should create LLMStatusResponse with all parameters', () {
      final status = LLMStatusResponse(
        provider: LLMProvider.local,
        available: true,
        healthy: true,
        responseTimeMs: 100.0,
        errorMessage: null,
        lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      expect(status.provider, LLMProvider.local);
      expect(status.available, true);
      expect(status.healthy, true);
      expect(status.responseTimeMs, 100.0);
      expect(status.errorMessage, null);
      expect(status.lastCheckedAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
    });

    test('should handle null response time', () {
      final status = LLMStatusResponse(
        provider: LLMProvider.local,
        available: false,
        healthy: false,
        responseTimeMs: null,
        errorMessage: 'Connection failed',
        lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      expect(status.responseTimeMs, null);
      expect(status.errorMessage, 'Connection failed');
    });

    test('should serialize to JSON correctly', () {
      final status = LLMStatusResponse(
        provider: LLMProvider.local,
        available: true,
        healthy: true,
        responseTimeMs: 100.0,
        errorMessage: null,
        lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      final json = status.toJson();
      expect(json['provider'], 'local');
      expect(json['available'], true);
      expect(json['healthy'], true);
      expect(json['response_time_ms'], 100.0);
      expect(json['error_message'], null);
      expect(json['last_checked_at'], '2023-01-01T00:00:00.000Z');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'provider': 'local',
        'available': true,
        'healthy': true,
        'response_time_ms': 100.0,
        'error_message': null,
        'last_checked_at': '2023-01-01T00:00:00.000Z',
      };

      final status = LLMStatusResponse.fromJson(json);
      expect(status.provider, LLMProvider.local);
      expect(status.available, true);
      expect(status.healthy, true);
      expect(status.responseTimeMs, 100.0);
      expect(status.errorMessage, null);
      expect(status.lastCheckedAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
    });
  });

  group('LLMConfigResponse Tests', () {
    test('should create LLMConfigResponse with all parameters', () {
      final providers = {
        LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
        LLMProvider.openrouter: LLMProviderSettings(
          provider: LLMProvider.openrouter,
          apiKey: 'test-key',
        ),
      };

      final models = {
        'local-model': LLMModelConfig(
          modelName: 'local-model',
          provider: LLMProvider.local,
        ),
        'openrouter-model': LLMModelConfig(
          modelName: 'openrouter-model',
          provider: LLMProvider.openrouter,
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'local-model',
        providers: providers,
        models: models,
      );

      expect(config.activeProvider, LLMProvider.local);
      expect(config.activeModel, 'local-model');
      expect(config.providers.length, 2);
      expect(config.models.length, 2);
    });

    test('should get active provider settings', () {
      final providers = {
        LLMProvider.local: LLMProviderSettings(
          provider: LLMProvider.local,
          timeout: 60,
        ),
        LLMProvider.openrouter: LLMProviderSettings(
          provider: LLMProvider.openrouter,
          apiKey: 'test-key',
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: providers,
        models: {},
      );

      final activeSettings = config.activeProviderSettings;
      expect(activeSettings.timeout, 60);
    });

    test('should return default settings when active provider not found', () {
      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: {},
        models: {},
      );

      final activeSettings = config.activeProviderSettings;
      expect(activeSettings.provider, LLMProvider.local);
    });

    test('should get active model config', () {
      final models = {
        'test-model': LLMModelConfig(
          modelName: 'test-model',
          provider: LLMProvider.local,
          temperature: 0.8,
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: {},
        models: models,
      );

      final activeConfig = config.activeModelConfig;
      expect(activeConfig?.temperature, 0.8);
    });

    test('should return null when active model not found', () {
      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'nonexistent-model',
        providers: {},
        models: {},
      );

      final activeConfig = config.activeModelConfig;
      expect(activeConfig, null);
    });

    test('should get models by provider', () {
      final models = {
        'local-model-1': LLMModelConfig(
          modelName: 'local-model-1',
          provider: LLMProvider.local,
        ),
        'local-model-2': LLMModelConfig(
          modelName: 'local-model-2',
          provider: LLMProvider.local,
        ),
        'openrouter-model': LLMModelConfig(
          modelName: 'openrouter-model',
          provider: LLMProvider.openrouter,
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'local-model-1',
        providers: {},
        models: models,
      );

      final localModels = config.getModelsByProvider(LLMProvider.local);
      expect(localModels, ['local-model-1', 'local-model-2']);
    });

    test('should check if provider is available', () {
      final providers = {
        LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
        LLMProvider.openrouter: LLMProviderSettings(
          provider: LLMProvider.openrouter,
          apiKey: 'valid-key',
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: providers,
        models: {},
      );

      expect(config.isProviderAvailable(LLMProvider.local), true);
      expect(config.isProviderAvailable(LLMProvider.openrouter), true);
    });

    test('should return false for OpenRouter without API key', () {
      final providers = {
        LLMProvider.openrouter: LLMProviderSettings(
          provider: LLMProvider.openrouter,
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: providers,
        models: {},
      );

      expect(config.isProviderAvailable(LLMProvider.openrouter), false);
    });

    test('should return false for non-configured provider', () {
      final providers = {
        LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: providers,
        models: {},
      );

      expect(config.isProviderAvailable(LLMProvider.openrouter), false);
    });

    test('should serialize to JSON correctly', () {
      final providers = {
        LLMProvider.local: LLMProviderSettings(
          provider: LLMProvider.local,
          timeout: 60,
        ),
      };

      final models = {
        'test-model': LLMModelConfig(
          modelName: 'test-model',
          provider: LLMProvider.local,
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: providers,
        models: models,
      );

      final json = config.toJson();
      expect(json['active_provider'], 'local');
      expect(json['active_model'], 'test-model');
      expect(json['providers']['local']['timeout'], 60);
      expect(json['models']['test-model']['model_name'], 'test-model');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'active_provider': 'local',
        'active_model': 'test-model',
        'providers': {
          'local': {
            'provider': 'local',
            'timeout': 60,
          },
          'openrouter': {
            'provider': 'openrouter',
            'api_key': 'test-key',
          },
        },
        'models': {
          'test-model': {
            'model_name': 'test-model',
            'provider': 'local',
          },
        },
      };

      final config = LLMConfigResponse.fromJson(json);
      expect(config.activeProvider, LLMProvider.local);
      expect(config.activeModel, 'test-model');
      expect(config.providers.length, 2);
      expect(config.models.length, 1);
    });
  });

  group('LocalModelInfo Tests', () {
    test('should create LocalModelInfo with required parameters', () {
      final model = LocalModelInfo(
        modelName: 'test-model',
        sizeGb: 2.5,
        loaded: true,
        contextWindow: 4096,
        maxTokens: 2048,
      );

      expect(model.modelName, 'test-model');
      expect(model.sizeGb, 2.5);
      expect(model.loaded, true);
      expect(model.contextWindow, 4096);
      expect(model.maxTokens, 2048);
      expect(model.lastUsed, null);
      expect(model.isLoading, false);
    });

    test('should create LocalModelInfo with all parameters', () {
      final lastUsed = DateTime.parse('2023-01-01T00:00:00.000Z');
      final model = LocalModelInfo(
        modelName: 'test-model',
        sizeGb: 2.5,
        loaded: true,
        contextWindow: 4096,
        maxTokens: 2048,
        lastUsed: lastUsed,
        isLoading: true,
      );

      expect(model.lastUsed, lastUsed);
      expect(model.isLoading, true);
    });

    test('should copy with updated values', () {
      final original = LocalModelInfo(
        modelName: 'test-model',
        sizeGb: 2.5,
        loaded: true,
        contextWindow: 4096,
        maxTokens: 2048,
      );

      final copied = original.copyWith(
        loaded: false,
        isLoading: true,
      );

      expect(copied.modelName, 'test-model');
      expect(copied.loaded, false);
      expect(copied.isLoading, true);
      expect(copied.sizeGb, 2.5); // unchanged
      expect(copied.contextWindow, 4096); // unchanged
    });

    test('should serialize to JSON correctly', () {
      final lastUsed = DateTime.parse('2023-01-01T00:00:00.000Z');
      final model = LocalModelInfo(
        modelName: 'test-model',
        sizeGb: 2.5,
        loaded: true,
        contextWindow: 4096,
        maxTokens: 2048,
        lastUsed: lastUsed,
      );

      final json = model.toJson();
      expect(json['model_name'], 'test-model');
      expect(json['size_gb'], 2.5);
      expect(json['loaded'], true);
      expect(json['context_window'], 4096);
      expect(json['max_tokens'], 2048);
      expect(json['last_used'], '2023-01-01T00:00:00.000Z');
    });

    test('should handle null lastUsed in JSON', () {
      final json = {
        'model_name': 'test-model',
        'size_gb': 2.5,
        'loaded': true,
        'context_window': 4096,
        'max_tokens': 2048,
        'last_used': null,
      };

      final model = LocalModelInfo.fromJson(json);
      expect(model.lastUsed, null);
    });
  });

  group('LocalModelsListResponse Tests', () {
    test('should create LocalModelsListResponse with models and loadedModels', () {
      final models = [
        LocalModelInfo(
          modelName: 'model1',
          sizeGb: 2.5,
          loaded: true,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
        LocalModelInfo(
          modelName: 'model2',
          sizeGb: 3.0,
          loaded: false,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
      ];

      final response = LocalModelsListResponse(
        models: models,
        loadedModels: ['model1'],
      );

      expect(response.models, hasLength(2));
      expect(response.loadedModels, ['model1']);
    });

    test('should copy with updated values', () {
      final original = LocalModelsListResponse(
        models: [
          LocalModelInfo(
            modelName: 'model1',
            sizeGb: 2.5,
            loaded: true,
            contextWindow: 4096,
            maxTokens: 2048,
          ),
        ],
        loadedModels: ['model1'],
      );

      final copied = original.copyWith(
        loadedModels: ['model1', 'model2'],
      );

      expect(copied.models, original.models); // unchanged
      expect(copied.loadedModels, ['model1', 'model2']); // updated
    });

    test('should serialize to JSON correctly', () {
      final models = [
        LocalModelInfo(
          modelName: 'model1',
          sizeGb: 2.5,
          loaded: true,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
      ];

      final response = LocalModelsListResponse(
        models: models,
        loadedModels: ['model1'],
      );

      final json = response.toJson();
      expect(json['models'], hasLength(1));
      expect(json['loaded_models'], ['model1']);
    });
  });

  group('OpenRouterModelsListResponse Tests', () {
    test('should create OpenRouterModelsListResponse with models and total', () {
      final response = OpenRouterModelsListResponse(
        models: ['gpt-3.5-turbo', 'gpt-4', 'claude-3'],
        total: 3,
      );

      expect(response.models, ['gpt-3.5-turbo', 'gpt-4', 'claude-3']);
      expect(response.total, 3);
    });

    test('should serialize to JSON correctly', () {
      final response = OpenRouterModelsListResponse(
        models: ['gpt-3.5-turbo', 'gpt-4'],
        total: 2,
      );

      final json = response.toJson();
      expect(json['models'], ['gpt-3.5-turbo', 'gpt-4']);
      expect(json['total'], 2);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'models': ['gpt-3.5-turbo', 'gpt-4'],
        'total': 2,
      };

      final response = OpenRouterModelsListResponse.fromJson(json);
      expect(response.models, ['gpt-3.5-turbo', 'gpt-4']);
      expect(response.total, 2);
    });
  });

  group('OpenRouterStatusResponse Tests', () {
    test('should create OpenRouterStatusResponse with connected status', () {
      final status = OpenRouterStatusResponse(
        connected: true,
        creditsRemaining: 15.75,
        rateLimitRemaining: 100,
      );

      expect(status.connected, true);
      expect(status.creditsRemaining, 15.75);
      expect(status.rateLimitRemaining, 100);
      expect(status.errorMessage, null);
    });

    test('should handle disconnected state', () {
      final status = OpenRouterStatusResponse(
        connected: false,
        creditsRemaining: null,
        rateLimitRemaining: null,
        errorMessage: 'Connection failed',
      );

      expect(status.connected, false);
      expect(status.creditsRemaining, null);
      expect(status.rateLimitRemaining, null);
      expect(status.errorMessage, 'Connection failed');
    });

    test('should serialize to JSON correctly', () {
      final status = OpenRouterStatusResponse(
        connected: true,
        creditsRemaining: 15.75,
        rateLimitRemaining: 100,
      );

      final json = status.toJson();
      expect(json['connected'], true);
      expect(json['credits_remaining'], 15.75);
      expect(json['rate_limit_remaining'], 100);
      expect(json['error_message'], null);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'connected': true,
        'credits_remaining': 15.75,
        'rate_limit_remaining': 100,
        'error_message': null,
      };

      final status = OpenRouterStatusResponse.fromJson(json);
      expect(status.connected, true);
      expect(status.creditsRemaining, 15.75);
      expect(status.rateLimitRemaining, 100);
      expect(status.errorMessage, null);
    });
  });

  group('PerformanceMetrics Tests', () {
    test('should create PerformanceMetrics with all parameters', () {
      final metrics = PerformanceMetrics(
        totalRequests: 1000,
        successfulRequests: 950,
        failedRequests: 50,
        averageResponseTimeMs: 1200.5,
        totalTokensUsed: 50000,
        errorRate: 0.05,
        uptimePercentage: 99.5,
      );

      expect(metrics.totalRequests, 1000);
      expect(metrics.successfulRequests, 950);
      expect(metrics.failedRequests, 50);
      expect(metrics.averageResponseTimeMs, 1200.5);
      expect(metrics.totalTokensUsed, 50000);
      expect(metrics.errorRate, 0.05);
      expect(metrics.uptimePercentage, 99.5);
    });

    test('should serialize to JSON correctly', () {
      final metrics = PerformanceMetrics(
        totalRequests: 1000,
        successfulRequests: 950,
        failedRequests: 50,
        averageResponseTimeMs: 1200.5,
        totalTokensUsed: 50000,
        errorRate: 0.05,
        uptimePercentage: 99.5,
      );

      final json = metrics.toJson();
      expect(json['total_requests'], 1000);
      expect(json['successful_requests'], 950);
      expect(json['failed_requests'], 50);
      expect(json['average_response_time_ms'], 1200.5);
      expect(json['total_tokens_used'], 50000);
      expect(json['error_rate'], 0.05);
      expect(json['uptime_percentage'], 99.5);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'total_requests': 1000,
        'successful_requests': 950,
        'failed_requests': 50,
        'average_response_time_ms': 1200.5,
        'total_tokens_used': 50000,
        'error_rate': 0.05,
        'uptime_percentage': 99.5,
      };

      final metrics = PerformanceMetrics.fromJson(json);
      expect(metrics.totalRequests, 1000);
      expect(metrics.successfulRequests, 950);
      expect(metrics.failedRequests, 50);
      expect(metrics.averageResponseTimeMs, 1200.5);
      expect(metrics.totalTokensUsed, 50000);
      expect(metrics.errorRate, 0.05);
      expect(metrics.uptimePercentage, 99.5);
    });
  });

  group('PerformanceReportResponse Tests', () {
    test('should create PerformanceReportResponse with all parameters', () {
      final metrics = PerformanceMetrics(
        totalRequests: 1000,
        successfulRequests: 950,
        failedRequests: 50,
        averageResponseTimeMs: 1200.5,
        totalTokensUsed: 50000,
        errorRate: 0.05,
        uptimePercentage: 99.5,
      );

      final report = PerformanceReportResponse(
        provider: LLMProvider.local,
        metrics: metrics,
        timeRange: '24h',
        generatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      expect(report.provider, LLMProvider.local);
      expect(report.metrics, metrics);
      expect(report.timeRange, '24h');
      expect(report.generatedAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
    });

    test('should serialize to JSON correctly', () {
      final metrics = PerformanceMetrics(
        totalRequests: 1000,
        successfulRequests: 950,
        failedRequests: 50,
        averageResponseTimeMs: 1200.5,
        totalTokensUsed: 50000,
        errorRate: 0.05,
        uptimePercentage: 99.5,
      );

      final report = PerformanceReportResponse(
        provider: LLMProvider.local,
        metrics: metrics,
        timeRange: '24h',
        generatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      final json = report.toJson();
      expect(json['provider'], 'local');
      expect(json['time_range'], '24h');
      expect(json['generated_at'], '2023-01-01T00:00:00.000Z');
      expect(json['metrics']['total_requests'], 1000);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'provider': 'local',
        'metrics': {
          'total_requests': 1000,
          'successful_requests': 950,
          'failed_requests': 50,
          'average_response_time_ms': 1200.5,
          'total_tokens_used': 50000,
          'error_rate': 0.05,
          'uptime_percentage': 99.5,
        },
        'time_range': '24h',
        'generated_at': '2023-01-01T00:00:00.000Z',
      };

      final report = PerformanceReportResponse.fromJson(json);
      expect(report.provider, LLMProvider.local);
      expect(report.timeRange, '24h');
      expect(report.generatedAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(report.metrics.totalRequests, 1000);
    });
  });

  group('LLMHealthSummary Tests', () {
    test('should create LLMHealthSummary with all parameters', () {
      final statuses = [
        LLMStatusResponse(
          provider: LLMProvider.local,
          available: true,
          healthy: true,
          responseTimeMs: 100.0,
          errorMessage: null,
          lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        ),
      ];

      final summary = LLMHealthSummary(
        providersStatus: statuses,
        localModelsLoaded: 2,
        localModelsAvailable: 5,
        openRouterConnected: true,
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        systemHealthy: true,
      );

      expect(summary.providersStatus, hasLength(1));
      expect(summary.localModelsLoaded, 2);
      expect(summary.localModelsAvailable, 5);
      expect(summary.openRouterConnected, true);
      expect(summary.activeProvider, LLMProvider.local);
      expect(summary.activeModel, 'test-model');
      expect(summary.systemHealthy, true);
    });

    test('should handle empty providers status list', () {
      final summary = LLMHealthSummary(
        providersStatus: [],
        localModelsLoaded: 0,
        localModelsAvailable: 0,
        openRouterConnected: false,
        activeProvider: LLMProvider.local,
        activeModel: '',
        systemHealthy: false,
      );

      expect(summary.providersStatus, isEmpty);
      expect(summary.systemHealthy, false);
    });

    test('should serialize to JSON correctly', () {
      final statuses = [
        LLMStatusResponse(
          provider: LLMProvider.local,
          available: true,
          healthy: true,
          responseTimeMs: 100.0,
          errorMessage: null,
          lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        ),
      ];

      final summary = LLMHealthSummary(
        providersStatus: statuses,
        localModelsLoaded: 2,
        localModelsAvailable: 5,
        openRouterConnected: true,
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        systemHealthy: true,
      );

      final json = summary.toJson();
      expect(json['providers_status'], hasLength(1));
      expect(json['local_models_loaded'], 2);
      expect(json['local_models_available'], 5);
      expect(json['openrouter_connected'], true);
      expect(json['active_provider'], 'local');
      expect(json['active_model'], 'test-model');
      expect(json['system_healthy'], true);
    });

    test('should deserialize from JSON correctly with null providers_status', () {
      final json = {
        'providers_status': null,
        'local_models_loaded': 2,
        'local_models_available': 5,
        'openrouter_connected': true,
        'active_provider': 'local',
        'active_model': 'test-model',
        'system_healthy': true,
      };

      final summary = LLMHealthSummary.fromJson(json);
      expect(summary.providersStatus, isEmpty);
      expect(summary.localModelsLoaded, 2);
      expect(summary.openRouterConnected, true);
    });
  });

  group('LLMTestResponse Tests', () {
    test('should create LLMTestResponse with all parameters', () {
      final response = LLMTestResponse(
        modelName: 'test-model',
        provider: LLMProvider.local,
        prompt: 'Hello, world!',
        response: 'Hello! How can I help you?',
        tokensUsed: 10,
        responseTimeMs: 500.0,
        success: true,
      );

      expect(response.modelName, 'test-model');
      expect(response.provider, LLMProvider.local);
      expect(response.prompt, 'Hello, world!');
      expect(response.response, 'Hello! How can I help you?');
      expect(response.tokensUsed, 10);
      expect(response.responseTimeMs, 500.0);
      expect(response.success, true);
    });

    test('should handle failed test', () {
      final response = LLMTestResponse(
        modelName: 'test-model',
        provider: LLMProvider.local,
        prompt: 'Hello, world!',
        response: '',
        tokensUsed: 0,
        responseTimeMs: 0.0,
        success: false,
      );

      expect(response.success, false);
      expect(response.response, isEmpty);
    });

    test('should serialize to JSON correctly', () {
      final response = LLMTestResponse(
        modelName: 'test-model',
        provider: LLMProvider.local,
        prompt: 'Hello, world!',
        response: 'Hello! How can I help you?',
        tokensUsed: 10,
        responseTimeMs: 500.0,
        success: true,
      );

      final json = response.toJson();
      expect(json['model_name'], 'test-model');
      expect(json['provider'], 'local');
      expect(json['prompt'], 'Hello, world!');
      expect(json['response'], 'Hello! How can I help you?');
      expect(json['tokens_used'], 10);
      expect(json['response_time_ms'], 500.0);
      expect(json['success'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'model_name': 'test-model',
        'provider': 'local',
        'prompt': 'Hello, world!',
        'response': 'Hello! How can I help you?',
        'tokens_used': 10,
        'response_time_ms': 500.0,
        'success': true,
      };

      final response = LLMTestResponse.fromJson(json);
      expect(response.modelName, 'test-model');
      expect(response.provider, LLMProvider.local);
      expect(response.prompt, 'Hello, world!');
      expect(response.response, 'Hello! How can I help you?');
      expect(response.tokensUsed, 10);
      expect(response.responseTimeMs, 500.0);
      expect(response.success, true);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('should handle invalid provider in JSON deserialization', () {
      final json = {
        'provider': 'invalid_provider',
        'available': true,
        'healthy': true,
        'response_time_ms': 100.0,
        'error_message': null,
        'last_checked_at': '2023-01-01T00:00:00.000Z',
      };

      expect(
        () => LLMStatusResponse.fromJson(json),
        throwsA(isA<StateError>()),
      );
    });

    test('should handle invalid date format in JSON', () {
      final json = {
        'provider': 'local',
        'available': true,
        'healthy': true,
        'response_time_ms': 100.0,
        'error_message': null,
        'last_checked_at': 'invalid-date',
      };

      expect(
        () => LLMStatusResponse.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('should handle negative values in PerformanceMetrics', () {
      final json = {
        'total_requests': -1,
        'successful_requests': -1,
        'failed_requests': -1,
        'average_response_time_ms': -1.0,
        'total_tokens_used': -1,
        'error_rate': -0.1,
        'uptime_percentage': -1.0,
      };

      final metrics = PerformanceMetrics.fromJson(json);
      // Should still deserialize successfully, validation is responsibility of business logic
      expect(metrics.totalRequests, -1);
      expect(metrics.errorRate, -0.1);
    });

    test('should handle extremely large numbers in model sizes', () {
      final model = LocalModelInfo(
        modelName: 'large-model',
        sizeGb: double.infinity,
        loaded: true,
        contextWindow: 2147483647, // Max int32
        maxTokens: 4294967295, // Max uint32
      );

      expect(model.sizeGb, double.infinity);
      expect(model.contextWindow, 2147483647);
      expect(model.maxTokens, 4294967295);
    });

    test('should handle empty model names', () {
      final config = LLMModelConfig(
        modelName: '',
        provider: LLMProvider.local,
      );

      expect(config.modelName, isEmpty);
    });

    test('should handle very long model names', () {
      final longName = 'a' * 1000;
      final config = LLMModelConfig(
        modelName: longName,
        provider: LLMProvider.local,
      );

      expect(config.modelName.length, 1000);
    });

    test('should handle special characters in model names', () {
      final specialName = 'model-name_with/special@chars!';
      final config = LLMModelConfig(
        modelName: specialName,
        provider: LLMProvider.local,
      );

      expect(config.modelName, specialName);
    });

    test('should handle unicode characters in provider settings', () {
      final settings = LLMProviderSettings(
        provider: LLMProvider.openrouter,
        apiKey: '🔑-api-key-🚀',
        baseUrl: 'https://api.example.com/测试',
      );

      expect(settings.apiKey, '🔑-api-key-🚀');
      expect(settings.baseUrl, 'https://api.example.com/测试');
    });
  });

  group('Data Integrity and Consistency Tests', () {
    test('should maintain consistency between models and loadedModels', () {
      final models = [
        LocalModelInfo(
          modelName: 'model1',
          sizeGb: 2.5,
          loaded: true,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
        LocalModelInfo(
          modelName: 'model2',
          sizeGb: 3.0,
          loaded: false,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
      ];

      final response = LocalModelsListResponse(
        models: models,
        loadedModels: ['model1'],
      );

      // Verify that all loaded models exist in the models list
      for (final loadedModel in response.loadedModels) {
        expect(
          response.models.any((model) => model.modelName == loadedModel),
          true,
        );
      }

      // Verify that loaded models have loaded=true
      for (final model in response.models) {
        if (response.loadedModels.contains(model.modelName)) {
          expect(model.loaded, true);
        }
      }
    });

    test('should handle duplicate model names in response', () {
      final models = [
        LocalModelInfo(
          modelName: 'duplicate',
          sizeGb: 2.5,
          loaded: true,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
        LocalModelInfo(
          modelName: 'duplicate',
          sizeGb: 3.0,
          loaded: false,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
      ];

      final response = LocalModelsListResponse(
        models: models,
        loadedModels: ['duplicate'],
      );

      // Should handle duplicates gracefully
      expect(response.models.length, 2);
      expect(response.loadedModels, ['duplicate']);
    });

    test('should maintain provider consistency in config', () {
      final providers = {
        LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
        LLMProvider.openrouter: LLMProviderSettings(
          provider: LLMProvider.openrouter,
        ),
      };

      final models = {
        'local-model': LLMModelConfig(
          modelName: 'local-model',
          provider: LLMProvider.local,
        ),
        'openrouter-model': LLMModelConfig(
          modelName: 'openrouter-model',
          provider: LLMProvider.openrouter,
        ),
        'mismatched-model': LLMModelConfig(
          modelName: 'mismatched-model',
          provider: LLMProvider.local,
        ),
      };

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'local-model',
        providers: providers,
        models: models,
      );

      // All models should have consistent provider mapping
      for (final entry in config.models.entries) {
        if (entry.key == 'openrouter-model') {
          expect(entry.value.provider, LLMProvider.openrouter);
        } else {
          expect(entry.value.provider, LLMProvider.local);
        }
      }
    });
  });

  group('Round-trip Serialization Tests', () {
    test('should maintain data integrity through JSON serialization/deserialization', () {
      final originalModels = [
        LocalModelInfo(
          modelName: 'test-model',
          sizeGb: 2.5,
          loaded: true,
          contextWindow: 4096,
          maxTokens: 2048,
          lastUsed: DateTime.parse('2023-01-01T00:00:00.000Z'),
          isLoading: false,
        ),
      ];

      final originalResponse = LocalModelsListResponse(
        models: originalModels,
        loadedModels: ['test-model'],
      );

      // Serialize to JSON
      final json = originalResponse.toJson();
      
      // Deserialize from JSON
      final deserializedResponse = LocalModelsListResponse.fromJson(json);

      // Verify data integrity
      expect(deserializedResponse.models.length, originalResponse.models.length);
      expect(deserializedResponse.loadedModels, originalResponse.loadedModels);
      
      final deserializedModel = deserializedResponse.models.first;
      final originalModel = originalResponse.models.first;
      expect(deserializedModel.modelName, originalModel.modelName);
      expect(deserializedModel.sizeGb, originalModel.sizeGb);
      expect(deserializedModel.loaded, originalModel.loaded);
      expect(deserializedModel.contextWindow, originalModel.contextWindow);
      expect(deserializedModel.maxTokens, originalModel.maxTokens);
      expect(deserializedModel.lastUsed, originalModel.lastUsed);
    });

    test('should handle complete LLMConfigResponse round-trip', () {
      final originalProviders = {
        LLMProvider.local: LLMProviderSettings(
          provider: LLMProvider.local,
          timeout: 60,
        ),
        LLMProvider.openrouter: LLMProviderSettings(
          provider: LLMProvider.openrouter,
          apiKey: 'test-key',
        ),
      };

      final originalModels = {
        'test-model': LLMModelConfig(
          modelName: 'test-model',
          provider: LLMProvider.local,
          temperature: 0.8,
        ),
      };

      final originalConfig = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model',
        providers: originalProviders,
        models: originalModels,
      );

      // Serialize to JSON
      final json = originalConfig.toJson();
      
      // Deserialize from JSON
      final deserializedConfig = LLMConfigResponse.fromJson(json);

      // Verify data integrity
      expect(deserializedConfig.activeProvider, originalConfig.activeProvider);
      expect(deserializedConfig.activeModel, originalConfig.activeModel);
      expect(deserializedConfig.providers.length, originalConfig.providers.length);
      expect(deserializedConfig.models.length, originalConfig.models.length);
      
      // Verify active settings
      expect(deserializedConfig.activeProviderSettings.timeout, 60);
      
      // Verify model config
      expect(deserializedConfig.activeModelConfig?.temperature, 0.8);
    });
  });
}