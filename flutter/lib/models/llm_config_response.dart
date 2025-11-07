import 'llm_provider.dart';
import 'llm_provider_settings.dart';
import 'llm_model_config.dart';

class LLMConfigResponse {
  final LLMProvider activeProvider;
  final String activeModel;
  final Map<LLMProvider, LLMProviderSettings> providers;
  final Map<String, LLMModelConfig> models;

  const LLMConfigResponse({
    required this.activeProvider,
    required this.activeModel,
    required this.providers,
    required this.models,
  });

  factory LLMConfigResponse.fromJson(Map<String, dynamic> json) {
    final providers = <LLMProvider, LLMProviderSettings>{};
    json['providers'].forEach((key, value) {
      providers[LLMProvider.fromString(key)] = LLMProviderSettings.fromJson(
        Map<String, dynamic>.from(value),
      );
    });

    final models = <String, LLMModelConfig>{};
    json['models'].forEach((key, value) {
      models[key] = LLMModelConfig.fromJson(Map<String, dynamic>.from(value));
    });

    return LLMConfigResponse(
      activeProvider: LLMProvider.fromString(json['active_provider'] as String),
      activeModel: json['active_model'] as String,
      providers: providers,
      models: models,
    );
  }

  Map<String, dynamic> toJson() => {
    'active_provider': activeProvider.value,
    'active_model': activeModel,
    'providers': providers.map((key, value) => MapEntry(key.value, value.toJson())),
    'models': models.map((key, value) => MapEntry(key, value.toJson())),
  };

  @override
  String toString() {
    return 'LLMConfigResponse(activeProvider: ${activeProvider.value}, activeModel: $activeModel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMConfigResponse &&
        other.activeProvider == activeProvider &&
        other.activeModel == activeModel &&
        _mapsEqual(other.providers, providers) &&
        _mapsEqual(other.models, models);
  }

  @override
  int get hashCode {
    return Object.hash(activeProvider, activeModel, providers.length, models.length);
  }

  static bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }

  /// Get the configuration for the active provider
  LLMProviderSettings get activeProviderSettings {
    return providers[activeProvider] ?? LLMProviderSettings(provider: activeProvider);
  }

  /// Get the configuration for the active model
  LLMModelConfig get activeModelConfig {
    return models[activeModel] ?? LLMModelConfig(modelName: activeModel, provider: activeProvider);
  }

  /// Get all models for a specific provider
  List<String> getModelsByProvider(LLMProvider provider) {
    return models.entries
        .where((entry) => entry.value.provider == provider)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if a provider is available
  bool isProviderAvailable(LLMProvider provider) {
    final settings = providers[provider];
    if (settings == null) return false;

    if (provider == LLMProvider.openrouter) {
      return settings.apiKey != null && settings.apiKey!.isNotEmpty;
    }

    return true; // Local provider is always available if configured
  }
}
