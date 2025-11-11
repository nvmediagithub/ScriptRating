import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locator.dart';
import '../services/llm_service.dart';

final llmServiceProvider = Provider<LlmService>((ref) {
  return locator<LlmService>();
});

// Simplified state using Map instead of complex models
class SimplifiedDashboardState {
  final Map<String, dynamic> config;
  final List<Map<String, dynamic>> statuses;
  final Map<String, dynamic> localModels;
  final Map<String, dynamic> openRouterStatus;
  final Map<String, dynamic> openRouterModels;
  final Map<String, dynamic> healthSummary;
  final Map<String, dynamic> configurationSettings;
  final bool isRefreshing;

  const SimplifiedDashboardState({
    required this.config,
    required this.statuses,
    required this.localModels,
    required this.openRouterStatus,
    required this.openRouterModels,
    required this.healthSummary,
    required this.configurationSettings,
    this.isRefreshing = false,
  });

  SimplifiedDashboardState copyWith({
    Map<String, dynamic>? config,
    List<Map<String, dynamic>>? statuses,
    Map<String, dynamic>? localModels,
    Map<String, dynamic>? openRouterStatus,
    Map<String, dynamic>? openRouterModels,
    Map<String, dynamic>? healthSummary,
    Map<String, dynamic>? configurationSettings,
    bool? isRefreshing,
  }) {
    return SimplifiedDashboardState(
      config: config ?? this.config,
      statuses: statuses ?? this.statuses,
      localModels: localModels ?? this.localModels,
      openRouterStatus: openRouterStatus ?? this.openRouterStatus,
      openRouterModels: openRouterModels ?? this.openRouterModels,
      healthSummary: healthSummary ?? this.healthSummary,
      configurationSettings: configurationSettings ?? this.configurationSettings,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final llmDashboardProvider =
    StateNotifierProvider<LlmDashboardNotifier, AsyncValue<SimplifiedDashboardState>>((ref) {
      final service = ref.watch(llmServiceProvider);
      return LlmDashboardNotifier(service);
    });

class LlmDashboardNotifier extends StateNotifier<AsyncValue<SimplifiedDashboardState>> {
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

  Future<SimplifiedDashboardState> _fetchState() async {
    final config = await _service.getConfig();
    final statuses = await _service.getStatuses();
    final localModels = await _service.getLocalModels();
    final openRouterStatus = await _service.getOpenRouterStatus();
    final openRouterModels = await _service.getOpenRouterModels();
    final healthSummary = await _service.getHealthSummary();
    final configurationSettings = _getDefaultConfigurationSettings();

    return SimplifiedDashboardState(
      config: config,
      statuses: statuses,
      localModels: localModels,
      openRouterStatus: openRouterStatus,
      openRouterModels: openRouterModels,
      healthSummary: healthSummary,
      configurationSettings: configurationSettings,
      isRefreshing: false,
    );
  }

  // Simplified provider management for just two modes
  Future<void> switchActiveProvider(String provider) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(isRefreshing: true));
    }

    try {
      await _service.setActiveProvider(provider);

      // Verify the switch was successful
      final newConfig = await _service.getConfig();
      if (newConfig['active_provider'] != provider) {
        throw Exception('Provider switch failed');
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

  Future<bool> testProviderConnection(String provider) async {
    try {
      return await _service.testConnection(provider);
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getUsageStats({String? timeRange}) async {
    try {
      return await _service.getSystemUsageStats(timeRange: timeRange);
    } catch (e) {
      return _getDefaultUsageStats();
    }
  }

  Future<Map<String, Map<String, dynamic>>> getProviderStatusMap() async {
    try {
      final statuses = await _service.getAllProvidersStatus();
      final statusMap = <String, Map<String, dynamic>>{};
      for (final status in statuses) {
        statusMap[status['provider'] as String] = status;
      }
      return statusMap;
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
      'default_model': 'llama2:7b',
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
