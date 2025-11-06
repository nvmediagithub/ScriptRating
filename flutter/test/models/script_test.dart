import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/script.dart';

void main() {
  group('Script Model Tests', () {
    // Valid script data for testing
    const validScriptJson = {
      'id': 'script-123',
      'title': 'Test Script',
      'content': 'This is a test script content.',
      'author': 'John Doe',
      'created_at': '2023-01-01T00:00:00.000Z',
      'updatedAt': '2023-01-02T00:00:00.000Z',
      'rating': 4.5,
    };

    // Script with minimal required data
    const minimalScriptJson = {
      'id': 'minimal-456',
      'title': 'Minimal Script',
      'content': 'Minimal content',
    };

    // Script with null optional values
    const scriptWithNullsJson = {
      'id': 'null-script-789',
      'title': 'Null Script',
      'content': 'Content with nulls',
      'author': null,
      'created_at': null,
      'updatedAt': null,
      'rating': null,
    };

    group('Script Constructor Tests', () {
      test('should create script with all required parameters', () {
        final script = Script(
          id: 'test-id',
          title: 'Test Title',
          content: 'Test Content',
          author: 'Test Author',
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
          rating: 4.5,
        );

        expect(script.id, 'test-id');
        expect(script.title, 'Test Title');
        expect(script.content, 'Test Content');
        expect(script.author, 'Test Author');
        expect(script.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
        expect(script.updatedAt, DateTime.parse('2023-01-02T00:00:00.000Z'));
        expect(script.rating, 4.5);
      });

      test('should create script with minimal required parameters', () {
        final script = Script(
          id: 'minimal-id',
          title: 'Minimal Title',
          content: 'Minimal Content',
        );

        expect(script.id, 'minimal-id');
        expect(script.title, 'Minimal Title');
        expect(script.content, 'Minimal Content');
        expect(script.author, null);
        expect(script.createdAt, null);
        expect(script.updatedAt, null);
        expect(script.rating, null);
      });

      test('should handle null values correctly', () {
        final script = Script(
          id: 'null-test',
          title: 'Null Test',
          content: 'Content',
          author: null,
          createdAt: null,
          updatedAt: null,
          rating: null,
        );

        expect(script.author, null);
        expect(script.createdAt, null);
        expect(script.updatedAt, null);
        expect(script.rating, null);
      });
    });

    group('Script.fromJson Tests', () {
      test('should create script from valid JSON', () {
        final script = Script.fromJson(validScriptJson);

        expect(script.id, 'script-123');
        expect(script.title, 'Test Script');
        expect(script.content, 'This is a test script content.');
        expect(script.author, 'John Doe');
        expect(script.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
        expect(script.updatedAt, DateTime.parse('2023-01-02T00:00:00.000Z'));
        expect(script.rating, 4.5);
      });

      test('should create script from minimal JSON', () {
        final script = Script.fromJson(minimalScriptJson);

        expect(script.id, 'minimal-456');
        expect(script.title, 'Minimal Script');
        expect(script.content, 'Minimal content');
        expect(script.author, null);
        expect(script.createdAt, null);
        expect(script.updatedAt, null);
        expect(script.rating, null);
      });

      test('should handle null values in JSON', () {
        final script = Script.fromJson(scriptWithNullsJson);

        expect(script.id, 'null-script-789');
        expect(script.title, 'Null Script');
        expect(script.content, 'Content with nulls');
        expect(script.author, null);
        expect(script.createdAt, null);
        expect(script.updatedAt, null);
        expect(script.rating, null);
      });

      test('should throw exception for missing required fields', () {
        expect(() => Script.fromJson({}), throwsA(isA<TypeError>()));
        expect(() => Script.fromJson({'title': 'Only Title'}), throwsA(isA<TypeError>()));
        expect(() => Script.fromJson({'id': 'Only ID'}), throwsA(isA<TypeError>()));
        expect(() => Script.fromJson({'content': 'Only Content'}), throwsA(isA<TypeError>()));
      });

      test('should handle different data types correctly', () {
        // Test with integer ID (should be converted to string)
        final scriptWithIntId = Script.fromJson({
          'id': 123,
          'title': 'Int ID Test',
          'content': 'Content',
        });
        expect(scriptWithIntId.id, '123');

        // Test with double rating
        final scriptWithDoubleRating = Script.fromJson({
          'id': 'test-double',
          'title': 'Double Rating Test',
          'content': 'Content',
          'rating': 4.0,
        });
        expect(scriptWithDoubleRating.rating, 4.0);
      });
    });

    group('Script.toJson Tests', () {
      test('should convert script to JSON correctly', () {
        final script = Script(
          id: 'json-test',
          title: 'JSON Test Title',
          content: 'JSON Test Content',
          author: 'JSON Test Author',
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
          rating: 4.5,
        );

        final json = script.toJson();
        expect(json['id'], 'json-test');
        expect(json['title'], 'JSON Test Title');
        expect(json['content'], 'JSON Test Content');
        expect(json['author'], 'JSON Test Author');
        expect(json['created_at'], '2023-01-01T00:00:00.000Z');
        expect(json['updatedAt'], '2023-01-02T00:00:00.000Z');
        expect(json['rating'], 4.5);
      });

      test('should handle null values in toJson', () {
        final script = Script(
          id: 'null-json-test',
          title: 'Null JSON Test',
          content: 'Content',
          author: null,
          createdAt: null,
          updatedAt: null,
          rating: null,
        );

        final json = script.toJson();
        expect(json['author'], null);
        expect(json['created_at'], null);
        expect(json['updatedAt'], null);
        expect(json['rating'], null);
      });

      test('should round trip conversion (fromJson -> toJson)', () {
        final originalScript = Script.fromJson(validScriptJson);
        final json = originalScript.toJson();
        final roundTripScript = Script.fromJson(json);

        expect(originalScript.id, roundTripScript.id);
        expect(originalScript.title, roundTripScript.title);
        expect(originalScript.content, roundTripScript.content);
        expect(originalScript.author, roundTripScript.author);
        expect(originalScript.createdAt, roundTripScript.createdAt);
        expect(originalScript.updatedAt, roundTripScript.updatedAt);
        expect(originalScript.rating, roundTripScript.rating);
      });
    });

    group('Script Edge Cases', () {
      test('should handle empty strings', () {
        final script = Script(
          id: '',
          title: '',
          content: '',
        );

        expect(script.id, isEmpty);
        expect(script.title, isEmpty);
        expect(script.content, isEmpty);
      });

      test('should handle very long strings', () {
        final longString = 'x' * 10000;
        final script = Script(
          id: longString,
          title: longString,
          content: longString,
        );

        expect(script.id.length, 10000);
        expect(script.title.length, 10000);
        expect(script.content.length, 10000);
      });

      test('should handle special characters in strings', () {
        final specialChars = 'Special: !@#$%^&*()_+{}|:<>?[]\\;\'",./~`';
        final script = Script(
          id: 'special-id',
          title: specialChars,
          content: specialChars,
          author: specialChars,
        );

        expect(script.title, specialChars);
        expect(script.content, specialChars);
        expect(script.author, specialChars);
      });

      test('should handle edge rating values', () {
        final scriptWithZeroRating = Script(
          id: 'zero-rating',
          title: 'Zero Rating',
          content: 'Content',
          rating: 0.0,
        );

        final scriptWithMaxRating = Script(
          id: 'max-rating',
          title: 'Max Rating',
          content: 'Content',
          rating: 10.0,
        );

        final scriptWithNegativeRating = Script(
          id: 'negative-rating',
          title: 'Negative Rating',
          content: 'Content',
          rating: -1.0,
        );

        expect(scriptWithZeroRating.rating, 0.0);
        expect(scriptWithMaxRating.rating, 10.0);
        expect(scriptWithNegativeRating.rating, -1.0);
      });

      test('should handle different DateTime formats', () {
        final scriptWithDifferentDateFormat = Script.fromJson({
          'id': 'date-test',
          'title': 'Date Test',
          'content': 'Content',
          'created_at': '2023-01-01T12:30:45.123Z',
          'updatedAt': '2023-12-31T23:59:59.999Z',
        });

        expect(scriptWithDifferentDateFormat.createdAt, 
               DateTime.parse('2023-01-01T12:30:45.123Z'));
        expect(scriptWithDifferentDateFormat.updatedAt, 
               DateTime.parse('2023-12-31T23:59:59.999Z'));
      });
    });

    group('Script Property Validation', () {
      test('should correctly identify script properties', () {
        final script = Script(
          id: 'property-test',
          title: 'Property Test',
          content: 'Content',
          author: 'Author',
        );

        expect(script.id, isA<String>());
        expect(script.title, isA<String>());
        expect(script.content, isA<String>());
        expect(script.author, isA<String?>());
        expect(script.createdAt, isA<DateTime?>());
        expect(script.updatedAt, isA<DateTime?>());
        expect(script.rating, isA<double?>());
      });

      test('should handle boundary conditions for strings', () {
        // Test with Unicode characters
        final unicodeScript = Script(
          id: 'unicode-🚀',
          title: 'Unicode Title 🎬',
          content: 'Content with emojis 🎭 and special chars: αβγ',
        );

        expect(unicodeScript.id, contains('🚀'));
        expect(unicodeScript.title, contains('🎬'));
        expect(unicodeScript.content, contains('🎭'));
      });
    });
  });
}

