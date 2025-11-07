import 'llm_provider.dart';

class LLMProviderSettings {
  final LLMProvider provider;
  final String? apiKey;
  final String? baseUrl;
  final int timeout;
  final int maxRetries;

  const LLMProviderSettings({
    required this.provider,
    this.apiKey,
    this.baseUrl,
    this.timeout = 30,
    this.maxRetries = 3,
  });

  factory LLMProviderSettings.fromJson(Map<String, dynamic> json) {
    return LLMProviderSettings(
      provider: LLMProvider.fromString(json['provider'] as String),
      apiKey: json['api_key'] as String?,
      baseUrl: json['base_url'] as String?,
      timeout: json['timeout'] as int? ?? 30,
      maxRetries: json['max_retries'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.value,
    if (apiKey != null) 'api_key': apiKey,
    if (baseUrl != null) 'base_url': baseUrl,
    'timeout': timeout,
    'max_retries': maxRetries,
  };

  @override
  String toString() {
    return 'LLMProviderSettings(provider: ${provider.value}, hasApiKey: ${apiKey != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMProviderSettings &&
        other.provider == provider &&
        other.apiKey == apiKey &&
        other.baseUrl == baseUrl &&
        other.timeout == timeout &&
        other.maxRetries == maxRetries;
  }

  @override
  int get hashCode {
    return Object.hash(provider, apiKey, baseUrl, timeout, maxRetries);
  }

  /// Create a sanitized version without sensitive data
  LLMProviderSettings sanitized() {
    return LLMProviderSettings(
      provider: provider,
      apiKey: apiKey != null ? 'configured' : null,
      baseUrl: baseUrl,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }
}
