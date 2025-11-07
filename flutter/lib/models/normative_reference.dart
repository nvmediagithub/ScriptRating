import 'package:json_annotation/json_annotation.dart';

part 'normative_reference.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class NormativeReference {
  final String documentId;
  final String title;
  final int page;
  final int paragraph;
  final String excerpt;
  final double score;

  NormativeReference({
    required this.documentId,
    required this.title,
    required this.page,
    required this.paragraph,
    required this.excerpt,
    required this.score,
  });

  factory NormativeReference.fromJson(Map<String, dynamic> json) =>
      _$NormativeReferenceFromJson(json);
  Map<String, dynamic> toJson() => _$NormativeReferenceToJson(this);
}
