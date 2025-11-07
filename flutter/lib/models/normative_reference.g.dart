// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normative_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NormativeReference _$NormativeReferenceFromJson(Map<String, dynamic> json) =>
    NormativeReference(
      documentId: json['document_id'] as String,
      title: json['title'] as String,
      page: (json['page'] as num).toInt(),
      paragraph: (json['paragraph'] as num).toInt(),
      excerpt: json['excerpt'] as String,
      score: (json['score'] as num).toDouble(),
    );

Map<String, dynamic> _$NormativeReferenceToJson(NormativeReference instance) =>
    <String, dynamic>{
      'document_id': instance.documentId,
      'title': instance.title,
      'page': instance.page,
      'paragraph': instance.paragraph,
      'excerpt': instance.excerpt,
      'score': instance.score,
    };
