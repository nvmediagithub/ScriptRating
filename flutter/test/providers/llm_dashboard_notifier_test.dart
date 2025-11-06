import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:script_rating_app/models/llm_dashboard_state.dart';
import 'package:script_rating_app/models/llm_models.dart';
import 'package:script_rating_app/providers/llm_dashboard_provider.dart';
import 'package:script_rating_app/services/llm_service.dart';

// Mock classes
class MockLlmService extends Mock implements LlmService {}

// Test utilities
void main() {
  group('LlmDashboardNotifier', () {
    late ProviderContainer container;
    late MockLlmService mockLlmService;

    setUp(() {
      mockLlmService = MockLlmService();
      container = ProviderContainer(overrides: [
        llmServiceProvider.overrideWith((ref) => mockLlmService),
      ]);
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
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);

      // Assert
      expect(dashboardNotifier.debugState, isA<AsyncValue<LlmDashboardState>>());
      expect(dashboardNotifier.debugState, isA<AsyncLoading<LlmDashboardState>>());
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

    test('LlmDashboardNotifier should handle refresh with force parameter', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act - Force refresh
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.refresh(force: true);

      // Assert
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.isRefreshing, isFalse);

      verify(() => mockLlmService.getConfig()).called(2); // Called once in constructor, once in refresh
      verify(() => mockLlmService.getStatuses()).called(2);
      verify(() => mockLlmService.getLocalModels()).called(2);
      verify(() => mockLlmService.getOpenRouterStatus()).called(2);
      verify(() => mockLlmService.getOpenRouterModels()).called(2);
      verify(() => mockLlmService.getHealthSummary()).called(2);
      verify(() => mockLlmService.getPerformanceReports()).called(2);
    });

    test('LlmDashboardNotifier should handle refresh without force parameter', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      final mockState = TestDataGenerator.createValidLlmDashboardState();
      
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act - First load
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.refresh();

      // Update mock for non-force refresh
      final updatedConfig = TestDataGenerator.createValidLLMConfig(activeModel: 'updated-model');
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => updatedConfig);

      // Non-force refresh
      await dashboardNotifier.refresh(force: false);

      // Assert
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.config.activeModel, equals('updated-model'));
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
      
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) async => {});

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

      // Assert
      verify(() => mockLlmService.switchMode(LLMProvider.openrouter, 'gpt-4')).called(1);
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.isRefreshing, isFalse);
    });

    test('LlmDashboardNotifier should handle switchActiveModel with error recovery', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      final mockState = TestDataGenerator.createValidLlmDashboardState();
      
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      
      // Switch mode fails first time, succeeds second time
      when(() => mockLlmService.switchMode(any(), any()))
          .thenThrow(Exception('Switch failed'))
          .thenAnswer((_) async => {});

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      
      // First attempt - should fail
      expect(
        () => dashboardNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4'),
        throwsA(isA<Exception>()),
      );
      
      // Second attempt - should succeed
      await dashboardNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

      // Assert
      verify(() => mockLlmService.switchMode(LLMProvider.openrouter, 'gpt-4')).called(2);
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
      
      when(() => mockLlmService.loadLocalModel(any())).thenAnswer((_) async => {});

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.loadLocalModel('llama-2-7b');

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
      
      when(() => mockLlmService.unloadLocalModel(any())).thenAnswer((_) async => {});

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.unloadLocalModel('llama-2-7b');

      // Assert
      verify(() => mockLlmService.unloadLocalModel('llama-2-7b')).called(1);
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.isRefreshing, isFalse);
    });

    test('LlmDashboardNotifier should handle refresh errors gracefully', () async {
      // Arrange
      final exception = Exception('Network error');
      when(() => mockLlmService.getConfig()).thenThrow(exception);

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);

      // Assert
      expect(
        () => dashboardNotifier.refresh(),
        throwsA(isA<Exception>()),
      );
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncError<LlmDashboardState>>());
    });

    test('LlmDashboardNotifier should handle partial service failures', () async {
      // Arrange
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenThrow(Exception('Local models error'));
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);

      // Assert
      expect(
        () => dashboardNotifier.refresh(),
        throwsA(isA<Exception>()),
      );
    });

    test('LlmDashboardNotifier should maintain isRefreshing state correctly', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      final refreshCompleter = Completer<void>();
      
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) => refreshCompleter.future);

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      final switchFuture = dashboardNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

      // Assert - Should show refreshing state
      final refreshingState = container.read(llmDashboardProvider);
      expect(refreshingState.value?.isRefreshing, isTrue);

      // Complete the operation
      refreshCompleter.complete();
      await switchFuture;

      // Assert - Should clear refreshing state
      final finalState = container.read(llmDashboardProvider);
      expect(finalState.value?.isRefreshing, isFalse);
    });

    test('LlmDashboardNotifier should handle concurrent operations', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) async => {});
      when(() => mockLlmService.loadLocalModel(any())).thenAnswer((_) async => {});

      // Act - Multiple concurrent operations
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      final switchFuture = dashboardNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');
      final loadFuture = dashboardNotifier.loadLocalModel('llama-2-7b');
      final refreshFuture = dashboardNotifier.refresh();

      // All should complete without error
      await expectLater(switchFuture, completes);
      await expectLater(loadFuture, completes);
      await expectLater(refreshFuture, completes);

      // Assert
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
    });

    test('LlmDashboardNotifier should handle service unavailability gracefully', () async {
      // Arrange
      final serviceUnavailableException = Exception('Service unavailable');
      when(() => mockLlmService.getConfig()).thenThrow(serviceUnavailableException);
      when(() => mockLlmService.getStatuses()).thenThrow(serviceUnavailableException);
      when(() => mockLlmService.getLocalModels()).thenThrow(serviceUnavailableException);
      when(() => mockLlmService.getOpenRouterStatus()).thenThrow(serviceUnavailableException);
      when(() => mockLlmService.getOpenRouterModels()).thenThrow(serviceUnavailableException);
      when(() => mockLlmService.getHealthSummary()).thenThrow(serviceUnavailableException);
      when(() => mockLlmService.getPerformanceReports()).thenThrow(serviceUnavailableException);

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);

      // Assert
      expect(
        () => dashboardNotifier.refresh(),
        throwsA(isA<Exception>()),
      );
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncError<LlmDashboardState>>());
    });

    test('LlmDashboardNotifier should handle empty data responses', () async {
      // Arrange
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => <LLMStatusResponse>[]);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModelsEmpty());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModelsEmpty());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummaryEmpty());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => <PerformanceReportResponse>[]);

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.refresh();

      // Assert
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.statuses, isEmpty);
      expect(state.value?.performanceReports, isEmpty);
    });

    test('LlmDashboardNotifier should not leak state between operations', () async {
      // Arrange
      final mockConfig = TestDataGenerator.createValidLLMConfig();
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => mockConfig);
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) async => {});

      // Act
      final dashboardNotifier = container.read(llmDashboardProvider.notifier);
      await dashboardNotifier.refresh();
      
      // Reset mocks for next operation
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig(activeModel: 'model-2'));
      
      await dashboardNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

      // Assert - Should have updated state
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      
      // Verify service calls are independent
      verify(() => mockLlmService.switchMode(LLMProvider.openrouter, 'gpt-4')).called(1);
    });

    group('Initial State Tests', () {
      test('LlmDashboardNotifier should initialize with loading state and auto-refresh', () async {
        // Arrange
        when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
        when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
        when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
        when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
        when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
        when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
        when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

        // Act & Assert - Initial read should trigger loading
        final state = container.read(llmDashboardProvider);
        expect(state, isA<AsyncLoading<LlmDashboardState>>());
        
        verify(() => mockLlmService.getConfig()).called(1);
        verify(() => mockLlmService.getStatuses()).called(1);
        verify(() => mockLlmService.getLocalModels()).called(1);
        verify(() => mockLlmService.getOpenRouterStatus()).called(1);
        verify(() => mockLlmService.getOpenRouterModels()).called(1);
        verify(() => mockLlmService.getHealthSummary()).called(1);
        verify(() => mockLlmService.getPerformanceReports()).called(1);
      });
    });

    group('Async Operations Tests', () {
      test('LlmDashboardNotifier should handle async operation states correctly', () async {
        // Arrange
        final completer = Completer<void>();
        when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
        when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
        when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
        when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
        when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
        when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
        when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
        when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) => completer.future);

        // Act
        final dashboardNotifier = container.read(llmDashboardProvider.notifier);
        final operationFuture = dashboardNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

        // Assert - Should show loading state
        final loadingState = container.read(llmDashboardProvider);
        expect(loadingState.value?.isRefreshing, isTrue);

        // Complete the operation
        completer.complete();
        await operationFuture;

        // Assert - Should complete and clear loading state
        final finalState = container.read(llmDashboardProvider);
        expect(finalState.value?.isRefreshing, isFalse);
      });
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

  static LocalModelsListResponse createValidLocalModelsEmpty() {
    return LocalModelsListResponse(
      models: [],
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

  static OpenRouterModelsListResponse createValidOpenRouterModelsEmpty() {
    return OpenRouterModelsListResponse(
      models: [],
      total: 0,
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

  static LLMHealthSummary createValidHealthSummaryEmpty() {
    return LLMHealthSummary(
      providersStatus: [],
      localModelsLoaded: 0,
      localModelsAvailable: 0,
      openRouterConnected: false,
      activeProvider: LLMProvider.local,
      activeModel: '',
      systemHealthy: false,
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

