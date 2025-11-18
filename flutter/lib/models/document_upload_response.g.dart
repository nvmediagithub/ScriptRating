// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_upload_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentUploadResponse _$DocumentUploadResponseFromJson(
  Map<String, dynamic> json,
) => DocumentUploadResponse(
  documentId: json['document_id'] as String,
  filename: json['filename'] as String,
  uploadedAt: DateTime.parse(json['uploaded_at'] as String),
  documentType: $enumDecode(_$DocumentTypeEnumMap, json['document_type']),
  chunksIndexed: (json['chunks_indexed'] as num?)?.toInt(),
  ragProcessingDetails: json['rag_processing_details'] == null
      ? null
      : RagProcessingDetails.fromJson(
          json['rag_processing_details'] as Map<String, dynamic>,
        ),
  status: json['status'] as String,
);

Map<String, dynamic> _$DocumentUploadResponseToJson(
  DocumentUploadResponse instance,
) => <String, dynamic>{
  'document_id': instance.documentId,
  'filename': instance.filename,
  'uploaded_at': instance.uploadedAt.toIso8601String(),
  'document_type': _$DocumentTypeEnumMap[instance.documentType]!,
  'chunks_indexed': instance.chunksIndexed,
  'rag_processing_details': instance.ragProcessingDetails,
  'status': instance.status,
};

const _$DocumentTypeEnumMap = {
  DocumentType.script: 'script',
  DocumentType.criteria: 'criteria',
};
