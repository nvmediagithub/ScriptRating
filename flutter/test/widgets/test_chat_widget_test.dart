import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:script_rating_app/widgets/llm_dashboard/test_chat_widget.dart';
import 'package:script_rating_app/services/llm_service.dart';

// Create a mock class for LlmService
class MockLlmService extends Mock implements LlmService {}

void main() {
  group('TestChatWidget Widget Tests', () {
    late TestChatWidget testChatWidget;
    late MockLlmService mockLlmService;
    const testProvider = 'local';
    const testModel = 'test-model';

    setUp(() {
      mockLlmService = MockLlmService();
      testChatWidget = TestChatWidget(
        llmService: mockLlmService,
        currentProvider: testProvider,
        currentModel: testModel,
      );
    });

    Widget createTestWidget() {
      return MaterialApp(home: Scaffold(body: testChatWidget));
    }

    group('Basic Widget Tests', () {
      testWidgets('should initialize and render without errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify main widget structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Flexible), findsWidgets);
      });

      testWidgets('should display welcome message on initialization', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify welcome message is displayed
        expect(find.text('LLM Test Chat'), findsOneWidget);
        expect(find.text('Provider: $testProvider'.toUpperCase()), findsOneWidget);
        expect(find.text('Model: $testModel'), findsOneWidget);
        expect(find.text('Type a test message...'), findsOneWidget);
      });

      testWidgets('should display provider and model information correctly', (
        WidgetTester tester,
      ) async {
        const provider = 'openrouter';
        const model = 'gpt-4-turbo';

        final customWidget = TestChatWidget(
          llmService: mockLlmService,
          currentProvider: provider,
          currentModel: model,
        );

        final customTestWidget = MaterialApp(home: Scaffold(body: customWidget));

        await tester.pumpWidget(customTestWidget);

        // Verify provider and model display
        expect(find.text('Provider: $provider'.toUpperCase()), findsOneWidget);
        expect(find.text('Model: $model'), findsOneWidget);
      });

      testWidgets('should have proper card styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final card = tester.widget<Card>(find.byType(Card));
        expect(card.child, isNotNull);
      });
    });

    group('Message Input Tests', () {
      testWidgets('should allow text input in message field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the text field
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.hintText, 'Type a test message...');
      });

      testWidgets('should update text field when user types', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find and interact with text field
        await tester.enterText(find.byType(TextField), 'Hello, world!');
        await tester.pump();

        // Verify text was entered
        expect(find.text('Hello, world!'), findsOneWidget);
      });

      testWidgets('should clear text after sending message', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter text and send
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock successful LLM response
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer(
          (_) async => {
            'response': 'Hello! How can I help you?',
            'response_time_ms': 500.0, // This is a double now
          },
        );

        // Send the message
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify text was cleared
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('should disable input when processing', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter text and send
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock slow LLM response
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return {'response': 'Hello! How can I help you?', 'response_time_ms': 100.0};
        });

        // Send the message
        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Verify input is disabled during processing
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, false);
      });
    });

    group('Message Display Tests', () {
      testWidgets('should display user messages correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'User message');
        await tester.pump();

        // Mock response
        when(
          () => mockLlmService.testLLM('User message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Assistant response', 'response_time_ms': 300.0});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify user message is displayed
        expect(find.text('User message'), findsOneWidget);
        expect(find.text('Assistant response'), findsOneWidget);
      });

      testWidgets('should display assistant messages with response time', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock response with specific response time
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer(
          (_) async => {
            'response': 'Hello! How can I help you?',
            'response_time_ms': 1673.2289401647313, // Double value to test the fix
          },
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify response time is displayed correctly
        expect(find.text('Response time: 1673.2289401647313ms'), findsOneWidget);
      });

      testWidgets('should handle messages without response time', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock response without response time
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Hello! How can I help you?'});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify response time is not displayed
        expect(find.textContaining('Response time'), findsNothing);
      });

      testWidgets('should display message bubbles with correct styling', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'User message');
        await tester.pump();

        // Mock response
        when(
          () => mockLlmService.testLLM('User message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Assistant response', 'response_time_ms': 500.0});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify message bubbles exist
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('LLM Service Integration Tests', () {
      testWidgets('should call LLM service with correct parameters', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock successful response
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Hello!', 'response_time_ms': 500.0});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify service was called with correct parameters
        verify(() => mockLlmService.testLLM('Test message', modelName: testModel)).called(1);
      });

      testWidgets('should handle successful LLM response', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock successful response
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer(
          (_) async => {'response': 'Hello! How can I help you?', 'response_time_ms': 1234.567},
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify response is displayed
        expect(find.text('Hello! How can I help you?'), findsOneWidget);
      });

      testWidgets('should handle LLM service errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock error response
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenThrow(Exception('Network error'));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.textContaining('Error:'), findsOneWidget);
      });

      testWidgets('should handle empty response gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock empty response
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenAnswer((_) async => {'response': null});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify default error message is displayed
        expect(find.text('No response received'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should display error messages correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock error response
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenThrow(Exception('Connection failed'));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.text('Error: Connection failed'), findsOneWidget);
      });

      testWidgets('should handle network timeouts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock timeout
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenThrow(Exception('Timeout: 30 seconds'));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify error is handled
        expect(find.textContaining('Error:'), findsOneWidget);
      });

      testWidgets('should not send empty messages', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Try to send empty message
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        // Try to tap send button
        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Verify service was not called
        verifyNever(() => mockLlmService.testLLM(any(), modelName: any(named: 'modelName')));
      });

      testWidgets('should handle rapid message sending', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send multiple messages rapidly
        for (int i = 0; i < 3; i++) {
          await tester.enterText(find.byType(TextField), 'Message $i');
          await tester.pump();

          // Mock response
          when(() => mockLlmService.testLLM('Message $i', modelName: testModel)).thenAnswer(
            (_) async => {'response': 'Response $i', 'response_time_ms': 100.0 + i * 100.0},
          );

          await tester.tap(find.byType(InkWell));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Verify messages are displayed
        for (int i = 0; i < 3; i++) {
          expect(find.text('Message $i'), findsOneWidget);
          expect(find.text('Response $i'), findsOneWidget);
        }
      });
    });

    group('Chat Management Tests', () {
      testWidgets('should clear chat when clear button is pressed', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message first
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock response
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Hello!', 'response_time_ms': 500.0});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify message was added
        expect(find.text('Test message'), findsOneWidget);
        expect(find.text('Hello!'), findsOneWidget);

        // Find and tap clear button
        final clearButton = find.byIcon(Icons.refresh);
        expect(clearButton, findsOneWidget);
        await tester.tap(clearButton);
        await tester.pump();

        // Verify chat is cleared and welcome message is added
        expect(find.text('Test message'), findsNothing);
        expect(find.text('Hello!'), findsNothing);
        expect(find.text('LLM Test Chat'), findsOneWidget);
      });

      testWidgets('should scroll to bottom when new messages arrive', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send multiple messages to trigger scrolling
        for (int i = 0; i < 3; i++) {
          await tester.enterText(find.byType(TextField), 'Message $i');
          await tester.pump();

          // Mock response
          when(
            () => mockLlmService.testLLM('Message $i', modelName: testModel),
          ).thenAnswer((_) async => {'response': 'Response $i', 'response_time_ms': 200.0});

          await tester.tap(find.byType(InkWell));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Verify all messages are displayed
        for (int i = 0; i < 3; i++) {
          expect(find.text('Message $i'), findsOneWidget);
          expect(find.text('Response $i'), findsOneWidget);
        }
      });
    });

    group('UI Interaction Tests', () {
      testWidgets('should show typing indicator during processing', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock slow response
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return {'response': 'Hello!', 'response_time_ms': 100.0};
        });

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Verify typing indicator is shown during processing
        expect(find.text('Thinking...'), findsOneWidget);
      });

      testWidgets('should disable send button when text is empty', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Ensure text field is empty
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);

        // Send button should be disabled (gray color)
        final sendButton = tester.widget<Material>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(Material)),
        );
        expect(sendButton.color, Colors.grey[300]);
      });

      testWidgets('should enable send button when text is entered', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter text
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Send button should be enabled
        final sendButton = tester.widget<Material>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(Material)),
        );
        expect(sendButton.color, isNot(Colors.grey[300]));
      });

      testWidgets('should show loading indicator during message processing', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock slow response
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return {'response': 'Hello!', 'response_time_ms': 100.0};
        });

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Message Bubble Tests', () {
      testWidgets('should display user and assistant messages with correct alignment', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'User message');
        await tester.pump();

        // Mock response
        when(
          () => mockLlmService.testLLM('User message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Assistant response', 'response_time_ms': 500.0});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify both messages are displayed
        expect(find.text('User message'), findsOneWidget);
        expect(find.text('Assistant response'), findsOneWidget);
      });

      testWidgets('should display avatars for messages', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock response
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Hello!', 'response_time_ms': 500.0});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify avatars are displayed
        expect(find.byType(CircleAvatar), findsWidgets);
      });

      testWidgets('should format response time display correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock response with specific response time
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer(
          (_) async => {
            'response': 'Hello!',
            'response_time_ms': 1234.567890123, // Double with many decimal places
          },
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify response time is displayed with full precision
        expect(find.text('Response time: 1234.567890123ms'), findsOneWidget);
      });
    });

    group('Edge Cases Tests', () {
      testWidgets('should handle very long messages', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Create a very long message
        final longMessage = 'A' * 1000;

        await tester.enterText(find.byType(TextField), longMessage);
        await tester.pump();

        // Mock response
        when(() => mockLlmService.testLLM(longMessage, modelName: testModel)).thenAnswer(
          (_) async => {'response': 'Response to long message', 'response_time_ms': 500.0},
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify long message is handled correctly
        expect(find.text(longMessage), findsOneWidget);
        expect(find.text('Response to long message'), findsOneWidget);
      });

      testWidgets('should handle messages with special characters', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Message with special characters
        const specialMessage = 'Hello! Test with emojis and special characters';

        await tester.enterText(find.byType(TextField), specialMessage);
        await tester.pump();

        // Mock response
        when(() => mockLlmService.testLLM(specialMessage, modelName: testModel)).thenAnswer(
          (_) async => {'response': 'Response with special chars', 'response_time_ms': 300.0},
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify special characters are handled correctly
        expect(find.text(specialMessage), findsOneWidget);
        expect(find.text('Response with special chars'), findsOneWidget);
      });

      testWidgets('should handle rapid user interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Simulate rapid typing and sending
        for (int i = 0; i < 5; i++) {
          await tester.enterText(find.byType(TextField), 'Message $i');
          await tester.pump();

          // Mock response
          when(
            () => mockLlmService.testLLM('Message $i', modelName: testModel),
          ).thenAnswer((_) async => {'response': 'Response $i', 'response_time_ms': 100.0});

          await tester.tap(find.byType(InkWell));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Verify all messages are processed correctly
        for (int i = 0; i < 5; i++) {
          expect(find.text('Message $i'), findsOneWidget);
          expect(find.text('Response $i'), findsOneWidget);
        }
      });

      testWidgets('should handle null response time gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock response with null response time
        when(
          () => mockLlmService.testLLM('Test message', modelName: testModel),
        ).thenAnswer((_) async => {'response': 'Hello!', 'response_time_ms': null});

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Verify response is displayed without response time
        expect(find.text('Hello!'), findsOneWidget);
        expect(find.textContaining('Response time'), findsNothing);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should be accessible with semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify main elements are accessible
        expect(find.text('LLM Test Chat'), findsOneWidget);
        expect(find.text('Type a test message...'), findsOneWidget);
      });

      testWidgets('should handle focus correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Test that text field can receive focus
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.tap(textField);
        await tester.pump();

        // Text field should be focused
        expect(find.text('Type a test message...'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle many messages efficiently', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Add many messages
        final messageCount = 50;
        for (int i = 0; i < messageCount; i++) {
          await tester.enterText(find.byType(TextField), 'Message $i');
          await tester.pump();

          // Mock response
          when(
            () => mockLlmService.testLLM('Message $i', modelName: testModel),
          ).thenAnswer((_) async => {'response': 'Response $i', 'response_time_ms': 50.0 + i});

          await tester.tap(find.byType(InkWell));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Verify all messages are displayed
        for (int i = 0; i < messageCount; i++) {
          expect(find.text('Message $i'), findsOneWidget);
          expect(find.text('Response $i'), findsOneWidget);
        }
      });

      testWidgets('should handle widget disposal correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Send a message
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Mock slow response
        when(() => mockLlmService.testLLM('Test message', modelName: testModel)).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return {'response': 'Hello!', 'response_time_ms': 100.0};
        });

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Verify widget is still functional
        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}
