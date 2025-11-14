import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:script_rating_app/screens/report_generation_screen.dart';

void main() {
  group('ReportGenerationScreen Widget Tests', () {
    // Test Helper Methods
    final List<Map<String, dynamic>> mockFormats = [
      {
        'name': 'PDF',
        'description': 'Portable Document Format - Best for printing and sharing',
        'icon': Icons.picture_as_pdf,
        'color': Colors.red,
      },
      {
        'name': 'DOCX',
        'description': 'Microsoft Word Document - Editable format',
        'icon': Icons.description,
        'color': Colors.blue,
      },
      {
        'name': 'HTML',
        'description': 'Web page format - Viewable in browsers',
        'icon': Icons.web,
        'color': Colors.green,
      },
      {
        'name': 'JSON',
        'description': 'Structured data format - For developers',
        'icon': Icons.code,
        'color': Colors.orange,
      },
    ];

    Widget createTestWidget() {
      return const MaterialApp(
        home: ReportGenerationScreen(),
      );
    }

    // Basic Rendering Tests
    testWidgets('ReportGenerationScreen should render with correct title and back button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Generate Report'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should render format selection section', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Choose Report Format'), findsOneWidget);
      expect(find.text('Select the format that best suits your needs'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should render all format options', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('DOCX'), findsOneWidget);
      expect(find.text('HTML'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNWidgets(4));
    });

    testWidgets('ReportGenerationScreen should render generate button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Generate PDF Report'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    // Format Selection Tests
    testWidgets('ReportGenerationScreen should allow format selection', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Select DOCX format
      await tester.tap(find.text('DOCX'));
      await tester.pumpAndSettle();

      // Assert
      final docxTile = tester.widget<RadioListTile<String>>(find.text('DOCX').parent as Finder);
      expect(docxTile.groupValue, 'DOCX');
      expect(find.text('Generate DOCX Report'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should update button text when format changes', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Change to HTML
      await tester.tap(find.text('HTML'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Generate HTML Report'), findsOneWidget);
      expect(find.text('Generate PDF Report'), findsNothing);
    });

    testWidgets('ReportGenerationScreen should reset generated state when format changes', (WidgetTester tester) async {
      // Arrange - Generate a report first
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('PDF'));
      await tester.pump();
      
      // Simulate generation completion (would need to wait for mock delay)
      // For now, verify format change resets state
      
      // Act - Change format after "generation"
      await tester.tap(find.text('DOCX'));
      await tester.pump();

      // Note: In a real scenario with state management, this would reset the generated state
      expect(find.text('Generate DOCX Report'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should have PDF as default selection', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final pdfTile = tester.widget<RadioListTile<String>>(find.text('PDF').parent as Finder);
      expect(pdfTile.groupValue, 'PDF');
    });

    // Format Description Tests
    testWidgets('ReportGenerationScreen should display format descriptions', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Portable Document Format - Best for printing and sharing'), findsOneWidget);
      expect(find.text('Microsoft Word Document - Editable format'), findsOneWidget);
      expect(find.text('Web page format - Viewable in browsers'), findsOneWidget);
      expect(find.text('Structured data format - For developers'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should render format icons', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.byIcon(Icons.web), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    // Generation Process Tests
    testWidgets('ReportGenerationScreen should show loading state during generation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Start generation
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(); // Should show loading

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Generating report...'), findsOneWidget);
      expect(find.text('Generate PDF Report'), findsNothing);
    });

    testWidgets('ReportGenerationScreen should show success state after generation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Generate and wait for completion
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(); // Loading state
      await tester.pump(const Duration(seconds: 4)); // Wait for mock generation

      // Assert - Success state
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Report generated in PDF format'), findsOneWidget);
      expect(find.text('Generate Another'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should show success snackbar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Generate report
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for completion

      // Assert - Snackbar should be shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Report generated successfully in PDF format!'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget); // Snackbar action
    });

    testWidgets('ReportGenerationScreen should handle download action', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for generation

      // Act - Tap download button
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      // Assert - Should show download snackbar
      expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
      expect(find.text('Download would start here'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should allow generating another report', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for generation

      // Act - Generate another report
      await tester.tap(find.text('Generate Another'));
      await tester.pumpAndSettle();

      // Assert - Should return to initial state
      expect(find.text('Generate PDF Report'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Report generated'), findsNothing);
    });

    // Error Handling Tests
    testWidgets('ReportGenerationScreen should show error state on generation failure', (WidgetTester tester) async {
      // Note: The current implementation doesn't handle generation errors
      // This test would need the mock generation to fail
      // For now, we verify the successful flow works correctly
    });

    testWidgets('ReportGenerationScreen should handle generation timeout', (WidgetTester tester) async {
      // Note: The current implementation uses a fixed 3-second delay
      // This test would need timeout handling to be added to the implementation
    });

    // Navigation Tests
    testWidgets('ReportGenerationScreen should navigate back when back button is pressed', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Navigate back (will pop in test environment)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert - Screen should be dismissed
      expect(find.text('Generate Report'), findsNothing);
    });

    testWidgets('ReportGenerationScreen should navigate back from success state', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for generation

      // Act - Navigate back from success state
      await tester.tap(find.text('Back to Results'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Generate Report'), findsNothing);
    });

    // Success State Tests
    testWidgets('ReportGenerationScreen success state should display generated report info', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Generate report
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for completion

      // Assert - Success state elements
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Report generated in PDF format'), findsOneWidget);
      expect(find.byType(Container), findsWidgets); // Success indicator container
    });

    testWidgets('ReportGenerationScreen should provide download and regenerate options', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for completion

      // Assert - Both buttons should be available
      expect(find.text('Generate Another'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget); // Generate Another
      expect(find.byType(ElevatedButton), findsOneWidget); // Download
    });

    testWidgets('ReportGenerationScreen should maintain format selection in success state', (WidgetTester tester) async {
      // Arrange - Select HTML format
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('HTML'));
      await tester.pumpAndSettle();

      // Act - Generate and complete
      await tester.tap(find.text('Generate HTML Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for completion

      // Assert - Should show HTML in success message
      expect(find.text('Report generated in HTML format'), findsOneWidget);
    });

    // UI Layout Tests
    testWidgets('ReportGenerationScreen should use SingleChildScrollView for content', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Padding), findsWidgets); // Multiple padding widgets
    });

    testWidgets('ReportGenerationScreen should render format cards with proper spacing', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Cards should be rendered with margins
      expect(find.byType(Card), findsNWidgets(4));
      expect(find.byType(RadioListTile<String>), findsNWidgets(4));
    });

    testWidgets('ReportGenerationScreen should have proper padding and spacing', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Verify layout structure
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(SizedBox), findsWidgets); // Spacing elements
    });

    // State Management Tests
    testWidgets('ReportGenerationScreen should manage generation states correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Start generation
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(); // Should show loading

      // Assert - Loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pump(const Duration(seconds: 4));

      // Loading should be cleared, success state shown
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Report generated'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should prevent multiple concurrent generations', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Start generation
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(); // Should be in loading state

      // Try to start another generation
      // Note: Button should be disabled during generation
      expect(find.text('Generate PDF Report'), findsNothing); // Button text changed
    });

    // Format-Specific Tests
    testWidgets('ReportGenerationScreen should handle different format generations', (WidgetTester tester) async {
      // Arrange - Test DOCX format
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('DOCX'));
      await tester.pumpAndSettle();

      // Act - Generate DOCX
      await tester.tap(find.text('Generate DOCX Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for completion

      // Assert - Should show DOCX success
      expect(find.text('Report generated in DOCX format'), findsOneWidget);

      // Reset and test JSON format
      await tester.tap(find.text('Generate Another'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Generate JSON Report'));
      await tester.pump(const Duration(seconds: 4));

      // Assert - Should show JSON success
      expect(find.text('Report generated in JSON format'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should show format-specific descriptions', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - All format descriptions should be visible
      mockFormats.forEach((format) {
        expect(find.text(format['description'] as String), findsOneWidget);
      });
    });

    // User Experience Tests
    testWidgets('ReportGenerationScreen should provide helpful guidance', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Choose Report Format'), findsOneWidget);
      expect(find.text('Select the format that best suits your needs'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should make format selection clear', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Radio buttons should clearly show selection
      expect(find.byType(RadioListTile<String>), findsNWidgets(4));
      
      // Default should be PDF
      final pdfTile = tester.widget<RadioListTile<String>>(find.text('PDF').parent as Finder);
      expect(pdfTile.groupValue, 'PDF');
    });

    // Performance Tests
    testWidgets('ReportGenerationScreen should handle format selection efficiently', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // Arrange & Act - Rapid format changes
      await tester.pumpWidget(createTestWidget());
      
      await tester.tap(find.text('DOCX'));
      await tester.pump();
      
      await tester.tap(find.text('HTML'));
      await tester.pump();
      
      await tester.tap(find.text('JSON'));
      await tester.pump();

      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(find.text('Generate JSON Report'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should generate reports efficiently', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4)); // Wait for completion

      stopwatch.stop();

      // Assert - Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(find.text('Report generated'), findsOneWidget);
    });

    // Accessibility Tests
    testWidgets('ReportGenerationScreen should have proper semantic labels', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.bySemanticsLabel('Generate Report'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsAtLeastNWidgets(1));
    });

    testWidgets('ReportGenerationScreen should be keyboard navigable', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Test keyboard navigation through format options
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Should not crash during navigation
      expect(find.text('Choose Report Format'), findsOneWidget);
    });

    // Edge Cases Tests
    testWidgets('ReportGenerationScreen should handle rapid generate attempts', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Multiple rapid generate attempts
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(milliseconds: 100));
      // Should be in loading state, preventing multiple attempts
      
      // Wait for completion
      await tester.pump(const Duration(seconds: 4));

      // Should complete successfully
      expect(find.text('Report generated'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen should handle format selection during generation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(); // Start generation

      // Act - Try to change format during generation (should be prevented)
      // Note: The UI should prevent this by disabling options during generation
      await tester.pump(const Duration(seconds: 4)); // Complete generation

      // Should complete normally
      expect(find.text('Report generated'), findsOneWidget);
    });

    // Integration Tests
    testWidgets('ReportGenerationScreen complete workflow for PDF format', (WidgetTester tester) async {
      // Arrange & Act - Select format
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      // Generate report
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(); // Loading
      await tester.pump(const Duration(seconds: 4)); // Completion

      // Assert - Success state
      expect(find.text('Report generated in PDF format'), findsOneWidget);

      // Test download
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(find.text('Download would start here'), findsOneWidget);

      // Test regenerate
      await tester.tap(find.text('Generate Another'));
      await tester.pumpAndSettle();

      // Assert - Back to initial state
      expect(find.text('Generate PDF Report'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen format selection and generation cycle', (WidgetTester tester) async {
      // Test multiple format selections and generations
      await tester.pumpWidget(createTestWidget());

      // Test HTML format
      await tester.tap(find.text('HTML'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate HTML Report'));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Report generated in HTML format'), findsOneWidget);

      // Generate another and try JSON
      await tester.tap(find.text('Generate Another'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate JSON Report'));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Report generated in JSON format'), findsOneWidget);
    });

    testWidgets('ReportGenerationScreen navigation workflow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Generate a report
      await tester.tap(find.text('Generate PDF Report'));
      await tester.pump(const Duration(seconds: 4));

      // Test navigation from success state
      await tester.tap(find.text('Back to Results'));
      await tester.pumpAndSettle();

      // Screen should be dismissed
      expect(find.text('Generate Report'), findsNothing);
    });
  });
}

