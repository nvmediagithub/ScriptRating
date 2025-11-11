import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locator.dart';
import '../models/llm_dashboard_state.dart';
import '../models/llm_models.dart';
import '../models/llm_provider.dart';
import '../services/llm_service.dart';

final llmServiceProvider = Provider<LlmService>((ref) {
  return locator<LlmService>();
});

final llmDashboardProvider =
    StateNotifierProvider<LlmDashboardNotifier, AsyncValue<LlmDashboardState>>((ref) {
      final service = ref.watch(llmServiceProvider);
      return LlmDashboardNotifier(service);
    });

class LlmDashboardNotifier extends StateNotifier<AsyncValue<LlmDashboardState>> {
  final LlmService _service;

  LlmDashboardNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh(force: true);
  }

  Future<void> refresh({bool force = false}) async {
    final previous = state.valueOrNull;
    if (previous != null && !force) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    } else if (force) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null && !force) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> switchActiveModelToProvider(LLMProvider provider, String modelName) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      await _service.switchMode(provider, modelName);
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> loadLocalModel(String modelName) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      await _service.loadLocalModel(modelName);
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> unloadLocalModel(String modelName) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      await _service.unloadLocalModel(modelName);
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<LlmDashboardState> _fetchState() async {
    final config = await _service.getConfig();
    final statuses = await _service.getStatuses();
    final localModels = await _service.getLocalModels();
    final openRouterStatus = await _service.getOpenRouterStatus();
    final openRouterModels = await _service.getOpenRouterModels();
    final healthSummary = await _service.getHealthSummary();
    // final performanceReports = await _service.getPerformanceReports();
    final configurationSettings = await _service.getConfigurationSettings().catchError((e) {
      // Fallback to default settings if API not available
      return _getDefaultConfigurationSettings();
    });

    return LlmDashboardState(
      config: config,
      statuses: statuses,
      localModels: localModels,
      openRouterStatus: openRouterStatus,
      openRouterModels: openRouterModels,
      healthSummary: healthSummary,
      // performanceReports: performanceReports,
      configurationSettings: configurationSettings,
      isRefreshing: false,
    );
  }

  // New methods for enhanced functionality
  Future<void> switchActiveProvider(LLMProvider provider) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      await _service.setActiveProvider(provider);
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> switchActiveModel(String modelName) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      await _service.setActiveModel(modelName);
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> configureProvider(LLMProvider provider, String apiKey, String baseUrl) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      if (provider == LLMProvider.openrouter) {
        await _service.configureOpenRouter(apiKey: apiKey, baseUrl: baseUrl);
      }
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<bool> testProviderConnection(LLMProvider provider) async {
    try {
      return await _service.testProviderConnectivity(provider);
    } catch (e) {
      return false;
    }
  }

  Future<void> updateConfigurationSettings(Map<String, dynamic> settings) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      await _service.updateConfigurationSettings(settings);
      final data = await _fetchState();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue.data(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUsageStats({String? timeRange}) async {
    try {
      return await _service.getSystemUsageStats(timeRange: timeRange);
    } catch (e) {
      // Fallback to default usage stats
      return _getDefaultUsageStats();
    }
  }

  Future<Map<LLMProvider, LLMStatusResponse>> getProviderStatusMap() async {
    try {
      final statuses = await _service.getAllProvidersStatus();
      return {for (final status in statuses) status.provider: status};
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _getDefaultConfigurationSettings() {
    return {
      'auto_save': true,
      'request_timeout': 30,
      'max_retries': 3,
      'caching_enabled': true,
      'cache_duration': 24,
      'log_level': 'info',
      'auto_refresh_status': true,
      'default_provider': 'local',
      'default_model': 'default',
    };
  }

  Map<String, dynamic> _getDefaultUsageStats() {
    return {
      'total_requests': 0,
      'successful_requests': 0,
      'failed_requests': 0,
      'total_tokens_used': 0,
      'average_response_time_ms': 0.0,
      'requests_per_hour': 0,
    };
  }
}
