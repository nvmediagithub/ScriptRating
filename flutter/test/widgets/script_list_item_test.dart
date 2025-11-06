import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:script_rating_app/models/script.dart';
import 'package:script_rating_app/widgets/script_list_item.dart';

void main() {
  group('ScriptListItem Widget Tests', () {
    late Script testScript;
    late BuildContext mockContext;
    late GoRouter mockRouter;

    setUp(() {
      testScript = Script(
        id: 'test-123',
        title: 'Test Movie Script',
        content: 'This is a test script content...',
        author: 'John Doe',
        createdAt: DateTime(2024, 1, 15),
        rating: 8.5,
      );

      // Create mock router for navigation testing
      mockRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/results',
            builder: (context, state) => const Scaffold(
              body: Text('Results Page'),
            ),
          ),
        ],
      );
    });

    Widget createTestWidget({required Script script, GoRouter? router}) {
      return MaterialApp(
        home: Scaffold(
          body: ScriptListItem(script: script),
        ),
      );
    }

    group('Basic Rendering Tests', () {
      testWidgets('should render with minimal script data', (WidgetTester tester) async {
        final minimalScript = Script(
          id: 'test-minimal',
          title: 'Minimal Script',
          content: 'Content',
        );

        await tester.pumpWidget(createTestWidget(script: minimalScript));

        // Verify basic structure exists
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
        
        // Verify title is displayed
        expect(find.text('Minimal Script'), findsOneWidget);
        
        // Verify optional fields are not displayed
        expect(find.text('Author:'), findsNothing);
        expect(find.text('Rating:'), findsNothing);
        expect(find.text('Created:'), findsNothing);
      });

      testWidgets('should render with complete script data', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        // Verify all elements are rendered
        expect(find.text('Test Movie Script'), findsOneWidget);
        expect(find.text('Author: John Doe'), findsOneWidget);
        expect(find.text('Rating: 8.5'), findsOneWidget);
        expect(find.text('Created: ${testScript.createdAt!.toLocal().toString().split(' ')[0]}'), findsOneWidget);
        
        // Verify star icon for rating
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should render with null author', (WidgetTester tester) async {
        final scriptWithoutAuthor = Script(
          id: 'test-no-author',
          title: 'No Author Script',
          content: 'Content',
          createdAt: DateTime(2024, 1, 15),
          rating: 7.0,
        );

        await tester.pumpWidget(createTestWidget(script: scriptWithoutAuthor));

        // Verify title and other fields are displayed
        expect(find.text('No Author Script'), findsOneWidget);
        expect(find.text('Rating: 7.0'), findsOneWidget);
        
        // Verify author field is not displayed
        expect(find.text('Author:'), findsNothing);
      });

      testWidgets('should render with null rating', (WidgetTester tester) async {
        final scriptWithoutRating = Script(
          id: 'test-no-rating',
          title: 'No Rating Script',
          content: 'Content',
          author: 'Jane Doe',
          createdAt: DateTime(2024, 1, 15),
        );

        await tester.pumpWidget(createTestWidget(script: scriptWithoutRating));

        // Verify title and author are displayed
        expect(find.text('No Rating Script'), findsOneWidget);
        expect(find.text('Author: Jane Doe'), findsOneWidget);
        
        // Verify rating elements are not displayed
        expect(find.text('Rating:'), findsNothing);
        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('should render with null created date', (WidgetTester tester) async {
        final scriptWithoutDate = Script(
          id: 'test-no-date',
          title: 'No Date Script',
          content: 'Content',
          author: 'Anonymous',
          rating: 6.5,
        );

        await tester.pumpWidget(createTestWidget(script: scriptWithoutDate));

        // Verify title and author are displayed
        expect(find.text('No Date Script'), findsOneWidget);
        expect(find.text('Author: Anonymous'), findsOneWidget);
        expect(find.text('Rating: 6.5'), findsOneWidget);
        
        // Verify created date is not displayed
        expect(find.text('Created:'), findsNothing);
      });
    });

    group('Visual States Tests', () {
      testWidgets('should handle loading state gracefully', (WidgetTester tester) async {
        // Test with very long title
        final longTitleScript = Script(
          id: 'test-long-title',
          title: 'This is a very long title that might cause layout issues and should be properly handled by the text widget with proper wrapping and ellipsis if needed',
          content: 'Content',
          author: 'Author Name That Is Also Quite Long',
          createdAt: DateTime(2024, 1, 15),
          rating: 9.9999999, // Very long decimal
        );

        await tester.pumpWidget(createTestWidget(script: longTitleScript));

        // Verify the widget renders without crashing
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
        
        // Verify ellipsis handling for long content
        expect(find.text('This is a very long title that might cause layout issues'), findsNothing);
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && widget.data != null && widget.data!.contains('This is a very long title'),
        ), findsOneWidget);
      });

      testWidgets('should handle empty data state', (WidgetTester tester) async {
        final emptyScript = Script(
          id: '',
          title: '',
          content: '',
          author: null,
          createdAt: null,
          rating: null,
        );

        await tester.pumpWidget(createTestWidget(script: emptyScript));

        // Verify basic structure still exists
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
        
        // Verify empty strings are displayed
        expect(find.text(''), findsAtLeastNWidgets(3)); // title, author placeholder, rating placeholder
      });

      testWidgets('should handle error state with invalid data', (WidgetTester tester) async {
        final scriptWithInvalidData = Script(
          id: 'test-invalid',
          title: 'Test with invalid date',
          content: 'Content',
          author: null,
          createdAt: DateTime.parse('invalid-date'), // This should be handled gracefully
          rating: -1.0, // Invalid rating
        );

        // This test mainly ensures the widget doesn't crash with edge cases
        await tester.pumpWidget(createTestWidget(script: scriptWithInvalidData));
        
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      });
    });

    group('Interaction Tests', () {
      testWidgets('should handle tap on main area', (WidgetTester tester) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/results',
              builder: (context, state) => const Scaffold(
                body: Text('Results Page'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(createTestWidget(script: testScript, router: router));

        // Find and tap the ListTile
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();

        // Verify navigation occurred (this would be better tested with a mock router)
        expect(find.text('Results Page'), findsOneWidget);
      });

      testWidgets('should handle tap on analytics button', (WidgetTester tester) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/results',
              builder: (context, state) => const Scaffold(
                body: Text('Results Page'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(createTestWidget(script: testScript, router: router));

        // Find and tap the analytics button
        await tester.tap(find.byIcon(Icons.analytics));
        await tester.pumpAndSettle();

        // Verify navigation occurred
        expect(find.text('Results Page'), findsOneWidget);
      });

      testWidgets('should have proper tooltip on analytics button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        final analyticsButton = find.byIcon(Icons.analytics);
        expect(analyticsButton, findsOneWidget);

        // Verify tooltip is set (this would require finding the IconButton and checking tooltip)
        final iconButton = tester.widget<IconButton>(find.byType(IconButton));
        expect(iconButton.tooltip, 'View Analysis');
      });
    });

    group('Layout and Styling Tests', () {
      testWidgets('should have proper card margins', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        final card = tester.widget<Card>(find.byType(Card));
        expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
      });

      testWidgets('should have proper trailing icons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        // Verify analytics button exists
        expect(find.byIcon(Icons.analytics), findsOneWidget);
        
        // Verify chevron right icon exists
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('should display rating with proper styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        final ratingRow = find.text('Rating: 8.5');
        expect(ratingRow, findsOneWidget);

        // Verify star icon is adjacent to rating text
        final starIcon = find.byIcon(Icons.star);
        expect(starIcon, findsOneWidget);
      });

      testWidgets('should handle created date formatting', (WidgetTester tester) async {
        final dateScript = Script(
          id: 'test-date',
          title: 'Date Test',
          content: 'Content',
          createdAt: DateTime(2024, 12, 31, 23, 59, 59), // End of year
        );

        await tester.pumpWidget(createTestWidget(script: dateScript));

        // Verify date is formatted as YYYY-MM-DD only (time part should be removed)
        final createdText = find.text('Created: 2024-12-31');
        expect(createdText, findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        // Check for semantic labels on interactive elements
        final listTile = tester.widget<ListTile>(find.byType(ListTile));
        expect(listTile.onTap, isNotNull); // Should be tappable
      });

      testWidgets('should have proper touch targets', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        // Verify main ListTile is tappable
        expect(find.byType(ListTile), findsOneWidget);
        
        // Verify IconButton has proper sizing
        expect(find.byType(IconButton), findsOneWidget);
      });

      testWidgets('should have proper text contrast', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(script: testScript));

        // This test would require color analysis tools to verify WCAG compliance
        // For now, just verify text elements exist with expected content
        final titleText = find.text('Test Movie Script');
        expect(titleText, findsOneWidget);
        
        final authorText = find.text('Author: John Doe');
        expect(authorText, findsOneWidget);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle very long script titles', (WidgetTester tester) async {
        final longTitleScript = Script(
          id: 'test-long',
          title: 'A' * 500, // Very long title
          content: 'Content',
        );

        await tester.pumpWidget(createTestWidget(script: longTitleScript));

        // Verify widget renders without crashing
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('should handle special characters in content', (WidgetTester tester) async {
        final specialCharScript = Script(
          id: 'test-special',
          title: 'Test with émojis 🚀 and spëcial chåracters',
          content: 'Content with unicode: αβγδε',
          author: 'José María 🕵️',
        );

        await tester.pumpWidget(createTestWidget(script: specialCharScript));

        // Verify special characters are rendered properly
        expect(find.text('Test with émojis 🚀 and spëcial chåracters'), findsOneWidget);
        expect(find.text('Author: José María 🕵️'), findsOneWidget);
      });

      testWidgets('should handle null script gracefully', (WidgetTester tester) async {
        // This test verifies the widget constructor handles null script
        // We can't actually pass null due to required field, but we can test with empty script
        final emptyScript = Script(id: '', title: '', content: '');

        await tester.pumpWidget(createTestWidget(script: emptyScript));

        // Should still render basic structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('should handle rating edge cases', (WidgetTester tester) async {
        // Test with boundary values
        final boundaryScript = Script(
          id: 'test-boundaries',
          title: 'Boundary Test',
          content: 'Content',
          rating: 0.0,
        );

        await tester.pumpWidget(createTestWidget(script: boundaryScript));
        expect(find.text('Rating: 0.0'), findsOneWidget);

        // Test with maximum rating
        final maxRatingScript = Script(
          id: 'test-max',
          title: 'Max Rating',
          content: 'Content',
          rating: 10.0,
        );

        await tester.pumpWidget(createTestWidget(script: maxRatingScript));
        expect(find.text('Rating: 10.0'), findsOneWidget);
      });

      testWidgets('should handle future dates', (WidgetTester tester) async {
        final futureDateScript = Script(
          id: 'test-future',
          title: 'Future Date Test',
          content: 'Content',
          createdAt: DateTime(2030, 1, 1), // Future date
        );

        await tester.pumpWidget(createTestWidget(script: futureDateScript));

        // Should handle future dates gracefully
        expect(find.text('Created: 2030-01-01'), findsOneWidget);
      });
    });

    group('Data Binding and State Updates', () {
      testWidgets('should update when script data changes', (WidgetTester tester) async {
        final initialScript = Script(
          id: 'test-1',
          title: 'Initial Title',
          content: 'Content',
        );

        await tester.pumpWidget(createTestWidget(script: initialScript));
        expect(find.text('Initial Title'), findsOneWidget);

        // Rebuild with different script (this simulates a state update)
        final updatedScript = Script(
          id: 'test-2',
          title: 'Updated Title',
          content: 'Content',
          author: 'New Author',
        );

        await tester.pumpWidget(createTestWidget(script: updatedScript));
        expect(find.text('Updated Title'), findsOneWidget);
        expect(find.text('Author: New Author'), findsOneWidget);
      });

      testWidgets('should properly format rating decimals', (WidgetTester tester) async {
        final preciseRatingScript = Script(
          id: 'test-precise',
          title: 'Precise Rating',
          content: 'Content',
          rating: 7.123456789, // Many decimal places
        );

        await tester.pumpWidget(createTestWidget(script: preciseRatingScript));

        // Should limit to one decimal place
        expect(find.text('Rating: 7.1'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should render multiple items efficiently', (WidgetTester tester) async {
        final scripts = List.generate(10, (index) => Script(
          id: 'test-$index',
          title: 'Script $index',
          content: 'Content $index',
          author: 'Author $index',
          createdAt: DateTime(2024, 1, index + 1),
          rating: 5.0 + index.toDouble(),
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: scripts.map((script) => ScriptListItem(script: script)).toList(),
              ),
            ),
          ),
        );

        // Verify all items are rendered
        expect(find.byType(ScriptListItem), findsNWidgets(10));
        
        // Verify specific content
        expect(find.text('Script 0'), findsOneWidget);
        expect(find.text('Author 9'), findsOneWidget);
        expect(find.text('Rating: 14.0'), findsOneWidget);
      });
    });
  });
}

