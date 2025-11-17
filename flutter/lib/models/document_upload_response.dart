import 'package:json_annotation/json_annotation.dart';

import 'document_type.dart';
import 'rag_processing_details.dart';

part 'document_upload_response.g.dart';

@JsonSerializable()
class DocumentUploadResponse {
  final String documentId;
  final String filename;
  final DateTime uploadedAt;
  final DocumentType documentType;
  final int? chunksIndexed;
  final RagProcessingDetails? ragProcessingDetails;
  final String status;

  DocumentUploadResponse({
    required this.documentId,
    required this.filename,
    required this.uploadedAt,
    required this.documentType,
    this.chunksIndexed,
    this.ragProcessingDetails,
    required this.status,
  });

  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$DocumentUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentUploadResponseToJson(this);
}