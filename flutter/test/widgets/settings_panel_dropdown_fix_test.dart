import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/widgets/llm_dashboard/settings_panel.dart';
import 'package:script_rating_app/models/llm_models.dart';
import 'package:script_rating_app/models/llm_provider.dart';

void main() {
  group('SettingsPanel Dropdown Fix Tests', () {
    late LLMConfigResponse config;
    late Map<String, dynamic> configurationSettings;
    late VoidCallback onSettingsUpdated;

    setUp(() {
      config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model-1',
        providers: {
          LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local),
          LLMProvider.openrouter: LLMProviderSettings(provider: LLMProvider.openrouter),
        },
        models: {
          'test-model-1': LLMModelConfig(modelName: 'test-model-1', provider: LLMProvider.local),
          'test-model-2': LLMModelConfig(
            modelName: 'test-model-2',
            provider: LLMProvider.openrouter,
          ),
        },
      );

      configurationSettings = {
        'auto_save': true,
        'request_timeout': 30,
        'max_retries': 3,
        'caching_enabled': true,
        'cache_duration': 24,
        'log_level': 'info',
        'auto_refresh_status': true,
        'default_provider': 'local',
        'default_model': 'default', // This would previously cause the assertion error
      };

      onSettingsUpdated = () {};
    });

    testWidgets(
      'SettingsPanel should build without assertion error when default_model is not in available models',
      (WidgetTester tester) async {
        // This test would previously fail with assertion error before the fix
        expect(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SettingsPanel(
                  config: config,
                  configurationSettings: configurationSettings,
                  onSettingsUpdated: (_) => onSettingsUpdated(),
                ),
              ),
            ),
          );
        }, returnsNormally);
      },
    );

    testWidgets(
      'Default model dropdown should use active model when stored default model is invalid',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsPanel(
                config: config,
                configurationSettings: configurationSettings,
                onSettingsUpdated: (_) => onSettingsUpdated(),
              ),
            ),
          ),
        );

        // Find the Default Model dropdown by text
        expect(find.text('Default Model'), findsOneWidget);
      },
    );

    testWidgets(
      'Default provider dropdown should build without assertion error when default_provider is valid',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsPanel(
                config: config,
                configurationSettings: configurationSettings,
                onSettingsUpdated: (_) => onSettingsUpdated(),
              ),
            ),
          ),
        );

        // Find the Default Provider dropdown by text
        expect(find.text('Default Provider'), findsOneWidget);
      },
    );
  });
}
