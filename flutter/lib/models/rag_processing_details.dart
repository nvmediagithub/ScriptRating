import 'package:json_annotation/json_annotation.dart';

part 'rag_processing_details.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RagProcessingDetails {
  final int totalChunks;
  final int chunksProcessed;
  final String? embeddingGenerationStatus;
  @JsonKey(name: 'embedding_model_used')
  final String? embeddingModelUsed;
  final String? vectorDbIndexingStatus;
  final int documentsIndexed;
  final double? indexingTimeMs;
  final List<String>? processingErrors;

  RagProcessingDetails({
    required this.totalChunks,
    required this.chunksProcessed,
    this.embeddingGenerationStatus,
    this.embeddingModelUsed,
    this.vectorDbIndexingStatus,
    required this.documentsIndexed,
    this.indexingTimeMs,
    this.processingErrors,
  });

  factory RagProcessingDetails.fromJson(Map<String, dynamic> json) =>
      _$RagProcessingDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$RagProcessingDetailsToJson(this);

  bool get hasErrors => processingErrors != null && processingErrors!.isNotEmpty;

  String get processingTimeFormatted {
    if (indexingTimeMs == null) return 'Неизвестно';
    final seconds = (indexingTimeMs! / 1000).round();
    if (seconds < 60) {
      return '$seconds сек';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '$minutes мин $remainingSeconds сек';
    }
  }

  String get statusIcon {
    if (hasErrors) return '⚠️';
    if (embeddingGenerationStatus == 'success' &&
        vectorDbIndexingStatus == 'success') {
      return '✅';
    }
    if ((embeddingGenerationStatus == 'partial' && embeddingGenerationStatus != null) ||
        (vectorDbIndexingStatus == 'partial' && vectorDbIndexingStatus != null)) {
      return '⚠️';
    }
    return '❌';
  }

  String get statusColor {
    if (hasErrors) return 'orange';
    if (embeddingGenerationStatus == 'success' &&
        vectorDbIndexingStatus == 'success') {
      return 'green';
    }
    if ((embeddingGenerationStatus == 'partial' && embeddingGenerationStatus != null) ||
        (vectorDbIndexingStatus == 'partial' && vectorDbIndexingStatus != null)) {
      return 'orange';
    }
    return 'red';
  }
}
