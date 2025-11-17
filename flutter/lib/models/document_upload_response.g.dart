// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_upload_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentUploadResponse _$DocumentUploadResponseFromJson(
  Map<String, dynamic> json,
) => DocumentUploadResponse(
  documentId: json['documentId'] as String,
  filename: json['filename'] as String,
  uploadedAt: DateTime.parse(json['uploadedAt'] as String),
  documentType: $enumDecode(_$DocumentTypeEnumMap, json['documentType']),
  chunksIndexed: (json['chunksIndexed'] as num?)?.toInt(),
  ragProcessingDetails: json['ragProcessingDetails'] == null
      ? null
      : RagProcessingDetails.fromJson(
          json['ragProcessingDetails'] as Map<String, dynamic>,
        ),
  status: json['status'] as String,
);

Map<String, dynamic> _$DocumentUploadResponseToJson(
  DocumentUploadResponse instance,
) => <String, dynamic>{
  'documentId': instance.documentId,
  'filename': instance.filename,
  'uploadedAt': instance.uploadedAt.toIso8601String(),
  'documentType': _$DocumentTypeEnumMap[instance.documentType]!,
  'chunksIndexed': instance.chunksIndexed,
  'ragProcessingDetails': instance.ragProcessingDetails,
  'status': instance.status,
};

const _$DocumentTypeEnumMap = {
  DocumentType.script: 'script',
  DocumentType.criteria: 'criteria',
};
