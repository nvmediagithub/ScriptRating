import 'llm_provider.dart';

class LLMModelConfig {
  final String modelName;
  final LLMProvider provider;
  final int contextWindow;
  final int maxTokens;
  final double temperature;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;

  const LLMModelConfig({
    required this.modelName,
    required this.provider,
    this.contextWindow = 4096,
    this.maxTokens = 2048,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
  });

  factory LLMModelConfig.fromJson(Map<String, dynamic> json) {
    return LLMModelConfig(
      modelName: json['model_name'] as String,
      provider: LLMProvider.fromString(json['provider'] as String),
      contextWindow: json['context_window'] as int? ?? 4096,
      maxTokens: json['max_tokens'] as int? ?? 2048,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (json['top_p'] as num?)?.toDouble() ?? 0.9,
      frequencyPenalty: (json['frequency_penalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (json['presence_penalty'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'model_name': modelName,
    'provider': provider.value,
    'context_window': contextWindow,
    'max_tokens': maxTokens,
    'temperature': temperature,
    'top_p': topP,
    'frequency_penalty': frequencyPenalty,
    'presence_penalty': presencePenalty,
  };

  @override
  String toString() {
    return 'LLMModelConfig(modelName: $modelName, provider: ${provider.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMModelConfig &&
        other.modelName == modelName &&
        other.provider == provider &&
        other.contextWindow == contextWindow &&
        other.maxTokens == maxTokens &&
        other.temperature == temperature &&
        other.topP == topP &&
        other.frequencyPenalty == frequencyPenalty &&
        other.presencePenalty == presencePenalty;
  }

  @override
  int get hashCode {
    return Object.hash(
      modelName,
      provider,
      contextWindow,
      maxTokens,
      temperature,
      topP,
      frequencyPenalty,
      presencePenalty,
    );
  }

  /// Create a copy with updated fields
  LLMModelConfig copyWith({
    String? modelName,
    LLMProvider? provider,
    int? contextWindow,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
  }) {
    return LLMModelConfig(
      modelName: modelName ?? this.modelName,
      provider: provider ?? this.provider,
      contextWindow: contextWindow ?? this.contextWindow,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
    );
  }
}
