import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:script_rating_app/widgets/llm_dashboard/test_chat_widget.dart';
import 'package:script_rating_app/services/llm_service.dart';

void main() {
  group('TestChatWidget Layout Fix Tests', () {
    testWidgets('TestChatWidget renders without unbounded height constraint errors', (
      WidgetTester tester,
    ) async {
      // Build the TestChatWidget with minimal dependencies
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _buildTestWidget())));

      // Verify the widget renders without errors
      expect(find.byType(TestChatWidget), findsOneWidget);
      expect(find.text('LLM Test Chat'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verify that the main layout structure exists
      final mainColumn = tester.widget<Column>(
        find.descendant(of: find.byType(TestChatWidget), matching: find.byType(Column).first),
      );

      // Verify the column has 3 children: header, message list, input area
      expect(mainColumn.children.length, 3);

      // Verify the middle child (message list) is a Flexible widget with loose fit
      final messageListWidget = mainColumn.children[1];
      expect(messageListWidget, isA<Flexible>());

      final flexibleWidget = messageListWidget as Flexible;
      expect(flexibleWidget.fit, FlexFit.loose);

      // Verify the flexible widget wraps a ListView (the message list)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('TestChatWidget shows welcome message on initialization', (
      WidgetTester tester,
    ) async {
      // Build the TestChatWidget
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _buildTestWidget())));

      // Verify welcome message is displayed
      expect(find.textContaining('Hello! I\'m your LLM test assistant'), findsOneWidget);
    });
  });
}

/// Build a TestChatWidget with mock LlmService for testing
Widget _buildTestWidget() {
  return TestChatWidget(
    llmService: MockLlmService(),
    currentProvider: 'local',
    currentModel: 'test-model',
  );
}

/// Mock LlmService that extends the real LlmService class
class MockLlmService extends LlmService {
  MockLlmService() : super(Dio());

  @override
  Future<Map<String, dynamic>> testLLM(String message, {String? modelName}) async {
    return {'response': 'Test response', 'response_time_ms': 100};
  }
}
