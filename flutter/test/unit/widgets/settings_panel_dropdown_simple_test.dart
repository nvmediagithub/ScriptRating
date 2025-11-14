import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/widgets/llm_dashboard/settings_panel.dart';
import 'package:script_rating_app/models/llm_models.dart';
import 'package:script_rating_app/models/llm_provider.dart';

void main() {
  group('SettingsPanel Dropdown Assertion Error Fix', () {
    testWidgets('Original assertion error should be fixed - no more "default" value errors', (
      WidgetTester tester,
    ) async {
      // This test specifically checks for the original assertion error:
      // "There should be exactly one item with [DropdownButton]'s value: default"

      final config = LLMConfigResponse(
        activeProvider: LLMProvider.local,
        activeModel: 'test-model-1',
        providers: {LLMProvider.local: LLMProviderSettings(provider: LLMProvider.local)},
        models: {
          'test-model-1': LLMModelConfig(modelName: 'test-model-1', provider: LLMProvider.local),
        },
      );

      // This configuration with 'default' value would previously cause the assertion error
      final configurationSettings = {
        'default_model': 'default', // This was the problematic value
        'default_provider': 'local',
      };

      bool hasError = false;
      String? errorMessage;

      // Set up Flutter error handler to catch assertion errors
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('DropdownButton') &&
            details.exception.toString().contains('default')) {
          hasError = true;
          errorMessage = details.exception.toString();
        }
      };

      // Build the widget - this would previously fail with assertion error
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: SettingsPanel(
                  config: config,
                  configurationSettings: configurationSettings,
                  onSettingsUpdated: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the original assertion error doesn't occur
      expect(
        hasError,
        isFalse,
        reason:
            'The original assertion error about "default" value should be fixed. Error was: $errorMessage',
      );

      // Verify the widget builds successfully
      expect(find.text('Settings Panel'), findsOneWidget);
    });
  });
}
