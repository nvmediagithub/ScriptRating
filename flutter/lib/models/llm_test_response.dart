import 'llm_provider.dart';

class LLMTestResponse {
  final String modelName;
  final LLMProvider provider;
  final String prompt;
  final String response;
  final int tokensUsed;
  final double responseTimeMs;
  final bool success;

  const LLMTestResponse({
    required this.modelName,
    required this.provider,
    required this.prompt,
    required this.response,
    required this.tokensUsed,
    required this.responseTimeMs,
    required this.success,
  });

  factory LLMTestResponse.fromJson(Map<String, dynamic> json) {
    return LLMTestResponse(
      modelName: json['model_name'] as String,
      provider: LLMProvider.fromString(json['provider'] as String),
      prompt: json['prompt'] as String,
      response: json['response'] as String,
      tokensUsed: json['tokens_used'] as int,
      responseTimeMs: (json['response_time_ms'] as num).toDouble(),
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'model_name': modelName,
    'provider': provider.value,
    'prompt': prompt,
    'response': response,
    'tokens_used': tokensUsed,
    'response_time_ms': responseTimeMs,
    'success': success,
  };

  @override
  String toString() {
    return 'LLMTestResponse(modelName: $modelName, provider: ${provider.value}, success: $success)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMTestResponse &&
        other.modelName == modelName &&
        other.provider == provider &&
        other.prompt == prompt &&
        other.response == response &&
        other.tokensUsed == tokensUsed &&
        other.responseTimeMs == responseTimeMs &&
        other.success == success;
  }

  @override
  int get hashCode {
    return Object.hash(modelName, provider, prompt, response, tokensUsed, responseTimeMs, success);
  }
}
