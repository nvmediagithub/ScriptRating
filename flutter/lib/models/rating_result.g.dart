// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingResult _$RatingResultFromJson(Map<String, dynamic> json) => RatingResult(
  finalRating: $enumDecode(_$AgeRatingEnumMap, json['finalRating']),
  confidenceScore: (json['confidenceScore'] as num).toDouble(),
  problemScenesCount: (json['problemScenesCount'] as num).toInt(),
  categoriesSummary: (json['categoriesSummary'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      $enumDecode(_$CategoryEnumMap, k),
      $enumDecode(_$SeverityEnumMap, e),
    ),
  ),
);

Map<String, dynamic> _$RatingResultToJson(RatingResult instance) =>
    <String, dynamic>{
      'finalRating': _$AgeRatingEnumMap[instance.finalRating]!,
      'confidenceScore': instance.confidenceScore,
      'problemScenesCount': instance.problemScenesCount,
      'categoriesSummary': instance.categoriesSummary.map(
        (k, e) => MapEntry(_$CategoryEnumMap[k]!, _$SeverityEnumMap[e]!),
      ),
    };

const _$AgeRatingEnumMap = {
  AgeRating.zeroPlus: 'zeroPlus',
  AgeRating.sixPlus: 'sixPlus',
  AgeRating.twelvePlus: 'twelvePlus',
  AgeRating.sixteenPlus: 'sixteenPlus',
  AgeRating.eighteenPlus: 'eighteenPlus',
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
