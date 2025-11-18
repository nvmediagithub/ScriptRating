// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rag_processing_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RagProcessingDetails _$RagProcessingDetailsFromJson(
  Map<String, dynamic> json,
) => RagProcessingDetails(
  totalChunks: (json['total_chunks'] as num).toInt(),
  chunksProcessed: (json['chunks_processed'] as num).toInt(),
  embeddingGenerationStatus: json['embedding_generation_status'] as String?,
  embeddingModelUsed: json['embedding_model_used'] as String?,
  vectorDbIndexingStatus: json['vector_db_indexing_status'] as String?,
  documentsIndexed: (json['documents_indexed'] as num).toInt(),
  indexingTimeMs: (json['indexing_time_ms'] as num?)?.toDouble(),
  processingErrors: (json['processing_errors'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$RagProcessingDetailsToJson(
  RagProcessingDetails instance,
) => <String, dynamic>{
  'total_chunks': instance.totalChunks,
  'chunks_processed': instance.chunksProcessed,
  'embedding_generation_status': instance.embeddingGenerationStatus,
  'embedding_model_used': instance.embeddingModelUsed,
  'vector_db_indexing_status': instance.vectorDbIndexingStatus,
  'documents_indexed': instance.documentsIndexed,
  'indexing_time_ms': instance.indexingTimeMs,
  'processing_errors': instance.processingErrors,
};
