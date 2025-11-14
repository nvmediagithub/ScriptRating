import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:script_rating_app/models/llm_dashboard_state.dart';
import 'package:script_rating_app/models/llm_models.dart';
import 'package:script_rating_app/models/llm_provider.dart';
import 'package:script_rating_app/providers/llm_dashboard_provider.dart';
import 'package:script_rating_app/services/llm_service.dart';

// Mock classes
class MockLlmService extends Mock implements LlmService {}

// Test utilities
void main() {
  group('LlmDashboardNotifier', () {
    late ProviderContainer container;
    late MockLlmService mockLlmService;
    late LlmDashboardNotifier notifier;

    setUp(() {
      mockLlmService = MockLlmService();
      container = ProviderContainer(overrides: [
        llmServiceProvider.overrideWith((ref) => mockLlmService),
      ]);
      notifier = container.read(llmDashboardProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('LlmDashboardNotifier should start with loading state', () {
      // Arrange
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act
      final state = container.read(llmDashboardProvider);

      // Assert
      expect(state, isA<AsyncLoading<LlmDashboardState>>());
    });

    test('LlmDashboardNotifier should load dashboard state successfully', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      final mockLocalModels = TestDataGenerator.createValidLocalModels();
      final mockOpenRouterStatus = TestDataGenerator.createValidOpenRouterStatus();
      final mockOpenRouterModels = TestDataGenerator.createValidOpenRouterModels();
      final mockHealthSummary = TestDataGenerator.createValidHealthSummary();
      final mockPerformanceReports = <PerformanceReportResponse>[];

      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => mockLocalModels);
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => mockOpenRouterStatus);
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => mockOpenRouterModels);
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => mockHealthSummary);
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => mockPerformanceReports);

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.refresh();

      // Assert
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value, isNotNull);
      expect(state.value?.config, equals(mockConfig));
      expect(state.value?.localModels, equals(mockLocalModels));
      expect(state.value?.openRouterStatus, equals(mockOpenRouterStatus));
      expect(state.value?.openRouterModels, equals(mockOpenRouterModels));
      expect(state.value?.healthSummary, equals(mockHealthSummary));
      expect(state.value?.isRefreshing, isFalse);

      verify(() => mockLlmService.getConfig()).called(1);
      verify(() => mockLlmService.getStatuses()).called(1);
      verify(() => mockLlmService.getLocalModels()).called(1);
      verify(() => mockLlmService.getOpenRouterStatus()).called(1);
      verify(() => mockLlmService.getOpenRouterModels()).called(1);
      verify(() => mockLlmService.getHealthSummary()).called(1);
      verify(() => mockLlmService.getPerformanceReports()).called(1);
    });

    test('LlmDashboardNotifier should handle switchActiveModel successfully', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());

      // Act
      await notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

      // Assert
      verify(() => mockLlmService.switchMode(LLMProvider.openrouter, 'gpt-4')).called(1);
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.isRefreshing, isFalse);
    });

    test('LlmDashboardNotifier should handle loadLocalModel successfully', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      
      when(() => mockLlmService.loadLocalModel(any())).thenAnswer((_) async => TestDataGenerator.createValidLocalModels().models.first);

      // Act
      await notifier.loadLocalModel('llama-2-7b');

      // Assert
      verify(() => mockLlmService.loadLocalModel('llama-2-7b')).called(1);
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.isRefreshing, isFalse);
    });

    test('LlmDashboardNotifier should handle unloadLocalModel successfully', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
        
      when(() => mockLlmService.unloadLocalModel(any())).thenAnswer((_) async => TestDataGenerator.createValidLocalModels().models.first);

      // Act
      await notifier.unloadLocalModel('llama-2-7b');

      // Assert
      verify(() => mockLlmService.unloadLocalModel('llama-2-7b')).called(1);
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.isRefreshing, isFalse);
    });
  });
}

// Test data generator for LLM dashboard
class TestDataGenerator {
  static LLMConfigResponse createValidLLMConfig({
    String activeProvider = 'local',
    String activeModel = 'test-model',
  }) {
    return LLMConfigResponse(
      activeProvider: LLMProvider.values.firstWhere((e) => e.name == activeProvider),
      activeModel: activeModel,
      providers: {
        LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
        LLMProvider.openrouter: LLMProviderSettings(provider: LLMProvider.openrouter),
      },
      models: {
        'test-model': LLMModelConfig(
          modelName: 'test-model',
          provider: LLMProvider.local,
        ),
        'gpt-4': LLMModelConfig(
          modelName: 'gpt-4',
          provider: LLMProvider.openrouter,
        ),
      },
    );
  }

  static LocalModelsListResponse createValidLocalModels() {
    return LocalModelsListResponse(
      models: [
        LocalModelInfo(
          modelName: 'llama-2-7b',
          sizeGb: 3.8,
          loaded: false,
          contextWindow: 4096,
          maxTokens: 2048,
        ),
      ],
      loadedModels: [],
    );
  }

  static OpenRouterStatusResponse createValidOpenRouterStatus() {
    return OpenRouterStatusResponse(
      connected: true,
      creditsRemaining: 10.5,
      rateLimitRemaining: 100,
    );
  }

  static OpenRouterModelsListResponse createValidOpenRouterModels() {
    return OpenRouterModelsListResponse(
      models: ['gpt-3.5-turbo', 'gpt-4', 'claude-3'],
      total: 3,
    );
  }

  static LLMHealthSummary createValidHealthSummary() {
    return LLMHealthSummary(
      providersStatus: [],
      localModelsLoaded: 0,
      localModelsAvailable: 5,
      openRouterConnected: true,
      activeProvider: LLMProvider.local,
      activeModel: 'test-model',
      systemHealthy: true,
    );
  }

  static LlmDashboardState createValidLlmDashboardState() {
    return LlmDashboardState(
      config: createValidLLMConfig(),
      statuses: [],
      localModels: createValidLocalModels(),
      openRouterStatus: createValidOpenRouterStatus(),
      openRouterModels: createValidOpenRouterModels(),
      healthSummary: createValidHealthSummary(),
      performanceReports: [],
      isRefreshing: false,
    );
  }
}