import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:script_rating_app/services/api_service.dart';
import 'package:script_rating_app/models/script.dart';
import 'package:script_rating_app/models/analysis_result.dart';
import 'package:script_rating_app/models/analysis_status.dart';
import 'package:script_rating_app/models/document_type.dart';
import 'test_utils.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      apiService = ApiService(mockDio);
    });

    group('Constructor Tests', () {
      test('should initialize with correct base URL and headers', () {
        final dio = Dio();
        final service = ApiService(dio);
        
        expect(dio.options.baseUrl, 'http://localhost:8000/api/v1');
        expect(dio.options.headers['Content-Type'], 'application/json');
        expect(dio.options.connectTimeout, const Duration(seconds: 30));
        expect(dio.options.receiveTimeout, const Duration(seconds: 30));
      });

      test('should preserve existing base URL if provided', () {
        final dio = Dio();
        dio.options.baseUrl = 'https://custom-api.example.com/api/v2';
        
        final service = ApiService(dio);
        
        expect(dio.options.baseUrl, 'https://custom-api.example.com/api/v2');
      });
    });

    group('getScript Tests', () {
      const scriptId = 'test-script-id';

      test('should successfully fetch script by ID', () async {
        // Arrange
        final scriptJson = TestDataGenerator.createValidScriptJson(
          id: scriptId,
          title: 'Test Script',
        );
        final response = MockResponseFactory.createSuccessResponse(scriptJson);
        
        when(() => mockDio.get('/scripts/$scriptId')).thenAnswer((_) async => response);

        // Act
        final result = await apiService.getScript(scriptId);

        // Assert
        expect(result, isA<Script>());
        expect(result.id, scriptId);
        expect(result.title, 'Test Script');
        verify(() => mockDio.get('/scripts/$scriptId')).called(1);
      });

      test('should handle network timeout', () async {
        // Arrange
        when(() => mockDio.get('/scripts/$scriptId'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/scripts/$scriptId'),
              type: DioExceptionType.connectionTimeout,
              message: 'Connection timeout',
            ));

        // Act & Assert
        expect(
          () => apiService.getScript(scriptId),
          throwsA(isA<Exception>()),
        );
        verify(() => mockDio.get('/scripts/$scriptId')).called(1);
      });

      test('should handle HTTP 404 Not Found', () async {
        // Arrange
        when(() => mockDio.get('/scripts/$scriptId')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 404,
            message: 'Script not found',
          ),
        );

        // Act & Assert
        expect(
          () => apiService.getScript(scriptId),
          throwsA(CustomMatchers.throwsApiExceptionWithMessage('Failed to load script')),
        );
        verify(() => mockDio.get('/scripts/$scriptId')).called(1);
      });

      test('should handle malformed JSON response', () async {
        // Arrange
        final malformedResponse = MockResponseFactory.createSuccessResponse({
          'id': scriptId,
          'title': 'Test Script',
          // Missing required fields
        });
        
        when(() => mockDio.get('/scripts/$scriptId')).thenAnswer((_) async => malformedResponse);

        // Act & Assert
        expect(
          () => apiService.getScript(scriptId),
          throwsA(isA<Exception>()),
        );
        verify(() => mockDio.get('/scripts/$scriptId')).called(1);
      });
    });

    group('getScripts Tests', () {
      test('should successfully fetch all scripts', () async {
        // Arrange
        final scriptsJson = [
          TestDataGenerator.createValidScriptJson(id: 'script-1', title: 'Script 1'),
          TestDataGenerator.createValidScriptJson(id: 'script-2', title: 'Script 2'),
          TestDataGenerator.createValidScriptJson(id: 'script-3', title: 'Script 3'),
        ];
        final response = MockResponseFactory.createSuccessListResponse(scriptsJson);
        
        when(() => mockDio.get('/scripts')).thenAnswer((_) async => response);

        // Act
        final result = await apiService.getScripts();

        // Assert
        expect(result, isA<List<Script>>());
        expect(result.length, 3);
        expect(result[0].id, 'script-1');
        expect(result[1].title, 'Script 2');
        expect(result[2].title, 'Script 3');
        verify(() => mockDio.get('/scripts')).called(1);
      });

      test('should handle empty scripts list', () async {
        // Arrange
        final emptyResponse = MockResponseFactory.createSuccessListResponse([]);
        when(() => mockDio.get('/scripts')).thenAnswer((_) async => emptyResponse);

        // Act
        final result = await apiService.getScripts();

        // Assert
        expect(result, isA<List<Script>>());
        expect(result, isEmpty);
        verify(() => mockDio.get('/scripts')).called(1);
      });

      test('should handle server error when fetching scripts', () async {
        // Arrange
        when(() => mockDio.get('/scripts')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 503,
            message: 'Service unavailable',
          ),
        );

        // Act & Assert
        expect(
          () => apiService.getScripts(),
          throwsA(CustomMatchers.throwsApiExceptionWithMessage('Failed to load scripts')),
        );
        verify(() => mockDio.get('/scripts')).called(1);
      });
    });

    group('uploadDocument Tests', () {
      final testBytes = [72, 101, 108, 108, 111]; // "Hello" in bytes
      const testFilename = 'test-document.pdf';
      const testDocumentId = 'uploaded-doc-123';

      test('should successfully upload document', () async {
        // Arrange
        final uploadResponse = {
          'document_id': testDocumentId,
          'filename': testFilename,
          'status': 'uploaded',
        };
        final response = MockResponseFactory.createSuccessResponse(uploadResponse);
        
        when(() => mockDio.post('/documents/upload', data: any(named: 'data')))
            .thenAnswer((_) async => response);

        // Act
        final result = await apiService.uploadDocument(testFilename, testBytes);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['document_id'], testDocumentId);
        expect(result['filename'], testFilename);
        verify(() => mockDio.post('/documents/upload', data: any(named: 'data'))).called(1);
      });

      test('should handle file too large error', () async {
        // Arrange
        when(() => mockDio.post('/documents/upload', data: any(named: 'data')))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 413,
                message: 'File too large',
              ),
            );

        // Act & Assert
        expect(
          () => apiService.uploadDocument(testFilename, testBytes),
          throwsA(CustomMatchers.throwsApiExceptionWithMessage('Failed to upload document')),
        );
        verify(() => mockDio.post('/documents/upload', data: any(named: 'data'))).called(1);
      });
    });

    group('analyzeScript Tests', () {
      const documentId = 'test-document-id';
      const criteriaDocumentId = 'criteria-doc-id';
      const targetRating = '12+';
      const analysisId = 'analysis-result-123';

      test('should successfully start analysis', () async {
        // Arrange
        final analysisJson = TestDataGenerator.createValidAnalysisResultJson(
          analysisId: analysisId,
          documentId: documentId,
        );
        final response = MockResponseFactory.createSuccessResponse(analysisJson);
        
        when(() => mockDio.post('/analysis/analyze', data: any(named: 'data')))
            .thenAnswer((_) async => response);

        // Act
        final result = await apiService.analyzeScript(
          documentId,
          criteriaDocumentId: criteriaDocumentId,
          targetRating: targetRating,
        );

        // Assert
        expect(result, isA<AnalysisResult>());
        expect(result.analysisId, analysisId);
        expect(result.documentId, documentId);
        verify(() => mockDio.post('/analysis/analyze', data: any(named: 'data'))).called(1);
      });

      test('should handle service unavailable during analysis', () async {
        // Arrange
        when(() => mockDio.post('/analysis/analyze', data: any(named: 'data')))
            .thenThrow(
              ErrorScenarios.createDioException(
                statusCode: 503,
                message: 'Service temporarily unavailable',
              ),
            );

        // Act & Assert
        expect(
          () => apiService.analyzeScript(documentId),
          throwsA(CustomMatchers.throwsApiExceptionWithMessage('Failed to start analysis')),
        );
        verify(() => mockDio.post('/analysis/analyze', data: any(named: 'data'))).called(1);
      });
    });

    group('getAnalysisStatus Tests', () {
      const analysisId = 'test-analysis-id';

      test('should successfully get analysis status', () async {
        // Arrange
        final statusJson = TestDataGenerator.createValidAnalysisStatusJson(
          analysisId: analysisId,
          status: 'in_progress',
          progress: 75.0,
        );
        final response = MockResponseFactory.createSuccessResponse(statusJson);
        
        when(() => mockDio.get('/analysis/status/$analysisId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await apiService.getAnalysisStatus(analysisId);

        // Assert
        expect(result, isA<AnalysisStatus>());
        expect(result.analysisId, analysisId);
        expect(result.status, 'in_progress');
        expect(result.progress, 75.0);
        verify(() => mockDio.get('/analysis/status/$analysisId')).called(1);
      });

      test('should handle analysis not found', () async {
        // Arrange
        when(() => mockDio.get('/analysis/status/$analysisId')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 404,
            message: 'Analysis not found',
          ),
        );

        // Act & Assert
        expect(
          () => apiService.getAnalysisStatus(analysisId),
          throwsA(CustomMatchers.throwsApiExceptionWithMessage('Failed to get analysis status')),
        );
        verify(() => mockDio.get('/analysis/status/$analysisId')).called(1);
      });

      test('should handle different status values', () async {
        // Arrange
        const statusValues = ['pending', 'in_progress', 'completed', 'failed'];
        
        for (final status in statusValues) {
          final statusJson = TestDataGenerator.createValidAnalysisStatusJson(
            analysisId: '$analysisId-$status',
            status: status,
          );
          final response = MockResponseFactory.createSuccessResponse(statusJson);
          
          when(() => mockDio.get('/analysis/status/$analysisId-$status'))
              .thenAnswer((_) async => response);

          // Act
          final result = await apiService.getAnalysisStatus('$analysisId-$status');

          // Assert
          expect(result.status, status);
        }
      });
    });

    group('getAnalysisResult Tests', () {
      const analysisId = 'test-analysis-id';
      const resultId = 'result-123';

      test('should successfully get analysis result', () async {
        // Arrange
        final resultJson = TestDataGenerator.createValidAnalysisResultJson(
          analysisId: resultId,
          documentId: 'doc-123',
          status: 'completed',
        );
        final response = MockResponseFactory.createSuccessResponse(resultJson);
        
        when(() => mockDio.get('/analysis/$analysisId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await apiService.getAnalysisResult(analysisId);

        // Assert
        expect(result, isA<AnalysisResult>());
        expect(result.analysisId, resultId);
        expect(result.status, 'completed');
        verify(() => mockDio.get('/analysis/$analysisId')).called(1);
      });

      test('should handle analysis not completed yet', () async {
        // Arrange
        when(() => mockDio.get('/analysis/$analysisId')).thenThrow(
          ErrorScenarios.createDioException(
            statusCode: 409,
            message: 'Analysis not yet completed',
          ),
        );

        // Act & Assert
        expect(
          () => apiService.getAnalysisResult(analysisId),
          throwsA(CustomMatchers.throwsApiExceptionWithMessage('Failed to load analysis result')),
        );
        verify(() => mockDio.get('/analysis/$analysisId')).called(1);
      });
    });

    group('Integration Tests', () {
      test('should handle complete analysis workflow', () async {
        // Arrange - Upload document
        const documentId = 'doc-workflow-123';
        final uploadResponse = {
          'document_id': documentId,
          'filename': 'test-script.pdf',
          'status': 'uploaded',
        };
        when(() => mockDio.post('/documents/upload', data: any(named: 'data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(uploadResponse));

        // Arrange - Start analysis
        const analysisId = 'analysis-workflow-123';
        final analysisResponse = TestDataGenerator.createValidAnalysisResultJson(
          analysisId: analysisId,
          documentId: documentId,
        );
        when(() => mockDio.post('/analysis/analyze', data: any(named: 'data')))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(analysisResponse));

        // Arrange - Check status
        final statusResponse = TestDataGenerator.createValidAnalysisStatusJson(
          analysisId: analysisId,
          status: 'completed',
          progress: 100.0,
        );
        when(() => mockDio.get('/analysis/status/$analysisId'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(statusResponse));

        // Arrange - Get result
        when(() => mockDio.get('/analysis/$analysisId'))
            .thenAnswer((_) async => MockResponseFactory.createSuccessResponse(analysisResponse));

        // Act - Execute workflow
        final uploadResult = await apiService.uploadDocument('test-script.pdf', [72, 101, 108, 108, 111]);
        final analysisResult = await apiService.analyzeScript(documentId);
        final statusResult = await apiService.getAnalysisStatus(analysisId);
        final finalResult = await apiService.getAnalysisResult(analysisId);

        // Assert
        expect(uploadResult['document_id'], documentId);
        expect(analysisResult.analysisId, analysisId);
        expect(statusResult.status, 'completed');
        expect(finalResult.analysisId, analysisId);
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle very long script content', () async {
        // Arrange
        final longContent = 'A' * 100000; // Very long content
        final scriptJson = TestDataGenerator.createValidScriptJson(
          content: longContent,
        );
        final response = MockResponseFactory.createSuccessResponse(scriptJson);
        
        when(() => mockDio.get('/scripts/test-id'))
            .thenAnswer((_) async => response);

        // Act
        final result = await apiService.getScript('test-id');

        // Assert
        expect(result.content.length, 100000);
        verify(() => mockDio.get('/scripts/test-id')).called(1);
      });

      test('should handle rapid sequential requests', () async {
        // Arrange
        final scriptJson = TestDataGenerator.createValidScriptJson();
        final response = MockResponseFactory.createSuccessResponse(scriptJson);
        when(() => mockDio.get('/scripts/test-id')).thenAnswer((_) async => response);

        // Act - Multiple rapid requests
        final futures = List.generate(5, (_) => apiService.getScript('test-id'));
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, 5);
        verify(() => mockDio.get('/scripts/test-id')).called(5);
      });

      test('should handle request cancellation', () async {
        // Arrange
        when(() => mockDio.get('/scripts/test-id')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/scripts/test-id'),
            type: DioExceptionType.cancel,
            message: 'Request cancelled',
          ),
        );

        // Act & Assert
        expect(
          () => apiService.getScript('test-id'),
          throwsA(isA<Exception>()),
        );
        verify(() => mockDio.get('/scripts/test-id')).called(1);
      });
    });

    group('Performance Tests', () {
      test('should handle concurrent requests efficiently', () async {
        // Arrange
        final scriptJson = TestDataGenerator.createValidScriptJson();
        final response = MockResponseFactory.createSuccessResponse(scriptJson);
        when(() => mockDio.get('/scripts/test-id')).thenAnswer((_) async => response);

        // Act - Concurrent requests
        final stopwatch = Stopwatch()..start();
        final results = await Future.wait([
          apiService.getScript('test-id'),
          apiService.getScript('test-id'),
          apiService.getScript('test-id'),
        ]);
        stopwatch.stop();

        // Assert
        expect(results.length, 3);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete quickly with mocks
        verify(() => mockDio.get('/scripts/test-id')).called(3);
      });
    });
  });
}

