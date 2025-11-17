// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rag_processing_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RagProcessingDetails _$RagProcessingDetailsFromJson(
  Map<String, dynamic> json,
) => RagProcessingDetails(
  totalChunks: (json['totalChunks'] as num).toInt(),
  chunksProcessed: (json['chunksProcessed'] as num).toInt(),
  embeddingGenerationStatus: json['embeddingGenerationStatus'] as String,
  embeddingModelUsed: json['embeddingModelUsed'] as String?,
  vectorDbIndexingStatus: json['vectorDbIndexingStatus'] as String,
  documentsIndexed: (json['documentsIndexed'] as num).toInt(),
  indexingTimeMs: (json['indexingTimeMs'] as num?)?.toDouble(),
  processingErrors: (json['processingErrors'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$RagProcessingDetailsToJson(
  RagProcessingDetails instance,
) => <String, dynamic>{
  'totalChunks': instance.totalChunks,
  'chunksProcessed': instance.chunksProcessed,
  'embeddingGenerationStatus': instance.embeddingGenerationStatus,
  'embeddingModelUsed': instance.embeddingModelUsed,
  'vectorDbIndexingStatus': instance.vectorDbIndexingStatus,
  'documentsIndexed': instance.documentsIndexed,
  'indexingTimeMs': instance.indexingTimeMs,
  'processingErrors': instance.processingErrors,
};
