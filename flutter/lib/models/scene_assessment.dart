import 'package:json_annotation/json_annotation.dart';

import 'age_rating.dart';
import 'category.dart';
import 'normative_reference.dart';
import 'severity.dart';

part 'scene_assessment.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class HighlightFragment {
  final int start;
  final int end;
  final String text;
  final Category category;
  final Severity severity;

  HighlightFragment({
    required this.start,
    required this.end,
    this.text = '',
    required this.category,
    required this.severity,
  });

  factory HighlightFragment.fromJson(Map<String, dynamic> json) =>
      _$HighlightFragmentFromJson(json);
  Map<String, dynamic> toJson() => _$HighlightFragmentToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SceneAssessment {
  final int sceneNumber;
  final String heading;
  final String pageRange;
  final Map<Category, Severity> categories;
  final List<String> flaggedContent;
  final String? justification;
  final AgeRating ageRating;
  final String llmComment;
  final List<NormativeReference> references;
  final String text;
  final String? textPreview;
  final List<HighlightFragment> highlights;

  SceneAssessment({
    required this.sceneNumber,
    required this.heading,
    required this.pageRange,
    required this.categories,
    this.flaggedContent = const [],
    this.justification,
    required this.ageRating,
    required this.llmComment,
    this.references = const [],
    required this.text,
    this.textPreview,
    this.highlights = const [],
  });

  factory SceneAssessment.fromJson(Map<String, dynamic> json) =>
      _$SceneAssessmentFromJson(json);
  Map<String, dynamic> toJson() => _$SceneAssessmentToJson(this);
}
