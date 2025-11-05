import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../core/dio_client.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Register Dio
  locator.registerLazySingleton<Dio>(() => DioClient.createDio());

  // Register ApiService
  locator.registerLazySingleton<ApiService>(() => ApiService(locator<Dio>()));
}