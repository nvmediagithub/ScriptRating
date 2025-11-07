// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) =>
    AnalysisResult(
      analysisId: json['analysis_id'] as String,
      documentId: json['document_id'] as String,
      status: json['status'] as String,
      ratingResult: RatingResult.fromJson(
        json['rating_result'] as Map<String, dynamic>,
      ),
      sceneAssessments: (json['scene_assessments'] as List<dynamic>)
          .map((e) => SceneAssessment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AnalysisResultToJson(AnalysisResult instance) =>
    <String, dynamic>{
      'analysis_id': instance.analysisId,
      'document_id': instance.documentId,
      'status': instance.status,
      'rating_result': instance.ratingResult,
      'scene_assessments': instance.sceneAssessments,
      'created_at': instance.createdAt.toIso8601String(),
      'recommendations': instance.recommendations,
    };
