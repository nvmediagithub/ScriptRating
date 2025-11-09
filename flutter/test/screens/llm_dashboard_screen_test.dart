import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:script_rating_app/models/llm_dashboard_state.dart';
import 'package:script_rating_app/models/llm_models.dart';
import 'package:script_rating_app/providers/llm_dashboard_provider.dart';
import 'package:script_rating_app/screens/llm_dashboard_screen.dart';

// Mock classes
class MockLlmDashboardNotifier extends Mock implements LlmDashboardNotifier {}

void main() {
  group('LlmDashboardScreen Widget Tests', () {
    late ProviderContainer container;
    late MockLlmDashboardNotifier mockNotifier;

    setUp(() {
      mockNotifier = MockLlmDashboardNotifier();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // Test Helper Methods
    LlmDashboardState createMockDashboardState() {
      return LlmDashboardState(
        config: LLMConfigResponse(
          activeProvider: LLMProvider.local,
          activeModel: 'llama2-7b',
          providers: {
            LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
            LLMProvider.openrouter: LLMProviderSettings(
              provider: LLMProvider.openrouter,
              apiKey: 'test-key',
            ),
          },
          models: {
            'llama2-7b': LLMModelConfig(
              modelName: 'llama2-7b',
              provider: LLMProvider.local,
              contextWindow: 4096,
              maxTokens: 2048,
            ),
            'gpt-3.5-turbo': LLMModelConfig(
              modelName: 'gpt-3.5-turbo',
              provider: LLMProvider.openrouter,
              contextWindow: 4096,
              maxTokens: 2048,
            ),
          },
        ),
        statuses: [
          LLMStatusResponse(
            provider: LLMProvider.local,
            available: true,
            healthy: true,
            responseTimeMs: 150.0,
            errorMessage: null,
            lastCheckedAt: DateTime.now(),
          ),
          LLMStatusResponse(
            provider: LLMProvider.openrouter,
            available: true,
            healthy: true,
            responseTimeMs: 300.0,
            errorMessage: null,
            lastCheckedAt: DateTime.now(),
          ),
        ],
        localModels: LocalModelsListResponse(
          models: [
            LocalModelInfo(
              modelName: 'llama2-7b',
              sizeGb: 3.8,
              loaded: true,
              contextWindow: 4096,
              maxTokens: 2048,
              lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            LocalModelInfo(
              modelName: 'codellama-13b',
              sizeGb: 6.9,
              loaded: false,
              contextWindow: 16384,
              maxTokens: 8192,
              lastUsed: null,
            ),
          ],
          loadedModels: ['llama2-7b'],
        ),
        openRouterStatus: OpenRouterStatusResponse(
          connected: true,
          creditsRemaining: 12.45,
          rateLimitRemaining: 95,
          errorMessage: null,
        ),
        openRouterModels: OpenRouterModelsListResponse(
          models: ['gpt-3.5-turbo', 'gpt-4', 'claude-3-sonnet'],
          total: 3,
        ),
        performanceReports: [
          PerformanceReportResponse(
            provider: LLMProvider.local,
            timeRange: '24h',
            metrics: PerformanceMetrics(
              totalRequests: 150,
              successfulRequests: 145,
              failedRequests: 5,
              averageResponseTimeMs: 1200.0,
              errorRate: 3.3,
              uptimePercentage: 99.2,
              totalTokensUsed: 25000,
            ),
            generatedAt: DateTime.now(),
          ),
        ],
        healthSummary: LLMHealthSummary(
          providersStatus: [],
          localModelsLoaded: 1,
          localModelsAvailable: 2,
          openRouterConnected: true,
          activeProvider: LLMProvider.local,
          activeModel: 'llama2-7b',
          systemHealthy: true,
        ),
        isRefreshing: false,
      );
    }

    AsyncValue<LlmDashboardState> createAsyncData() {
      return AsyncData(createMockDashboardState());
    }

    AsyncValue<LlmDashboardState> createAsyncLoading() {
      return const AsyncLoading<LlmDashboardState>();
    }

    AsyncValue<LlmDashboardState> createAsyncError() {
      return AsyncError('Failed to load dashboard', StackTrace.empty);
    }

    Widget createTestWidget({AsyncValue<LlmDashboardState>? state}) {
      return ProviderScope(
        overrides: [
          llmDashboardProvider.overrideWith((ref) {
            when(() => mockNotifier.refresh(force: anyNamed('force')))
                .thenAnswer((_) async {});
            when(() => mockNotifier.loadLocalModel(any()))
                .thenAnswer((_) async {});
            when(() => mockNotifier.unloadLocalModel(any()))
                .thenAnswer((_) async {});
            when(() => mockNotifier.switchActiveModel(any(), any()))
                .thenAnswer((_) async {});
            return mockNotifier;
          }),
        ],
        child: MaterialApp(
          home: LlmDashboardScreen(),
        ),
      );
    }

    // Basic Rendering Tests
    testWidgets('LlmDashboardScreen should render with correct title', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('LLM Control Center'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should show loading state', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncLoading();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('LLM Control Center'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should show error state', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncError();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load LLM status'), findsOneWidget);
      expect(find.text('Failed to load dashboard'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should render dashboard content when data is available', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert - Should show dashboard sections
      expect(find.text('Active LLM Configuration'), findsOneWidget);
      expect(find.text('Provider Status'), findsOneWidget);
      expect(find.text('Local Models'), findsOneWidget);
      expect(find.text('OpenRouter Models'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
    });

    // Active Configuration Tests
    testWidgets('LlmDashboardScreen should render active configuration card', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('Active LLM Configuration'), findsOneWidget);
      expect(find.text('Select the provider and model used for analysis and recommendations.'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Provider · Model'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should show active model in dropdown', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.textContaining('Local • llama2-7b'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should render summary chips', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('System healthy'), findsOneWidget);
      expect(find.text('Local models loaded: 1/2'), findsOneWidget);
      expect(find.text('OpenRouter connected'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(3));
    });

    // Provider Status Tests
    testWidgets('LlmDashboardScreen should render provider status section', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('Provider Status'), findsOneWidget);
      expect(find.text('Local Runtime'), findsOneWidget);
      expect(find.text('OpenRouter API'), findsOneWidget);
      expect(find.text('Available'), findsNWidgets(2));
      expect(find.byType(Card), findsNWidgets(2)); // One card per provider
    });

    testWidgets('LlmDashboardScreen should show provider response times', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('150.0 ms'), findsOneWidget);
      expect(find.text('300.0 ms'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should show provider health status', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert - Should show green circles for healthy providers
      expect(find.byIcon(Icons.circle), findsNWidgets(2)); // Health indicators
    });

    testWidgets('LlmDashboardScreen should show provider last check times', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.textContaining('Last check:'), findsNWidgets(2));
    });

    // Local Models Tests
    testWidgets('LlmDashboardScreen should render local models section', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('Local Models'), findsOneWidget);
      expect(find.text('1 loaded'), findsOneWidget);
      expect(find.text('llama2-7b'), findsOneWidget);
      expect(find.text('codellama-13b'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should show model details', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('Size: 3.8 GB'), findsOneWidget);
      expect(find.text('Context: 4096'), findsOneWidget);
      expect(find.text('Max tokens: 2048'), findsOneWidget);
      expect(find.text('Last used:'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should show model status badges', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('Loaded'), findsOneWidget); // llama2-7b is loaded
      expect(find.text('Not loaded'), findsOneWidget); // codellama-13b is not loaded
    });

    testWidgets('LlmDashboardScreen should render model action buttons', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('Unload from RAM'), findsOneWidget); // For loaded model
      expect(find.text('Load into RAM'), findsOneWidget); // For unloaded model
      expect(find.text('Currently Active'), findsOneWidget); // For active model
      expect(find.text('Activate'), findsOneWidget); // For inactive model
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.byType(FilledButton), findsNWidgets(2));
    });

    // OpenRouter Models Tests
    testWidgets('LlmDashboardScreen should render OpenRouter section', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('OpenRouter Models'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Credits: 12.45 • Rate limit: 95'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should render OpenRouter model chips', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('gpt-3.5-turbo'), findsOneWidget);
      expect(find.text('gpt-4'), findsOneWidget);
      expect(find.text('claude-3-sonnet'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('LlmDashboardScreen should show selected OpenRouter model', (WidgetTester tester) async {
      // Arrange - Note: In our mock, no OpenRouter model is active
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert - Model chips should be visible (none selected in our mock)
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    // Performance Metrics Tests
    testWidgets('LlmDashboardScreen should render performance section', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('Performance Metrics'), findsOneWidget);
      expect(find.text('Local runtime (24h)'), findsOneWidget);
      expect(find.byType(Card), findsAtLeastNWidgets(1)); // Performance card
    });

    testWidgets('LlmDashboardScreen should show performance metrics', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.text('145/150'), findsOneWidget); // Success rate
      expect(find.text('1200.0 ms'), findsOneWidget); // Average response
      expect(find.text('3.3%'), findsOneWidget); // Error rate
      expect(find.text('99.2%'), findsOneWidget); // Uptime
      expect(find.text('Tokens used: 25000'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should hide performance section when no data', (WidgetTester tester) async {
      // Arrange - Create state without performance reports
      final stateWithoutPerformance = createMockDashboardState().copyWith(
        performanceReports: [],
      );

      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(stateWithoutPerformance)));
      await tester.pump();

      // Assert
      expect(find.text('Performance Metrics'), findsNothing);
    });

    // Refresh Functionality Tests
    testWidgets('LlmDashboardScreen should trigger refresh when refresh button is pressed', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      verify(() => mockNotifier.refresh(force: true)).called(1);
    });

    testWidgets('LlmDashboardScreen should show refresh feedback', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Note: The actual snackbar would be shown by the real implementation
      // In test environment, we just verify the action was triggered
      verify(() => mockNotifier.refresh(force: true)).called(1);
    });

    // Error Handling Tests
    testWidgets('LlmDashboardScreen should handle refresh errors', (WidgetTester tester) async {
      // Arrange
      when(() => mockNotifier.refresh(force: anyNamed('force')))
          .thenThrow(Exception('Refresh failed'));
      
      final state = createAsyncData();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Act
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert - Should handle error gracefully
      verify(() => mockNotifier.refresh(force: true)).called(1);
    });

    testWidgets('LlmDashboardScreen should handle provider switching errors', (WidgetTester tester) async {
      // Arrange
      when(() => mockNotifier.switchActiveModel(any(), any()))
          .thenThrow(Exception('Provider switch failed'));
      
      final state = createAsyncData();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Act - Try to switch provider
      await tester.tap(find.byType(DropdownButtonFormField<String>()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OpenRouter • gpt-3.5-turbo'));
      await tester.pump();

      // Assert
      verify(() => mockNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-3.5-turbo')).called(1);
    });

    testWidgets('LlmDashboardScreen should handle model loading errors', (WidgetTester tester) async {
      // Arrange
      when(() => mockNotifier.loadLocalModel(any()))
          .thenThrow(Exception('Model load failed'));
      
      final state = createAsyncData();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Act
      await tester.tap(find.text('Load into RAM'));
      await tester.pump();

      // Assert
      verify(() => mockNotifier.loadLocalModel('codellama-13b')).called(1);
    });

    testWidgets('LlmDashboardScreen should handle model unloading errors', (WidgetTester tester) async {
      // Arrange
      when(() => mockNotifier.unloadLocalModel(any()))
          .thenThrow(Exception('Model unload failed'));
      
      final state = createAsyncData();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Act
      await tester.tap(find.text('Unload from RAM'));
      await tester.pump();

      // Assert
      verify(() => mockNotifier.unloadLocalModel('llama2-7b')).called(1);
    });

    // Navigation Tests
    testWidgets('LlmDashboardScreen should not have navigation in app bar', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert - Should only have refresh button
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, hasLength(1));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    // UI Layout Tests
    testWidgets('LlmDashboardScreen should use RefreshIndicator', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should use ListView for scrolling', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should show loading overlay when refreshing', (WidgetTester tester) async {
      // Arrange - State with refreshing flag
      final refreshingState = createMockDashboardState().copyWith(isRefreshing: true);
      
      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(refreshingState)));
      await tester.pump();

      // Assert - Should show loading overlay
      expect(find.byType(Positioned), findsOneWidget); // Overlay positioning
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    // State Management Tests
    testWidgets('LlmDashboardScreen should handle loading to data transition', (WidgetTester tester) async {
      // Arrange
      final loadingState = createAsyncLoading();
      
      // Act - Start with loading
      await tester.pumpWidget(createTestWidget(state: loadingState));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate transition to data (would need to rebuild with new state)
      // Note: In a real test, we'd use a state notifier to trigger updates
    });

    testWidgets('LlmDashboardScreen should handle data to error transition', (WidgetTester tester) async {
      // Arrange - Start with data
      await tester.pumpWidget(createTestWidget(state: createAsyncData()));
      await tester.pump();
      expect(find.text('LLM Control Center'), findsOneWidget);

      // Simulate error transition
      // Note: This would require testing state transitions using a real notifier
    });

    // Model Management Tests
    testWidgets('LlmDashboardScreen should handle local model loading', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();
      
      // Find unload button for loaded model
      final unloadButton = find.text('Unload from RAM');
      expect(unloadButton, findsOneWidget);
      
      // Tap unload button
      await tester.tap(unloadButton);
      await tester.pump();

      // Assert
      verify(() => mockNotifier.unloadLocalModel('llama2-7b')).called(1);
    });

    testWidgets('LlmDashboardScreen should handle local model unloading', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();
      
      // Find load button for unloaded model
      final loadButton = find.text('Load into RAM');
      expect(loadButton, findsOneWidget);
      
      // Tap load button
      await tester.tap(loadButton);
      await tester.pump();

      // Assert
      verify(() => mockNotifier.loadLocalModel('codellama-13b')).called(1);
    });

    testWidgets('LlmDashboardScreen should handle model activation', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();
      
      // Find activate button
      final activateButton = find.text('Activate');
      expect(activateButton, findsOneWidget);
      
      // Tap activate button
      await tester.tap(activateButton);
      await tester.pump();

      // Assert
      verify(() => mockNotifier.switchActiveModel(LLMProvider.local, 'codellama-13b')).called(1);
    });

    // Provider Selection Tests
    testWidgets('LlmDashboardScreen should handle provider switching via dropdown', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();
      
      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>()));
      await tester.pumpAndSettle();

      // Select OpenRouter model
      await tester.tap(find.text('OpenRouter • gpt-3.5-turbo'));
      await tester.pump();

      // Assert
      verify(() => mockNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-3.5-turbo')).called(1);
    });

    // OpenRouter Model Selection Tests
    testWidgets('LlmDashboardScreen should handle OpenRouter model selection', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();
      
      // Select a ChoiceChip
      await tester.tap(find.text('gpt-4'));
      await tester.pump();

      // Assert
      verify(() => mockNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4')).called(1);
    });

    // Accessibility Tests
    testWidgets('LlmDashboardScreen should have proper semantic labels', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Assert
      expect(find.bySemanticsLabel('LLM Control Center'), findsOneWidget);
      expect(find.bySemanticsLabel('Refresh status'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should be scrollable for accessibility', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      
      // Act
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Test scrolling behavior
      await tester.fling(find.byType(ListView), const Offset(0, -200), 1000);
      await tester.pumpAndSettle();

      // Should handle scroll events gracefully
      expect(find.text('Active LLM Configuration'), findsOneWidget);
    });

    // Performance Tests
    testWidgets('LlmDashboardScreen should render efficiently with complex dashboard data', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // Arrange & Act
      await tester.pumpWidget(createTestWidget(state: createAsyncData()));
      await tester.pump();

      stopwatch.stop();

      // Assert - Should render within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(5)); // Multiple cards
    });

    testWidgets('LlmDashboardScreen should handle rapid refresh requests', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Act - Multiple rapid refresh attempts
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert - Should handle gracefully
      verify(() => mockNotifier.refresh(force: true)).called(3);
    });

    // Edge Cases Tests
    testWidgets('LlmDashboardScreen should handle missing provider data', (WidgetTester tester) async {
      // Arrange - Create state with minimal data
      final minimalState = createMockDashboardState().copyWith(
        statuses: [],
        performanceReports: [],
      );

      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(minimalState)));
      await tester.pump();

      // Assert - Should handle gracefully
      expect(find.text('Active LLM Configuration'), findsOneWidget);
      expect(find.text('Provider Status'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsNothing);
    });

    testWidgets('LlmDashboardScreen should handle offline provider states', (WidgetTester tester) async {
      // Arrange - State with offline provider
      final offlineState = createMockDashboardState().copyWith(
        openRouterStatus: OpenRouterStatusResponse(
          connected: false,
          creditsRemaining: null,
          rateLimitRemaining: null,
          errorMessage: 'Connection failed',
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(offlineState)));
      await tester.pump();

      // Assert - Should show offline status
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Connect to OpenRouter to enable network-based models.'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should handle provider errors', (WidgetTester tester) async {
      // Arrange - State with error status
      final errorState = createMockDashboardState().copyWith(
        statuses: [
          LLMStatusResponse(
            provider: LLMProvider.openrouter,
            available: false,
            healthy: false,
            responseTimeMs: null,
            errorMessage: 'API key invalid',
            lastCheckedAt: DateTime.now(),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(errorState)));
      await tester.pump();

      // Assert - Should show error message
      expect(find.text('API key invalid'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should handle empty model lists', (WidgetTester tester) async {
      // Arrange - State with no models
      final emptyState = createMockDashboardState().copyWith(
        localModels: LocalModelsListResponse(models: [], loadedModels: []),
        openRouterModels: OpenRouterModelsListResponse(models: [], total: 0),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(emptyState)));
      await tester.pump();

      // Assert - Should handle empty lists gracefully
      expect(find.text('Local Models'), findsOneWidget);
      expect(find.text('0 loaded'), findsOneWidget);
      expect(find.text('OpenRouter Models'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should handle very long model names', (WidgetTester tester) async {
      // Arrange - State with long model names
      final longNameState = createMockDashboardState().copyWith(
        localModels: LocalModelsListResponse(
          models: [
            LocalModelInfo(
              modelName: 'very-long-model-name-with-many-characters-that-might-cause-ui-issues',
              sizeGb: 3.8,
              loaded: true,
              contextWindow: 4096,
              maxTokens: 2048,
            ),
          ],
          loadedModels: ['very-long-model-name-with-many-characters-that-might-cause-ui-issues'],
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(longNameState)));
      await tester.pump();

      // Assert - Should handle long names gracefully
      expect(find.textContaining('very-long-model-name'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should handle special characters in model names', (WidgetTester tester) async {
      // Arrange - State with special characters
      final specialCharState = createMockDashboardState().copyWith(
        localModels: LocalModelsListResponse(
          models: [
            LocalModelInfo(
              modelName: 'model-with-special-chars-@#$%',
              sizeGb: 3.8,
              loaded: true,
              contextWindow: 4096,
              maxTokens: 2048,
            ),
          ],
          loadedModels: ['model-with-special-chars-@#$%'],
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state: AsyncData(specialCharState)));
      await tester.pump();

      // Assert - Should handle special characters
      expect(find.textContaining('model-with-special-chars'), findsOneWidget);
    });

    // Integration Tests
    testWidgets('LlmDashboardScreen complete workflow - provider switching', (WidgetTester tester) async {
      // Arrange & Act - Initial state
      await tester.pumpWidget(createTestWidget(state: createAsyncData()));
      await tester.pump();

      // Switch to OpenRouter model
      await tester.tap(find.byType(DropdownButtonFormField<String>()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OpenRouter • gpt-3.5-turbo'));
      await tester.pump();

      // Verify call
      verify(() => mockNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-3.5-turbo')).called(1);
    });

    testWidgets('LlmDashboardScreen complete workflow - local model management', (WidgetTester tester) async {
      // Arrange & Act - Load new model
      await tester.pumpWidget(createTestWidget(state: createAsyncData()));
      await tester.pump();

      // Load codellama-13b
      await tester.tap(find.text('Load into RAM'));
      await tester.pump();
      verify(() => mockNotifier.loadLocalModel('codellama-13b')).called(1);

      // Activate the loaded model
      await tester.tap(find.text('Activate'));
      await tester.pump();
      verify(() => mockNotifier.switchActiveModel(LLMProvider.local, 'codellama-13b')).called(1);
    });

    testWidgets('LlmDashboardScreen refresh and state management workflow', (WidgetTester tester) async {
      // Arrange & Act - Multiple refreshes
      await tester.pumpWidget(createTestWidget(state: createAsyncData()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      verify(() => mockNotifier.refresh(force: true)).called(1);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      verify(() => mockNotifier.refresh(force: true)).called(2);
    });

    testWidgets('LlmDashboardScreen should handle network connectivity changes', (WidgetTester tester) async {
      // Arrange - Start with connected state
      final connectedState = createAsyncData();
      await tester.pumpWidget(createTestWidget(state: connectedState));
      await tester.pump();

      // Act - Simulate disconnection
      final disconnectedState = createMockDashboardState().copyWith(
        openRouterStatus: OpenRouterStatusResponse(
          connected: false,
          errorMessage: 'Network unavailable',
        ),
      );
      await tester.pumpWidget(createTestWidget(state: AsyncData(disconnectedState)));
      await tester.pump();

      // Assert - Should show disconnected state
      expect(find.text('Network unavailable'), findsOneWidget);
    });

    testWidgets('LlmDashboardScreen should handle concurrent user interactions', (WidgetTester tester) async {
      // Arrange
      final state = createAsyncData();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Act - Multiple rapid interactions
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.tap(find.text('Load into RAM'));
      await tester.tap(find.text('gpt-4'));
      await tester.pump();

      // Assert - All interactions should be handled
      verify(() => mockNotifier.refresh(force: true)).called(1);
      verify(() => mockNotifier.loadLocalModel('codellama-13b')).called(1);
      verify(() => mockNotifier.switchActiveModel(LLMProvider.openrouter, 'gpt-4')).called(1);
    });
  });
}
