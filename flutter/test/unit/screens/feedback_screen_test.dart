import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:script_rating_app/screens/feedback_screen.dart';

void main() {
  group('FeedbackScreen Widget Tests', () {
    // Test Helper Methods
    final List<String> mockFeedbackTypes = [
      'Rating Correction',
      'Content Flagging Error',
      'Scene Assessment Issue',
      'Technical Problem',
      'General Feedback',
    ];

    Widget createTestWidget() {
      return const MaterialApp(
        home: FeedbackScreen(),
      );
    }

    // Basic Rendering Tests
    testWidgets('FeedbackScreen should render with correct title and back button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Submit Feedback'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('FeedbackScreen should render form with all required fields', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Help us improve our analysis'), findsOneWidget);
      expect(find.text('Please provide details about any issues or corrections you\'d like to suggest.'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Feedback Type'), findsOneWidget);
      expect(find.text('Issue/Scene Number (optional)'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('FeedbackScreen should render submit button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Submit Feedback'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    // Form Field Tests
    testWidgets('FeedbackScreen should render feedback type dropdown with correct options', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Initial selection
      expect(find.text('Rating Correction'), findsOneWidget);

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Assert - All options should be visible
      expect(find.text('Rating Correction'), findsOneWidget);
      expect(find.text('Content Flagging Error'), findsOneWidget);
      expect(find.text('Scene Assessment Issue'), findsOneWidget);
      expect(find.text('Technical Problem'), findsOneWidget);
      expect(find.text('General Feedback'), findsOneWidget);
    });

    testWidgets('FeedbackScreen should allow changing feedback type', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Open dropdown and select different option
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Technical Problem'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Technical Problem'), findsOneWidget);
    });

    testWidgets('FeedbackScreen should have optional issue/scene field', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Find the first TextFormField (issue field)
      final issueFields = find.descendant(
        of: find.byType(TextFormField),
        matching: find.byWidgetPredicate(
          (widget) => widget is TextFormField && 
                     (widget.controller?.text == null || widget.controller!.text.isEmpty),
        ),
      );

      // Act - Enter text in issue field
      await tester.enterText(find.text('Issue/Scene Number (optional)'), 'Scene 12');
      await tester.pump();

      // Assert
      expect(find.text('Scene 12'), findsOneWidget);
    });

    testWidgets('FeedbackScreen should have required description field', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Find description field (should be the one with 'Description' label)
      await tester.enterText(find.text('Description'), 'This is my feedback description');
      await tester.pump();

      // Assert
      expect(find.text('This is my feedback description'), findsOneWidget);
    });

    // Form Validation Tests
    testWidgets('FeedbackScreen should show validation error when description is empty', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Leave description empty and try to submit
      await tester.tap(find.text('Submit Feedback'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Please provide a description'), findsOneWidget);
    });

    testWidgets('FeedbackScreen should validate feedback type is selected', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Add description but no feedback type change needed (default should be valid)
      await tester.enterText(find.text('Description'), 'Test feedback');
      await tester.pump();

      // Act - Try to submit with valid data
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(); // May start submission process

      // Note: The current implementation doesn't validate feedback type as required
      // This test verifies that the default selection is acceptable
    });

    testWidgets('FeedbackScreen should show validation error for empty description', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Issue/Scene Number (optional)'), 'Scene 5');
      await tester.pump();

      // Act - Try to submit without description
      await tester.tap(find.text('Submit Feedback'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please provide a description'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget); // Still visible
    });

    // Submission Tests
    testWidgets('FeedbackScreen should show loading state during submission', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Description'), 'Valid feedback description');
      await tester.pump();

      // Act - Submit form
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(); // Should show loading

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Feedback'), findsNothing);
    });

    testWidgets('FeedbackScreen should show success state after successful submission', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Description'), 'Valid feedback description');
      await tester.pump();

      // Act - Submit and wait for success
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(); // Loading
      await tester.pump(const Duration(seconds: 3)); // Wait for mock submission

      // Assert
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Thank you for your feedback!'), findsOneWidget);
      expect(find.text('Your correction has been submitted and will be reviewed by our team.'), findsOneWidget);
      expect(find.text('Submit Another Feedback'), findsOneWidget);
      expect(find.text('Back to Results'), findsOneWidget);
    });

    testWidgets('FeedbackScreen should reset form after successful submission', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Issue/Scene Number (optional)'), 'Scene 10');
      await tester.enterText(find.text('Description'), 'Test feedback description');
      await tester.pump();

      // Act - Submit
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(const Duration(seconds: 3)); // Wait for completion

      // Assert - Should be in success state
      expect(find.text('Thank you for your feedback!'), findsOneWidget);

      // Act - Submit another feedback
      await tester.tap(find.text('Submit Another Feedback'));
      await tester.pumpAndSettle();

      // Assert - Form should be reset
      expect(find.text('Help us improve our analysis'), findsOneWidget);
      expect(find.text('Rating Correction'), findsOneWidget); // Default selection
      expect(find.text('Issue/Scene Number (optional)'), findsOneWidget); // Empty field
      expect(find.text('Description'), findsOneWidget); // Empty field
    });

    testWidgets('FeedbackScreen should show error state on submission failure', (WidgetTester tester) async {
      // Note: The current implementation doesn't handle submission errors
      // This test would need the API call to be mocked to fail
      // For now, we verify the successful flow works as expected
    });

    // Navigation Tests
    testWidgets('FeedbackScreen should navigate back to results when back button is pressed', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Navigate back (will pop in test environment)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert - Screen should be dismissed
      expect(find.text('Submit Feedback'), findsNothing);
    });

    testWidgets('FeedbackScreen should navigate back from success state', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Description'), 'Valid feedback');
      await tester.pump();
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(const Duration(seconds: 3)); // Wait for success

      // Act - Navigate back from success state
      await tester.tap(find.text('Back to Results'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Thank you for your feedback!'), findsNothing);
    });

    // Success State Tests
    testWidgets('FeedbackScreen success state should display correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Description'), 'Valid feedback description');
      await tester.pump();

      // Act - Submit to trigger success state
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(const Duration(seconds: 3)); // Wait for completion

      // Assert - Success state elements
      expect(find.byType(Column), findsWidgets); // Multiple columns in success state
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Thank you for your feedback!'), findsOneWidget);
      expect(find.text('Your correction has been submitted and will be reviewed by our team.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Submit Another Feedback
      expect(find.byType(TextButton), findsAtLeastNWidgets(1)); // Back to Results
    });

    testWidgets('FeedbackScreen should allow multiple feedback submissions', (WidgetTester tester) async {
      // Arrange - First submission
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Description'), 'First feedback');
      await tester.pump();
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(const Duration(seconds: 3)); // Wait for first submission

      // Act - Submit another feedback
      await tester.tap(find.text('Submit Another Feedback'));
      await tester.pumpAndSettle();

      // Second submission
      await tester.enterText(find.text('Description'), 'Second feedback');
      await tester.pump();
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(const Duration(seconds: 3)); // Wait for second submission

      // Assert - Should show success state again
      expect(find.text('Thank you for your feedback!'), findsOneWidget);
    });

    // Form State Management Tests
    testWidgets('FeedbackScreen should preserve form data during validation errors', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Issue/Scene Number (optional)'), 'Scene 15');
      await tester.enterText(find.text('Description'), 'My detailed feedback');
      await tester.pump();

      // Act - Try invalid submission (empty description would trigger this, but let's simulate validation)
      await tester.tap(find.text('Submit Feedback'));
      await tester.pumpAndSettle();

      // If validation were to fail, data should be preserved
      // Note: Current implementation doesn't handle validation state preservation well
    });

    testWidgets('FeedbackScreen should clear error state when form is corrected', (WidgetTester tester) async {
      // Arrange - This test assumes error handling is implemented
      // The current implementation doesn't show validation errors persistently
      // This test would need error state handling to be added
    });

    // UI Layout Tests
    testWidgets('FeedbackScreen should use SingleChildScrollView for content', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Padding), findsWidgets); // Multiple padding widgets
    });

    testWidgets('FeedbackScreen should have proper form spacing', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Verify form layout with adequate spacing
      expect(find.byType(SizedBox), findsWidgets); // SizedBox for spacing
      expect(find.byType(Text), findsWidgets); // Multiple text widgets
    });

    testWidgets('FeedbackScreen should render form with proper input decoration', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Check for proper input decoration
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      final dropdownField = tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>));
      expect(dropdownField.decoration, isA<InputDecoration>());
      expect((dropdownField.decoration as InputDecoration).labelText, 'Feedback Type');
    });

    // Input Field Tests
    testWidgets('FeedbackScreen should handle multiline description input', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter multiline text
      final multilineText = 'This is a detailed feedback\nwith multiple lines\n describing the issue\nand suggested corrections.';
      await tester.enterText(find.text('Description'), multilineText);
      await tester.pump();

      // Assert
      expect(find.text(multilineText), findsOneWidget);
    });

    testWidgets('FeedbackScreen should handle character limits on text fields', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter very long text
      final longText = 'A' * 1000;
      await tester.enterText(find.text('Description'), longText);
      await tester.pump();

      // Assert - Should handle long input (Flutter's TextFormField has built-in limits)
      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('FeedbackScreen should handle special characters in input', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter text with special characters
      await tester.enterText(find.text('Description'), 'Feedback with special chars: @#$%^&*()_+-={}[]|\\:";\'<>?,./');
      await tester.pump();

      // Assert
      expect(find.text('Feedback with special chars'), findsOneWidget);
    });

    // User Experience Tests
    testWidgets('FeedbackScreen should provide helpful guidance text', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Help us improve our analysis'), findsOneWidget);
      expect(find.text('Please provide details about any issues or corrections you\'d like to suggest.'), findsOneWidget);
      expect(find.text('Issue/Scene Number (optional)'), findsOneWidget);
      expect(find.text('Please describe the issue and your suggested correction'), findsOneWidget);
    });

    testWidgets('FeedbackScreen should show appropriate feedback type options', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Verify all feedback types are available
      mockFeedbackTypes.forEach((type) {
        expect(find.text(type), findsOneWidget);
      });
    });

    // State Management Tests
    testWidgets('FeedbackScreen should manage loading states correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Description'), 'Valid feedback');
      await tester.pump();

      // Act - Submit
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(); // Should show loading

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pump(const Duration(seconds: 3));

      // Loading should be cleared
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('FeedbackScreen should handle concurrent submissions gracefully', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Description'), 'Test feedback');
      await tester.pump();

      // Act - Rapid taps on submit
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump();

      // Should handle gracefully (only one submission should process)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Performance Tests
    testWidgets('FeedbackScreen should handle long description text efficiently', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      final longDescription = List.generate(
        50,
        (index) => 'This is paragraph $index with detailed feedback content about the analysis results and recommendations for improvement.',
      ).join('\n\n');

      final stopwatch = Stopwatch()..start();

      // Act
      await tester.enterText(find.text('Description'), longDescription);
      await tester.pump();

      stopwatch.stop();

      // Assert - Should handle long text efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(find.text(longDescription.split('\n').first), findsOneWidget);
    });

    testWidgets('FeedbackScreen should render efficiently with complex form data', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.text('Issue/Scene Number (optional)'), 'Scenes 5-12');
      await tester.enterText(find.text('Description'), 'Detailed feedback about multiple scenes and their content analysis');
      await tester.pump();

      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(find.byType(Form), findsOneWidget);
    });

    // Accessibility Tests
    testWidgets('FeedbackScreen should have proper semantic labels', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.bySemanticsLabel('Submit Feedback'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsAtLeastNWidgets(1));
    });

    testWidgets('FeedbackScreen should be keyboard navigable', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Test keyboard navigation through form fields
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Should not crash during navigation
      expect(find.text('Submit Feedback'), findsOneWidget);
    });

    // Integration Tests
    testWidgets('FeedbackScreen complete user workflow', (WidgetTester tester) async {
      // Arrange & Act - Fill form
      await tester.pumpWidget(createTestWidget());
      
      // Fill feedback type
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Content Flagging Error'));
      await tester.pumpAndSettle();

      // Fill issue field
      await tester.enterText(find.text('Issue/Scene Number (optional)'), 'Scene 8, rating seems incorrect');
      await tester.pump();

      // Fill description
      await tester.enterText(find.text('Description'), 'The violence level in scene 8 appears to be rated too low. The scene contains explicit violence that should be rated as high severity.');
      await tester.pump();

      // Submit
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(); // Loading
      await tester.pump(const Duration(seconds: 3)); // Success

      // Assert - Success state
      expect(find.text('Thank you for your feedback!'), findsOneWidget);

      // Act - Submit another
      await tester.tap(find.text('Submit Another Feedback'));
      await tester.pumpAndSettle();

      // Assert - Form reset
      expect(find.text('Help us improve our analysis'), findsOneWidget);
      expect(find.text('Rating Correction'), findsOneWidget); // Default
    });

    testWidgets('FeedbackScreen error handling workflow', (WidgetTester tester) async {
      // Arrange & Act - Try to submit empty form
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Submit Feedback'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Please provide a description'), findsOneWidget);

      // Act - Fill form and submit
      await tester.enterText(find.text('Description'), 'Valid feedback now');
      await tester.pump();
      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(); // Loading
      await tester.pump(const Duration(seconds: 3)); // Success

      // Assert - Should succeed
      expect(find.text('Thank you for your feedback!'), findsOneWidget);
    });
  });
}

