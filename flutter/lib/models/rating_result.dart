import 'package:json_annotation/json_annotation.dart';
import 'category.dart';
import 'severity.dart';
import 'age_rating.dart';

part 'rating_result.g.dart';

@JsonSerializable()
class RatingResult {
  final AgeRating finalRating;
  final double confidenceScore;
  final int problemScenesCount;
  final Map<Category, Severity> categoriesSummary;

  RatingResult({
    required this.finalRating,
    required this.confidenceScore,
    required this.problemScenesCount,
    required this.categoriesSummary,
  });

  factory RatingResult.fromJson(Map<String, dynamic> json) =>
      _$RatingResultFromJson(json);
  Map<String, dynamic> toJson() => _$RatingResultToJson(this);
}
