import 'package:flutter/material.dart';

class ErrorEntry {
  final String timestamp;
  final String serviceName;
  final String error;
  final String? details;
  final bool resolved;

  ErrorEntry({
    required this.timestamp,
    required this.serviceName,
    required this.error,
    this.details,
    this.resolved = false,
  });

  factory ErrorEntry.fromJson(Map<String, dynamic> json) {
    return ErrorEntry(
      timestamp: json['timestamp'] ?? '',
      serviceName: json['service_name'] ?? '',
      error: json['error'] ?? '',
      details: json['details'],
      resolved: json['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'service_name': serviceName,
      'error': error,
      'details': details,
      'resolved': resolved,
    };
  }

  String get formattedTime {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return timestamp;
    }
  }
}

class ErrorHistory {
  final List<ErrorEntry> errors;
  final int totalErrors;
  final int resolvedErrors;

  ErrorHistory({
    required this.errors,
    required this.totalErrors,
    required this.resolvedErrors,
  });

  factory ErrorHistory.fromJson(Map<String, dynamic> json) {
    return ErrorHistory(
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => ErrorEntry.fromJson(e))
          .toList() ?? [],
      totalErrors: json['total_errors'] ?? 0,
      resolvedErrors: json['resolved_errors'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'errors': errors.map((e) => e.toJson()).toList(),
      'total_errors': totalErrors,
      'resolved_errors': resolvedErrors,
    };
  }

  List<ErrorEntry> get activeErrors => errors.where((e) => !e.resolved).toList();
  List<ErrorEntry> get resolvedErrorsList => errors.where((e) => e.resolved).toList();
}