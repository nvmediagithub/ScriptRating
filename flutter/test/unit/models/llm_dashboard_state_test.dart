import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/llm_dashboard_state.dart';
import 'package:script_rating_app/models/llm_models.dart';

void main() {
  group('LlmDashboardState Model Tests', () {
    // Valid test data
    final validConfig = LLMConfigResponse(
      activeProvider: LLMProvider.local,
      activeModel: 'test-model',
      providers: {},
      models: {},
    );

    final validStatuses = [
      LLMStatusResponse(
        provider: LLMProvider.local,
        available: true,
        healthy: true,
        responseTimeMs: 100.0,
        errorMessage: null,
        lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      ),
    ];

    final validLocalModels = LocalModelsListResponse(
      models: [
        LocalModelInfo(
          modelName: 'test-model',
          sizeGb: 1.5,
          loaded: true,
          contextWindow: 4096,
          maxTokens: 2048,
          lastUsed: DateTime.parse('2023-01-01T00:00:00.000Z'),
        ),
      ],
      loadedModels: ['test-model'],
    );

    final validOpenRouterStatus = OpenRouterStatusResponse(
      connected: true,
      creditsRemaining: 100.0,
      rateLimitRemaining: 1000,
      errorMessage: null,
    );

    final validOpenRouterModels = OpenRouterModelsListResponse(
      models: ['model1', 'model2'],
      total: 2,
    );

    final validHealthSummary = LLMHealthSummary(
      providersStatus: validStatuses,
      localModelsLoaded: 1,
      localModelsAvailable: 5,
      openRouterConnected: true,
      activeProvider: LLMProvider.local,
      activeModel: 'test-model',
      systemHealthy: true,
    );

    final validPerformanceReports = [
      PerformanceReportResponse(
        provider: LLMProvider.local,
        metrics: PerformanceMetrics(
          totalRequests: 100,
          successfulRequests: 95,
          failedRequests: 5,
          averageResponseTimeMs: 150.0,
          totalTokensUsed: 10000,
          errorRate: 0.05,
          uptimePercentage: 95.0,
        ),
        timeRange: '24h',
        generatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      ),
    ];

    group('LlmDashboardState Constructor Tests', () {
      test('should create LLM dashboard state with all parameters', () {
        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
          isRefreshing: true,
        );

        expect(state.config, validConfig);
        expect(state.statuses, validStatuses);
        expect(state.localModels, validLocalModels);
        expect(state.openRouterStatus, validOpenRouterStatus);
        expect(state.openRouterModels, validOpenRouterModels);
        expect(state.healthSummary, validHealthSummary);
        expect(state.performanceReports, validPerformanceReports);
        expect(state.isRefreshing, true);
      });

      test('should create LLM dashboard state with minimal parameters', () {
        final minimalConfig = LLMConfigResponse(
          activeProvider: LLMProvider.local,
          activeModel: 'minimal-model',
          providers: {},
          models: {},
        );

        final minimalState = LlmDashboardState(
          config: minimalConfig,
          statuses: [],
          localModels: LocalModelsListResponse(models: [], loadedModels: []),
          openRouterStatus: OpenRouterStatusResponse(connected: false),
          openRouterModels: OpenRouterModelsListResponse(models: [], total: 0),
          healthSummary: LLMHealthSummary(
            providersStatus: [],
            localModelsLoaded: 0,
            localModelsAvailable: 0,
            openRouterConnected: false,
            activeProvider: LLMProvider.local,
            activeModel: 'minimal-model',
            systemHealthy: false,
          ),
          performanceReports: [],
        );

        expect(minimalState.config, minimalConfig);
        expect(minimalState.statuses, isEmpty);
        expect(minimalState.localModels.models, isEmpty);
        expect(minimalState.openRouterStatus.connected, false);
        expect(minimalState.openRouterModels.total, 0);
        expect(minimalState.performanceReports, isEmpty);
        expect(minimalState.isRefreshing, false); // Default value
      });

      test('should use default value for isRefreshing', () {
        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        expect(state.isRefreshing, false);
      });

      test('should handle large data sets', () {
        final largeStatuses = List.generate(100, (index) => LLMStatusResponse(
          provider: LLMProvider.local,
          available: true,
          healthy: index % 2 == 0,
          responseTimeMs: 100.0 + index,
          errorMessage: index % 3 == 0 ? 'Error $index' : null,
          lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        ));

        final largeLocalModels = LocalModelsListResponse(
          models: List.generate(1000, (index) => LocalModelInfo(
            modelName: 'model-$index',
            sizeGb: 1.0 + index * 0.1,
            loaded: index % 2 == 0,
            contextWindow: 4096,
            maxTokens: 2048,
            lastUsed: DateTime.parse('2023-01-01T00:00:00.000Z'),
          )),
          loadedModels: List.generate(50, (index) => 'model-$index'),
        );

        final largePerformanceReports = List.generate(50, (index) => PerformanceReportResponse(
          provider: index % 2 == 0 ? LLMProvider.local : LLMProvider.openrouter,
          metrics: PerformanceMetrics(
            totalRequests: 1000 + index * 100,
            successfulRequests: 900 + index * 90,
            failedRequests: 100 + index * 10,
            averageResponseTimeMs: 150.0 + index * 10,
            totalTokensUsed: 100000 + index * 10000,
            errorRate: 0.1 + index * 0.01,
            uptimePercentage: 90.0 + index * 0.5,
          ),
          timeRange: '24h',
          generatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        ));

        final state = LlmDashboardState(
          config: validConfig,
          statuses: largeStatuses,
          localModels: largeLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: largePerformanceReports,
        );

        expect(state.statuses.length, 100);
        expect(state.localModels.models.length, 1000);
        expect(state.localModels.loadedModels.length, 50);
        expect(state.performanceReports.length, 50);
      });

      test('should handle null values in nullable fields', () {
        final stateWithNulls = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: OpenRouterStatusResponse(
            connected: true,
            creditsRemaining: null,
            rateLimitRemaining: null,
            errorMessage: null,
          ),
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        expect(stateWithNulls.openRouterStatus.creditsRemaining, null);
        expect(stateWithNulls.openRouterStatus.rateLimitRemaining, null);
        expect(stateWithNulls.openRouterStatus.errorMessage, null);
      });
    });

    group('LlmDashboardState.copyWith Tests', () {
      test('should copy state with all parameters changed', () {
        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final newConfig = LLMConfigResponse(
          activeProvider: LLMProvider.openrouter,
          activeModel: 'new-model',
          providers: {},
          models: {},
        );

        final newStatuses = [
          LLMStatusResponse(
            provider: LLMProvider.openrouter,
            available: false,
            healthy: false,
            responseTimeMs: null,
            errorMessage: 'Connection failed',
            lastCheckedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
          ),
        ];

        final newState = originalState.copyWith(
          config: newConfig,
          statuses: newStatuses,
          isRefreshing: true,
        );

        expect(newState.config, newConfig);
        expect(newState.statuses, newStatuses);
        expect(newState.isRefreshing, true);
        
        // Other properties should remain the same
        expect(newState.localModels, originalState.localModels);
        expect(newState.openRouterStatus, originalState.openRouterStatus);
        expect(newState.openRouterModels, originalState.openRouterModels);
        expect(newState.healthSummary, originalState.healthSummary);
        expect(newState.performanceReports, originalState.performanceReports);
      });

      test('should copy state with single parameter changed', () {
        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
          isRefreshing: false,
        );

        final newState = originalState.copyWith(isRefreshing: true);

        expect(newState.isRefreshing, true);
        expect(newState.config, originalState.config);
        expect(newState.statuses, originalState.statuses);
      });

      test('should copy state with null values', () {
        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final newState = originalState.copyWith(
          config: null,
          statuses: null,
        );

        expect(newState.config, originalState.config);
        expect(newState.statuses, originalState.statuses);
      });

      test('should copy state with empty lists', () {
        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final newState = originalState.copyWith(
          statuses: [],
          performanceReports: [],
        );

        expect(newState.statuses, isEmpty);
        expect(newState.performanceReports, isEmpty);
        expect(newState.config, originalState.config);
      });

      test('should create independent copies', () {
        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final modifiedStatuses = [
          ...validStatuses,
          LLMStatusResponse(
            provider: LLMProvider.openrouter,
            available: true,
            healthy: true,
            responseTimeMs: 200.0,
            errorMessage: null,
            lastCheckedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
          ),
        ];

        final newState = originalState.copyWith(statuses: modifiedStatuses);

        // Original state should not be affected
        expect(originalState.statuses.length, 1);
        expect(newState.statuses.length, 2);

        // Modifying the input list should not affect the copied state
        modifiedStatuses.add(LLMStatusResponse(
          provider: LLMProvider.local,
          available: false,
          healthy: false,
          responseTimeMs: null,
          errorMessage: 'Test error',
          lastCheckedAt: DateTime.parse('2023-01-03T00:00:00.000Z'),
        ));

        expect(newState.statuses.length, 2);
      });
    });

    group('LlmDashboardState.props Tests', () {
      test('should have correct props count', () {
        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        expect(state.props.length, 8);
      });

      test('should include all properties in props', () {
        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
          isRefreshing: true,
        );

        expect(state.props[0], validConfig);
        expect(state.props[1], validStatuses);
        expect(state.props[2], validLocalModels);
        expect(state.props[3], validOpenRouterStatus);
        expect(state.props[4], validOpenRouterModels);
        expect(state.props[5], validHealthSummary);
        expect(state.props[6], validPerformanceReports);
        expect(state.props[7], true);
      });

      test('should be equal when all properties are the same', () {
        final state1 = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final state2 = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        expect(state1 == state2, true);
        expect(state1.props, state2.props);
      });

      test('should not be equal when any property differs', () {
        final state1 = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final differentConfig = LLMConfigResponse(
          activeProvider: LLMProvider.openrouter,
          activeModel: 'different-model',
          providers: {},
          models: {},
        );

        final state2 = LlmDashboardState(
          config: differentConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        expect(state1 == state2, false);
      });

      test('should not be equal when isRefreshing differs', () {
        final state1 = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final state2 = state1.copyWith(isRefreshing: true);

        expect(state1 == state2, false);
        expect(state1.props[7], false);
        expect(state2.props[7], true);
      });

      test('should handle equality with empty lists', () {
        final state1 = LlmDashboardState(
          config: validConfig,
          statuses: [],
          localModels: LocalModelsListResponse(models: [], loadedModels: []),
          openRouterStatus: OpenRouterStatusResponse(connected: false),
          openRouterModels: OpenRouterModelsListResponse(models: [], total: 0),
          healthSummary: LLMHealthSummary(
            providersStatus: [],
            localModelsLoaded: 0,
            localModelsAvailable: 0,
            openRouterConnected: false,
            activeProvider: LLMProvider.local,
            activeModel: 'empty-model',
            systemHealthy: false,
          ),
          performanceReports: [],
        );

        final state2 = LlmDashboardState(
          config: validConfig,
          statuses: [],
          localModels: LocalModelsListResponse(models: [], loadedModels: []),
          openRouterStatus: OpenRouterStatusResponse(connected: false),
          openRouterModels: OpenRouterModelsListResponse(models: [], total: 0),
          healthSummary: LLMHealthSummary(
            providersStatus: [],
            localModelsLoaded: 0,
            localModelsAvailable: 0,
            openRouterConnected: false,
            activeProvider: LLMProvider.local,
            activeModel: 'empty-model',
            systemHealthy: false,
          ),
          performanceReports: [],
        );

        expect(state1 == state2, true);
      });
    });

    group('LlmDashboardState Edge Cases', () {
      test('should handle empty states', () {
        final emptyConfig = LLMConfigResponse(
          activeProvider: LLMProvider.local,
          activeModel: '',
          providers: {},
          models: {},
        );

        final emptyState = LlmDashboardState(
          config: emptyConfig,
          statuses: [],
          localModels: LocalModelsListResponse(models: [], loadedModels: []),
          openRouterStatus: OpenRouterStatusResponse(connected: false),
          openRouterModels: OpenRouterModelsListResponse(models: [], total: 0),
          healthSummary: LLMHealthSummary(
            providersStatus: [],
            localModelsLoaded: 0,
            localModelsAvailable: 0,
            openRouterConnected: false,
            activeProvider: LLMProvider.local,
            activeModel: '',
            systemHealthy: false,
          ),
          performanceReports: [],
        );

        expect(emptyState.config.activeModel, isEmpty);
        expect(emptyState.statuses, isEmpty);
        expect(emptyState.localModels.models, isEmpty);
        expect(emptyState.openRouterModels.models, isEmpty);
        expect(emptyState.performanceReports, isEmpty);
      });

      test('should handle states with null values in nested objects', () {
        final stateWithNulls = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: LocalModelsListResponse(
            models: [
              LocalModelInfo(
                modelName: 'null-dates-model',
                sizeGb: 1.0,
                loaded: true,
                contextWindow: 4096,
                maxTokens: 2048,
                lastUsed: null, // Nullable field
              ),
            ],
            loadedModels: ['null-dates-model'],
          ),
          openRouterStatus: OpenRouterStatusResponse(
            connected: true,
            creditsRemaining: null,
            rateLimitRemaining: null,
            errorMessage: null,
          ),
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        expect(stateWithNulls.localModels.models.first.lastUsed, null);
        expect(stateWithNulls.openRouterStatus.creditsRemaining, null);
      });

      test('should handle very large performance metrics', () {
        final largeMetrics = PerformanceMetrics(
          totalRequests: 999999999,
          successfulRequests: 999999998,
          failedRequests: 1,
          averageResponseTimeMs: 999999.999,
          totalTokensUsed: 999999999999,
          errorRate: 0.000001,
          uptimePercentage: 99.9999,
        );

        final reportWithLargeMetrics = PerformanceReportResponse(
          provider: LLMProvider.local,
          metrics: largeMetrics,
          timeRange: 'all-time',
          generatedAt: DateTime.parse('2023-12-31T23:59:59.999Z'),
        );

        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: [reportWithLargeMetrics],
        );

        expect(state.performanceReports.first.metrics.totalRequests, 999999999);
        expect(state.performanceReports.first.metrics.averageResponseTimeMs, 999999.999);
      });

      test('should handle multiple provider types', () {
        final multiProviderState = LlmDashboardState(
          config: LLMConfigResponse(
            activeProvider: LLMProvider.openrouter,
            activeModel: 'openrouter-model',
            providers: {
              LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
              LLMProvider.openrouter: LLMProviderSettings(provider: LLMProvider.openrouter),
            },
            models: {},
          ),
          statuses: [
            LLMStatusResponse(
              provider: LLMProvider.local,
              available: true,
              healthy: true,
              responseTimeMs: 100.0,
              errorMessage: null,
              lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
            ),
            LLMStatusResponse(
              provider: LLMProvider.openrouter,
              available: true,
              healthy: false,
              responseTimeMs: 200.0,
              errorMessage: 'Service degraded',
              lastCheckedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
            ),
          ],
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: [
            PerformanceReportResponse(
              provider: LLMProvider.local,
              metrics: PerformanceMetrics(
                totalRequests: 100,
                successfulRequests: 95,
                failedRequests: 5,
                averageResponseTimeMs: 100.0,
                totalTokensUsed: 10000,
                errorRate: 0.05,
                uptimePercentage: 95.0,
              ),
              timeRange: '24h',
              generatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
            ),
            PerformanceReportResponse(
              provider: LLMProvider.openrouter,
              metrics: PerformanceMetrics(
                totalRequests: 200,
                successfulRequests: 180,
                failedRequests: 20,
                averageResponseTimeMs: 300.0,
                totalTokensUsed: 20000,
                errorRate: 0.10,
                uptimePercentage: 90.0,
              ),
              timeRange: '24h',
              generatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
            ),
          ],
        );

        expect(multiProviderState.config.providers.length, 2);
        expect(multiProviderState.statuses.length, 2);
        expect(multiProviderState.performanceReports.length, 2);
        expect(multiProviderState.performanceReports[0].provider, LLMProvider.local);
        expect(multiProviderState.performanceReports[1].provider, LLMProvider.openrouter);
      });

      test('should handle special characters in model names and configs', () {
        final specialCharsConfig = LLMConfigResponse(
          activeProvider: LLMProvider.local,
          activeModel: 'special-model-🚀🎬',
          providers: {},
          models: {
            'special-model': LLMModelConfig(
              modelName: 'special-model',
              provider: LLMProvider.local,
            ),
          },
        );

        final specialCharsModel = LocalModelInfo(
          modelName: 'Model-With-Special!@#\$%^&*()',
          sizeGb: 1.5,
          loaded: true,
          contextWindow: 4096,
          maxTokens: 2048,
          lastUsed: null,
        );

        final state = LlmDashboardState(
          config: specialCharsConfig,
          statuses: validStatuses,
          localModels: LocalModelsListResponse(
            models: [specialCharsModel],
            loadedModels: [specialCharsModel.modelName],
          ),
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        expect(state.config.activeModel, contains('🚀'));
        expect(state.localModels.models.first.modelName, contains('!@#'));
      });
    });

    group('LlmDashboardState Data Integrity', () {
      test('should maintain data integrity through copy operations', () {
        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        // Multiple copy operations
        final state1 = originalState.copyWith(isRefreshing: true);
        final state2 = state1.copyWith(config: validConfig); // Same config
        final state3 = state2.copyWith(isRefreshing: false);

        // Data integrity should be maintained
        expect(state1.config, originalState.config);
        expect(state2.config, originalState.config);
        expect(state1.isRefreshing, true);
        expect(state3.isRefreshing, false);
        expect(state3.config, originalState.config);
        expect(state3.statuses, originalState.statuses);
      });

      test('should handle concurrent modifications of nested objects', () {
        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        // Modify the original lists and objects
        validStatuses.clear();
        validLocalModels.models.clear();
        validPerformanceReports.clear();

        // Original state should not be affected
        expect(originalState.statuses.length, 1);
        expect(originalState.localModels.models.length, 1);
        expect(originalState.performanceReports.length, 1);

        // Copy should also be unaffected by modifications to originals
        final copiedState = originalState.copyWith(isRefreshing: true);
        expect(copiedState.statuses.length, 1);
        expect(copiedState.localModels.models.length, 1);
        expect(copiedState.performanceReports.length, 1);
      });

      test('should handle deep copy of complex nested structures', () {
        final complexLocalModels = LocalModelsListResponse(
          models: [
            LocalModelInfo(
              modelName: 'model1',
              sizeGb: 1.0,
              loaded: false,
              contextWindow: 4096,
              maxTokens: 2048,
              isLoading: false,
            ),
          ],
          loadedModels: [],
        );

        final originalState = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: complexLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        final copiedState = originalState.copyWith();

        // Should be equal
        expect(originalState == copiedState, true);
        
        // But should be independent instances
        expect(identical(originalState, copiedState), false);
        expect(identical(originalState.localModels, copiedState.localModels), false);
        expect(identical(originalState.localModels.models, copiedState.localModels.models), false);
      });

      test('should maintain provider enum consistency', () {
        final providerStates = [
          LLMProvider.local,
          LLMProvider.openrouter,
        ];

        for (final provider in providerStates) {
          final config = LLMConfigResponse(
            activeProvider: provider,
            activeModel: 'test-model',
            providers: {},
            models: {},
          );

          final healthSummary = LLMHealthSummary(
            providersStatus: [],
            localModelsLoaded: 0,
            localModelsAvailable: 0,
            openRouterConnected: provider == LLMProvider.openrouter,
            activeProvider: provider,
            activeModel: 'test-model',
            systemHealthy: true,
          );

          final state = LlmDashboardState(
            config: config,
            statuses: [],
            localModels: LocalModelsListResponse(models: [], loadedModels: []),
            openRouterStatus: OpenRouterStatusResponse(connected: provider == LLMProvider.openrouter),
            openRouterModels: OpenRouterModelsListResponse(models: [], total: 0),
            healthSummary: healthSummary,
            performanceReports: [],
          );

          expect(state.config.activeProvider, provider);
          expect(state.healthSummary.activeProvider, provider);
        }
      });
    });

    group('LlmDashboardState Property Validation', () {
      test('should correctly identify all property types', () {
        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
          isRefreshing: true,
        );

        expect(state.config, isA<LLMConfigResponse>());
        expect(state.statuses, isA<List<LLMStatusResponse>>());
        expect(state.localModels, isA<LocalModelsListResponse>());
        expect(state.openRouterStatus, isA<OpenRouterStatusResponse>());
        expect(state.openRouterModels, isA<OpenRouterModelsListResponse>());
        expect(state.healthSummary, isA<LLMHealthSummary>());
        expect(state.performanceReports, isA<List<PerformanceReportResponse>>());
        expect(state.isRefreshing, isA<bool>());
      });

      test('should validate props method returns correct types', () {
        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
          isRefreshing: false,
        );

        final props = state.props;
        expect(props[0], isA<LLMConfigResponse>());
        expect(props[1], isA<List<LLMStatusResponse>>());
        expect(props[2], isA<LocalModelsListResponse>());
        expect(props[3], isA<OpenRouterStatusResponse>());
        expect(props[4], isA<OpenRouterModelsListResponse>());
        expect(props[5], isA<LLMHealthSummary>());
        expect(props[6], isA<List<PerformanceReportResponse>>());
        expect(props[7], isA<bool>());
      });

      test('should handle property access correctly', () {
        final state = LlmDashboardState(
          config: validConfig,
          statuses: validStatuses,
          localModels: validLocalModels,
          openRouterStatus: validOpenRouterStatus,
          openRouterModels: validOpenRouterModels,
          healthSummary: validHealthSummary,
          performanceReports: validPerformanceReports,
        );

        // Test nested property access
        expect(state.config.activeProvider, LLMProvider.local);
        expect(state.config.activeModel, 'test-model');
        expect(state.statuses.first.provider, LLMProvider.local);
        expect(state.localModels.models.first.modelName, 'test-model');
        expect(state.openRouterStatus.connected, true);
        expect(state.openRouterModels.total, 2);
        expect(state.healthSummary.localModelsLoaded, 1);
        expect(state.performanceReports.first.provider, LLMProvider.local);
      });
    });
  });
}

