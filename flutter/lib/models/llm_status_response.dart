import 'llm_provider.dart';

class LLMStatusResponse {
  final LLMProvider provider;
  final bool available;
  final bool healthy;
  final double? responseTimeMs;
  final String? errorMessage;
  final DateTime lastCheckedAt;

  const LLMStatusResponse({
    required this.provider,
    required this.available,
    required this.healthy,
    this.responseTimeMs,
    this.errorMessage,
    required this.lastCheckedAt,
  });

  factory LLMStatusResponse.fromJson(Map<String, dynamic> json) {
    return LLMStatusResponse(
      provider: LLMProvider.fromString(json['provider'] as String),
      available: json['available'] as bool,
      healthy: json['healthy'] as bool,
      responseTimeMs: (json['response_time_ms'] as num?)?.toDouble(),
      errorMessage: json['error_message'] as String?,
      lastCheckedAt: DateTime.parse(json['last_checked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.value,
    'available': available,
    'healthy': healthy,
    if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
    if (errorMessage != null) 'error_message': errorMessage,
    'last_checked_at': lastCheckedAt.toIso8601String(),
  };

  @override
  String toString() {
    return 'LLMStatusResponse(provider: ${provider.value}, available: $available, healthy: $healthy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMStatusResponse &&
        other.provider == provider &&
        other.available == available &&
        other.healthy == healthy &&
        other.responseTimeMs == responseTimeMs &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(provider, available, healthy, responseTimeMs, errorMessage);
  }

  /// Get status color for UI representation
  String get statusColor {
    if (!available) return 'red';
    if (!healthy) return 'orange';
    return 'green';
  }

  /// Get status text for UI representation
  String get statusText {
    if (!available) return 'Unavailable';
    if (!healthy) return 'Unhealthy';
    return 'Healthy';
  }
}
