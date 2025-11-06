import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/scene_assessment.dart';
import 'package:script_rating_app/models/age_rating.dart';
import 'package:script_rating_app/models/category.dart';
import 'package:script_rating_app/models/severity.dart';
import 'package:script_rating_app/models/normative_reference.dart';
import 'package:script_rating_app/widgets/scene_detail_widget.dart';

void main() {
  group('SceneDetailWidget Widget Tests', () {
    late SceneAssessment testAssessment;
    late SceneAssessment emptyAssessment;
    late List<NormativeReference> testReferences;

    setUp(() {
      testReferences = [
        NormativeReference(
          documentId: 'doc-1',
          title: 'Content Guidelines',
          page: 25,
          paragraph: 3,
          excerpt: 'Violent content should be rated appropriately.',
          score: 0.8,
        ),
      ];

      testAssessment = SceneAssessment(
        sceneNumber: 3,
        heading: 'Action Sequence',
        pageRange: '15-25',
        categories: {
          Category.violence: Severity.moderate,
          Category.disturbingScenes: Severity.mild,
        },
        ageRating: AgeRating.sixteenPlus,
        llmComment: 'This scene contains moderate violence and mild disturbing content.',
        text: 'The hero confronts the villain in a dramatic fight scene.',
        textPreview: 'The hero confronts the villain...',
        flaggedContent: ['moderate violence', 'disturbing imagery'],
        references: testReferences,
        highlights: [
          HighlightFragment(
            start: 10,
            end: 25,
            text: 'violent scene',
            category: Category.violence,
            severity: Severity.moderate,
          ),
        ],
      );

      emptyAssessment = SceneAssessment(
        sceneNumber: 1,
        heading: '',
        pageRange: '',
        categories: {},
        ageRating: AgeRating.zeroPlus,
        llmComment: '',
        text: '',
        flaggedContent: [],
        references: [],
        highlights: [],
      );
    });

    Widget createTestWidget({
      required SceneAssessment assessment,
      bool showReferences = false,
      bool dense = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SceneDetailWidget(
            assessment: assessment,
            showReferences: showReferences,
            dense: dense,
          ),
        ),
      );
    }

    group('Basic Rendering Tests', () {
      testWidgets('should render with complete assessment data', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(assessment: testAssessment));

        // Verify main structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Padding), findsWidgets);

        // Verify header elements
        expect(find.text('3'), findsOneWidget); // Scene number
        expect(find.text('Action Sequence'), findsOneWidget);
        expect(find.text('Страницы: 15-25'), findsOneWidget);

        // Verify rating chips
        expect(find.text(AgeRating.sixteenPlus.value), findsOneWidget);
        expect(find.text(Severity.moderate.name), findsOneWidget);

        // Verify comment panel
        expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

        // Verify flagged content
        expect(find.text('Обнаруженные элементы:'), findsOneWidget);
        expect(find.text('moderate violence'), findsOneWidget);
        expect(find.text('disturbing imagery'), findsOneWidget);

        // Verify highlighted script section
        expect(find.text('Фрагмент сценария'), findsOneWidget);
        expect(find.byType(SelectableText), findsOneWidget);
      });

      testWidgets('should render with minimal assessment data', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(assessment: emptyAssessment));

        // Should still render basic structure
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // Scene number
      });

      testWidgets('should handle different age ratings', (WidgetTester tester) async {
        for (final rating in AgeRating.values) {
          final assessment = SceneAssessment(
            sceneNumber: 1,
            heading: 'Test Scene',
            pageRange: '1-5',
            categories: {},
            ageRating: rating,
            llmComment: 'Test comment',
            text: 'Test text',
          );

          await tester.pumpWidget(createTestWidget(assessment: assessment));
          expect(find.text(rating.value), findsOneWidget);
        }
      });

      testWidgets('should handle different severity levels', (WidgetTester tester) async {
        for (final severity in Severity.values) {
          final assessment = SceneAssessment(
            sceneNumber: 1,
            heading: 'Test Scene',
            pageRange: '1-5',
            categories: {Category.violence: severity},
            ageRating: AgeRating.twelvePlus,
            llmComment: 'Test comment',
            text: 'Test text',
          );

          await tester.pumpWidget(createTestWidget(assessment: assessment));
          expect(find.text(severity.name), findsOneWidget);
        }
      });
    });

    group('Text Display Tests', () {
      testWidgets('should handle empty text gracefully', (WidgetTester tester) async {
        final emptyTextAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Empty Text Scene',
          pageRange: '1-5',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Empty text scene',
          text: '',
          textPreview: null,
          flaggedContent: [],
        );

        await tester.pumpWidget(createTestWidget(assessment: emptyTextAssessment));

        // Should not display text-related sections when empty
        expect(find.text('Фрагмент сценария'), findsNothing);
        expect(find.byType(SelectableText), findsNothing);
      });

      testWidgets('should handle null text preview', (WidgetTester tester) async {
        final noPreviewAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'No Preview Scene',
          pageRange: '1-5',
          categories: {},
          ageRating: AgeRating.twelvePlus,
          llmComment: 'Scene with no preview',
          text: 'This scene has text but no preview',
          textPreview: null,
          flaggedContent: [],
        );

        await tester.pumpWidget(createTestWidget(assessment: noPreviewAssessment));

        // Should display main text but not preview
        expect(find.byType(SelectableText), findsOneWidget);
        expect(find.text('Фрагмент:'), findsNothing);
      });
    });

    group('Interactive Elements Tests', () {
      testWidgets('should handle tap on scene card', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(assessment: testAssessment));

        final card = find.byType(Card);
        await tester.tap(card);
        await tester.pump();

        // Should handle tap gracefully
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Different Scene Types Tests', () {
      testWidgets('should handle violent scenes', (WidgetTester tester) async {
        final violentAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Violent Scene',
          pageRange: '10-20',
          categories: {
            Category.violence: Severity.severe,
          },
          ageRating: AgeRating.eighteenPlus,
          llmComment: 'This scene contains severe violence.',
          text: 'Graphic violent content here.',
          flaggedContent: ['severe violence'],
        );

        await tester.pumpWidget(createTestWidget(assessment: violentAssessment));

        expect(find.text('severe'), findsOneWidget);
        expect(find.text('18+'), findsOneWidget);
        expect(find.text('severe violence'), findsOneWidget);
      });

      testWidgets('should handle multi-category scenes', (WidgetTester tester) async {
        final multiCategoryAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Multi Category Scene',
          pageRange: '1-5',
          categories: {
            Category.violence: Severity.severe,
            Category.sexualContent: Severity.moderate,
            Category.language: Severity.mild,
          },
          ageRating: AgeRating.eighteenPlus,
          llmComment: 'Multiple category content.',
          text: 'Multi category scene text.',
          flaggedContent: ['violence', 'sexual content', 'language'],
        );

        await tester.pumpWidget(createTestWidget(assessment: multiCategoryAssessment));

        // Should display highest severity as chip
        expect(find.text('severe'), findsAtLeastNWidgets(1));
      });
    });

    group('References Section Tests', () {
      testWidgets('should render references when showReferences is true', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(assessment: testAssessment, showReferences: true),
        );

        // Should display references section
        expect(find.text('Нормативные ссылки:'), findsOneWidget);
        expect(find.text('Content Guidelines'), findsOneWidget);
        expect(find.text('Стр. 25, п. 3'), findsOneWidget);
      });

      testWidgets('should not render references when showReferences is false', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(assessment: testAssessment, showReferences: false),
        );

        // Should not display references section
        expect(find.text('Нормативные ссылки:'), findsNothing);
        expect(find.text('Content Guidelines'), findsNothing);
      });
    });

    group('Data Validation Tests', () {
      testWidgets('should validate flagged content display', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(assessment: testAssessment));

        // Should display flagged content section
        expect(find.text('Обнаруженные элементы:'), findsOneWidget);
        
        // Should display individual flagged items
        expect(find.text('moderate violence'), findsOneWidget);
        expect(find.text('disturbing imagery'), findsOneWidget);
      });

      testWidgets('should validate highest severity calculation', (WidgetTester tester) async {
        final multiSeverityAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Multi Severity Scene',
          pageRange: '1-5',
          categories: {
            Category.language: Severity.none,
            Category.violence: Severity.mild,
            Category.disturbingScenes: Severity.severe,
          },
          ageRating: AgeRating.eighteenPlus,
          llmComment: 'Test comment',
          text: 'Test text',
        );

        await tester.pumpWidget(createTestWidget(assessment: multiSeverityAssessment));

        // Should display highest severity (severe)
        expect(find.text('severe'), findsAtLeastNWidgets(1));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(assessment: testAssessment));

        // Verify main content is accessible
        expect(find.text('Action Sequence'), findsOneWidget);
        expect(find.text('moderate violence'), findsOneWidget);
        expect(find.byType(SelectableText), findsOneWidget);
      });

      testWidgets('should support text selection', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(assessment: testAssessment));

        // Verify selectable text is available
        final selectableText = find.byType(SelectableText);
        expect(selectableText, findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid widget updates', (WidgetTester tester) async {
        // Test multiple rapid updates
        for (int i = 0; i < 5; i++) {
          final updatedAssessment = SceneAssessment(
            sceneNumber: i,
            heading: 'Updated Scene $i',
            pageRange: '1-5',
            categories: {
              Category.language: Severity.values[i % Severity.values.length],
            },
            ageRating: AgeRating.values[i % AgeRating.values.length],
            llmComment: 'Updated comment $i',
            text: 'Updated text $i',
          );

          await tester.pumpWidget(createTestWidget(assessment: updatedAssessment));
        }

        // Should handle all updates gracefully
        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}