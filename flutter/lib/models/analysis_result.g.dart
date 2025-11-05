// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) =>
    AnalysisResult(
      analysisId: json['analysisId'] as String,
      documentId: json['documentId'] as String,
      status: json['status'] as String,
      ratingResult: RatingResult.fromJson(
        json['ratingResult'] as Map<String, dynamic>,
      ),
      sceneAssessments: (json['sceneAssessments'] as List<dynamic>)
          .map((e) => SceneAssessment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AnalysisResultToJson(AnalysisResult instance) =>
    <String, dynamic>{
      'analysisId': instance.analysisId,
      'documentId': instance.documentId,
      'status': instance.status,
      'ratingResult': instance.ratingResult,
      'sceneAssessments': instance.sceneAssessments,
      'createdAt': instance.createdAt.toIso8601String(),
      'recommendations': instance.recommendations,
    };
