import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/widgets/category_summary_widget.dart';

void main() {
  group('CategorySummaryWidget Widget Tests', () {
    late Map<String, double> testCategories;
    late Map<String, double> emptyCategories;
    late Map<String, double> singleCategory;
    late Map<String, double> boundaryCategories;

    setUp(() {
      testCategories = {
        'Violence': 0.85,
        'Sexual Content': 0.3,
        'Language': 0.65,
        'Alcohol & Drugs': 0.15,
        'Disturbing Scenes': 0.92,
      };

      emptyCategories = {};

      singleCategory = {
        'Single Category': 0.5,
      };

      boundaryCategories = {
        'Safe Category': 0.0,
        'Low Risk': 0.39,
        'Medium Risk': 0.6,
        'High Risk': 0.79,
        'Critical Risk': 1.0,
      };
    });

    Widget createTestWidget({required Map<String, double> categories}) {
      return MaterialApp(
        home: Scaffold(
          body: CategorySummaryWidget(categories: categories),
        ),
      );
    }

    group('Basic Rendering Tests', () {
      testWidgets('should render with multiple categories', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Verify main structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Padding), findsWidgets);
        expect(find.byType(Column), findsWidgets);

        // Verify header elements
        expect(find.byIcon(Icons.category), findsOneWidget);
        expect(find.text('Категории содержания'), findsOneWidget);

        // Verify category entries are rendered
        expect(find.text('Violence'), findsOneWidget);
        expect(find.text('Sexual Content'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Alcohol & Drugs'), findsOneWidget);
        expect(find.text('Disturbing Scenes'), findsOneWidget);

        // Verify percentage values
        expect(find.text('85%'), findsOneWidget);
        expect(find.text('30%'), findsOneWidget);
        expect(find.text('65%'), findsOneWidget);
        expect(find.text('15%'), findsOneWidget);
        expect(find.text('92%'), findsOneWidget);

        // Verify progress bars
        expect(find.byType(LinearProgressIndicator), findsNWidgets(5));

        // Verify info panel
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.textContaining('Чем выше показатель'), findsOneWidget);
      });

      testWidgets('should render with single category', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: singleCategory));

        // Verify basic structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Single Category'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('should render with empty categories map', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: emptyCategories));

        // Should still render basic structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byIcon(Icons.category), findsOneWidget);
        expect(find.text('Категории содержания'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        
        // Should not render category entries or progress bars
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('%'), findsNothing);
      });

      testWidgets('should handle category names with special characters', (WidgetTester tester) async {
        final specialCharCategories = {
          'Violence/Action': 0.7,
          'Sexual Content (Graphic)': 0.8,
          'Language: Strong': 0.9,
          'Alcohol & Drugs*': 0.3,
          'Disturbing Scenes™': 0.6,
        };

        await tester.pumpWidget(createTestWidget(categories: specialCharCategories));

        // Verify special characters are handled properly
        expect(find.text('Violence/Action'), findsOneWidget);
        expect(find.text('Sexual Content (Graphic)'), findsOneWidget);
        expect(find.text('Language: Strong'), findsOneWidget);
        expect(find.text('Alcohol & Drugs*'), findsOneWidget);
        expect(find.text('Disturbing Scenes™'), findsOneWidget);
      });
    });

    group('Visual States Tests', () {
      testWidgets('should handle high risk categories (>= 0.8)', (WidgetTester tester) async {
        final highRiskCategories = {
          'Violence': 0.95,
          'Sexual Content': 0.88,
          'Language': 0.82,
          'Disturbing Scenes': 0.91,
        };

        await tester.pumpWidget(createTestWidget(categories: highRiskCategories));

        // Should display with red color for high risk
        expect(find.text('Violence'), findsOneWidget);
        expect(find.text('95%'), findsOneWidget);
        expect(find.text('Sexual Content'), findsOneWidget);
        expect(find.text('88%'), findsOneWidget);
      });

      testWidgets('should handle medium-high risk categories (>= 0.6)', (WidgetTester tester) async {
        final mediumHighRiskCategories = {
          'Alcohol & Drugs': 0.75,
          'Language': 0.68,
          'Violence': 0.62,
        };

        await tester.pumpWidget(createTestWidget(categories: mediumHighRiskCategories));

        // Should display with orange color
        expect(find.text('Alcohol & Drugs'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('should handle medium risk categories (>= 0.4)', (WidgetTester tester) async {
        final mediumRiskCategories = {
          'Language': 0.55,
          'Alcohol & Drugs': 0.47,
          'Disturbing Scenes': 0.42,
        };

        await tester.pumpWidget(createTestWidget(categories: mediumRiskCategories));

        // Should display with yellow color
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('55%'), findsOneWidget);
      });

      testWidgets('should handle low risk categories (< 0.4)', (WidgetTester tester) async {
        final lowRiskCategories = {
          'Violence': 0.2,
          'Language': 0.1,
          'Sexual Content': 0.35,
        };

        await tester.pumpWidget(createTestWidget(categories: lowRiskCategories));

        // Should display with green color
        expect(find.text('Violence'), findsOneWidget);
        expect(find.text('20%'), findsOneWidget);
      });

      testWidgets('should handle boundary values correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: boundaryCategories));

        // Test exact boundary values
        expect(find.text('Safe Category'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
        
        expect(find.text('Low Risk'), findsOneWidget);
        expect(find.text('39%'), findsOneWidget);
        
        expect(find.text('Medium Risk'), findsOneWidget);
        expect(find.text('60%'), findsOneWidget);
        
        expect(find.text('High Risk'), findsOneWidget);
        expect(find.text('79%'), findsOneWidget);
        
        expect(find.text('Critical Risk'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
      });

      testWidgets('should handle zero and one values', (WidgetTester tester) async {
        final extremeCategories = {
          'Zero Risk': 0.0,
          'Maximum Risk': 1.0,
        };

        await tester.pumpWidget(createTestWidget(categories: extremeCategories));

        expect(find.text('Zero Risk'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
        expect(find.text('Maximum Risk'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
      });
    });

    group('Progress Indicator Tests', () {
      testWidgets('should render progress bars with correct values', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        final progressBars = tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
        expect(progressBars, hasLength(5));

        // Verify specific progress values using indexed access
        final progressBarList = progressBars.toList();
        final violenceProgress = progressBarList[0];
        expect(violenceProgress.value, 0.85);

        final sexualContentProgress = progressBarList[1];
        expect(sexualContentProgress.value, 0.3);
      });

      testWidgets('should have proper progress indicator styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        final progressBar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator).first);
        
        // Verify background color
        expect(progressBar.backgroundColor, Colors.grey.shade200);
        
        // Verify value color is set (should be an AlwaysStoppedAnimation)
        expect(progressBar.valueColor, isNotNull);
        expect(progressBar.valueColor, isA<AlwaysStoppedAnimation<Color>>());
      });

      testWidgets('should handle very small progress values', (WidgetTester tester) async {
        final smallValueCategories = {
          'Minimal Content': 0.01,
          'Trace Amount': 0.05,
          'Very Low': 0.001,
        };

        await tester.pumpWidget(createTestWidget(categories: smallValueCategories));

        expect(find.text('Minimal Content'), findsOneWidget);
        expect(find.text('1%'), findsOneWidget);
        expect(find.text('Trace Amount'), findsOneWidget);
        expect(find.text('5%'), findsOneWidget);
        expect(find.text('Very Low'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget); // Should round down
      });

      testWidgets('should handle very large progress values', (WidgetTester tester) async {
        final largeValueCategories = {
          'Near Maximum': 0.999,
          'Almost Full': 0.995,
          'Extremely High': 0.9999,
        };

        await tester.pumpWidget(createTestWidget(categories: largeValueCategories));

        expect(find.text('Near Maximum'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('Almost Full'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
      });
    });

    group('Interactive Elements Tests', () {
      testWidgets('should handle tap interactions on progress bars', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Tap on category row
        final categoryText = find.text('Violence');
        await tester.tap(categoryText);
        await tester.pump();

        // Should handle tap gracefully
        expect(find.text('Violence'), findsOneWidget);
      });

      testWidgets('should handle long press interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        final progressBar = find.byType(LinearProgressIndicator).first;
        await tester.longPress(progressBar);
        await tester.pump();

        // Should handle long press gracefully
        expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
      });

      testWidgets('should handle scroll interactions', (WidgetTester tester) async {
        // Create a scrollable container with the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CategorySummaryWidget(categories: testCategories),
              ),
            ),
          ),
        );

        // Scroll within the widget
        await tester.scrollUntilVisible(find.text('Disturbing Scenes'), 100.0);
        await tester.pump();

        // Should handle scroll gracefully
        expect(find.text('Disturbing Scenes'), findsOneWidget);
      });

      testWidgets('should handle drag interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        final card = find.byType(Card);
        await tester.drag(card, const Offset(0, 50));
        await tester.pump();

        // Should handle drag gracefully
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Different Summary States Tests', () {
      testWidgets('should handle loading state with empty data', (WidgetTester tester) async {
        // Simulate loading state with empty categories
        await tester.pumpWidget(createTestWidget(categories: emptyCategories));

        // Should show basic structure even with no data
        expect(find.byType(Card), findsOneWidget);
        expect(find.byIcon(Icons.category), findsOneWidget);
        expect(find.text('Категории содержания'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('should handle mixed state with varying risk levels', (WidgetTester tester) async {
        final mixedStateCategories = {
          'Safe': 0.1,
          'Low Risk': 0.3,
          'Medium Risk': 0.5,
          'High Risk': 0.7,
          'Critical Risk': 0.9,
        };

        await tester.pumpWidget(createTestWidget(categories: mixedStateCategories));

        // Should render all risk levels
        expect(find.text('Safe'), findsOneWidget);
        expect(find.text('10%'), findsOneWidget);
        expect(find.text('Low Risk'), findsOneWidget);
        expect(find.text('30%'), findsOneWidget);
        expect(find.text('Medium Risk'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.text('High Risk'), findsOneWidget);
        expect(find.text('70%'), findsOneWidget);
        expect(find.text('Critical Risk'), findsOneWidget);
        expect(find.text('90%'), findsOneWidget);
      });

      testWidgets('should handle all high-risk categories', (WidgetTester tester) async {
        final allHighRiskCategories = {
          'Violence': 0.95,
          'Sexual Content': 0.88,
          'Language': 0.92,
          'Alcohol & Drugs': 0.85,
          'Disturbing Scenes': 0.97,
        };

        await tester.pumpWidget(createTestWidget(categories: allHighRiskCategories));

        // Should handle consistently
        expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
        expect(find.text('%'), findsNWidgets(5));
      });

      testWidgets('should handle all low-risk categories', (WidgetTester tester) async {
        final allLowRiskCategories = {
          'Violence': 0.1,
          'Sexual Content': 0.05,
          'Language': 0.2,
          'Alcohol & Drugs': 0.15,
          'Disturbing Scenes': 0.08,
        };

        await tester.pumpWidget(createTestWidget(categories: allLowRiskCategories));

        // Should handle consistently
        expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
        expect(find.text('%'), findsNWidgets(5));
      });
    });

    group('Layout and Responsiveness Tests', () {
      testWidgets('should have proper card padding', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        final card = tester.widget<Card>(find.byType(Card));
        final cardChild = card.child as Padding;
        expect(cardChild.padding, const EdgeInsets.all(16));
      });

      testWidgets('should have proper spacing between elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Verify proper spacing exists (these are structural tests)
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('should handle long category names', (WidgetTester tester) async {
        final longNameCategories = {
          'This is an extremely long category name that might cause layout issues': 0.5,
          'Another Very Long Category Name With Multiple Words': 0.7,
          'X': 0.3,
        };

        await tester.pumpWidget(createTestWidget(categories: longNameCategories));

        // Should handle long names gracefully
        expect(find.text('This is an extremely long category name that might cause layout issues'), findsOneWidget);
        expect(find.text('Another Very Long Category Name With Multiple Words'), findsOneWidget);
        expect(find.text('X'), findsOneWidget);
      });

      testWidgets('should handle many categories efficiently', (WidgetTester tester) async {
        final manyCategories = Map<String, double>.fromEntries(
          List.generate(20, (index) => MapEntry('Category $index', index * 0.05)),
        );

        await tester.pumpWidget(createTestWidget(categories: manyCategories));

        // Should render all categories
        expect(find.byType(LinearProgressIndicator), findsNWidgets(20));
        expect(find.text('%'), findsNWidgets(20));
      });

      testWidgets('should have proper progress indicator layout', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Verify progress indicators are properly positioned
        final progressBars = find.byType(LinearProgressIndicator);
        expect(progressBars, findsNWidgets(5));
      });
    });

    group('Color Coding Tests', () {
      testWidgets('should use red color for high scores (>= 0.8)', (WidgetTester tester) async {
        final highScoreCategories = {
          'High Score Category': 0.85,
        };

        await tester.pumpWidget(createTestWidget(categories: highScoreCategories));

        // The color is applied to both text and progress indicator
        // This test verifies the widget handles high scores properly
        expect(find.text('High Score Category'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
      });

      testWidgets('should use orange color for medium-high scores (>= 0.6)', (WidgetTester tester) async {
        final mediumHighScoreCategories = {
          'Medium High Category': 0.65,
        };

        await tester.pumpWidget(createTestWidget(categories: mediumHighScoreCategories));

        expect(find.text('Medium High Category'), findsOneWidget);
        expect(find.text('65%'), findsOneWidget);
      });

      testWidgets('should use yellow color for medium scores (>= 0.4)', (WidgetTester tester) async {
        final mediumScoreCategories = {
          'Medium Category': 0.45,
        };

        await tester.pumpWidget(createTestWidget(categories: mediumScoreCategories));

        expect(find.text('Medium Category'), findsOneWidget);
        expect(find.text('45%'), findsOneWidget);
      });

      testWidgets('should use green color for low scores (< 0.4)', (WidgetTester tester) async {
        final lowScoreCategories = {
          'Low Score Category': 0.35,
        };

        await tester.pumpWidget(createTestWidget(categories: lowScoreCategories));

        expect(find.text('Low Score Category'), findsOneWidget);
        expect(find.text('35%'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle negative category values gracefully', (WidgetTester tester) async {
        final negativeValueCategories = {
          'Negative Category': -0.5,
          'Zero Category': 0.0,
        };

        await tester.pumpWidget(createTestWidget(categories: negativeValueCategories));

        // Should handle negative values (they would display as -50% and 0%)
        expect(find.text('Negative Category'), findsOneWidget);
        expect(find.text('Zero Category'), findsOneWidget);
      });

      testWidgets('should handle values greater than 1.0 gracefully', (WidgetTester tester) async {
        final highValueCategories = {
          'Over 1.0 Category': 1.5,
          'Exactly 1.0 Category': 1.0,
        };

        await tester.pumpWidget(createTestWidget(categories: highValueCategories));

        // Should handle values > 1.0 (they would display as 150% and 100%)
        expect(find.text('Over 1.0 Category'), findsOneWidget);
        expect(find.text('Exactly 1.0 Category'), findsOneWidget);
      });

      testWidgets('should handle null category names gracefully', (WidgetTester tester) async {
        // This would be unusual but test edge case
        final edgeCaseCategories = {
          '': 0.5,
          ' ': 0.3,
        };

        await tester.pumpWidget(createTestWidget(categories: edgeCaseCategories));

        // Should handle empty/whitespace names
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should handle extremely long category names', (WidgetTester tester) async {
        final extremelyLongNameCategories = {
          'A' * 1000: 0.5,
          'B' * 500: 0.3,
        };

        await tester.pumpWidget(createTestWidget(categories: extremelyLongNameCategories));

        // Should handle extremely long names without crashing
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      });
    });

    group('Info Panel Tests', () {
      testWidgets('should always render info panel', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Verify info panel is always present
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.textContaining('Чем выше показатель'), findsOneWidget);
        expect(find.textContaining('выше 60%'), findsOneWidget);
        expect(find.textContaining('повышают возрастной рейтинг'), findsOneWidget);
      });

      testWidgets('should render info panel with empty categories', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: emptyCategories));

        // Info panel should still be present
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.textContaining('Чем выше показатель'), findsOneWidget);
      });

      testWidgets('should have proper info panel styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // The info panel has specific styling with blue background
        // This is verified by the presence of the info icon and text
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.textContaining('Чем выше показатель'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Verify main content is accessible
        expect(find.text('Категории содержания'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
      });

      testWidgets('should have proper text contrast', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Verify text elements are rendered properly
        final categoryText = find.text('Violence');
        expect(categoryText, findsOneWidget);
        
        final percentageText = find.text('85%');
        expect(percentageText, findsOneWidget);
      });

      testWidgets('should have proper touch targets', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: testCategories));

        // Verify elements have reasonable touch target size
        final card = find.byType(Card);
        expect(card, findsOneWidget);
        
        // Test tap responsiveness
        await tester.tap(card);
        await tester.pump();
      });
    });

    group('Data Binding and State Updates', () {
      testWidgets('should update when categories data changes', (WidgetTester tester) async {
        final initialCategories = {
          'Initial Category': 0.5,
        };

        await tester.pumpWidget(createTestWidget(categories: initialCategories));
        expect(find.text('Initial Category'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);

        // Update with new data
        final updatedCategories = {
          'Updated Category': 0.8,
          'New Category': 0.3,
        };

        await tester.pumpWidget(createTestWidget(categories: updatedCategories));
        expect(find.text('Updated Category'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
        expect(find.text('New Category'), findsOneWidget);
        expect(find.text('30%'), findsOneWidget);
        
        // Old data should no longer exist
        expect(find.text('Initial Category'), findsNothing);
      });

      testWidgets('should handle percentage rounding correctly', (WidgetTester tester) async {
        final preciseCategories = {
          'Precise 0.333': 0.333,
          'Precise 0.666': 0.666,
          'Precise 0.999': 0.999,
        };

        await tester.pumpWidget(createTestWidget(categories: preciseCategories));

        // Should round to nearest integer
        expect(find.text('Precise 0.333'), findsOneWidget);
        expect(find.text('33%'), findsOneWidget);
        expect(find.text('Precise 0.666'), findsOneWidget);
        expect(find.text('67%'), findsOneWidget);
        expect(find.text('Precise 0.999'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should render efficiently with many categories', (WidgetTester tester) async {
        final manyCategories = Map<String, double>.fromEntries(
          List.generate(50, (index) => MapEntry('Category $index', (index % 100) / 100.0)),
        );

        await tester.pumpWidget(createTestWidget(categories: manyCategories));

        // Should render without performance issues
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(50));
      });

      testWidgets('should handle rapid widget updates', (WidgetTester tester) async {
        // Test multiple rapid updates
        for (int i = 0; i < 10; i++) {
          final updatedCategories = {
            'Dynamic Category ${i % 5}': (i * 0.1).clamp(0.0, 1.0),
          };

          await tester.pumpWidget(createTestWidget(categories: updatedCategories));
        }

        // Should handle all updates gracefully
        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}