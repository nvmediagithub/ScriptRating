// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_assessment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SceneAssessment _$SceneAssessmentFromJson(Map<String, dynamic> json) =>
    SceneAssessment(
      sceneNumber: (json['sceneNumber'] as num).toInt(),
      heading: json['heading'] as String,
      pageRange: json['pageRange'] as String,
      categories: (json['categories'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          $enumDecode(_$CategoryEnumMap, k),
          $enumDecode(_$SeverityEnumMap, e),
        ),
      ),
      flaggedContent:
          (json['flaggedContent'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      justification: json['justification'] as String?,
    );

Map<String, dynamic> _$SceneAssessmentToJson(SceneAssessment instance) =>
    <String, dynamic>{
      'sceneNumber': instance.sceneNumber,
      'heading': instance.heading,
      'pageRange': instance.pageRange,
      'categories': instance.categories.map(
        (k, e) => MapEntry(_$CategoryEnumMap[k]!, _$SeverityEnumMap[e]!),
      ),
      'flaggedContent': instance.flaggedContent,
      'justification': instance.justification,
    };

const _$SeverityEnumMap = {
  Severity.none: 'none',
  Severity.mild: 'mild',
  Severity.moderate: 'moderate',
  Severity.severe: 'severe',
};

const _$CategoryEnumMap = {
  Category.violence: 'violence',
  Category.sexualContent: 'sexualContent',
  Category.language: 'language',
  Category.alcoholDrugs: 'alcoholDrugs',
  Category.disturbingScenes: 'disturbingScenes',
};
