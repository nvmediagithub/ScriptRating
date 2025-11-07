// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisStatus _$AnalysisStatusFromJson(Map<String, dynamic> json) =>
    AnalysisStatus(
      analysisId: json['analysis_id'] as String,
      status: json['status'] as String,
      progress: (json['progress'] as num?)?.toDouble(),
      processedBlocks: (json['processed_blocks'] as List<dynamic>?)
              ?.map((e) => SceneAssessment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      ratingResult: json['rating_result'] == null
          ? null
          : RatingResult.fromJson(json['rating_result'] as Map<String, dynamic>),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      errors: json['errors'] as String?,
    );

Map<String, dynamic> _$AnalysisStatusToJson(AnalysisStatus instance) =>
    <String, dynamic>{
      'analysis_id': instance.analysisId,
      'status': instance.status,
      'progress': instance.progress,
      'processed_blocks': instance.processedBlocks,
      'rating_result': instance.ratingResult,
      'recommendations': instance.recommendations,
      'errors': instance.errors,
    };
