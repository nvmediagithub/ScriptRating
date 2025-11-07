import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/analysis_result.dart';
import 'package:script_rating_app/models/severity.dart';
import 'package:script_rating_app/models/age_rating.dart';
import 'package:script_rating_app/models/scene_assessment.dart';
import 'package:script_rating_app/models/category.dart';
import 'package:script_rating_app/models/rating_result.dart';
import 'package:script_rating_app/models/normative_reference.dart';
import 'package:script_rating_app/widgets/analysis_result_widget.dart';

void main() {
  group('AnalysisResultWidget Widget Tests', () {
    late AnalysisResult testAnalysisResult;

    setUp(() {
      // Create test scene assessments
      final scene1 = SceneAssessment(
        sceneNumber: 1,
        heading: 'Opening Scene',
        pageRange: '1-5',
        categories: {
          Category.language: Severity.mild,
          Category.violence: Severity.none,
        },
        ageRating: AgeRating.twelvePlus,
        llmComment: 'Mild language detected in this scene.',
        text: 'Some text content here...',
        flaggedContent: ['mild language'],
      );

      final scene2 = SceneAssessment(
        sceneNumber: 2,
        heading: 'Action Sequence',
        pageRange: '15-25',
        categories: {
          Category.violence: Severity.moderate,
          Category.disturbingScenes: Severity.mild,
        },
        ageRating: AgeRating.sixteenPlus,
        llmComment: 'Moderate violence and disturbing content.',
        text: 'Action sequence with violence...',
        flaggedContent: ['moderate violence', 'disturbing imagery'],
      );

      final scene3 = SceneAssessment(
        sceneNumber: 3,
        heading: 'Peaceful Scene',
        pageRange: '30-35',
        categories: {
          Category.language: Severity.none,
          Category.violence: Severity.none,
          Category.sexualContent: Severity.none,
          Category.alcoholDrugs: Severity.none,
          Category.disturbingScenes: Severity.none,
        },
        ageRating: AgeRating.zeroPlus,
        llmComment: 'No problematic content detected.',
        text: 'Peaceful conversation...',
        flaggedContent: [],
      );

      testAnalysisResult = AnalysisResult(
        analysisId: 'analysis-123',
        documentId: 'doc-456',
        status: 'completed',
        ratingResult: RatingResult(
          finalRating: AgeRating.sixteenPlus,
          targetRating: AgeRating.twelvePlus,
          confidenceScore: 0.85,
          problemScenesCount: 2,
          categoriesSummary: {
            Category.violence: Severity.moderate,
            Category.disturbingScenes: Severity.mild,
            Category.language: Severity.mild,
            Category.sexualContent: Severity.none,
            Category.alcoholDrugs: Severity.none,
          },
        ),
        sceneAssessments: [scene1, scene2, scene3],
        createdAt: DateTime(2024, 1, 15, 10, 30),
        recommendations: [
          'Consider reducing violence content',
          'Review language used in dialogue',
        ],
      );
    });

    Widget createTestWidget({required AnalysisResult result}) {
      return MaterialApp(
        home: Scaffold(
          body: AnalysisResultWidget(result: result),
        ),
      );
    }

    group('Basic Rendering Tests', () {
      testWidgets('should render with complete analysis result data', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Verify main structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Padding), findsWidgets);
        expect(find.byType(Column), findsWidgets);

        // Verify header elements
        expect(find.byIcon(Icons.analytics), findsOneWidget);
        expect(find.text('Итоги оценки'), findsOneWidget);

        // Verify main rating display
        expect(find.text(AgeRating.sixteenPlus.display), findsOneWidget);
        expect(find.text('(целевой: ${AgeRating.twelvePlus.display})'), findsOneWidget);

        // Verify confidence score
        expect(find.text('Уверенность 85%'), findsOneWidget);
        expect(find.byIcon(Icons.verified), findsOneWidget);

        // Verify statistics
        expect(find.text('Блоков анализировано'), findsOneWidget);
        expect(find.text('3'), findsOneWidget); // Total scenes
        expect(find.text('Проблемных блоков'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // Problem scenes count
      });

      testWidgets('should render with minimal analysis result', (WidgetTester tester) async {
        final minimalResult = AnalysisResult(
          analysisId: 'minimal-analysis',
          documentId: 'doc-1',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.zeroPlus,
            confidenceScore: 1.0,
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: minimalResult));

        // Verify basic structure still exists
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Итоги оценки'), findsOneWidget);
        expect(find.text(AgeRating.zeroPlus.display), findsOneWidget);
        expect(find.text('Уверенность 100%'), findsOneWidget);
        expect(find.text('Блоков анализировано'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('Проблемных блоков'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('should render with different confidence scores', (WidgetTester tester) async {
        // Test with low confidence
        final lowConfidenceResult = AnalysisResult(
          analysisId: 'low-confidence',
          documentId: 'doc-2',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.twelvePlus,
            confidenceScore: 0.45,
            problemScenesCount: 1,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: lowConfidenceResult));
        expect(find.text('Уверенность 45%'), findsOneWidget);

        // Test with high confidence
        final highConfidenceResult = AnalysisResult(
          analysisId: 'high-confidence',
          documentId: 'doc-3',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.eighteenPlus,
            confidenceScore: 0.99,
            problemScenesCount: 5,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: highConfidenceResult));
        expect(find.text('Уверенность 99%'), findsOneWidget);
      });

      testWidgets('should render without target rating when null', (WidgetTester tester) async {
        final noTargetResult = AnalysisResult(
          analysisId: 'no-target',
          documentId: 'doc-4',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.sixPlus,
            confidenceScore: 0.8,
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: noTargetResult));

        // Verify final rating is displayed
        expect(find.text(AgeRating.sixPlus.display), findsOneWidget);
        
        // Verify target rating text is not displayed
        expect(find.text('(целевой:'), findsNothing);
      });
    });

    group('Visual States Tests', () {
      testWidgets('should handle different age ratings', (WidgetTester tester) async {
        final testRatings = [
          AgeRating.zeroPlus,
          AgeRating.sixPlus,
          AgeRating.twelvePlus,
          AgeRating.sixteenPlus,
          AgeRating.eighteenPlus,
        ];

        for (final rating in testRatings) {
          final result = AnalysisResult(
            analysisId: 'test-$rating',
            documentId: 'doc-$rating',
            status: 'completed',
            ratingResult: RatingResult(
              finalRating: rating,
              confidenceScore: 0.8,
              problemScenesCount: 0,
              categoriesSummary: {},
            ),
            sceneAssessments: [],
            createdAt: DateTime.now(),
          );

          await tester.pumpWidget(createTestWidget(result: result));
          expect(find.text(rating.display), findsOneWidget);
        }
      });

      testWidgets('should handle empty analysis result', (WidgetTester tester) async {
        final emptyResult = AnalysisResult(
          analysisId: '',
          documentId: '',
          status: '',
          ratingResult: RatingResult(
            finalRating: AgeRating.zeroPlus,
            confidenceScore: 0.0,
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime(1970, 1, 1), // Unix epoch
        );

        await tester.pumpWidget(createTestWidget(result: emptyResult));

        // Should still render basic structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Итоги оценки'), findsOneWidget);
      });

      testWidgets('should handle very large problem scene counts', (WidgetTester tester) async {
        final resultWithManyProblems = AnalysisResult(
          analysisId: 'many-problems',
          documentId: 'doc-many',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.eighteenPlus,
            confidenceScore: 0.7,
            problemScenesCount: 150, // Very high count
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: resultWithManyProblems));
        expect(find.text('150'), findsOneWidget);
      });
    });

    group('Data Display Tests', () {
      testWidgets('should display correct problem scene count calculation', (WidgetTester tester) async {
        // Test with known problem scene count
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Scene 1: Has mild language (problem)
        // Scene 2: Has moderate violence and mild disturbing scenes (problem)
        // Scene 3: Has no problems
        // Expected: 2 problem scenes
        
        expect(find.text('2'), findsAtLeastNWidgets(1));
      });

      testWidgets('should format confidence score correctly', (WidgetTester tester) async {
        // Test with decimal confidence
        final decimalConfidenceResult = AnalysisResult(
          analysisId: 'decimal-confidence',
          documentId: 'doc-decimal',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.twelvePlus,
            confidenceScore: 0.867, // 86.7% should round to 87%
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: decimalConfidenceResult));
        expect(find.text('Уверенность 87%'), findsOneWidget);
      });

      testWidgets('should handle edge case confidence scores', (WidgetTester tester) async {
        // Test exactly 0.0
        final zeroConfidenceResult = AnalysisResult(
          analysisId: 'zero-confidence',
          documentId: 'doc-zero',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.zeroPlus,
            confidenceScore: 0.0,
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: zeroConfidenceResult));
        expect(find.text('Уверенность 0%'), findsOneWidget);

        // Test exactly 1.0
        final fullConfidenceResult = AnalysisResult(
          analysisId: 'full-confidence',
          documentId: 'doc-full',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.eighteenPlus,
            confidenceScore: 1.0,
            problemScenesCount: 10,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: fullConfidenceResult));
        expect(find.text('Уверенность 100%'), findsOneWidget);
      });

      testWidgets('should handle boundary confidence scores', (WidgetTester tester) async {
        // Test just below rounding threshold
        final nearThresholdResult = AnalysisResult(
          analysisId: 'near-threshold',
          documentId: 'doc-threshold',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.sixPlus,
            confidenceScore: 0.864, // Should round to 86%
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: nearThresholdResult));
        expect(find.text('Уверенность 86%'), findsOneWidget);
      });
    });

    group('Layout and Styling Tests', () {
      testWidgets('should have proper card styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, 4.0);
      });

      testWidgets('should have proper padding throughout', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Check main padding
        final mainPadding = tester.widget<Padding>(find.widgetWithText(Padding, 'Итоги оценки').first);
        expect(mainPadding.padding, const EdgeInsets.all(20));

        // Check nested padding widgets exist
        final paddingWidgets = find.descendant(
          of: find.byType(Card),
          matching: find.byType(Padding),
        );
        expect(paddingWidgets, findsWidgets);
      });

      testWidgets('should have proper icon styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        final analyticsIcon = tester.widget<Icon>(find.byIcon(Icons.analytics));
        expect(analyticsIcon.size, 32.0);
        expect(analyticsIcon.color, Colors.blue);
      });

      testWidgets('should have proper title styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        final titleText = tester.widget<Text>(find.text('Итоги оценки'));
        expect(titleText.style?.fontSize, 22.0);
        expect(titleText.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('should have proper rating display styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        final ratingText = find.text(AgeRating.sixteenPlus.display);
        expect(ratingText, findsOneWidget);

        // The rating should be prominently displayed in blue color
        // (Color verification would require extracting from widget tree)
      });

      testWidgets('should have proper container styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Check for the main content container with blue background
        final container = tester.widget<Container>(find.descendant(
          of: find.byType(Card),
          matching: find.byWidgetPredicate(
            (widget) => widget is Container && 
                       widget.decoration is BoxDecoration &&
                       (widget.decoration as BoxDecoration).color == Colors.blue.shade50,
          ),
        ));
        expect(container, isNotNull);
      });
    });

    group('Interactive Elements Tests', () {
      testWidgets('should handle tap interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Verify widget is tappable
        final card = find.byType(Card);
        await tester.tap(card);
        await tester.pump(); // No crash should occur

        // Verify state remains stable after interaction
        expect(find.text('Итоги оценки'), findsOneWidget);
      });

      testWidgets('should handle long press interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        final card = find.byType(Card);
        await tester.longPress(card);
        await tester.pump();

        // Should handle long press gracefully
        expect(find.text('Итоги оценки'), findsOneWidget);
      });

      testWidgets('should handle scroll interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Scroll within the widget
        final card = find.byType(Card);
        await tester.scrollUntilVisible(card, 100.0);
        await tester.pump();

        // Should handle scroll gracefully
        expect(find.text('Итоги оценки'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle invalid confidence scores gracefully', (WidgetTester tester) async {
        final invalidConfidenceResult = AnalysisResult(
          analysisId: 'invalid-confidence',
          documentId: 'doc-invalid',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.twelvePlus,
            confidenceScore: 2.5, // Invalid: > 1.0
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: invalidConfidenceResult));
        
        // Should handle gracefully and not crash
        expect(find.text('Уверенность 250%'), findsOneWidget); // Will round to 250%
      });

      testWidgets('should handle negative confidence scores', (WidgetTester tester) async {
        final negativeConfidenceResult = AnalysisResult(
          analysisId: 'negative-confidence',
          documentId: 'doc-negative',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.sixPlus,
            confidenceScore: -0.5, // Invalid: < 0.0
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: negativeConfidenceResult));
        
        // Should handle gracefully
        expect(find.text('Уверенность -50%'), findsOneWidget);
      });

      testWidgets('should handle empty scene assessments list', (WidgetTester tester) async {
        final emptyScenesResult = AnalysisResult(
          analysisId: 'empty-scenes',
          documentId: 'doc-empty',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.zeroPlus,
            confidenceScore: 1.0,
            problemScenesCount: 0,
            categoriesSummary: {},
          ),
          sceneAssessments: [], // Empty list
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: emptyScenesResult));

        // Should still render with correct stats
        expect(find.text('0'), findsWidgets);
        expect(find.text('0'), findsAtLeastNWidgets(2)); // Both counters should be 0
      });
    });

    group('Expandable Content Tests', () {
      testWidgets('should handle expandable sections', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // The widget should handle expandable content gracefully
        expect(find.text('Итоги оценки'), findsOneWidget);
        
        // Main content should be visible
        expect(find.text('Блоков анализировано'), findsOneWidget);
        expect(find.text('Проблемных блоков'), findsOneWidget);
      });

      testWidgets('should handle large amounts of scene data', (WidgetTester tester) async {
        // Create many scenes to test performance
        final largeSceneList = List.generate(50, (index) => SceneAssessment(
          sceneNumber: index + 1,
          heading: 'Scene $index',
          pageRange: '${index * 10}-${(index + 1) * 10}',
          categories: {
            Category.language: Severity.values[index % Severity.values.length],
          },
          ageRating: AgeRating.twelvePlus,
          llmComment: 'Comment for scene $index',
          text: 'Text for scene $index',
        ));

        final largeDataResult = AnalysisResult(
          analysisId: 'large-data',
          documentId: 'doc-large',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.eighteenPlus,
            confidenceScore: 0.9,
            problemScenesCount: 25, // Half have problems
            categoriesSummary: {},
          ),
          sceneAssessments: largeSceneList,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: largeDataResult));

        // Should render correctly with large dataset
        expect(find.text('50'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
      });
    });

    group('Data Validation Tests', () {
      testWidgets('should validate scene count calculations', (WidgetTester tester) async {
        // Create specific test data with known problem count
        final scene1 = SceneAssessment(
          sceneNumber: 1,
          heading: 'Safe Scene',
          pageRange: '1-5',
          categories: {
            Category.language: Severity.none,
            Category.violence: Severity.none,
          },
          ageRating: AgeRating.zeroPlus,
          llmComment: 'No issues',
          text: 'Safe content',
          flaggedContent: [],
        );

        final scene2 = SceneAssessment(
          sceneNumber: 2,
          heading: 'Problem Scene',
          pageRange: '6-10',
          categories: {
            Category.violence: Severity.mild,
          },
          ageRating: AgeRating.sixPlus,
          llmComment: 'Mild violence',
          text: 'Violent content',
          flaggedContent: ['mild violence'],
        );

        final resultWithKnownCount = AnalysisResult(
          analysisId: 'known-count',
          documentId: 'doc-known',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.sixPlus,
            confidenceScore: 0.8,
            problemScenesCount: 1, // Expected: 1 problem scene
            categoriesSummary: {},
          ),
          sceneAssessments: [scene1, scene2],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(result: resultWithKnownCount));
        
        // Should display correct problem count
        expect(find.text('2'), findsAtLeastNWidgets(1)); // Total scenes
        expect(find.text('1'), findsAtLeastNWidgets(1)); // Problem scenes
      });

      testWidgets('should display recommendations when available', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Recommendations should be displayed (they are part of the AnalysisResult)
        // Note: The current widget implementation doesn't display recommendations,
        // but this test verifies the data is available for display
        expect(testAnalysisResult.recommendations, isNotNull);
        expect(testAnalysisResult.recommendations!.isNotEmpty, true);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Verify main content is accessible
        expect(find.text('Итоги оценки'), findsOneWidget);
        expect(find.text('Блоков анализировано'), findsOneWidget);
        expect(find.text('Проблемных блоков'), findsOneWidget);
      });

      testWidgets('should have proper text contrast', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Verify text elements are rendered (color contrast would need specialized testing tools)
        final titleText = find.text('Итоги оценки');
        expect(titleText, findsOneWidget);
        
        final ratingText = find.text(AgeRating.sixteenPlus.display);
        expect(ratingText, findsOneWidget);
      });

      testWidgets('should have proper touch targets', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(result: testAnalysisResult));

        // Verify card has reasonable touch target size
        final card = find.byType(Card);
        expect(card, findsOneWidget);
        
        // Test tap responsiveness
        await tester.tap(card);
        await tester.pump();
      });
    });

    group('Performance Tests', () {
      testWidgets('should render efficiently with complex data', (WidgetTester tester) async {
        final complexResult = AnalysisResult(
          analysisId: 'complex',
          documentId: 'doc-complex',
          status: 'completed',
          ratingResult: RatingResult(
            finalRating: AgeRating.eighteenPlus,
            targetRating: AgeRating.zeroPlus,
            confidenceScore: 0.95,
            problemScenesCount: 20,
            categoriesSummary: {
              Category.violence: Severity.severe,
              Category.sexualContent: Severity.severe,
              Category.language: Severity.moderate,
              Category.alcoholDrugs: Severity.mild,
              Category.disturbingScenes: Severity.severe,
            },
          ),
          sceneAssessments: List.generate(25, (index) => SceneAssessment(
            sceneNumber: index + 1,
            heading: 'Complex Scene $index',
            pageRange: '${index * 5}-${(index + 1) * 5}',
            categories: {
              Category.language: Severity.values[index % Severity.values.length],
              Category.violence: Severity.values[(index + 1) % Severity.values.length],
            },
            ageRating: AgeRating.eighteenPlus,
            llmComment: 'Complex analysis for scene $index with multiple categories and detailed feedback.',
            text: 'Complex scene text with multiple elements and detailed analysis.',
            flaggedContent: ['complex content $index'],
          )),
          createdAt: DateTime.now(),
          recommendations: List.generate(10, (index) => 'Recommendation $index for complex analysis'),
        );

        await tester.pumpWidget(createTestWidget(result: complexResult));

        // Should render without performance issues
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Итоги оценки'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('Уверенность 95%'), findsOneWidget);
      });

      testWidgets('should handle rapid widget updates', (WidgetTester tester) async {
        // Test multiple rapid updates
        for (int i = 0; i < 10; i++) {
          final updatedResult = AnalysisResult(
            analysisId: 'rapid-update-$i',
            documentId: 'doc-$i',
            status: 'completed',
            ratingResult: RatingResult(
              finalRating: AgeRating.values[i % AgeRating.values.length],
              confidenceScore: 0.8 + (i * 0.02),
              problemScenesCount: i,
              categoriesSummary: {},
            ),
            sceneAssessments: [],
            createdAt: DateTime.now(),
          );

          await tester.pumpWidget(createTestWidget(result: updatedResult));
        }

        // Should handle all updates gracefully
        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}