// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_assessment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HighlightFragment _$HighlightFragmentFromJson(Map<String, dynamic> json) =>
    HighlightFragment(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      text: json['text'] as String? ?? '',
      category: $enumDecode(_$CategoryEnumMap, json['category']),
      severity: $enumDecode(_$SeverityEnumMap, json['severity']),
    );

Map<String, dynamic> _$HighlightFragmentToJson(HighlightFragment instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'text': instance.text,
      'category': _$CategoryEnumMap[instance.category]!,
      'severity': _$SeverityEnumMap[instance.severity]!,
    };

const _$CategoryEnumMap = {
  Category.violence: 'violence',
  Category.sexualContent: 'sexualContent',
  Category.language: 'language',
  Category.alcoholDrugs: 'alcoholDrugs',
  Category.disturbingScenes: 'disturbingScenes',
};

const _$SeverityEnumMap = {
  Severity.none: 'none',
  Severity.mild: 'mild',
  Severity.moderate: 'moderate',
  Severity.severe: 'severe',
};

SceneAssessment _$SceneAssessmentFromJson(
  Map<String, dynamic> json,
) => SceneAssessment(
  sceneNumber: (json['scene_number'] as num).toInt(),
  heading: json['heading'] as String,
  pageRange: json['page_range'] as String,
  categories: (json['categories'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      $enumDecode(_$CategoryEnumMap, k),
      $enumDecode(_$SeverityEnumMap, e),
    ),
  ),
  flaggedContent:
      (json['flagged_content'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  justification: json['justification'] as String?,
  ageRating: $enumDecode(_$AgeRatingEnumMap, json['age_rating']),
  llmComment: json['llm_comment'] as String,
  references:
      (json['references'] as List<dynamic>?)
          ?.map((e) => NormativeReference.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  text: json['text'] as String,
  textPreview: json['text_preview'] as String?,
  highlights:
      (json['highlights'] as List<dynamic>?)
          ?.map((e) => HighlightFragment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SceneAssessmentToJson(SceneAssessment instance) =>
    <String, dynamic>{
      'scene_number': instance.sceneNumber,
      'heading': instance.heading,
      'page_range': instance.pageRange,
      'categories': instance.categories.map(
        (k, e) => MapEntry(_$CategoryEnumMap[k]!, _$SeverityEnumMap[e]!),
      ),
      'flagged_content': instance.flaggedContent,
      'justification': instance.justification,
      'age_rating': _$AgeRatingEnumMap[instance.ageRating]!,
      'llm_comment': instance.llmComment,
      'references': instance.references,
      'text': instance.text,
      'text_preview': instance.textPreview,
      'highlights': instance.highlights,
    };

const _$AgeRatingEnumMap = {
  AgeRating.zeroPlus: '0+',
  AgeRating.sixPlus: '6+',
  AgeRating.twelvePlus: '12+',
  AgeRating.sixteenPlus: '16+',
  AgeRating.eighteenPlus: '18+',
};
