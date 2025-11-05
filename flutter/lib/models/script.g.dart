// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Script _$ScriptFromJson(Map<String, dynamic> json) => Script(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  author: json['author'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  rating: (json['rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ScriptToJson(Script instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'author': instance.author,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'rating': instance.rating,
};
