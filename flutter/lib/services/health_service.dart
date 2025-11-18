import 'package:dio/dio.dart';
import '../models/health_status.dart';

class HealthService {
  final Dio _dio;

  HealthService(this._dio) {
    _dio.options.baseUrl = 'http://localhost:8000/api';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  Future<HealthStatus> getBasicHealth() async {
    try {
      final response = await _dio.get('/health');
      return HealthStatus.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get basic health: $e');
    }
  }

  Future<HealthStatus> getComprehensiveHealth() async {
    try {
      final response = await _dio.get('/health/comprehensive');
      return HealthStatus.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get comprehensive health: $e');
    }
  }

  Future<Map<String, dynamic>> getQdrantHealth() async {
    try {
      final response = await _dio.get('/health/qdrant');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get Qdrant health: $e');
    }
  }

  Future<Map<String, dynamic>> getRAGHealth() async {
    try {
      final response = await _dio.get('/health/rag');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get RAG health: $e');
    }
  }
}