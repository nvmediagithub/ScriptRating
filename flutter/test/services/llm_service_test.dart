import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:script_rating_app/services/llm_service.dart';
import 'package:script_rating_app/models/llm_models.dart';
import 'test_utils.dart';

void main() {
  group('LlmService', () {
    late LlmService llmService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      llmService = LlmService(mockDio);
      // Reset any registered calls
      reset(mockDio);
    });

    group('Constructor Tests', () {
      test('should initialize with correct base URL and headers when base URL is empty', () {
        final dio = Dio();
        final service = LlmService(dio);
        
        expect(dio.options.baseUrl, 'http://localhost:8000/api/v1');
        expect(dio.options.headers['Content-Type'], 'application/json');
      });

      test('should preserve existing base URL if provided', () {
        final dio = Dio();
        dio.options.baseUrl = 'https://custom-api.example.com/api/v2';
        
        final service = LlmService(dio);
        
        expect(dio.options.baseUrl, 'https://custom-api.example.com/api/v2');
      });

      test('should preserve existing headers and add Content-Type if missing', () {
        final dio = Dio();
        dio.options.headers['Authorization'] = 'Bearer token';
        
        final service = LlmService(dio);
        
        expect(dio.options.baseUrl, 'http://localhost:8000/api/v1');
        expect(dio.options.headers['Content-Type'], 'application/json');
        expect(dio.options.headers['Authorization'], 'Bearer token');
      });
    });

    group('getConfig Tests', () {
      test('should successfully fetch LLM configuration', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson();
        final response = MockResponseFactory.createSuccessResponse(configJson);
        
        when(() => mockDio.get('/llm/config')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getConfig();

        // Assert
        expect(result, isA<LLMConfigResponse>());
        expect(result.activeProvider, LLMProvider.local);
        expect(result.activeModel, 'test-model');
        expect(result.providers, isA<Map<LLMProvider, LLMProviderSettings>>());
        expect(result.models, isA<Map<String, LLMModelConfig>>());
        verify(() => mockDio.get('/llm/config')).called(1);
      });

      test('should handle getLLMConfig as alias for getConfig', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson();
        final response = MockResponseFactory.createSuccessResponse(configJson);
        
        when(() => mockDio.get('/llm/config')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getLLMConfig();

        // Assert
        expect(result, isA<LLMConfigResponse>());
        expect(result.activeProvider, LLMProvider.local);
        verify(() => mockDio.get('/llm/config')).called(1);
      });

      test('should handle malformed JSON response', () async {
        // Arrange
        final malformedResponse = MockResponseFactory.createSuccessResponse({'invalid': 'json'});
        
        when(() => mockDio.get('/llm/config')).thenAnswer((_) async => malformedResponse);

        // Act & Assert
        expect(
          () => llmService.getConfig(),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle network timeout', () async {
        // Arrange
        when(() => mockDio.get('/llm/config'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/llm/config'),
              type: DioExceptionType.connectionTimeout,
              message: 'Connection timeout',
            ));

        // Act & Assert
        expect(
          () => llmService.getConfig(),
          throwsA(isA<DioException>()),
        );
        verify(() => mockDio.get('/llm/config')).called(1);
      });

      test('should handle HTTP 500 Internal Server Error', () async {
        // Arrange
        when(() => mockDio.get('/llm/config')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getConfig(),
          throwsA(isA<DioException>()),
        );
        verify(() => mockDio.get('/llm/config')).called(1);
      });

      test('should handle HTTP 404 Not Found', () async {
        // Arrange
        when(() => mockDio.get('/llm/config')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 404,
            message: 'Not found',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getConfig(),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle server unavailable (HTTP 503)', () async {
        // Arrange
        when(() => mockDio.get('/llm/config')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 503,
            message: 'Service unavailable',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getConfig(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getStatuses Tests', () {
      test('should successfully fetch LLM provider statuses', () async {
        // Arrange
        final statusesJson = [
          TestDataGenerator.createValidLLMStatusJson(
            provider: 'local',
            available: true,
            healthy: true,
          ),
          TestDataGenerator.createValidLLMStatusJson(
            provider: 'open_router',
            available: true,
            healthy: false,
            errorMessage: 'Rate limit exceeded',
          ),
        ];
        final response = MockResponseFactory.createSuccessListResponse(statusesJson);
        
        when(() => mockDio.get('/llm/status')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getStatuses();

        // Assert
        expect(result, isA<List<LLMStatusResponse>>());
        expect(result.length, 2);
        expect(result[0].provider, LLMProvider.local);
        expect(result[0].available, true);
        expect(result[0].healthy, true);
        expect(result[1].provider, LLMProvider.openrouter);
        expect(result[1].available, true);
        expect(result[1].healthy, false);
        expect(result[1].errorMessage, 'Rate limit exceeded');
        verify(() => mockDio.get('/llm/status')).called(1);
      });

      test('should handle empty statuses list', () async {
        // Arrange
        final emptyResponse = MockResponseFactory.createSuccessListResponse([]);
        when(() => mockDio.get('/llm/status')).thenAnswer((_) async => emptyResponse);

        // Act
        final result = await llmService.getStatuses();

        // Assert
        expect(result, isA<List<LLMStatusResponse>>());
        expect(result, isEmpty);
        verify(() => mockDio.get('/llm/status')).called(1);
      });

      test('should handle getAllProvidersStatus as alias', () async {
        // Arrange
        final statusesJson = [
          TestDataGenerator.createValidLLMStatusJson(
            provider: 'local',
            available: true,
            healthy: true,
          ),
        ];
        final response = MockResponseFactory.createSuccessListResponse(statusesJson);
        
        when(() => mockDio.get('/llm/status')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getAllProvidersStatus();

        // Assert
        expect(result, isA<List<LLMStatusResponse>>());
        expect(result.length, 1);
        verify(() => mockDio.get('/llm/status')).called(1);
      });

      test('should handle malformed status response', () async {
        // Arrange
        final malformedResponse = MockResponseFactory.createSuccessListResponse([
          {'invalid': 'data'},
        ]);
        
        when(() => mockDio.get('/llm/status')).thenAnswer((_) async => malformedResponse);

        // Act & Assert
        expect(
          () => llmService.getStatuses(),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        when(() => mockDio.get('/llm/status')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getStatuses(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getLocalModels Tests', () {
      test('should successfully fetch local models list', () async {
        // Arrange
        final modelsJson = TestDataGenerator.createValidLocalModelsJson();
        final response = MockResponseFactory.createSuccessResponse(modelsJson);
        
        when(() => mockDio.get('/llm/local/models')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getLocalModels();

        // Assert
        expect(result, isA<LocalModelsListResponse>());
        expect(result.models, isA<List<LocalModelInfo>>());
        expect(result.loadedModels, isA<List<String>>());
        expect(result.models.first, isA<LocalModelInfo>());
        verify(() => mockDio.get('/llm/local/models')).called(1);
      });

      test('should handle multiple loaded models', () async {
        // Arrange
        final multiLoadedModelsJson = TestDataGenerator.createValidLocalModelsJson(
          models: [
            {
              'model_name': 'model1',
              'size_gb': 2.5,
              'loaded': true,
              'context_window': 4096,
              'max_tokens': 2048,
            },
            {
              'model_name': 'model2',
              'size_gb': 4.2,
              'loaded': true,
              'context_window': 8192,
              'max_tokens': 4096,
            },
          ],
          loadedModels: ['model1', 'model2'],
        );
        final response = MockResponseFactory.createSuccessResponse(multiLoadedModelsJson);
        when(() => mockDio.get('/llm/local/models')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getLocalModels();

        // Assert
        expect(result.models.length, 2);
        expect(result.loadedModels.length, 2);
        expect(result.models.where((m) => m.loaded).length, 2);
      });

      test('should handle model with lastUsed date', () async {
        // Arrange
        final modelsJson = {
          'models': [
            {
              'model_name': 'test-model',
              'size_gb': 2.5,
              'loaded': true,
              'context_window': 4096,
              'max_tokens': 2048,
              'last_used': '2023-01-01T00:00:00.000Z',
            },
          ],
          'loaded_models': ['test-model'],
        };
        final response = MockResponseFactory.createSuccessResponse(modelsJson);
        when(() => mockDio.get('/llm/local/models')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getLocalModels();

        // Assert
        expect(result.models.first.lastUsed, isA<DateTime>());
        expect(result.models.first.lastUsed, DateTime.parse('2023-01-01T00:00:00.000Z'));
      });

      test('should handle empty models list', () async {
        // Arrange
        final emptyModelsJson = {
          'models': [],
          'loaded_models': [],
        };
        final response = MockResponseFactory.createSuccessResponse(emptyModelsJson);
        when(() => mockDio.get('/llm/local/models')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getLocalModels();

        // Assert
        expect(result.models, isEmpty);
        expect(result.loadedModels, isEmpty);
      });

      test('should handle server error for local models', () async {
        // Arrange
        when(() => mockDio.get('/llm/local/models')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getLocalModels(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getOpenRouterStatus Tests', () {
      test('should successfully fetch OpenRouter status', () async {
        // Arrange
        final statusJson = TestDataGenerator.createValidOpenRouterStatusJson(
          connected: true,
          creditsRemaining: 15.75,
          rateLimitRemaining: 50,
        );
        final response = MockResponseFactory.createSuccessResponse(statusJson);
        
        when(() => mockDio.get('/llm/openrouter/status')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getOpenRouterStatus();

        // Assert
        expect(result, isA<OpenRouterStatusResponse>());
        expect(result.connected, true);
        expect(result.creditsRemaining, 15.75);
        expect(result.rateLimitRemaining, 50);
        expect(result.errorMessage, null);
        verify(() => mockDio.get('/llm/openrouter/status')).called(1);
      });

      test('should handle OpenRouter not connected', () async {
        // Arrange
        final disconnectedJson = TestDataGenerator.createValidOpenRouterStatusJson(
          connected: false,
          creditsRemaining: null,
          rateLimitRemaining: null,
          errorMessage: 'Invalid API key',
        );
        final response = MockResponseFactory.createSuccessResponse(disconnectedJson);
        when(() => mockDio.get('/llm/openrouter/status')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getOpenRouterStatus();

        // Assert
        expect(result.connected, false);
        expect(result.creditsRemaining, null);
        expect(result.rateLimitRemaining, null);
        expect(result.errorMessage, 'Invalid API key');
      });

      test('should handle null values in status response', () async {
        // Arrange
        final nullStatusJson = {
          'connected': true,
          'credits_remaining': null,
          'rate_limit_remaining': null,
          'error_message': null,
        };
        final response = MockResponseFactory.createSuccessResponse(nullStatusJson);
        when(() => mockDio.get('/llm/openrouter/status')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getOpenRouterStatus();

        // Assert
        expect(result.creditsRemaining, null);
        expect(result.rateLimitRemaining, null);
        expect(result.errorMessage, null);
      });

      test('should handle OpenRouter service unavailable', () async {
        // Arrange
        when(() => mockDio.get('/llm/openrouter/status')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 503,
            message: 'Service unavailable',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getOpenRouterStatus(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getOpenRouterModels Tests', () {
      test('should successfully fetch OpenRouter models', () async {
        // Arrange
        final modelsJson = TestDataGenerator.createValidOpenRouterModelsJson(
          models: ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo', 'claude-3-haiku'],
          total: 4,
        );
        final response = MockResponseFactory.createSuccessResponse(modelsJson);
        
        when(() => mockDio.get('/llm/openrouter/models')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getOpenRouterModels();

        // Assert
        expect(result, isA<OpenRouterModelsListResponse>());
        expect(result.models.length, 4);
        expect(result.total, 4);
        expect(result.models.first, 'gpt-3.5-turbo');
        expect(result.models.last, 'claude-3-haiku');
        verify(() => mockDio.get('/llm/openrouter/models')).called(1);
      });

      test('should handle empty models list', () async {
        // Arrange
        final emptyModelsJson = {
          'models': [],
          'total': 0,
        };
        final response = MockResponseFactory.createSuccessResponse(emptyModelsJson);
        when(() => mockDio.get('/llm/openrouter/models')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getOpenRouterModels();

        // Assert
        expect(result.models, isEmpty);
        expect(result.total, 0);
      });

      test('should handle API error for models fetch', () async {
        // Arrange
        when(() => mockDio.get('/llm/openrouter/models')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getOpenRouterModels(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getHealthSummary Tests', () {
      test('should successfully fetch health summary', () async {
        // Arrange
        final healthJson = TestDataGenerator.createValidHealthSummaryJson(
          localModelsLoaded: 2,
          localModelsAvailable: 5,
          openRouterConnected: true,
          activeProvider: 'local',
          activeModel: 'llama2-7b',
          systemHealthy: true,
        );
        final response = MockResponseFactory.createSuccessResponse(healthJson);
        
        when(() => mockDio.get('/llm/config/health')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getHealthSummary();

        // Assert
        expect(result, isA<LLMHealthSummary>());
        expect(result.localModelsLoaded, 2);
        expect(result.localModelsAvailable, 5);
        expect(result.openRouterConnected, true);
        expect(result.activeProvider, LLMProvider.local);
        expect(result.activeModel, 'llama2-7b');
        expect(result.systemHealthy, true);
        expect(result.providersStatus, isA<List<LLMStatusResponse>>());
        verify(() => mockDio.get('/llm/config/health')).called(1);
      });

      test('should handle unhealthy system status', () async {
        // Arrange
        final unhealthyJson = TestDataGenerator.createValidHealthSummaryJson(
          localModelsLoaded: 0,
          localModelsAvailable: 0,
          openRouterConnected: false,
          activeProvider: 'local',
          activeModel: '',
          systemHealthy: false,
        );
        final response = MockResponseFactory.createSuccessResponse(unhealthyJson);
        when(() => mockDio.get('/llm/config/health')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getHealthSummary();

        // Assert
        expect(result.systemHealthy, false);
        expect(result.localModelsLoaded, 0);
        expect(result.openRouterConnected, false);
      });

      test('should handle server error for health summary', () async {
        // Arrange
        when(() => mockDio.get('/llm/config/health')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getHealthSummary(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getPerformanceReports Tests', () {
      test('should successfully fetch performance reports', () async {
        // Arrange
        final reportsJson = [
          TestDataGenerator.createValidPerformanceReportJson(
            provider: 'local',
            timeRange: '24h',
          ),
          TestDataGenerator.createValidPerformanceReportJson(
            provider: 'open_router',
            timeRange: '24h',
          ),
        ];
        final response = MockResponseFactory.createSuccessListResponse(reportsJson);
        
        when(() => mockDio.get('/llm/performance')).thenAnswer((_) async => response);

        // Act
        final result = await llmService.getPerformanceReports();

        // Assert
        expect(result, isA<List<PerformanceReportResponse>>());
        expect(result.length, 2);
        expect(result[0].provider, LLMProvider.local);
        expect(result[0].metrics, isA<PerformanceMetrics>());
        expect(result[1].provider, LLMProvider.openrouter);
        expect(result[0].timeRange, '24h');
        expect(result[0].generatedAt, isA<DateTime>());
        verify(() => mockDio.get('/llm/performance')).called(1);
      });

      test('should handle empty performance reports', () async {
        // Arrange
        final emptyResponse = MockResponseFactory.createSuccessListResponse([]);
        when(() => mockDio.get('/llm/performance')).thenAnswer((_) async => emptyResponse);

        // Act
        final result = await llmService.getPerformanceReports();

        // Assert
        expect(result, isEmpty);
      });

      test('should handle server error for performance reports', () async {
        // Arrange
        when(() => mockDio.get('/llm/performance')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.getPerformanceReports(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('loadLocalModel Tests', () {
      const modelName = 'llama2-7b';

      test('should successfully load local model', () async {
        // Arrange
        final modelInfoJson = {
          'model_name': modelName,
          'size_gb': 2.5,
          'loaded': true,
          'context_window': 4096,
          'max_tokens': 2048,
          'last_used': '2023-01-01T00:00:00.000Z',
        };
        final response = MockResponseFactory.createSuccessResponse(modelInfoJson);
        
        when(() => mockDio.post('/llm/local/models/load', data: {'model_name': modelName}))
            .thenAnswer((_) async => response);

        // Act
        final result = await llmService.loadLocalModel(modelName);

        // Assert
        expect(result, isA<LocalModelInfo>());
        expect(result.modelName, modelName);
        expect(result.loaded, true);
        expect(result.sizeGb, 2.5);
        expect(result.contextWindow, 4096);
        expect(result.maxTokens, 2048);
        expect(result.lastUsed, isA<DateTime>());
        verify(() => mockDio.post('/llm/local/models/load', data: {'model_name': modelName})).called(1);
      });

      test('should handle model loading failure', () async {
        // Arrange
        when(() => mockDio.post('/llm/local/models/load', data: any(named: 'data')))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 400,
                message: 'Model not found',
              ),
            );

        // Act & Assert
        expect(
          () => llmService.loadLocalModel(modelName),
          throwsA(isA<DioException>()),
        );
        verify(() => mockDio.post('/llm/local/models/load', data: any(named: 'data'))).called(1);
      });

      test('should handle model already loaded', () async {
        // Arrange
        final alreadyLoadedJson = {
          'model_name': modelName,
          'size_gb': 2.5,
          'loaded': true,
          'context_window': 4096,
          'max_tokens': 2048,
        };
        final response = MockResponseFactory.createSuccessResponse(alreadyLoadedJson);
        
        when(() => mockDio.post('/llm/local/models/load', data: {'model_name': modelName}))
            .thenAnswer((_) async => response);

        // Act
        final result = await llmService.loadLocalModel(modelName);

        // Assert - Should still return the model info
        expect(result.loaded, true);
      });

      test('should handle insufficient memory error', () async {
        // Arrange
        when(() => mockDio.post('/llm/local/models/load', data: any(named: 'data')))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 507,
                message: 'Insufficient memory',
              ),
            );

        // Act & Assert
        expect(
          () => llmService.loadLocalModel(modelName),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('unloadLocalModel Tests', () {
      const modelName = 'llama2-7b';

      test('should successfully unload local model', () async {
        // Arrange
        final modelInfoJson = {
          'model_name': modelName,
          'size_gb': 2.5,
          'loaded': false,
          'context_window': 4096,
          'max_tokens': 2048,
        };
        final response = MockResponseFactory.createSuccessResponse(modelInfoJson);
        
        when(() => mockDio.post('/llm/local/models/unload', data: {'model_name': modelName}))
            .thenAnswer((_) async => response);

        // Act
        final result = await llmService.unloadLocalModel(modelName);

        // Assert
        expect(result, isA<LocalModelInfo>());
        expect(result.modelName, modelName);
        expect(result.loaded, false);
        verify(() => mockDio.post('/llm/local/models/unload', data: {'model_name': modelName})).called(1);
      });

      test('should handle model not loaded error', () async {
        // Arrange
        when(() => mockDio.post('/llm/local/models/unload', data: any(named: 'data')))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 400,
                message: 'Model not loaded',
              ),
            );

        // Act & Assert
        expect(
          () => llmService.unloadLocalModel(modelName),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('switchMode Tests', () {
      const provider = LLMProvider.local;
      const modelName = 'llama2-7b';

      test('should successfully switch to local model', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson(
          activeProvider: provider.name,
          activeModel: modelName,
        );
        final response = MockResponseFactory.createSuccessResponse(configJson);
        
        when(() => mockDio.put(
          '/llm/config/mode',
          queryParameters: {'provider': provider.name, 'model_name': modelName},
        )).thenAnswer((_) async => response);

        // Act
        final result = await llmService.switchMode(provider, modelName);

        // Assert
        expect(result, isA<LLMConfigResponse>());
        expect(result.activeProvider, provider);
        expect(result.activeModel, modelName);
        verify(() => mockDio.put(
          '/llm/config/mode',
          queryParameters: {'provider': provider.name, 'model_name': modelName},
        )).called(1);
      });

      test('should successfully switch to OpenRouter model', () async {
        // Arrange
        const openRouterProvider = LLMProvider.openrouter;
        const openRouterModel = 'gpt-4';
        final configJson = TestDataGenerator.createValidLLMConfigJson(
          activeProvider: openRouterProvider.name,
          activeModel: openRouterModel,
        );
        final response = MockResponseFactory.createSuccessResponse(configJson);
        
        when(() => mockDio.put(
          '/llm/config/mode',
          queryParameters: {'provider': openRouterProvider.name, 'model_name': openRouterModel},
        )).thenAnswer((_) async => response);

        // Act
        final result = await llmService.switchMode(openRouterProvider, openRouterModel);

        // Assert
        expect(result.activeProvider, openRouterProvider);
        expect(result.activeModel, openRouterModel);
        verify(() => mockDio.put(
          '/llm/config/mode',
          queryParameters: {'provider': openRouterProvider.name, 'model_name': openRouterModel},
        )).called(1);
      });

      test('should handle switch to non-existent model', () async {
        // Arrange
        const nonExistentModel = 'non-existent-model';
        when(() => mockDio.put(
          '/llm/config/mode',
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 404,
            message: 'Model not found',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.switchMode(provider, nonExistentModel),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle provider unavailable error', () async {
        // Arrange
        when(() => mockDio.put(
          '/llm/config/mode',
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 503,
            message: 'Provider unavailable',
          ),
        );

        // Act & Assert
        expect(
          () => llmService.switchMode(provider, modelName),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('Integration Tests', () {
      test('should handle complete LLM management workflow', () async {
        // Arrange - Get initial configuration
        final configJson = TestDataGenerator.createValidLLMConfigJson(
          activeProvider: 'local',
          activeModel: 'model1',
        );
        when(() => mockDio.get('/llm/config'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(configJson));

        // Arrange - Get statuses
        final statusesJson = [
          TestDataGenerator.createValidLLMStatusJson(provider: 'local', available: true, healthy: true),
        ];
        when(() => mockDio.get('/llm/status'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessListResponse(statusesJson));

        // Arrange - Get local models
        final modelsJson = TestDataGenerator.createValidLocalModelsJson(
          models: [
            {
              'model_name': 'model1',
              'size_gb': 2.5,
              'loaded': true,
              'context_window': 4096,
              'max_tokens': 2048,
            },
            {
              'model_name': 'model2',
              'size_gb': 3.0,
              'loaded': false,
              'context_window': 4096,
              'max_tokens': 2048,
            },
          ],
          loadedModels: ['model1'],
        );
        when(() => mockDio.get('/llm/local/models'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(modelsJson));

        // Arrange - Load new model
        final loadResponse = {
          'model_name': 'model2',
          'size_gb': 3.0,
          'loaded': true,
          'context_window': 4096,
          'max_tokens': 2048,
        };
        when(() => mockDio.post('/llm/local/models/load', data: {'model_name': 'model2'}))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(loadResponse));

        // Arrange - Switch to new model
        final switchConfigJson = TestDataGenerator.createValidLLMConfigJson(
          activeProvider: 'local',
          activeModel: 'model2',
        );
        when(() => mockDio.put(
          '/llm/config/mode',
          queryParameters: {'provider': 'local', 'model_name': 'model2'},
        )).thenAnswer((_) async => MockResponseFactory.createSuccessResponse(switchConfigJson));

        // Act - Execute workflow
        final config = await llmService.getConfig();
        final statuses = await llmService.getStatuses();
        final models = await llmService.getLocalModels();
        final loadedModel = await llmService.loadLocalModel('model2');
        final switchedConfig = await llmService.switchMode(LLMProvider.local, 'model2');

        // Assert
        expect(config.activeModel, 'model1');
        expect(statuses.length, 1);
        expect(models.loadedModels, ['model1']);
        expect(loadedModel.modelName, 'model2');
        expect(switchedConfig.activeModel, 'model2');
      });
    });

    group('Provider Management Tests', () {
      test('should get LLM providers from config', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson();
        when(() => mockDio.get('/llm/config'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(configJson));

        // Act
        final result = await llmService.getLLMProviders();

        // Assert
        expect(result, isA<Map<LLMProvider, LLMProviderSettings>>());
        expect(result.length, 2);
        expect(result.containsKey(LLMProvider.local), true);
        expect(result.containsKey(LLMProvider.openrouter), true);
      });

      test('should get active provider', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson();
        when(() => mockDio.get('/llm/config'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(configJson));

        // Act
        final result = await llmService.getActiveProvider();

        // Assert
        expect(result, isA<LLMProvider>());
        expect(result, LLMProvider.local);
      });

      test('should set active provider', () async {
        // Arrange
        final updateJson = TestDataGenerator.createValidLLMConfigJson(activeProvider: 'openrouter');
        when(() => mockDio.put('/llm/config', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(updateJson));

        // Act
        await llmService.setActiveProvider(LLMProvider.openrouter);

        // Assert
        verify(() => mockDio.put('/llm/config', data: {'provider': 'openrouter'})).called(1);
      });

      test('should handle set active provider error', () async {
        // Arrange
        when(() => mockDio.put('/llm/config', data: anyNamed('data')))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 500,
                message: 'Internal server error',
              ),
            );

        // Act & Assert
        expect(
          () => llmService.setActiveProvider(LLMProvider.openrouter),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Model Management Tests', () {
      test('should get LLM models from config', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson();
        when(() => mockDio.get('/llm/config'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(configJson));

        // Act
        final result = await llmService.getLLMModels();

        // Assert
        expect(result, isA<Map<String, LLMModelConfig>>());
        expect(result.length, greaterThan(0));
      });

      test('should get active model', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson();
        when(() => mockDio.get('/llm/config'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(configJson));

        // Act
        final result = await llmService.getActiveModel();

        // Assert
        expect(result, isA<String>());
        expect(result, 'test-model');
      });

      test('should set active model', () async {
        // Arrange
        final updateJson = TestDataGenerator.createValidLLMConfigJson(activeModel: 'new-model');
        when(() => mockDio.put('/llm/config', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(updateJson));

        // Act
        await llmService.setActiveModel('new-model', provider: LLMProvider.local);

        // Assert
        verify(() => mockDio.put('/llm/config', data: {
          'model_name': 'new-model',
          'provider': 'local',
        })).called(1);
      });

      test('should get models by provider', () async {
        // Arrange
        final configJson = TestDataGenerator.createValidLLMConfigJson();
        when(() => mockDio.get('/llm/config'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(configJson));

        final models = await llmService.getLLMModels();

        // Act
        final result = llmService.getModelsByProvider(LLMProvider.local, models);

        // Assert
        expect(result, isA<List<String>>());
        expect(result.isNotEmpty, true);
      });
    });

    group('Status Monitoring Tests', () {
      test('should get provider status for specific provider', () async {
        // Arrange
        final statusJson = TestDataGenerator.createValidLLMStatusJson(
          provider: 'local',
          available: true,
          healthy: true,
        );
        when(() => mockDio.get('/llm/status/local'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(statusJson));

        // Act
        final result = await llmService.getProviderStatus(LLMProvider.local);

        // Assert
        expect(result, isA<LLMStatusResponse>());
        expect(result.provider, LLMProvider.local);
        expect(result.available, true);
        expect(result.healthy, true);
      });

      test('should check providers health', () async {
        // Arrange
        final statusesJson = [
          TestDataGenerator.createValidLLMStatusJson(provider: 'local', available: true, healthy: true),
          TestDataGenerator.createValidLLMStatusJson(provider: 'openrouter', available: true, healthy: false),
        ];
        when(() => mockDio.get('/llm/status'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessListResponse(statusesJson));

        // Act
        final result = await llmService.checkProvidersHealth();

        // Assert
        expect(result, isA<Map<LLMProvider, bool>>());
        expect(result[LLMProvider.local], true);
        expect(result[LLMProvider.openrouter], false);
      });

      test('should handle provider status error', () async {
        // Arrange
        when(() => mockDio.get('/llm/status/local'))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 500,
                message: 'Internal server error',
              ),
            );

        // Act & Assert
        expect(
          () => llmService.getProviderStatus(LLMProvider.local),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Performance and Health Tests', () {
      test('should get provider metrics', () async {
        // Arrange
        final metricsJson = {
          'total_requests': 100,
          'successful_requests': 95,
          'average_response_time_ms': 150.0,
        };
        when(() => mockDio.get('/llm/performance/local'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(metricsJson));

        // Act
        final result = await llmService.getProviderMetrics(LLMProvider.local);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['total_requests'], 100);
        expect(result['successful_requests'], 95);
      });

      test('should get all providers metrics', () async {
        // Arrange
        final metricsJson = {
          'local': {
            'total_requests': 100,
            'successful_requests': 95,
          },
          'openrouter': {
            'total_requests': 200,
            'successful_requests': 180,
          },
        };
        when(() => mockDio.get('/llm/performance'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(metricsJson));

        // Act
        final result = await llmService.getAllProvidersMetrics();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['local'], isA<Map<String, dynamic>>());
        expect(result['openrouter'], isA<Map<String, dynamic>>());
      });

      test('should get system health', () async {
        // Arrange
        final healthJson = TestDataGenerator.createValidHealthSummaryJson(
          systemHealthy: true,
        );
        when(() => mockDio.get('/llm/config/health'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(healthJson));

        // Act
        final result = await llmService.getSystemHealth();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['system_healthy'], true);
      });
    });

    group('Testing and Validation Tests', () {
      test('should test LLM with prompt', () async {
        // Arrange
        final testJson = {
          'model_name': 'test-model',
          'provider': 'local',
          'prompt': 'Hello, world!',
          'response': 'Hello! How can I help you?',
          'tokens_used': 10,
          'response_time_ms': 500.0,
          'success': true,
        };
        when(() => mockDio.post('/llm/test', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(testJson));

        // Act
        final result = await llmService.testLLM('Hello, world!');

        // Assert
        expect(result, isA<LLMTestResponse>());
        expect(result.success, true);
        expect(result.prompt, 'Hello, world!');
        expect(result.response, 'Hello! How can I help you?');
      });

      test('should test LLM with specific model', () async {
        // Arrange
        final testJson = {
          'model_name': 'gpt-4',
          'provider': 'openrouter',
          'prompt': 'Test prompt',
          'response': 'Test response',
          'tokens_used': 5,
          'response_time_ms': 300.0,
          'success': true,
        };
        when(() => mockDio.post('/llm/test', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(testJson));

        // Act
        final result = await llmService.testLLM('Test prompt', modelName: 'gpt-4');

        // Assert
        expect(result.modelName, 'gpt-4');
        expect(result.provider, LLMProvider.openrouter);
      });

      test('should handle test LLM failure', () async {
        // Arrange
        when(() => mockDio.post('/llm/test', data: anyNamed('data')))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 500,
                message: 'Test failed',
              ),
            );

        // Act & Assert
        expect(
          () => llmService.testLLM('Test prompt'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Configuration Tests', () {
      test('should update config with provider', () async {
        // Arrange
        final updateJson = TestDataGenerator.createValidLLMConfigJson(activeProvider: 'openrouter');
        when(() => mockDio.put('/llm/config', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(updateJson));

        // Act
        final result = await llmService.updateConfig(provider: LLMProvider.openrouter);

        // Assert
        expect(result.activeProvider, LLMProvider.openrouter);
        verify(() => mockDio.put('/llm/config', data: {'provider': 'openrouter'})).called(1);
      });

      test('should update config with model name', () async {
        // Arrange
        final updateJson = TestDataGenerator.createValidLLMConfigJson(activeModel: 'new-model');
        when(() => mockDio.put('/llm/config', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(updateJson));

        // Act
        final result = await llmService.updateConfig(modelName: 'new-model');

        // Assert
        expect(result.activeModel, 'new-model');
        verify(() => mockDio.put('/llm/config', data: {'model_name': 'new-model'})).called(1);
      });

      test('should update provider settings', () async {
        // Arrange
        final settings = LLMProviderSettings(
          provider: LLMProvider.openrouter,
          apiKey: 'test-key',
          timeout: 60,
        );
        final updateJson = TestDataGenerator.createValidLLMConfigJson();
        when(() => mockDio.put('/llm/config', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(updateJson));

        // Act
        await llmService.updateProviderSettings(settings);

        // Assert
        verify(() => mockDio.put('/llm/config', data: anyNamed('data'))).called(1);
      });

      test('should configure OpenRouter', () async {
        // Arrange
        final updateJson = TestDataGenerator.createValidLLMConfigJson();
        when(() => mockDio.put('/llm/config', data: anyNamed('data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(updateJson));

        // Act
        await llmService.configureOpenRouter(
          apiKey: 'test-key',
          timeout: 60,
          maxRetries: 5,
        );

        // Assert
        verify(() => mockDio.put('/llm/config', data: anyNamed('data'))).called(1);
      });
    });

    group('Connection Testing Tests', () {
      test('should test connection to provider', () async {
        // Arrange
        final statusJson = TestDataGenerator.createValidLLMStatusJson(
          provider: 'local',
          available: true,
          healthy: true,
        );
        when(() => mockDio.get('/llm/status/local'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(statusJson));

        // Act
        final result = await llmService.testConnection(LLMProvider.local);

        // Assert
        expect(result, true);
      });

      test('should handle connection test failure', () async {
        // Arrange
        when(() => mockDio.get('/llm/status/local'))
            .thenThrow(Exception('Connection failed'));

        // Act
        final result = await llmService.testConnection(LLMProvider.local);

        // Assert
        expect(result, false);
      });

      test('should test OpenRouter connection', () async {
        // Arrange
        final statusJson = TestDataGenerator.createValidOpenRouterStatusJson(connected: true);
        when(() => mockDio.get('/llm/openrouter/status'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(statusJson));

        // Act
        final result = await llmService.testOpenRouterConnection();

        // Assert
        expect(result, true);
      });

      test('should handle OpenRouter connection test failure', () async {
        // Arrange
        when(() => mockDio.get('/llm/openrouter/status'))
            .thenThrow(Exception('Connection failed'));

        // Act
        final result = await llmService.testOpenRouterConnection();

        // Assert
        expect(result, false);
      });
    });

    group('Lifecycle Tests', () {
      test('should initialize service', () async {
        // Act
        await llmService.initialize();

        // Assert - Should not throw any exceptions
        expect(true, true);
      });

      test('should dispose service', () async {
        // Act
        await llmService.dispose();

        // Assert - Should not throw any exceptions
        expect(true, true);
      });
    });
  });
}
