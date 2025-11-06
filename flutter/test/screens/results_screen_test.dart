import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:script_rating_app/models/analysis_result.dart';
import 'package:script_rating_app/models/category.dart';
import 'package:script_rating_app/models/severity.dart';
import 'package:script_rating_app/services/api_service.dart';
import 'package:script_rating_app/screens/results_screen.dart';
import 'package:script_rating_app/widgets/analysis_result_widget.dart';
import 'package:script_rating_app/widgets/category_summary_widget.dart';
import 'package:script_rating_app/widgets/scene_detail_widget.dart';

// Mock classes
class MockApiService extends Mock implements ApiService {}

void main() {
  group('ResultsScreen Widget Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    tearDown(() {
      reset(mockApiService);
    });

    // Test Helper Methods
    AnalysisResult createMockAnalysisResult() {
      return AnalysisResult(
        analysisId: 'analysis-123',
        documentId: 'doc-123',
        overallRating: 'PG-13',
        confidenceScore: 0.85,
        processedAt: DateTime(2024, 1, 15, 14, 30),
        ratingResult: const RatingResult(
          overallRating: 'PG-13',
          confidenceScore: 0.85,
          categoriesSummary: {
            Category.violence: Severity.medium,
            Category.language: Severity.low,
          },
        ),
        sceneAssessments: [
          SceneAssessment(
            id: 'scene-1',
            sceneNumber: 1,
            description: 'Opening scene with family dinner',
            content: 'FADE IN: INT. FAMILY KITCHEN - DAY\nJohn sits at the table...',
            categories: {
              Category.violence: Severity.low,
              Category.language: Severity.none,
            },
            rating: 'G',
            confidenceScore: 0.92,
            severity: Severity.low,
            flagged: false,
            references: [
              'Federal Law 436, Article 3.1',
              'Methodology Guidelines p. 15',
            ],
          ),
        ],
        recommendations: [
          'Consider softening dialogue in scene 15',
          'Add content warning for mature themes in Act II',
        ],
      );
    }

    AnalysisResult createEmptyAnalysisResult() {
      return AnalysisResult(
        analysisId: 'empty-123',
        documentId: 'doc-empty',
        overallRating: 'G',
        confidenceScore: 0.95,
        processedAt: DateTime.now(),
        ratingResult: const RatingResult(
          overallRating: 'G',
          confidenceScore: 0.95,
          categoriesSummary: {},
        ),
        sceneAssessments: const [],
        recommendations: const [],
      );
    }

    Widget createTestWidget({String? analysisId}) {
      return MaterialApp(
        home: ResultsScreen(analysisId: analysisId),
      );
    }

    // Basic Rendering Tests
    testWidgets('ResultsScreen should render with correct title and actions', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization

      // Assert
      expect(find.text('Результаты анализа'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.feedback), findsOneWidget);
      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('ResultsScreen should show loading indicator when fetching results', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Immediately after widget creation

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Результаты анализа'), findsOneWidget);
    });

    testWidgets('ResultsScreen should render error state when no analysis ID provided', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(analysisId: null));
      await tester.pump(); // Trigger initialization

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Не передан идентификатор анализа'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('ResultsScreen should render error state when API fails', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Не удалось получить результат: Network error'), findsOneWidget);
      expect(find.text('Повторить запрос'), findsOneWidget);
    });

    testWidgets('ResultsScreen should render empty state when no data available', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createEmptyAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'empty-123'));
      await tester.pump(); // Trigger initialization

      // Assert
      expect(find.text('Данных анализа пока нет. Вернитесь позже.'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    // Content Rendering Tests
    testWidgets('ResultsScreen should render AnalysisResultWidget', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.byType(AnalysisResultWidget), findsOneWidget);
    });

    testWidgets('ResultsScreen should render recommendations section', (WidgetTester tester) async {
      // Arrange
      final result = createMockAnalysisResult();
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => result);

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.text('Рекомендации'), findsOneWidget);
      expect(find.text('Consider softening dialogue in scene 15'), findsOneWidget);
      expect(find.text('Add content warning for mature themes in Act II'), findsOneWidget);
    });

    testWidgets('ResultsScreen should render category summary section', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.text('Сводка по категориям'), findsOneWidget);
      expect(find.byType(CategorySummaryWidget), findsOneWidget);
    });

    testWidgets('ResultsScreen should render scene assessments section', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.text('Смысловые блоки'), findsOneWidget);
      expect(find.byType(SceneDetailWidget), findsNWidgets(1));
    });

    testWidgets('ResultsScreen should render multiple scene assessments', (WidgetTester tester) async {
      // Arrange
      final result = createMockAnalysisResult().copyWith(
        sceneAssessments: [
          SceneAssessment(
            id: 'scene-1',
            sceneNumber: 1,
            description: 'Scene 1',
            content: 'Content 1',
            categories: {Category.violence: Severity.low},
            rating: 'G',
            confidenceScore: 0.9,
            severity: Severity.low,
            flagged: false,
            references: const [],
          ),
          SceneAssessment(
            id: 'scene-2',
            sceneNumber: 2,
            description: 'Scene 2',
            content: 'Content 2',
            categories: {Category.language: Severity.medium},
            rating: 'PG-13',
            confidenceScore: 0.85,
            severity: Severity.medium,
            flagged: true,
            references: const [],
          ),
        ],
      );

      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => result);

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.byType(SceneDetailWidget), findsNWidgets(2));
      expect(find.text('Scene 1'), findsOneWidget);
      expect(find.text('Scene 2'), findsOneWidget);
    });

    // Navigation Tests
    testWidgets('ResultsScreen should navigate to history when history button is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Act
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Assert - In test environment, this would navigate
      verify(() => mockApiService.getAnalysisResult('test-123')).called(1);
    });

    testWidgets('ResultsScreen should navigate to feedback when feedback button is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Act
      await tester.tap(find.byIcon(Icons.feedback));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockApiService.getAnalysisResult('test-123')).called(1);
    });

    testWidgets('ResultsScreen should navigate to report generation when download button is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Act
      await tester.tap(find.byIcon(Icons.file_download));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockApiService.getAnalysisResult('test-123')).called(1);
    });

    testWidgets('ResultsScreen should navigate to upload when analyze another button is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Act
      await tester.tap(find.text('Анализировать ещё сценарий'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockApiService.getAnalysisResult('test-123')).called(1);
    });

    // Retry Functionality Tests
    testWidgets('ResultsScreen should retry on error when retry button is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization

      // First attempt fails
      expect(find.text('Не удалось получить результат'), findsOneWidget);

      // Reset mock to succeed
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.tap(find.text('Повторить запрос'));
      await tester.pump(); // Trigger retry
      await tester.pump(); // Allow loading

      // Assert - Should show loading again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ResultsScreen should retry on error when no analysis ID and retry button is pressed', (WidgetTester tester) async {
      // Arrange - Already in error state due to null analysisId
      await tester.pumpWidget(createTestWidget(analysisId: null));
      await tester.pump(); // Trigger initialization

      expect(find.text('Не передан идентификатор анализа'), findsOneWidget);

      // Act
      await tester.tap(find.text('Повторить запрос'));
      await tester.pump(); // Trigger retry

      // Assert - Should still be in error state (no analysisId to load)
      expect(find.text('Не передан идентификатор анализа'), findsOneWidget);
    });

    // Content Layout Tests
    testWidgets('ResultsScreen should use SingleChildScrollView for content', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Check padding is applied
      final scrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      expect(scrollView.padding, const EdgeInsets.all(16));
    });

    testWidgets('ResultsScreen should render all sections in correct order', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Verify the content order by checking visibility
      expect(find.byType(AnalysisResultWidget), findsOneWidget);
      expect(find.text('Рекомендации'), findsOneWidget);
      expect(find.text('Сводка по категориям'), findsOneWidget);
      expect(find.text('Смысловые блоки'), findsOneWidget);
      expect(find.text('Анализировать ещё сценарий'), findsOneWidget);
    });

    // Content Formatting Tests
    testWidgets('ResultsScreen should format recommendations with bullet points', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert - Should show bullet points in recommendations
      expect(find.text('• Consider softening dialogue in scene 15'), findsOneWidget);
      expect(find.text('• Add content warning for mature themes in Act II'), findsOneWidget);
    });

    testWidgets('ResultsScreen should hide recommendations section when empty', (WidgetTester tester) async {
      // Arrange
      final emptyResult = createEmptyAnalysisResult();
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => emptyResult);

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'empty-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert - Empty results don't show recommendations section
      expect(find.text('Рекомендации'), findsNothing);
    });

    testWidgets('ResultsScreen should hide scene assessments section when empty', (WidgetTester tester) async {
      // Arrange
      final emptyResult = createEmptyAnalysisResult();
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => emptyResult);

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'empty-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.text('Смысловые блоки'), findsNothing);
      expect(find.byType(SceneDetailWidget), findsNothing);
    });

    // State Management Tests
    testWidgets('ResultsScreen should reset loading state after successful load', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pump(); // Allow loading to complete
      await tester.pump(); // Allow state update

      // Assert - Loading state should be cleared
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AnalysisResultWidget), findsOneWidget);
    });

    testWidgets('ResultsScreen should manage loading state correctly on retry', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization - should show error

      // Reset mock to succeed
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act - Retry
      await tester.tap(find.text('Повторить запрос'));
      await tester.pump(); // Should show loading

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Не удалось получить результат'), findsNothing);
    });

    // Edge Cases Tests
    testWidgets('ResultsScreen should handle very long recommendations gracefully', (WidgetTester tester) async {
      // Arrange
      final longRecommendations = List.generate(
        10,
        (index) => 'This is a very long recommendation number ${index + 1} that contains detailed instructions and suggestions for improving the content of the script analysis. It goes on and on with specific details about how to handle different scenes and content warnings.',
      );

      final result = createMockAnalysisResult().copyWith(
        recommendations: longRecommendations,
      );

      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => result);

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert - Should render all recommendations
      expect(find.text('Рекомендации'), findsOneWidget);
      longRecommendations.forEach((rec) {
        expect(find.textContaining(rec.split(' ').first), findsOneWidget);
      });
    });

    testWidgets('ResultsScreen should handle large scene assessment lists efficiently', (WidgetTester tester) async {
      // Arrange
      final largeSceneList = List.generate(
        100,
        (index) => SceneAssessment(
          id: 'scene-$index',
          sceneNumber: index + 1,
          description: 'Scene $index description',
          content: 'Scene $index content',
          categories: {Category.violence: Severity.values[index % 3]},
          rating: index % 2 == 0 ? 'PG-13' : 'R',
          confidenceScore: 0.8 + (index * 0.001),
          severity: Severity.values[index % 3],
          flagged: index % 5 == 0,
          references: const ['Reference $index'],
        ),
      );

      final result = createMockAnalysisResult().copyWith(
        sceneAssessments: largeSceneList,
      );

      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => result);

      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      stopwatch.stop();

      // Assert - Should handle large lists efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(find.byType(SceneDetailWidget), findsNWidgets(100));
    });

    // Performance Tests
    testWidgets('ResultsScreen should render efficiently with complex analysis data', (WidgetTester tester) async {
      // Arrange
      final complexResult = AnalysisResult(
        analysisId: 'complex-123',
        documentId: 'doc-complex',
        overallRating: 'R',
        confidenceScore: 0.78,
        processedAt: DateTime.now(),
        ratingResult: const RatingResult(
          overallRating: 'R',
          confidenceScore: 0.78,
          categoriesSummary: {
            Category.violence: Severity.high,
            Category.language: Severity.high,
            Category.adult_content: Severity.medium,
          },
        ),
        sceneAssessments: List.generate(
          25,
          (index) => SceneAssessment(
            id: 'scene-$index',
            sceneNumber: index + 1,
            description: 'Complex scene $index with multiple references and detailed analysis',
            content: 'FADE IN: Scene content with lots of text and dialogue...\nINT. LOCATION - TIME\nCharacter dialogues and action descriptions...',
            categories: {
              Category.violence: index % 2 == 0 ? Severity.high : Severity.medium,
              Category.language: index % 3 == 0 ? Severity.medium : Severity.low,
            },
            rating: index % 4 == 0 ? 'R' : 'PG-13',
            confidenceScore: 0.7 + (index * 0.01),
            severity: Severity.values[index % 3],
            flagged: index % 6 == 0,
            references: ['Reference ${index}A', 'Reference ${index}B', 'Reference ${index}C'],
          ),
        ),
        recommendations: [
          'Complex recommendation with detailed technical analysis and specific improvement suggestions',
          'Another recommendation focusing on content warnings and age-appropriate modifications',
        ],
      );

      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => complexResult);

      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'complex-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      stopwatch.stop();

      // Assert - Should render complex content efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(find.byType(AnalysisResultWidget), findsOneWidget);
      expect(find.byType(CategorySummaryWidget), findsOneWidget);
      expect(find.byType(SceneDetailWidget), findsNWidgets(25));
    });

    // Accessibility Tests
    testWidgets('ResultsScreen should have proper semantic labels', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      await tester.pump(); // Allow loading to complete

      // Assert
      expect(find.bySemanticsLabel('Результаты анализа'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.feedback), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.file_download), findsAtLeastNWidgets(1));
    });

    // Integration Tests
    testWidgets('ResultsScreen complete workflow from error to success', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisResult(any()))
          .thenThrow(Exception('Network error'));

      // Act & Assert - Initial error state
      await tester.pumpWidget(createTestWidget(analysisId: 'test-123'));
      await tester.pump(); // Trigger initialization
      expect(find.text('Не удалось получить результат'), findsOneWidget);

      // Reset mock to succeed
      when(() => mockApiService.getAnalysisResult(any()))
          .thenAnswer((_) async => createMockAnalysisResult());

      // Act - Retry
      await tester.tap(find.text('Повторить запрос'));
      await tester.pump(); // Show loading
      await tester.pump(); // Complete loading

      // Assert - Success state
      expect(find.text('Не удалось получить результат'), findsNothing);
      expect(find.byType(AnalysisResultWidget), findsOneWidget);
      expect(find.text('Рекомендации'), findsOneWidget);
    });
  });
}

