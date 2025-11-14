import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/age_rating.dart';

void main() {
  group('AgeRating JSON Serialization Test', () {
    test('should properly serialize age rating enum to string', () {
      // Test that enum values serialize to the expected strings
      expect(AgeRating.zeroPlus.displayName, '0+');
      expect(AgeRating.sixPlus.displayName, '6+');
      expect(AgeRating.twelvePlus.displayName, '12+');
      expect(AgeRating.sixteenPlus.displayName, '16+');
      expect(AgeRating.eighteenPlus.displayName, '18+');
    });

    test('should properly deserialize string to age rating enum', () {
      // Test that strings from Python API properly deserialize to enums
      final zeroPlus = AgeRating.fromString('0+');
      final sixPlus = AgeRating.fromString('6+');
      final twelvePlus = AgeRating.fromString('12+');
      final sixteenPlus = AgeRating.fromString('16+');
      final eighteenPlus = AgeRating.fromString('18+');

      expect(zeroPlus, isA<AgeRating>());
      expect(zeroPlus, AgeRating.zeroPlus);
      
      expect(sixPlus, isA<AgeRating>());
      expect(sixPlus, AgeRating.sixPlus);
      
      expect(twelvePlus, isA<AgeRating>());
      expect(twelvePlus, AgeRating.twelvePlus);
      
      expect(sixteenPlus, isA<AgeRating>());
      expect(sixteenPlus, AgeRating.sixteenPlus);
      
      expect(eighteenPlus, isA<AgeRating>());
      expect(eighteenPlus, AgeRating.eighteenPlus);
    });

    test('should return null for invalid age rating strings', () {
      // Test that invalid strings return null
      final invalidPlus = AgeRating.fromString('0+plus');
      final invalidFormat = AgeRating.fromString('0+0');
      final nullValue = AgeRating.fromString(null);
      final emptyValue = AgeRating.fromString('');

      expect(invalidPlus, isNull);
      expect(invalidFormat, isNull);
      expect(nullValue, isNull);
      expect(emptyValue, isNull);
    });

    test('should validate age rating strings correctly', () {
      // Test validation methods
      expect(AgeRating.isValid('0+'), true);
      expect(AgeRating.isValid('6+'), true);
      expect(AgeRating.isValid('12+'), true);
      expect(AgeRating.isValid('16+'), true);
      expect(AgeRating.isValid('18+'), true);
      
      expect(AgeRating.isValid('0+0'), false);
      expect(AgeRating.isValid('3+'), false);
      expect(AgeRating.isValid('invalid'), false);
      expect(AgeRating.isValid(''), false);
      // Test that null returns false by checking null safety
      expect(AgeRating.fromString(null), isNull);
    });

    test('should return all valid age rating values', () {
      final validValues = AgeRating.validValues;
      expect(validValues, ['0+', '6+', '12+', '16+', '18+']);
    });

    test('should display correct values for UI', () {
      // Test that the display property works correctly
      expect(AgeRating.zeroPlus.display, '0+');
      expect(AgeRating.sixPlus.display, '6+');
      expect(AgeRating.twelvePlus.display, '12+');
      expect(AgeRating.sixteenPlus.display, '16+');
      expect(AgeRating.eighteenPlus.display, '18+');
    });
  });
}