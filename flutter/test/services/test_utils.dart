// Test utilities and mock data for service tests
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:script_rating_app/models/script.dart';
import 'package:script_rating_app/models/analysis_result.dart';
import 'package:script_rating_app/models/analysis_status.dart';
import 'package:script_rating_app/models/document_type.dart';
import 'package:script_rating_app/models/llm_models.dart';

// Mock Dio instance
class MockDio extends Mock implements Dio {
  final BaseOptions _options = BaseOptions();
  
  @override
  BaseOptions get options => _options;
}

// Mock Response
class MockResponse<T> extends Mock implements Response<T> {}

// Mock FormData
class MockFormData extends Mock implements FormData {}

// Mock MultipartFile
class MockMultipartFile extends Mock implements MultipartFile {}

// Test Data Generators
class TestDataGenerator {
  // Script test data
  static Map<String, dynamic> createValidScriptJson({
    String id = 'test-script-id',
    String title = 'Test Script',
    String content = 'Test script content',
    String? author = 'Test Author',
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating = 4.5,
  }) {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'rating': rating,
    };
  }

  static Script createValidScript({
    String id = 'test-script-id',
    String title = 'Test Script',
    String content = 'Test script content',
    String? author = 'Test Author',
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating = 4.5,
  }) {
    return Script(
      id: id,
      title: title,
      content: content,
      author: author,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      rating: rating,
    );
  }

  // Analysis Result test data
  static Map<String, dynamic> createValidAnalysisResultJson({
    String analysisId = 'test-analysis-id',
    String documentId = 'test-document-id',
    String status = 'completed',
  }) {
    const blockText = 'INT. ROOM - DAY. A heated argument escalates quickly with raised voices.';
    return {
      'analysis_id': analysisId,
      'document_id': documentId,
      'status': status,
      'rating_result': {
        'final_rating': '12+',
        'confidence_score': 0.85,
        'problem_scenes_count': 3,
        'categories_summary': {
          'violence': 'mild',
          'language': 'moderate',
        },
      },
      'scene_assessments': [
        {
          'scene_number': 1,
          'heading': 'Test Scene',
          'page_range': '1-10',
          'categories': {'violence': 'mild'},
          'flagged_content': ['Violence: argument escalates'],
          'age_rating': '12+',
          'llm_comment': 'Escalating confrontation detected.',
          'references': [],
          'text': blockText,
          'text_preview': blockText.substring(0, 40),
          'highlights': [
            {
              'start': 0,
              'end': 15,
              'text': blockText.substring(0, 15),
              'category': 'violence',
              'severity': 'mild',
            },
          ],
        },
      ],
      'created_at': DateTime.now().toIso8601String(),
      'recommendations': ['Test recommendation'],
    };
  }


  // Analysis Status test data
  static Map<String, dynamic> createValidAnalysisStatusJson({
    String analysisId = 'test-analysis-id',
    String status = 'in_progress',
    double? progress = 50.0,
    List<Map<String, dynamic>>? processedBlocks,
    Map<String, dynamic>? ratingResult,
    List<String>? recommendations,
    String? errors,
  }) {
    const defaultBlockText = 'Dialogue contains strong wording that may affect rating.';
    final defaultBlocks = [
      {
        'scene_number': 1,
        'heading': 'Progress Scene',
        'page_range': '1-5',
        'categories': {'language': 'moderate'},
        'flagged_content': ['Language: strong wording'],
        'age_rating': '12+',
        'llm_comment': 'Language requires attention',
        'references': [],
        'text': defaultBlockText,
        'text_preview': defaultBlockText.substring(0, 40),
        'highlights': [
          {
            'start': 0,
            'end': 8,
            'text': defaultBlockText.substring(0, 8),
            'category': 'language',
            'severity': 'moderate',
          },
        ],
      },
    ];

    final normalizedRating = ratingResult ?? {
      'final_rating': '12+',
      'confidence_score': 0.9,
      'problem_scenes_count': 1,
      'categories_summary': {'language': 'moderate'},
    };

    return {
      'analysis_id': analysisId,
      'status': status,
      if (progress != null) 'progress': progress,
      'processed_blocks': processedBlocks ?? defaultBlocks,
      'rating_result': normalizedRating,
      if (recommendations != null) 'recommendations': recommendations,
      if (errors != null) 'errors': errors,
    };
  }


  // LLM Config test data
  static Map<String, dynamic> createValidLLMConfigJson({
    String activeProvider = 'local',
    String activeModel = 'test-model',
    Map<String, dynamic>? providers,
    Map<String, dynamic>? models,
  }) {
    return {
      'active_provider': activeProvider,
      'active_model': activeModel,
      'providers': providers ?? {
        'local': {
          'provider': 'local',
          'timeout': 30,
          'max_retries': 3,
        },
      },
      'models': models ?? {
        'test-model': {
          'model_name': 'test-model',
          'provider': 'local',
          'context_window': 4096,
          'max_tokens': 2048,
          'temperature': 0.7,
        },
      },
    };
  }

  // LLM Status test data
  static Map<String, dynamic> createValidLLMStatusJson({
    String provider = 'local',
    bool available = true,
    bool healthy = true,
    double? responseTimeMs = 100.0,
    String? errorMessage,
  }) {
    return {
      'provider': provider,
      'available': available,
      'healthy': healthy,
      'lastCheckedAt': DateTime.now().toIso8601String(),
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  // Local Models test data
  static Map<String, dynamic> createValidLocalModelsJson({
    List<Map<String, dynamic>>? models,
    List<String>? loadedModels,
  }) {
    return {
      'models': models ?? [
        {
          'model_name': 'test-model',
          'size_gb': 2.5,
          'loaded': false,
          'context_window': 4096,
          'max_tokens': 2048,
        },
      ],
      'loaded_models': loadedModels ?? [],
    };
  }

  // OpenRouter Models test data
  static Map<String, dynamic> createValidOpenRouterModelsJson({
    List<String>? models,
    int total = 100,
  }) {
    return {
      'models': models ?? ['gpt-3.5-turbo', 'gpt-4', 'claude-3'],
      'total': total,
    };
  }

  // OpenRouter Status test data
  static Map<String, dynamic> createValidOpenRouterStatusJson({
    bool connected = true,
    double? creditsRemaining = 10.5,
    int? rateLimitRemaining = 100,
    String? errorMessage,
  }) {
    return {
      'connected': connected,
      if (creditsRemaining != null) 'credits_remaining': creditsRemaining,
      if (rateLimitRemaining != null) 'rate_limit_remaining': rateLimitRemaining,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  // Health Summary test data
  static Map<String, dynamic> createValidHealthSummaryJson({
    List<Map<String, dynamic>>? providersStatus,
    int localModelsLoaded = 1,
    int localModelsAvailable = 5,
    bool openRouterConnected = true,
    String activeProvider = 'local',
    String activeModel = 'test-model',
    bool systemHealthy = true,
  }) {
    return {
      'providers_status': providersStatus ?? [
        {
          'provider': 'local',
          'available': true,
          'healthy': true,
          'lastCheckedAt': DateTime.now().toIso8601String(),
        },
      ],
      'local_models_loaded': localModelsLoaded,
      'local_models_available': localModelsAvailable,
      'openrouter_connected': openRouterConnected,
      'active_provider': activeProvider,
      'active_model': activeModel,
      'system_healthy': systemHealthy,
    };
  }

  // Performance Reports test data
  static Map<String, dynamic> createValidPerformanceReportJson({
    String provider = 'local',
    Map<String, dynamic>? metrics,
    String timeRange = '24h',
    DateTime? generatedAt,
  }) {
    return {
      'provider': provider,
      'metrics': metrics ?? {
        'total_requests': 100,
        'successful_requests': 95,
        'failed_requests': 5,
        'average_response_time_ms': 150.0,
        'total_tokens_used': 5000,
        'error_rate': 0.05,
        'uptime_percentage': 99.5,
      },
      'time_range': timeRange,
      'generated_at': generatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

// Mock response creators
class MockResponseFactory {
  static Response<Map<String, dynamic>> createSuccessResponse(
    Map<String, dynamic> data, {
    int statusCode = 200,
    String statusMessage = 'OK',
  }) {
    return Response<Map<String, dynamic>>(
      data: data,
      statusCode: statusCode,
      statusMessage: statusMessage,
      requestOptions: RequestOptions(path: '/test'),
    );
  }

  static Response<List<dynamic>> createSuccessListResponse(
    List<dynamic> data, {
    int statusCode = 200,
    String statusMessage = 'OK',
  }) {
    return Response<List<dynamic>>(
      data: data,
      statusCode: statusCode,
      statusMessage: statusMessage,
      requestOptions: RequestOptions(path: '/test'),
    );
  }

  static Response<Map<String, dynamic>> createErrorResponse({
    int statusCode = 500,
    String statusMessage = 'Internal Server Error',
    Map<String, dynamic>? data,
  }) {
    return Response<Map<String, dynamic>>(
      data: data,
      statusCode: statusCode,
      statusMessage: statusMessage,
      requestOptions: RequestOptions(path: '/test'),
    );
  }
}

// Test matchers
class CustomMatchers {
  static Matcher throwsApiException() {
    return predicate<Exception>((e) => 
      e is Exception && e.toString().contains('Failed to'),
    );
  }

  static Matcher throwsApiExceptionWithMessage(String message) {
    return predicate<Exception>((e) => 
      e is Exception && e.toString().contains(message),
    );
  }

  static Matcher isValidDioError() {
    return predicate<DioException>((error) => 
      error is DioException && error.response != null,
    );
  }
}

// Error scenarios
class ErrorScenarios {
  static DioException createDioException({
    int statusCode = 500,
    String? message,
    dynamic data,
  }) {
    final response = MockResponseFactory.createErrorResponse(
      statusCode: statusCode,
      statusMessage: message ?? 'Request failed',
      data: data,
    );
    
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: response,
      type: DioExceptionType.badResponse,
      message: message ?? 'Request failed',
    );
  }

  static Exception createGenericException([String message = 'Test exception']) {
    return Exception(message);
  }
}

