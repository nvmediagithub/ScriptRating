import 'package:dio/dio.dart';
import '../models/script.dart';
import '../models/analysis_result.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio) {
    _dio.options.baseUrl =
        'http://localhost:8000/api/v1'; // Adjust based on your backend URL
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    // Add headers for CORS preflight
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
      return (response.data as List)
          .map((json) => Script.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load scripts: $e');
    }
  }

  Future<Map<String, dynamic>> uploadDocument(
    String filename,
    dynamic file,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file, filename: filename),
      });
      final response = await _dio.post('/documents/upload', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<AnalysisResult> analyzeScript(String documentId) async {
    try {
      final response = await _dio.post(
        '/analysis/analyze',
        data: {'document_id': documentId},
      );
      return AnalysisResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to analyze script: $e');
    }
  }

  Future<Map<String, dynamic>> getAnalysisStatus(String analysisId) async {
    try {
      final response = await _dio.get('/analysis/status/$analysisId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get analysis status: $e');
    }
  }
}
