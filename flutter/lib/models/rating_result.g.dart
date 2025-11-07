// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingResult _$RatingResultFromJson(Map<String, dynamic> json) => RatingResult(
  finalRating: $enumDecode(_$AgeRatingEnumMap, json['final_rating']),
  targetRating: $enumDecodeNullable(_$AgeRatingEnumMap, json['target_rating']),
  confidenceScore: (json['confidence_score'] as num).toDouble(),
  problemScenesCount: (json['problem_scenes_count'] as num).toInt(),
  categoriesSummary: (json['categories_summary'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      $enumDecode(_$CategoryEnumMap, k),
      $enumDecode(_$SeverityEnumMap, e),
    ),
  ),
);

Map<String, dynamic> _$RatingResultToJson(RatingResult instance) =>
    <String, dynamic>{
      'final_rating': _$AgeRatingEnumMap[instance.finalRating]!,
      'target_rating': _$AgeRatingEnumMap[instance.targetRating],
      'confidence_score': instance.confidenceScore,
      'problem_scenes_count': instance.problemScenesCount,
      'categories_summary': instance.categoriesSummary.map(
        (k, e) => MapEntry(_$CategoryEnumMap[k]!, _$SeverityEnumMap[e]!),
      ),
    };

const _$AgeRatingEnumMap = {
  AgeRating.zeroPlus: '0+',
  AgeRating.sixPlus: '6+',
  AgeRating.twelvePlus: '12+',
  AgeRating.sixteenPlus: '16+',
  AgeRating.eighteenPlus: '18+',
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
