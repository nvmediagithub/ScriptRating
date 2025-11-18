import '../models/document_upload_response.dart';
import 'package:dio/dio.dart';
import '../models/analysis_result.dart';
import '../models/analysis_status.dart';
import '../models/document_type.dart';
import '../models/script.dart';

String _getMimeType(String filename) {
  final extension = filename.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'doc':
      return 'application/msword';
    case 'txt':
      return 'text/plain';
    case 'rtf':
      return 'application/rtf';
    default:
      return 'application/octet-stream';
  }
}

class ApiService {
  final Dio _dio;

  ApiService(this._dio) {
    _dio.options.baseUrl = 'http://localhost:8000/api';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  Future<Script> getScript(String scriptId) async {
    try {
      final response = await _dio.get('/scripts/$scriptId');
      return Script.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load script: $e');
    }
  }

  Future<List<Script>> getScripts() async {
    try {
      final response = await _dio.get('/scripts');
      return (response.data as List).map((json) => Script.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load scripts: $e');
    }
  }

  Future<DocumentUploadResponse> uploadDocument(
    String filename,
    List<int> bytes, {
    DocumentType documentType = DocumentType.script,
  }) async {
    try {
      final mimeType = _getMimeType(filename);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
        'filename': filename,
        'document_type': documentType.value,
      });
      final response = await _dio.post('/documents/upload', data: formData);
      return DocumentUploadResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<AnalysisResult> analyzeScript(
    String documentId, {
    String? criteriaDocumentId,
    String? targetRating,
  }) async {
    try {
      final payload = {
        'document_id': documentId,
        'criteria_document_id': criteriaDocumentId,
        'options': {
          if (targetRating != null) 'target_rating': targetRating,
          'include_recommendations': true,
          'detailed_scenes': true,
        },
      };
      final response = await _dio.post('/analysis/analyze', data: payload);
      return AnalysisResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to start analysis: $e');
    }
  }

  Future<AnalysisStatus> getAnalysisStatus(String analysisId) async {
    try {
      final response = await _dio.get('/analysis/status/$analysisId');
      return AnalysisStatus.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get analysis status: $e');
    }
  }

  Future<AnalysisResult> getAnalysisResult(String analysisId) async {
    try {
      final response = await _dio.get('/analysis/$analysisId');
      return AnalysisResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load analysis result: $e');
    }
  }

  /// Simplified per-scene rule-based analysis.
  /// Calls backend /analysis/check_scene and returns raw JSON map.
  Future<Map<String, dynamic>> checkScene({
    required String scriptId,
    required String sceneId,
    required String sceneText,
  }) async {
    try {
      final payload = {
        'script_id': scriptId,
        'scene_id': sceneId,
        'scene_text': sceneText,
      };
      final response = await _dio.post('/analysis/check_scene', data: payload);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to run scene check: $e');
    }
  }
}
