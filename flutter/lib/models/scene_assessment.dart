import 'package:json_annotation/json_annotation.dart';
import 'category.dart';
import 'severity.dart';

part 'scene_assessment.g.dart';

@JsonSerializable()
class SceneAssessment {
  final int sceneNumber;
  final String heading;
  final String pageRange;
  final Map<Category, Severity> categories;
  final List<String> flaggedContent;
  final String? justification;

  SceneAssessment({
    required this.sceneNumber,
    required this.heading,
    required this.pageRange,
    required this.categories,
    this.flaggedContent = const [],
    this.justification,
  });

  factory SceneAssessment.fromJson(Map<String, dynamic> json) => _$SceneAssessmentFromJson(json);
  Map<String, dynamic> toJson() => _$SceneAssessmentToJson(this);
}