class AnalysisStatus {
  final double progress;
  final String status;
  final dynamic ratingResult;
  final List<String>? recommendations;
  final List<dynamic> processedBlocks;
  final String? errors;

  const AnalysisStatus({
    required this.progress,
    required this.status,
    this.ratingResult,
    this.recommendations,
    required this.processedBlocks,
    this.errors,
  });

  factory AnalysisStatus.fromJson(Map<String, dynamic> json) {
    return AnalysisStatus(
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      ratingResult: json['rating_result'],
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : null,
      processedBlocks: json['processed_blocks'] != null
          ? List<dynamic>.from(json['processed_blocks'])
          : [],
      errors: json['errors'] as String?,
    );
  }
}
