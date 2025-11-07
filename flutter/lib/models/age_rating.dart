import 'package:json_annotation/json_annotation.dart';

part 'age_rating.g.dart';

@JsonEnum(alwaysCreate: true)
enum AgeRating {
  @JsonValue('0+') zeroPlus('0+'),
  @JsonValue('6+') sixPlus('6+'),
  @JsonValue('12+') twelvePlus('12+'),
  @JsonValue('16+') sixteenPlus('16+'),
  @JsonValue('18+') eighteenPlus('18+');
  
  const AgeRating(this.displayName);
  final String displayName;
  
  /// Helper method to get the display name
  String get display => displayName;
  
  /// Safe parsing method to convert string to AgeRating enum
  /// Returns null if the string is not a valid age rating
  static AgeRating? fromString(String? ratingString) {
    if (ratingString == null) return null;
    
    for (final rating in AgeRating.values) {
      if (rating.displayName == ratingString) {
        return rating;
      }
    }
    
    // Log a warning for invalid values to help with debugging
    print('Warning: Invalid age rating value: $ratingString. '
        'Expected values: ${AgeRating.values.map((r) => r.displayName).join(', ')}');
    
    return null;
  }
  
  /// Get all valid age rating values as strings
  static List<String> get validValues => AgeRating.values.map((r) => r.displayName).toList();
  
  /// Check if a string represents a valid age rating
  static bool isValid(String ratingString) {
    return validValues.contains(ratingString);
  }
}
