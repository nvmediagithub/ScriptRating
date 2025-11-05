import 'package:json_annotation/json_annotation.dart';

part 'script.g.dart';

@JsonSerializable()
class Script {
  final String id;
  final String title;
  final String content;
  final String? author;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? rating;

  Script({
    required this.id,
    required this.title,
    required this.content,
    this.author,
    this.createdAt,
    this.updatedAt,
    this.rating,
  });

  factory Script.fromJson(Map<String, dynamic> json) => _$ScriptFromJson(json);
  Map<String, dynamic> toJson() => _$ScriptToJson(this);
}