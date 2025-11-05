import 'package:json_annotation/json_annotation.dart';
import 'scene_assessment.dart';
import 'rating_result.dart';

part 'analysis_result.g.dart';

@JsonSerializable()
class AnalysisResult {
  final String analysisId;
  final String documentId;
  final String status;
  final RatingResult ratingResult;
  final List<SceneAssessment> sceneAssessments;
  final DateTime createdAt;
  final List<String>? recommendations;

  AnalysisResult({
    required this.analysisId,
    required this.documentId,
    required this.status,
    required this.ratingResult,
    required this.sceneAssessments,
    required this.createdAt,
    this.recommendations,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => _$AnalysisResultFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);
}