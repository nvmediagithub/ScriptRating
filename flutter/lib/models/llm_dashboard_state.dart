import 'package:equatable/equatable.dart';

import 'llm_models.dart';

class LlmDashboardState extends Equatable {
  final LLMConfigResponse config;
  final List<LLMStatusResponse> statuses;
  final LocalModelsListResponse localModels;
  final OpenRouterStatusResponse openRouterStatus;
  final OpenRouterModelsListResponse openRouterModels;
  final LLMHealthSummary healthSummary;
  // final List<PerformanceReportResponse> performanceReports;
  final Map<String, dynamic> configurationSettings;
  final bool isRefreshing;

  const LlmDashboardState({
    required this.config,
    required this.statuses,
    required this.localModels,
    required this.openRouterStatus,
    required this.openRouterModels,
    required this.healthSummary,
    // required this.performanceReports,
    required this.configurationSettings,
    this.isRefreshing = false,
  });

  LlmDashboardState copyWith({
    LLMConfigResponse? config,
    List<LLMStatusResponse>? statuses,
    LocalModelsListResponse? localModels,
    OpenRouterStatusResponse? openRouterStatus,
    OpenRouterModelsListResponse? openRouterModels,
    LLMHealthSummary? healthSummary,
    // List<PerformanceReportResponse>? performanceReports,
    Map<String, dynamic>? configurationSettings,
    bool? isRefreshing,
  }) {
    return LlmDashboardState(
      config: config ?? this.config,
      statuses: statuses ?? this.statuses,
      localModels: localModels ?? this.localModels,
      openRouterStatus: openRouterStatus ?? this.openRouterStatus,
      openRouterModels: openRouterModels ?? this.openRouterModels,
      healthSummary: healthSummary ?? this.healthSummary,
      // performanceReports: performanceReports ?? this.performanceReports,
      configurationSettings: configurationSettings ?? this.configurationSettings,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    config,
    statuses,
    localModels,
    openRouterStatus,
    openRouterModels,
    healthSummary,
    // performanceReports,
    configurationSettings,
    isRefreshing,
  ];
}
