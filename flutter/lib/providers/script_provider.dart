import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/script.dart';
import '../services/api_service.dart';
import '../core/locator.dart';

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return locator<ApiService>();
});

// Provider for scripts list
final scriptsProvider = StateNotifierProvider<ScriptsNotifier, AsyncValue<List<Script>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ScriptsNotifier(apiService);
});

// Provider for current script
final scriptProvider = StateNotifierProvider.family<ScriptNotifier, AsyncValue<Script?>, String>((ref, scriptId) {
  final apiService = ref.watch(apiServiceProvider);
  return ScriptNotifier(apiService, scriptId);
});

class ScriptsNotifier extends StateNotifier<AsyncValue<List<Script>>> {
  final ApiService _apiService;

  ScriptsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadScripts();
  }

  Future<void> loadScripts() async {
    state = const AsyncValue.loading();
    try {
      final scripts = await _apiService.getScripts();
      state = AsyncValue.data(scripts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadScripts();
  }
}

class ScriptNotifier extends StateNotifier<AsyncValue<Script?>> {
  final ApiService _apiService;
  final String _scriptId;

  ScriptNotifier(this._apiService, this._scriptId) : super(const AsyncValue.loading()) {
    loadScript();
  }

  Future<void> loadScript() async {
    state = const AsyncValue.loading();
    try {
      final script = await _apiService.getScript(_scriptId);
      state = AsyncValue.data(script);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadScript();
  }
}