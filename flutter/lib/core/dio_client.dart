import 'package:dio/dio.dart';

class DioClient {
  static Dio createDio() {
    final dio = Dio();

    // Configure interceptors
    dio.interceptors.addAll([
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        requestHeader: false,
        error: true,
      ),
    ]);

    // Configure timeouts
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    return dio;
  }
}