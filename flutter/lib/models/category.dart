import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonEnum(alwaysCreate: true)
enum Category {
  @JsonValue('violence') violence('violence'),
  @JsonValue('sexual_content') sexualContent('sexual_content'),
  @JsonValue('language') language('language'),
  @JsonValue('alcohol_drugs') alcoholDrugs('alcohol_drugs'),
  @JsonValue('disturbing_scenes') disturbingScenes('disturbing_scenes');

  const Category(this.value);
  final String value;

  /// Convert to JSON representation for API calls
  String toJson() => value;

  /// Create from JSON representation
  static Category fromJson(String json) {
    return Category.values.firstWhere(
      (category) => category.value == json,
      orElse: () => throw ArgumentError('Invalid category: $json'),
    );
  }
}
