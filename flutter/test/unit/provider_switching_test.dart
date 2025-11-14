import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock the required imports for testing
import '../lib/services/llm_service.dart';
import '../lib/providers/llm_dashboard_provider.dart';
import '../lib/models/llm_models.dart';
import '../lib/models/llm_provider.dart';

void main() {
  group('Provider Switching Tests', () {
    late ProviderContainer container;
    late MockLlmService mockService;

    setUp(() {
      mockService = MockLlmService();
      container = ProviderContainer(overrides: [llmServiceProvider.overrideWithValue(mockService)]);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('ProviderConfigCard shows switch button for configured providers', (
      WidgetTester tester,
    ) async {
      // Arrange
      final config = _createTestConfig();
      bool providerSwitched = false;
      LLMProvider? switchedProvider;

      final card = Provider(
        provider: llmDashboardProvider,
        child: ProviderConfigCard(
          config: config,
          providerSettings: config.activeProviderSettings,
          onSwitchProvider: (provider) {
            providerSwitched = true;
            switchedProvider = provider;
          },
          onConfigureProvider: (apiKey, baseUrl) {},
        ),
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: card));

      // Assert
      expect(find.text('Switch'), findsAtLeastNWidgets(1));
      expect(find.text('Active'), findsAtLeastNWidgets(1));
      expect(find.text('Configured'), findsAtLeastNWidgets(2));
    });

    testWidgets('ProviderConfigCard shows configure button for unconfigured providers', (
      WidgetTester tester,
    ) async {
      // Arrange - Create config with unconfigured OpenRouter
      final config = _createConfigWithUnconfiguredOpenRouter();
      bool providerConfigured = false;

      final card = ProviderConfigCard(
        config: config,
        providerSettings: config.activeProviderSettings,
        onSwitchProvider: (provider) {},
        onConfigureProvider: (apiKey, baseUrl) {
          providerConfigured = true;
        },
      );

      await tester.pumpWidget(MaterialApp(home: card));

      // Assert
      expect(find.text('Configure'), findsOneWidget);
      expect(find.text('Click to configure OpenRouter API key'), findsOneWidget);
    });

    testWidgets('Provider switching calls onSwitchProvider callback', (WidgetTester tester) async {
      // Arrange
      final config = _createTestConfig();
      LLMProvider? switchedProvider;

      final card = ProviderConfigCard(
        config: config,
        providerSettings: config.activeProviderSettings,
        onSwitchProvider: (provider) {
          switchedProvider = provider;
        },
        onConfigureProvider: (apiKey, baseUrl) {},
      );

      await tester.pumpWidget(MaterialApp(home: card));

      // Act
      await tester.tap(find.text('Switch').first);
      await tester.pumpAndSettle();

      // Assert
      expect(switchedProvider, isNotNull);
      expect(switchedProvider, equals(LLMProvider.openrouter));
    });

    testWidgets('ProviderConfigCard shows loading state during switching', (
      WidgetTester tester,
    ) async {
      // Arrange
      final config = _createTestConfig();

      final card = ProviderConfigCard(
        config: config,
        providerSettings: config.activeProviderSettings,
        onSwitchProvider: (provider) => Future.delayed(Duration(milliseconds: 100)),
        onConfigureProvider: (apiKey, baseUrl) {},
        isLoading: true,
      );

      await tester.pumpWidget(MaterialApp(home: card));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Switch'), findsNothing);
    });

    testWidgets('LLM service provider switching uses switchMode endpoint', (
      WidgetTester tester,
    ) async {
      // Arrange
      final notifier = container.read(llmDashboardProvider.notifier);

      // Act
      await notifier.switchActiveProvider(LLMProvider.openrouter);

      // Assert - The mock service should track that switchMode was called
      expect(mockService.switchModeCalled, true);
      expect(mockService.lastSwitchedProvider, equals(LLMProvider.openrouter));
    });
  });
}

LLMConfigResponse _createTestConfig() {
  final providers = <LLMProvider, LLMProviderSettings>{
    LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
    LLMProvider.openrouter: LLMProviderSettings(
      provider: LLMProvider.openrouter,
      apiKey: 'configured', // Marked as configured
    ),
  };

  final models = <String, LLMModelConfig>{
    'llama2:7b': LLMModelConfig(modelName: 'llama2:7b', provider: LLMProvider.local),
    'gpt-3.5-turbo': LLMModelConfig(modelName: 'gpt-3.5-turbo', provider: LLMProvider.openrouter),
  };

  return LLMConfigResponse(
    activeProvider: LLMProvider.local,
    activeModel: 'llama2:7b',
    providers: providers,
    models: models,
  );
}

LLMConfigResponse _createConfigWithUnconfiguredOpenRouter() {
  final providers = <LLMProvider, LLMProviderSettings>{
    LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
    LLMProvider.openrouter: LLMProviderSettings(
      provider: LLMProvider.openrouter,
      // No API key - not configured
    ),
  };

  final models = <String, LLMModelConfig>{
    'llama2:7b': LLMModelConfig(modelName: 'llama2:7b', provider: LLMProvider.local),
  };

  return LLMConfigResponse(
    activeProvider: LLMProvider.local,
    activeModel: 'llama2:7b',
    providers: providers,
    models: models,
  );
}

class MockLlmService extends Mock implements LlmService {
  bool switchModeCalled = false;
  LLMProvider? lastSwitchedProvider;

  @override
  Future<void> setActiveProvider(LLMProvider provider) async {
    switchModeCalled = true;
    lastSwitchedProvider = provider;
  }
}
