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
        verify(() => mockDio.get('/llm/config')).called(1);
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
        expect(result.errorMessage, 'Invalid API key');
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
        verify(() => mockDio.get('/llm/openrouter/models')).called(1);
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
        verify(() => mockDio.get('/llm/config/health')).called(1);
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
        expect(result[1].provider, LLMProvider.openrouter);
        verify(() => mockDio.get('/llm/performance')).called(1);
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
  });
}

