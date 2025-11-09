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
      await notifier.refresh(force: true);

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
      await notifier.refresh();

      // Update mock for non-force refresh
      final updatedConfig = TestDataGenerator.createValidLLMConfig(activeModel: 'updated-model');
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => updatedConfig);

      // Non-force refresh
      await notifier.refresh(force: false);

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
      
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());

    // Act
    await notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

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
      // Switch mode fails first time, succeeds second time
      when(() => mockLlmService.switchMode(any(), any()))
          .thenThrow(Exception('Switch failed'));
      when(() => mockLlmService.switchMode(any(), any()))
          .thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());

      // Act
      // First attempt - should fail
      expect(
        () => notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4'),
        throwsA(isA<Exception>()),
      );
      
      // Second attempt - should succeed
      await notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

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

    test('LlmDashboardNotifier should handle refresh errors gracefully', () async {
      // Arrange
      final exception = Exception('Network error');
      when(() => mockLlmService.getConfig()).thenThrow(exception);

      // Act
      expect(
        () => notifier.refresh(),
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
      expect(
        () => notifier.refresh(),
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
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) => refreshCompleter.future.then((_) => TestDataGenerator.createValidLLMConfig()));

    // Act
    final switchFuture = notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

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
      final switchFuture = notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');
      final loadFuture = notifier.loadLocalModel('llama-2-7b');
      final refreshFuture = notifier.refresh();

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
      expect(
        () => notifier.refresh(),
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
      await notifier.refresh();

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
      await notifier.refresh();
      
      // Reset mocks for next operation
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig(activeModel: 'model-2'));
      
      await notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');

      // Assert - Should have updated state
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      
      // Verify service calls are independent
      verify(() => mockLlmService.switchMode(LLMProvider.openrouter, 'gpt-4')).called(1);
    });

    test('LlmDashboardNotifier should handle invalid provider enum', () async {
      // Arrange
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      when(() => mockLlmService.switchMode(any(), any())).thenThrow(Exception('Invalid provider'));

      // Act & Assert
      expect(
        () => notifier.switchActiveModel(LLMProvider.openrouter, 'invalid-model'),
        throwsA(isA<Exception>()),
      );
    });

    test('LlmDashboardNotifier should handle model load errors', () async {
      // Arrange
      when(() => mockLlmService.loadLocalModel(any())).thenThrow(Exception('Model load failed'));
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act & Assert
      expect(
        () => notifier.loadLocalModel('nonexistent-model'),
        throwsA(isA<Exception>()),
      );
    });

    test('LlmDashboardNotifier should handle model unload errors', () async {
      // Arrange
      when(() => mockLlmService.unloadLocalModel(any())).thenThrow(Exception('Model unload failed'));
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act & Assert
      expect(
        () => notifier.unloadLocalModel('unloaded-model'),
        throwsA(isA<Exception>()),
      );
    });

    test('LlmDashboardNotifier should handle timeout during operations', () async {
      // Arrange
      final timeoutCompleter = Completer<void>();
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) => timeoutCompleter.future);
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act
      final switchFuture = notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');
      
      // Verify refreshing state is set
      expect(container.read(llmDashboardProvider).value?.isRefreshing, isTrue);
      
      // Complete the operation
      timeoutCompleter.complete();
      await switchFuture;

      // Assert
      expect(container.read(llmDashboardProvider).value?.isRefreshing, isFalse);
    });

    test('LlmDashboardNotifier should handle rapid consecutive operations', () async {
      // Arrange
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) async => {});
      when(() => mockLlmService.loadLocalModel(any())).thenAnswer((_) async => {});
      when(() => mockLlmService.unloadLocalModel(any())).thenAnswer((_) async => {});
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act - Rapid consecutive operations
      await notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');
      await notifier.loadLocalModel('llama-2-7b');
      await notifier.unloadLocalModel('llama-2-7b');
      await notifier.refresh();

      // Assert - All operations should complete successfully
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      expect(state.value?.isRefreshing, isFalse);
    });

    test('LlmDashboardNotifier should maintain data consistency during updates', () async {
      // Arrange
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);
      when(() => mockLlmService.switchMode(any(), any())).thenAnswer((_) async => {});

      // Act
      await notifier.refresh();
      final initialState = container.read(llmDashboardProvider);
      
      await notifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4');
      final updatedState = container.read(llmDashboardProvider);

      // Assert - Data should be consistent
      expect(initialState.value?.config, isNotNull);
      expect(updatedState.value?.config, isNotNull);
      expect(updatedState.value?.localModels, isNotNull);
      expect(updatedState.value?.openRouterStatus, isNotNull);
    });

    test('LlmDashboardNotifier should handle partial refresh failures', () async {
      // Arrange - First call succeeds, second call fails
      when(() => mockLlmService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
      when(() => mockLlmService.getStatuses()).thenAnswer((_) async => []);
      when(() => mockLlmService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
      when(() => mockLlmService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
      when(() => mockLlmService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
      when(() => mockLlmService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
      when(() => mockLlmService.getPerformanceReports()).thenAnswer((_) async => []);

      // Act - First refresh should succeed
      await notifier.refresh();
      expect(container.read(llmDashboardProvider), isA<AsyncData<LlmDashboardState>>());
      
      // Simulate partial failure in second refresh
      when(() => mockLlmService.getHealthSummary()).thenThrow(Exception('Health check failed'));
      
      // Act & Assert - Second refresh should fail
      expect(
        () => notifier.refresh(force: true),
        throwsA(isA<Exception>()),
      );
      expect(container.read(llmDashboardProvider), isA<AsyncError<LlmDashboardState>>());
    });
  });

  group('LlmDashboardNotifier Edge Cases and Error Scenarios', () {
    test('should handle rapid refresh calls without interference', () async {
      // Arrange
      final container = ProviderContainer(overrides: [
        llmServiceProvider.overrideWith((ref) {
          final mockService = MockLlmService();
          when(() => mockService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
          when(() => mockService.getStatuses()).thenAnswer((_) async => []);
          when(() => mockService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
          when(() => mockService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
          when(() => mockService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
          when(() => mockService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
          when(() => mockService.getPerformanceReports()).thenAnswer((_) async => []);
          return mockService;
        }),
      ]);
      
      final notifier = container.read(llmDashboardProvider.notifier);

      // Act - Multiple rapid refresh calls
      final refresh1 = notifier.refresh();
      final refresh2 = notifier.refresh(force: true);
      final refresh3 = notifier.refresh();

      // All should complete without errors
      await expectLater(refresh1, completes);
      await expectLater(refresh2, completes);
      await expectLater(refresh3, completes);

      // Assert - Final state should be valid
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncData<LlmDashboardState>>());
      
      container.dispose();
    });

    test('should handle provider service dependency errors', () async {
      // Arrange
      final container = ProviderContainer(overrides: [
        llmServiceProvider.overrideWith((ref) {
          final mockService = MockLlmService();
          // Config service fails
          when(() => mockService.getConfig()).thenThrow(Exception('Config service down'));
          return mockService;
        }),
      ]);
      
      final notifier = container.read(llmDashboardProvider.notifier);

      // Act & Assert
      expect(
        () => notifier.refresh(),
        throwsA(isA<Exception>()),
      );
      
      final state = container.read(llmDashboardProvider);
      expect(state, isA<AsyncError<LlmDashboardState>>());
      
      container.dispose();
    });

    test('should maintain operation isolation between different notifiers', () async {
      // Arrange - Create two separate containers
      final container1 = ProviderContainer(overrides: [
        llmServiceProvider.overrideWith((ref) {
          final mockService = MockLlmService();
          when(() => mockService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
          when(() => mockService.getStatuses()).thenAnswer((_) async => []);
          when(() => mockService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
          when(() => mockService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
          when(() => mockService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
          when(() => mockService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
          when(() => mockService.getPerformanceReports()).thenAnswer((_) async => []);
          when(() => mockService.switchMode(any(), any())).thenAnswer((_) async => {});
          return mockService;
        }),
      ]);
      
      final container2 = ProviderContainer(overrides: [
        llmServiceProvider.overrideWith((ref) {
          final mockService = MockLlmService();
          when(() => mockService.getConfig()).thenAnswer((_) async => TestDataGenerator.createValidLLMConfig());
          when(() => mockService.getStatuses()).thenAnswer((_) async => []);
          when(() => mockService.getLocalModels()).thenAnswer((_) async => TestDataGenerator.createValidLocalModels());
          when(() => mockService.getOpenRouterStatus()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterStatus());
          when(() => mockService.getOpenRouterModels()).thenAnswer((_) async => TestDataGenerator.createValidOpenRouterModels());
          when(() => mockService.getHealthSummary()).thenAnswer((_) async => TestDataGenerator.createValidHealthSummary());
          when(() => mockService.getPerformanceReports()).thenAnswer((_) async => []);
          when(() => mockService.switchMode(any(), any())).thenAnswer((_) async => {});
          return mockService;
        }),
      ]);
      
      final notifier1 = container1.read(llmDashboardProvider.notifier);
      final notifier2 = container2.read(llmDashboardProvider.notifier);

      // Act - Different operations on different notifiers
      final future1 = notifier1.switchActiveModel(LLMProvider.openrouter, 'gpt-4');
      final future2 = notifier2.loadLocalModel('llama-2-7b');
      final future3 = notifier1.refresh();

      // All should complete independently
      await expectLater(future1, completes);
      await expectLater(future2, completes);
      await expectLater(future3, completes);

      // Assert - States should be independent
      final state1 = container1.read(llmDashboardProvider);
      final state2 = container2.read(llmDashboardProvider);
      
      expect(state1, isA<AsyncData<LlmDashboardState>>());
      expect(state2, isA<AsyncData<LlmDashboardState>>());
      expect(state1.value, isNot(equals(state2.value))); // Should be different instances
      
      container1.dispose();
      container2.dispose();
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

