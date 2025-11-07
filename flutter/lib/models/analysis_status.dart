import 'package:json_annotation/json_annotation.dart';

import 'rating_result.dart';
import 'scene_assessment.dart';

part 'analysis_status.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AnalysisStatus {
  final String analysisId;
  final String status;
  final double? progress;
  final List<SceneAssessment> processedBlocks;
  final RatingResult? ratingResult;
  final List<String>? recommendations;
  final String? errors;

  AnalysisStatus({
    required this.analysisId,
    required this.status,
    this.progress,
    this.processedBlocks = const [],
    this.ratingResult,
    this.recommendations,
    this.errors,
  });

  factory AnalysisStatus.fromJson(Map<String, dynamic> json) =>
      _$AnalysisStatusFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisStatusToJson(this);
}
