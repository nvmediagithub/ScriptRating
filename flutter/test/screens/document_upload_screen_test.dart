import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';

import 'package:script_rating_app/models/analysis_result.dart';
import 'package:script_rating_app/models/document_type.dart';
import 'package:script_rating_app/services/api_service.dart';
import 'package:script_rating_app/screens/document_upload_screen.dart';

// Mock classes
class MockApiService extends Mock implements ApiService {}

void main() {
  group('DocumentUploadScreen Widget Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      // Register the mock before any calls
      registerFallbackValue(DocumentType.criteria);
    });

    tearDown(() {
      reset(mockApiService);
    });

    // Test Helper Methods
    PlatformFile createMockFile({
      required String name,
      required List<int> bytes,
    }) {
      return PlatformFile(
        name: name,
        size: bytes.length,
        bytes: Uint8List.fromList(bytes),
      );
    }

    AnalysisResult createMockAnalysisResult() {
      return AnalysisResult(
        analysisId: 'analysis-123',
        documentId: 'doc-123',
        overallRating: 'PG-13',
        confidenceScore: 0.85,
        processedAt: DateTime.now(),
        ratingResult: const RatingResult(
          overallRating: 'PG-13',
          confidenceScore: 0.85,
          categoriesSummary: {},
        ),
        sceneAssessments: const [],
        recommendations: const [],
      );
    }

    Map<String, dynamic> createMockUploadResponse() {
      return {
        'document_id': 'doc-123',
        'chunks_indexed': 42,
      };
    }

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: DocumentUploadScreen(),
        ),
      );
    }

    // Basic Rendering Tests
    testWidgets('DocumentUploadScreen should render with correct title and description', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Загрузка документов'), findsOneWidget);
      expect(find.text('Подготовьте нормативные критерии и сценарий'), findsOneWidget);
      expect(find.text('Загрузите выдержки из ФЗ-436 (или других регламентов)'), findsOneWidget);
    });

    testWidgets('DocumentUploadScreen should render both upload cards', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Нормативный документ (ФЗ-436, методики и т.п.)'), findsOneWidget);
      expect(find.text('Сценарий для оценки'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('DocumentUploadScreen should render file picker buttons', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Выбрать файл'), findsNWidgets(2));
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byIcon(Icons.movie_filter_outlined), findsOneWidget);
    });

    // File Upload Tests
    testWidgets('DocumentUploadScreen should handle criteria document upload successfully', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'criteria.pdf', bytes: [1, 2, 3, 4, 5]);
      final mockResponse = createMockUploadResponse();

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      // Mock FilePicker to return our test file
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap criteria upload button
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Файл criteria.pdf загружен'), findsOneWidget);
      expect(find.text('Индексировано фрагментов: 42'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    });

    testWidgets('DocumentUploadScreen should handle script upload and navigation', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'script.txt', bytes: [1, 2, 3, 4, 5]);
      final mockResponse = createMockUploadResponse();
      final mockAnalysis = createMockAnalysisResult();

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      when(() => mockApiService.analyzeScript(
        any(),
        criteriaDocumentId: anyNamed('criteriaDocumentId'),
      )).thenAnswer((_) async => mockAnalysis);

      // Mock FilePicker to return our test file
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - First upload criteria
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Then upload script
      await tester.tap(find.text('Выбрать файл').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Сценарий script.txt отправлен на анализ'), findsOneWidget);
      verify(() => mockApiService.analyzeScript(
        'doc-123',
        criteriaDocumentId: 'doc-123',
      )).called(1);
    });

    // Error Handling Tests
    testWidgets('DocumentUploadScreen should display error when file picker is cancelled', (WidgetTester tester) async {
      // Arrange
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Assert - No error should be shown for cancelled picker
      expect(find.textContaining('Ошибка загрузки'), findsNothing);
    });

    testWidgets('DocumentUploadScreen should display error when file has no data', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'empty.txt', bytes: []); // Empty file
      final mockResponse = createMockUploadResponse();

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      // Mock FilePicker to return file with no bytes
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Assert - Should not process empty file
      expect(find.text('Выбрать файл'), findsNWidgets(2));
    });

    testWidgets('DocumentUploadScreen should handle API upload errors', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'test.pdf', bytes: [1, 2, 3]);
      
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenThrow(Exception('Upload failed'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Ошибка загрузки'), findsOneWidget);
      expect(find.textContaining('Upload failed'), findsOneWidget);
    });

    // Loading States Tests
    testWidgets('DocumentUploadScreen should show loading state during criteria upload', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'criteria.pdf', bytes: [1, 2, 3]);
      final mockResponse = createMockUploadResponse();
      
      // Create a completer to delay the response
      final completer = Completer<Map<String, dynamic>>();
      
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Start upload
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pump(); // This should show loading state

      // Assert - Should show loading state
      expect(find.text('Загрузка...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Выбрать файл'), findsNothing);

      // Complete the upload
      completer.complete(mockResponse);
      await tester.pumpAndSettle();

      // Assert - Should show success state
      expect(find.text('Загрузка...'), findsNothing);
      expect(find.text('Файл criteria.pdf загружен'), findsOneWidget);
    });

    testWidgets('DocumentUploadScreen should show loading state during script upload', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'script.txt', bytes: [1, 2, 3]);
      final mockResponse = createMockUploadResponse();
      
      // Create a completer to delay the response
      final completer = Completer<Map<String, dynamic>>();
      
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Start upload
      await tester.tap(find.text('Выбрать файл').last);
      await tester.pump(); // This should show loading state

      // Assert - Should show loading state for script upload
      expect(find.text('Загрузка...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // Complete the upload
      completer.complete(mockResponse);
      await tester.pumpAndSettle();
    });

    // UI State Tests
    testWidgets('DocumentUploadScreen should show success indicators after upload', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'test.pdf', bytes: [1, 2, 3]);
      final mockResponse = createMockUploadResponse();

      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Upload criteria document
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
      expect(find.text('Файл test.pdf загружен'), findsOneWidget);
    });

    testWidgets('DocumentUploadScreen should show script upload in progress indicator', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'script.txt', bytes: [1, 2, 3]);
      final mockResponse = createMockUploadResponse();
      final mockAnalysis = createMockAnalysisResult();

      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      when(() => mockApiService.analyzeScript(
        any(),
        criteriaDocumentId: anyNamed('criteriaDocumentId'),
      )).thenAnswer((_) async => mockAnalysis);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - First upload criteria
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Then upload script
      await tester.tap(find.text('Выбрать файл').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.play_circle), findsAtLeastNWidgets(1));
      expect(find.text('Сценарий script.txt отправлен на анализ'), findsOneWidget);
    });

    // Navigation Tests
    testWidgets('DocumentUploadScreen should navigate back when back button is pressed', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'test.pdf', bytes: [1, 2, 3]);
      final mockResponse = createMockUploadResponse();

      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Upload a file first
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Act - Navigate back (since we don't have a router in this test, it will pop the screen)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert - Screen should be dismissed (finder won't find the screen content)
      expect(find.text('Загрузка документов'), findsNothing);
    });

    // Tips Section Tests
    testWidgets('DocumentUploadScreen should render tips section correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Подсказки'), findsOneWidget);
      expect(find.textContaining('Сначала загрузите нормативный документ'), findsOneWidget);
      expect(find.textContaining('Можно переиспользовать ранее загруженный регламент'), findsOneWidget);
      expect(find.textContaining('Поддерживаются документы на русском языке'), findsOneWidget);
    });

    // Edge Cases Tests
    testWidgets('DocumentUploadScreen should handle multiple rapid uploads gracefully', (WidgetTester tester) async {
      // Arrange
      final mockFile = createMockFile(name: 'test.pdf', bytes: [1, 2, 3]);
      final mockResponse = createMockUploadResponse();

      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap both upload buttons rapidly
      await tester.tap(find.text('Выбрать файл').first);
      await tester.tap(find.text('Выбрать файл').last);
      await tester.pumpAndSettle();

      // Assert - Should handle both uploads
      expect(find.text('Файл test.pdf загружен'), findsOneWidget);
      verify(() => mockApiService.uploadDocument(
        'test.pdf',
        any(),
        documentType: anyNamed('documentType'),
      )).called(greaterThan(0));
    });

    testWidgets('DocumentUploadScreen should clear errors on new upload attempt', (WidgetTester tester) async {
      // Arrange - First upload fails
      final mockFile = createMockFile(name: 'test.pdf', bytes: [1, 2, 3]);

      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenThrow(Exception('Upload failed'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // First upload fails
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Ошибка загрузки'), findsOneWidget);

      // Reset mock to succeed
      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => createMockUploadResponse());

      // Second upload succeeds
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // Assert - Error should be cleared
      expect(find.textContaining('Ошибка загрузки'), findsNothing);
      expect(find.text('Файл test.pdf загружен'), findsOneWidget);
    });

    // File Type and Size Validation Tests
    testWidgets('DocumentUploadScreen should validate file extensions', (WidgetTester tester) async {
      // The FilePicker is configured with allowedExtensions: ['pdf', 'docx', 'txt']
      // This test verifies the configuration is passed correctly
      
      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true,
      )).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      // File picker should be called with correct parameters
      verify(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true,
      )).called(1);
    });

    // Accessibility Tests
    testWidgets('DocumentUploadScreen should have proper semantic labels', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.bySemanticsLabel('Загрузка документов'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    // Performance Tests
    testWidgets('DocumentUploadScreen should handle large file upload efficiently', (WidgetTester tester) async {
      // Arrange - Create a mock large file (simulate 1MB)
      final largeBytes = List.generate(1024 * 1024, (index) => index % 256);
      final mockFile = createMockFile(name: 'large.pdf', bytes: largeBytes);
      final mockResponse = createMockUploadResponse();

      when(() => FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: anyNamed('allowedExtensions'),
        withData: true,
      )).thenAnswer((_) async => FilePickerResult([mockFile]));

      when(() => mockApiService.uploadDocument(
        any(),
        any(),
        documentType: anyNamed('documentType'),
      )).thenAnswer((_) async => mockResponse);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Выбрать файл').first);
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Assert - Should complete upload processing efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(find.text('Файл large.pdf загружен'), findsOneWidget);
    });
  });
}

