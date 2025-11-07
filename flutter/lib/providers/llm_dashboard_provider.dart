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
    StateNotifierProvider<LlmDashboardNotifier, AsyncValue<LlmDashboardState>>((
      ref,
    ) {
      final service = ref.watch(llmServiceProvider);
      return LlmDashboardNotifier(service);
    });

class LlmDashboardNotifier
    extends StateNotifier<AsyncValue<LlmDashboardState>> {
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

  Future<void> switchActiveModel(LLMProvider provider, String modelName) async {
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
    final performanceReports = await _service.getPerformanceReports();

    return LlmDashboardState(
      config: config,
      statuses: statuses,
      localModels: localModels,
      openRouterStatus: openRouterStatus,
      openRouterModels: openRouterModels,
      healthSummary: healthSummary,
      performanceReports: performanceReports,
      isRefreshing: false,
    );
  }
}