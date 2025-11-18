import 'package:flutter/material.dart';

class ServiceStatus {
  final String status;
  final bool available;
  final String? type;
  final Map<String, dynamic>? detailedHealth;
  final String? error;

  ServiceStatus({
    required this.status,
    required this.available,
    this.type,
    this.detailedHealth,
    this.error,
  });

  factory ServiceStatus.fromJson(Map<String, dynamic> json) {
    return ServiceStatus(
      status: json['status'] ?? 'unknown',
      available: json['available'] ?? false,
      type: json['type'],
      detailedHealth: json['detailed_health'] ?? json['detailedHealth'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'available': available,
      'type': type,
      'detailed_health': detailedHealth,
      'error': error,
    };
  }
}

class ConfigurationStatus {
  final Map<String, dynamic> rag;
  final Map<String, bool> environment;
  final String? ragError;

  ConfigurationStatus({
    required this.rag,
    required this.environment,
    this.ragError,
  });

  factory ConfigurationStatus.fromJson(Map<String, dynamic> json) {
    return ConfigurationStatus(
      rag: json['rag'] ?? {},
      environment: Map<String, bool>.from(json['environment'] ?? {}),
      ragError: json['rag_error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rag': rag,
      'environment': environment,
      'rag_error': ragError,
    };
  }
}

class HealthStatus {
  final String timestamp;
  final String overallStatus;
  final Map<String, ServiceStatus> services;
  final List<String> errors;
  final List<String> warnings;
  final ConfigurationStatus? configuration;

  HealthStatus({
    required this.timestamp,
    required this.overallStatus,
    required this.services,
    required this.errors,
    required this.warnings,
    this.configuration,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    final servicesJson = json['services'] as Map<String, dynamic>? ?? {};
    final services = servicesJson.map(
      (key, value) => MapEntry(key, ServiceStatus.fromJson(value)),
    );

    return HealthStatus(
      timestamp: json['timestamp'] ?? '',
      overallStatus: json['overall_status'] ?? 'unknown',
      services: services,
      errors: List<String>.from(json['errors'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      configuration: json['configuration'] != null
          ? ConfigurationStatus.fromJson(json['configuration'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'overall_status': overallStatus,
      'services': services.map((key, value) => MapEntry(key, value.toJson())),
      'errors': errors,
      'warnings': warnings,
      'configuration': configuration?.toJson(),
    };
  }

  bool get isHealthy => overallStatus == 'healthy';
  bool get isDegraded => overallStatus == 'degraded';
  bool get isUnhealthy => overallStatus == 'unhealthy';

  Color get statusColor {
    switch (overallStatus) {
      case 'healthy':
        return Colors.green;
      case 'degraded':
        return Colors.orange;
      case 'unhealthy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (overallStatus) {
      case 'healthy':
        return Icons.check_circle;
      case 'degraded':
        return Icons.warning;
      case 'unhealthy':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}