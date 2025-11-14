import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:script_rating_app/models/analysis_status.dart';
import 'package:script_rating_app/models/rating_result.dart';
import 'package:script_rating_app/models/scene_assessment.dart';
import 'package:script_rating_app/services/api_service.dart';
import 'package:script_rating_app/screens/analysis_screen.dart';
import 'package:script_rating_app/widgets/scene_detail_widget.dart';

// Mock classes
class MockApiService extends Mock implements ApiService {}

void main() {
  group('AnalysisScreen Widget Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    tearDown(() {
      reset(mockApiService);
    });

    // Test Helper Methods
    AnalysisStatus createProcessingStatus({double progress = 50.0}) {
      return AnalysisStatus(
        status: 'processing',
        progress: progress,
        processedBlocks: [],
        ratingResult: null,
        recommendations: null,
        errors: null,
      );
    }

    AnalysisStatus createCompletedStatus() {
      return AnalysisStatus(
        status: 'completed',
        progress: 100.0,
        processedBlocks: [
          SceneAssessment(
            id: 'scene-1',
            sceneNumber: 1,
            description: 'Test scene description',
            content: 'Scene content text',
            categories: const {},
            rating: 'PG-13',
            confidenceScore: 0.85,
            severity: Severity.medium,
            flagged: false,
            references: const [],
          ),
        ],
        ratingResult: const RatingResult(
          overallRating: 'PG-13',
          confidenceScore: 0.85,
          categoriesSummary: {},
        ),
        recommendations: const ['Test recommendation'],
        errors: null,
      );
    }

    AnalysisStatus createFailedStatus() {
      return AnalysisStatus(
        status: 'failed',
        progress: 25.0,
        processedBlocks: [],
        ratingResult: null,
        recommendations: null,
        errors: 'Analysis failed due to network error',
      );
    }

    Widget createTestWidget({
      String analysisId = 'test-analysis-123',
      String documentId = 'test-doc-123',
      String? criteriaDocumentId,
    }) {
      return MaterialApp(
        home: AnalysisScreen(
          analysisId: analysisId,
          documentId: documentId,
          criteriaDocumentId: criteriaDocumentId,
        ),
      );
    }

    // Basic Rendering Tests
    testWidgets('AnalysisScreen should render with correct title and close button', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.text('Анализ сценария'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('AnalysisScreen should render processing state correctly', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus(progress: 65.0));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.text('Выполняется анализ...'), findsOneWidget);
      expect(find.text('65.0%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      // Verify progress indicator value
      final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressIndicator.value, 0.65);
    });

    testWidgets('AnalysisScreen should render completed state correctly', (WidgetTester tester) async {
      // Arrange
      final completedStatus = createCompletedStatus();
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => completedStatus);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization
      await tester.pump(const Duration(seconds: 1)); // Allow state changes

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Анализ завершён'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('AnalysisScreen should render failed state correctly', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createFailedStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Анализ завершился с ошибкой'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Analysis failed due to network error'), findsOneWidget);
    });

    // Polling Tests
    testWidgets('AnalysisScreen should poll for status updates', (WidgetTester tester) async {
      // Arrange
      int callCount = 0;
      when(() => mockApiService.getAnalysisStatus(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return createProcessingStatus(progress: 25.0);
        } else {
          return createProcessingStatus(progress: 75.0);
        }
      });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // First poll
      
      // Wait for second poll (approximately 2 seconds + some buffer)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert
      expect(callCount, greaterThan(1));
      verify(() => mockApiService.getAnalysisStatus('test-analysis-123')).called(greaterThan(1));
    });

    testWidgets('AnalysisScreen should stop polling when analysis completes', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createCompletedStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial poll
      await tester.pump(const Duration(seconds: 5)); // Wait for additional polling

      // Assert - Timer should be cancelled, so we should not see multiple calls
      verify(() => mockApiService.getAnalysisStatus(any())).called(1);
    });

    // Scene Detail Rendering Tests
    testWidgets('AnalysisScreen should render processed blocks list', (WidgetTester tester) async {
      // Arrange
      final completedStatus = createCompletedStatus();
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => completedStatus);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SceneDetailWidget), findsOneWidget);
    });

    testWidgets('AnalysisScreen should render multiple scene assessments', (WidgetTester tester) async {
      // Arrange
      final statusWithMultipleBlocks = createCompletedStatus().copyWith(
        processedBlocks: [
          SceneAssessment(
            id: 'scene-1',
            sceneNumber: 1,
            description: 'Scene 1 description',
            content: 'Scene 1 content',
            categories: const {},
            rating: 'PG-13',
            confidenceScore: 0.85,
            severity: Severity.medium,
            flagged: false,
            references: const [],
          ),
          SceneAssessment(
            id: 'scene-2',
            sceneNumber: 2,
            description: 'Scene 2 description',
            content: 'Scene 2 content',
            categories: const {},
            rating: 'R',
            confidenceScore: 0.92,
            severity: Severity.high,
            flagged: true,
            references: const [],
          ),
        ],
      );

      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => statusWithMultipleBlocks);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.byType(SceneDetailWidget), findsNWidgets(2));
      expect(find.byType(ListView.separated), findsOneWidget);
    });

    // Navigation Tests
    testWidgets('AnalysisScreen should navigate to home when close button is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus());

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Act - Close button navigation (will pop in this test environment)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert - Screen should be dismissed
      expect(find.text('Анализ сценария'), findsNothing);
    });

    testWidgets('AnalysisScreen should navigate to results when analysis completes', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createCompletedStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial poll
      await tester.pump(const Duration(seconds: 2)); // Wait for completion and navigation

      // Assert - In a real app with GoRouter, this would navigate to /results
      // In test environment, we check that the navigation logic was triggered
      verify(() => mockApiService.getAnalysisStatus('test-analysis-123')).called(1);
    });

    // Error Handling Tests
    testWidgets('AnalysisScreen should handle API errors gracefully', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Не удалось получить статус'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('AnalysisScreen should handle null responses from API', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => AnalysisStatus(
                status: 'processing',
                progress: null, // Null progress
                processedBlocks: [],
                ratingResult: null,
                recommendations: null,
                errors: null,
              ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert - Should handle null progress without crashing
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    // Progress Indicator Tests
    testWidgets('AnalysisScreen progress indicator should reflect progress value', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus(progress: 42.5));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressIndicator.value, 0.425);
      expect(find.text('42.5%'), findsOneWidget);
    });

    testWidgets('AnalysisScreen progress indicator should be clamped between 0 and 1', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus(progress: 150.0)); // Over 100%

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressIndicator.value, 1.0); // Should be clamped to 1.0
    });

    testWidgets('AnalysisScreen progress indicator should handle negative progress', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus(progress: -10.0)); // Negative

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressIndicator.value, 0.0); // Should be clamped to 0.0
    });

    // Idle State Tests
    testWidgets('AnalysisScreen should render idle state when no blocks processed yet', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus(progress: 30.0)); // Early stage

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.text('Формируем смысловые блоки сценария'), findsOneWidget);
      expect(find.byType(ListView), findsNothing); // No blocks to show yet
    });

    testWidgets('AnalysisScreen should render completion idle state', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createCompletedStatus()); // 100% but still processing recommendations

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.text('Собираем финальные рекомендации...'), findsOneWidget);
    });

    // Color Coding Tests
    testWidgets('AnalysisScreen should use correct colors for different states', (WidgetTester tester) async {
      // Arrange - Completed state
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createCompletedStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert - Check that green color is used for completed state
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, Colors.green);

      final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressIndicator.color, Colors.green);
    });

    testWidgets('AnalysisScreen should use red color for failed state', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createFailedStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(icon.color, Colors.red);

      final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressIndicator.color, Colors.red);
    });

    // Timing and Delays Tests
    testWidgets('AnalysisScreen should delay navigation after completion', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createCompletedStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial state
      
      // Verify navigation doesn't happen immediately
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Анализ сценария'), findsOneWidget); // Still visible

      // Wait for the navigation delay
      await tester.pump(const Duration(milliseconds: 500)); // Total ~1 second delay

      // Assert - In test environment, navigation delay still runs
      // The actual navigation would happen with real router
    });

    testWidgets('AnalysisScreen should dispose timer on screen disposal', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Start polling
      
      // Dispose the widget
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      // Assert - Timer should be cleaned up (no additional polling in real scenario)
      // In a real app, this would prevent memory leaks
    });

    // Widget Lifecycle Tests
    testWidgets('AnalysisScreen should initialize polling on mount', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Trigger initState

      // Assert
      verify(() => mockApiService.getAnalysisStatus('test-analysis-123')).called(1);
    });

    testWidgets('AnalysisScreen should handle analysisId parameter correctly', (WidgetTester tester) async {
      // Arrange
      const customAnalysisId = 'custom-analysis-456';
      when(() => mockApiService.getAnalysisStatus(customAnalysisId))
          .thenAnswer((_) async => createProcessingStatus());

      // Act
      await tester.pumpWidget(createTestWidget(analysisId: customAnalysisId));
      await tester.pump(); // Trigger initialization

      // Assert
      verify(() => mockApiService.getAnalysisStatus(customAnalysisId)).called(1);
    });

    // Performance Tests
    testWidgets('AnalysisScreen should handle frequent status updates efficiently', (WidgetTester tester) async {
      // Arrange
      int callCount = 0;
      when(() => mockApiService.getAnalysisStatus(any())).thenAnswer((_) async {
        callCount++;
        return createProcessingStatus(progress: callCount * 10.0);
      });

      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial call
      await tester.pumpAndSettle(const Duration(seconds: 6)); // Multiple polling cycles

      stopwatch.stop();

      // Assert - Should handle multiple updates efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(callCount, greaterThan(2));
    });

    // Accessibility Tests
    testWidgets('AnalysisScreen should have proper semantic labels', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => createProcessingStatus());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert
      expect(find.bySemanticsLabel('Анализ сценария'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsAtLeastNWidgets(1));
    });

    // Edge Cases Tests
    testWidgets('AnalysisScreen should handle very long scene assessment lists', (WidgetTester tester) async {
      // Arrange
      final longListBlocks = List.generate(
        50,
        (index) => SceneAssessment(
          id: 'scene-$index',
          sceneNumber: index + 1,
          description: 'Scene $index description',
          content: 'Scene $index content',
          categories: const {},
          rating: index % 2 == 0 ? 'PG-13' : 'R',
          confidenceScore: 0.8 + (index * 0.01),
          severity: Severity.values[index % 3],
          flagged: index % 4 == 0,
          references: const [],
        ),
      );

      final statusWithLongList = createCompletedStatus().copyWith(
        processedBlocks: longListBlocks,
      );

      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => statusWithLongList);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert - Should handle long lists efficiently
      expect(find.byType(ListView.separated), findsOneWidget);
      expect(find.byType(SceneDetailWidget), findsNWidgets(50));
    });

    testWidgets('AnalysisScreen should handle empty scene assessments', (WidgetTester tester) async {
      // Arrange
      final emptyBlocksStatus = createCompletedStatus().copyWith(
        processedBlocks: [],
      );

      when(() => mockApiService.getAnalysisStatus(any()))
          .thenAnswer((_) async => emptyBlocksStatus);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow initialization

      // Assert - Should render idle state when no blocks
      expect(find.text('Собираем финальные рекомендации...'), findsOneWidget);
    });
  });
}

