class OpenRouterModelsListResponse {
  final List<String> models;
  final int total;

  const OpenRouterModelsListResponse({required this.models, required this.total});

  factory OpenRouterModelsListResponse.fromJson(Map<String, dynamic> json) {
    return OpenRouterModelsListResponse(
      models: (json['models'] as List<dynamic>).cast<String>(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'models': models, 'total': total};
}

class OpenRouterCallRequest {
  final String model;
  final String prompt;
  final int maxTokens;
  final double temperature;

  const OpenRouterCallRequest({
    required this.model,
    required this.prompt,
    this.maxTokens = 100,
    this.temperature = 0.7,
  });

  factory OpenRouterCallRequest.fromJson(Map<String, dynamic> json) {
    return OpenRouterCallRequest(
      model: json['model'] as String,
      prompt: json['prompt'] as String,
      maxTokens: json['max_tokens'] as int? ?? 100,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
    );
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'prompt': prompt,
    'max_tokens': maxTokens,
    'temperature': temperature,
  };
}

class OpenRouterCallResponse {
  final String model;
  final String response;
  final int tokensUsed;
  final double cost;
  final double responseTimeMs;

  const OpenRouterCallResponse({
    required this.model,
    required this.response,
    required this.tokensUsed,
    required this.cost,
    required this.responseTimeMs,
  });

  factory OpenRouterCallResponse.fromJson(Map<String, dynamic> json) {
    return OpenRouterCallResponse(
      model: json['model'] as String,
      response: json['response'] as String,
      tokensUsed: json['tokens_used'] as int,
      cost: (json['cost'] as num).toDouble(),
      responseTimeMs: (json['response_time_ms'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'response': response,
    'tokens_used': tokensUsed,
    'cost': cost,
    'response_time_ms': responseTimeMs,
  };
}

class OpenRouterStatusResponse {
  final bool connected;
  final double? creditsRemaining;
  final int? rateLimitRemaining;
  final String? errorMessage;

  const OpenRouterStatusResponse({
    required this.connected,
    this.creditsRemaining,
    this.rateLimitRemaining,
    this.errorMessage,
  });

  factory OpenRouterStatusResponse.fromJson(Map<String, dynamic> json) {
    return OpenRouterStatusResponse(
      connected: json['connected'] as bool,
      creditsRemaining: (json['credits_remaining'] as num?)?.toDouble(),
      rateLimitRemaining: json['rate_limit_remaining'] as int?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'connected': connected,
    if (creditsRemaining != null) 'credits_remaining': creditsRemaining,
    if (rateLimitRemaining != null) 'rate_limit_remaining': rateLimitRemaining,
    if (errorMessage != null) 'error_message': errorMessage,
  };
}
