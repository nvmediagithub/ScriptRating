import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/rating_result.dart';
import 'package:script_rating_app/models/category.dart';
import 'package:script_rating_app/models/severity.dart';
import 'package:script_rating_app/models/age_rating.dart';

void main() {
  group('RatingResult Model Tests', () {
    // Valid test data
    final validCategoriesSummary = {
      Category.violence: Severity.mild,
      Category.sexualContent: Severity.moderate,
      Category.language: Severity.severe,
    };

    const validRatingResultJson = {
      'finalRating': '16+',
      'confidence_score': 0.87,
      'problem_scenes_count': 5,
      'categories_summary': {
        'violence': 'mild',
        'sexual_content': 'moderate',
        'language': 'severe',
      },
    };

    const minimalRatingResultJson = {
      'finalRating': '0+',
      'confidence_score': 0.0,
      'problem_scenes_count': 0,
      'categories_summary': {},
    };

    const complexRatingResultJson = {
      'finalRating': '18+',
      'confidence_score': 0.99,
      'problem_scenes_count': 25,
      'categories_summary': {
        'violence': 'severe',
        'sexual_content': 'severe',
        'language': 'severe',
        'alcohol_drugs': 'moderate',
        'disturbing_scenes': 'severe',
      },
    };

    group('RatingResult Constructor Tests', () {
      test('should create rating result with all parameters', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.sixteenPlus,
          confidenceScore: 0.85,
          problemScenesCount: 3,
          categoriesSummary: validCategoriesSummary,
        );

        expect(ratingResult.finalRating, AgeRating.sixteenPlus);
        expect(ratingResult.confidenceScore, 0.85);
        expect(ratingResult.problemScenesCount, 3);
        expect(ratingResult.categoriesSummary, validCategoriesSummary);
      });

      test('should create rating result with minimal parameters', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 0.0,
          problemScenesCount: 0,
          categoriesSummary: {},
        );

        expect(ratingResult.finalRating, AgeRating.zeroPlus);
        expect(ratingResult.confidenceScore, 0.0);
        expect(ratingResult.problemScenesCount, 0);
        expect(ratingResult.categoriesSummary, isEmpty);
      });

      test('should handle all age rating types', () {
        final ageRatings = [
          AgeRating.zeroPlus,
          AgeRating.sixPlus,
          AgeRating.twelvePlus,
          AgeRating.sixteenPlus,
          AgeRating.eighteenPlus,
        ];

        for (final rating in ageRatings) {
          final ratingResult = RatingResult(
            finalRating: rating,
            confidenceScore: 0.5,
            problemScenesCount: 1,
            categoriesSummary: {Category.violence: Severity.none},
          );

          expect(ratingResult.finalRating, rating);
          expect(ratingResult.finalRating.value, isA<String>());
        }
      });

      test('should handle all severity types in categories', () {
        final allSeverities = [
          Severity.none,
          Severity.mild,
          Severity.moderate,
          Severity.severe,
        ];

        final categoriesWithAllSeverities = {
          Category.violence: Severity.none,
          Category.sexualContent: Severity.mild,
          Category.language: Severity.moderate,
          Category.alcoholDrugs: Severity.severe,
          Category.disturbingScenes: Severity.none,
        };

        final ratingResult = RatingResult(
          finalRating: AgeRating.twelvePlus,
          confidenceScore: 0.75,
          problemScenesCount: 2,
          categoriesSummary: categoriesWithAllSeverities,
        );

        expect(ratingResult.categoriesSummary.length, 5);
        expect(ratingResult.categoriesSummary[Category.violence], Severity.none);
        expect(ratingResult.categoriesSummary[Category.sexualContent], Severity.mild);
        expect(ratingResult.categoriesSummary[Category.language], Severity.moderate);
        expect(ratingResult.categoriesSummary[Category.alcoholDrugs], Severity.severe);
      });

      test('should handle empty categories summary', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 1.0,
          problemScenesCount: 0,
          categoriesSummary: {},
        );

        expect(ratingResult.categoriesSummary, isEmpty);
      });

      test('should handle large problem scenes count', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.eighteenPlus,
          confidenceScore: 0.95,
          problemScenesCount: 999,
          categoriesSummary: {Category.violence: Severity.severe},
        );

        expect(ratingResult.problemScenesCount, 999);
      });
    });

    group('RatingResult.fromJson Tests', () {
      test('should create rating result from valid JSON', () {
        final ratingResult = RatingResult.fromJson(validRatingResultJson);

        expect(ratingResult.finalRating, AgeRating.sixteenPlus);
        expect(ratingResult.confidenceScore, 0.87);
        expect(ratingResult.problemScenesCount, 5);
        expect(ratingResult.categoriesSummary, isA<Map<Category, Severity>>());
        expect(ratingResult.categoriesSummary.length, 3);
        expect(ratingResult.categoriesSummary[Category.violence], Severity.mild);
        expect(ratingResult.categoriesSummary[Category.sexualContent], Severity.moderate);
        expect(ratingResult.categoriesSummary[Category.language], Severity.severe);
      });

      test('should create rating result from minimal JSON', () {
        final ratingResult = RatingResult.fromJson(minimalRatingResultJson);

        expect(ratingResult.finalRating, AgeRating.zeroPlus);
        expect(ratingResult.confidenceScore, 0.0);
        expect(ratingResult.problemScenesCount, 0);
        expect(ratingResult.categoriesSummary, isEmpty);
      });

      test('should handle complex JSON with all categories', () {
        final ratingResult = RatingResult.fromJson(complexRatingResultJson);

        expect(ratingResult.finalRating, AgeRating.eighteenPlus);
        expect(ratingResult.confidenceScore, 0.99);
        expect(ratingResult.problemScenesCount, 25);
        expect(ratingResult.categoriesSummary.length, 5);
        expect(ratingResult.categoriesSummary[Category.violence], Severity.severe);
        expect(ratingResult.categoriesSummary[Category.sexualContent], Severity.severe);
        expect(ratingResult.categoriesSummary[Category.language], Severity.severe);
        expect(ratingResult.categoriesSummary[Category.alcoholDrugs], Severity.moderate);
        expect(ratingResult.categoriesSummary[Category.disturbingScenes], Severity.severe);
      });

      test('should handle different confidence score ranges', () {
        const confidenceScores = [0.0, 0.25, 0.5, 0.75, 0.99, 1.0];
        
        for (final score in confidenceScores) {
          final json = Map<String, dynamic>.from(minimalRatingResultJson);
          json['confidence_score'] = score;
          
          final ratingResult = RatingResult.fromJson(json);
          expect(ratingResult.confidenceScore, score);
        }
      });

      test('should handle different problem scenes counts', () {
        const problemScenesCounts = [0, 1, 5, 10, 100, 1000];
        
        for (final count in problemScenesCounts) {
          final json = Map<String, dynamic>.from(minimalRatingResultJson);
          json['problem_scenes_count'] = count;
          
          final ratingResult = RatingResult.fromJson(json);
          expect(ratingResult.problemScenesCount, count);
        }
      });

      test('should throw exception for missing required fields', () {
        expect(() => RatingResult.fromJson({}), throwsA(isA<TypeError>()));
        expect(() => RatingResult.fromJson({'finalRating': '0+'}), throwsA(isA<TypeError>()));
        expect(() => RatingResult.fromJson({'confidence_score': 0.5}), throwsA(isA<TypeError>()));
        expect(() => RatingResult.fromJson({'problem_scenes_count': 1}), throwsA(isA<TypeError>()));
        expect(() => RatingResult.fromJson({'categories_summary': {}}), throwsA(isA<TypeError>()));
      });

      test('should handle case-sensitive enum values', () {
        // Test valid enum values
        final validJson = Map<String, dynamic>.from(validRatingResultJson);
        final ratingResult = RatingResult.fromJson(validJson);
        expect(ratingResult.finalRating, isA<AgeRating>());
        expect(ratingResult.finalRating.value, '16+');
      });

      test('should handle multiple categories in JSON', () {
        final multiCategoryJson = {
          'finalRating': '12+',
          'confidence_score': 0.7,
          'problem_scenes_count': 8,
          'categories_summary': {
            'violence': 'mild',
            'sexual_content': 'none',
            'language': 'moderate',
            'alcohol_drugs': 'mild',
            'disturbing_scenes': 'none',
          },
        };

        final ratingResult = RatingResult.fromJson(multiCategoryJson);
        
        expect(ratingResult.categoriesSummary.length, 5);
        expect(ratingResult.categoriesSummary[Category.violence], Severity.mild);
        expect(ratingResult.categoriesSummary[Category.sexualContent], Severity.none);
        expect(ratingResult.categoriesSummary[Category.language], Severity.moderate);
        expect(ratingResult.categoriesSummary[Category.alcoholDrugs], Severity.mild);
        expect(ratingResult.categoriesSummary[Category.disturbingScenes], Severity.none);
      });
    });

    group('RatingResult.toJson Tests', () {
      test('should convert rating result to JSON correctly', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.twelvePlus,
          confidenceScore: 0.82,
          problemScenesCount: 7,
          categoriesSummary: {
            Category.violence: Severity.moderate,
            Category.language: Severity.mild,
          },
        );

        final json = ratingResult.toJson();
        expect(json['finalRating'], '12+');
        expect(json['confidence_score'], 0.82);
        expect(json['problem_scenes_count'], 7);
        expect(json['categories_summary'], isA<Map<String, String>>());
        expect(json['categories_summary']['violence'], 'moderate');
        expect(json['categories_summary']['language'], 'mild');
      });

      test('should handle empty categories summary in toJson', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 1.0,
          problemScenesCount: 0,
          categoriesSummary: {},
        );

        final json = ratingResult.toJson();
        expect(json['categories_summary'], isEmpty);
      });

      test('should handle single category in toJson', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.sixPlus,
          confidenceScore: 0.6,
          problemScenesCount: 1,
          categoriesSummary: {Category.violence: Severity.none},
        );

        final json = ratingResult.toJson();
        expect(json['categories_summary'], {'violence': 'none'});
      });

      test('should round trip conversion (fromJson -> toJson)', () {
        final originalRatingResult = RatingResult.fromJson(complexRatingResultJson);
        final json = originalRatingResult.toJson();
        final roundTripRatingResult = RatingResult.fromJson(json);

        expect(originalRatingResult.finalRating, roundTripRatingResult.finalRating);
        expect(originalRatingResult.confidenceScore, roundTripRatingResult.confidenceScore);
        expect(originalRatingResult.problemScenesCount, roundTripRatingResult.problemScenesCount);
        expect(originalRatingResult.categoriesSummary.length, roundTripRatingResult.categoriesSummary.length);
        
        // Check that all categories match
        for (final category in Category.values) {
          expect(
            originalRatingResult.categoriesSummary[category],
            roundTripRatingResult.categoriesSummary[category],
          );
        }
      });
    });

    group('RatingResult Edge Cases', () {
      test('should handle edge confidence score values', () {
        final zeroConfidence = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 0.0,
          problemScenesCount: 0,
          categoriesSummary: {},
        );

        final fullConfidence = RatingResult(
          finalRating: AgeRating.eighteenPlus,
          confidenceScore: 1.0,
          problemScenesCount: 10,
          categoriesSummary: {Category.violence: Severity.severe},
        );

        expect(zeroConfidence.confidenceScore, 0.0);
        expect(fullConfidence.confidenceScore, 1.0);
      });

      test('should handle zero problem scenes count', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 1.0,
          problemScenesCount: 0,
          categoriesSummary: {},
        );

        expect(ratingResult.problemScenesCount, 0);
      });

      test('should handle very high problem scenes count', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.eighteenPlus,
          confidenceScore: 0.9,
          problemScenesCount: 10000,
          categoriesSummary: {Category.violence: Severity.severe},
        );

        expect(ratingResult.problemScenesCount, 10000);
      });

      test('should handle negative confidence score', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.sixPlus,
          confidenceScore: -0.1,
          problemScenesCount: 0,
          categoriesSummary: {},
        );

        expect(ratingResult.confidenceScore, -0.1);
      });

      test('should handle confidence score greater than 1.0', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.twelvePlus,
          confidenceScore: 1.5,
          problemScenesCount: 2,
          categoriesSummary: {Category.language: Severity.mild},
        );

        expect(ratingResult.confidenceScore, 1.5);
      });

      test('should handle empty categories summary with all categories present', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 0.5,
          problemScenesCount: 0,
          categoriesSummary: {
            Category.violence: Severity.none,
            Category.sexualContent: Severity.none,
            Category.language: Severity.none,
            Category.alcoholDrugs: Severity.none,
            Category.disturbingScenes: Severity.none,
          },
        );

        expect(ratingResult.categoriesSummary.length, 5);
        expect(ratingResult.categoriesSummary[Category.violence], Severity.none);
      });

      test('should handle duplicate categories in constructor', () {
        // Note: This will overwrite duplicate keys in Dart Map
        final categoriesWithDuplicate = {
          Category.violence: Severity.mild,
          Category.violence: Severity.severe, // This will overwrite the previous one
        };

        final ratingResult = RatingResult(
          finalRating: AgeRating.twelvePlus,
          confidenceScore: 0.6,
          problemScenesCount: 1,
          categoriesSummary: categoriesWithDuplicate,
        );

        // Should only have one violence entry with the last value
        expect(ratingResult.categoriesSummary.length, 1);
        expect(ratingResult.categoriesSummary[Category.violence], Severity.severe);
      });
    });

    group('RatingResult Property Validation', () {
      test('should correctly identify property types', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.sixPlus,
          confidenceScore: 0.8,
          problemScenesCount: 5,
          categoriesSummary: {Category.language: Severity.moderate},
        );

        expect(ratingResult.finalRating, isA<AgeRating>());
        expect(ratingResult.confidenceScore, isA<double>());
        expect(ratingResult.problemScenesCount, isA<int>());
        expect(ratingResult.categoriesSummary, isA<Map<Category, Severity>>());
      });

      test('should handle enum value properties correctly', () {
        final ratingResult = RatingResult(
          finalRating: AgeRating.sixteenPlus,
          confidenceScore: 0.75,
          problemScenesCount: 3,
          categoriesSummary: {
            Category.violence: Severity.moderate,
          },
        );

        expect(ratingResult.finalRating.value, '16+');
        expect(ratingResult.categoriesSummary[Category.violence]!.value, 'moderate');
      });

      test('should verify all category values are present when specified', () {
        final completeCategories = {
          Category.violence: Severity.none,
          Category.sexualContent: Severity.none,
          Category.language: Severity.none,
          Category.alcoholDrugs: Severity.none,
          Category.disturbingScenes: Severity.none,
        };

        final ratingResult = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 1.0,
          problemScenesCount: 0,
          categoriesSummary: completeCategories,
        );

        expect(ratingResult.categoriesSummary.length, Category.values.length);
        for (final category in Category.values) {
          expect(ratingResult.categoriesSummary.containsKey(category), true);
          expect(ratingResult.categoriesSummary[category], Severity.none);
        }
      });

      test('should handle missing optional categories', () {
        final partialCategories = {
          Category.violence: Severity.mild,
          Category.language: Severity.severe,
        };

        final ratingResult = RatingResult(
          finalRating: AgeRating.twelvePlus,
          confidenceScore: 0.7,
          problemScenesCount: 2,
          categoriesSummary: partialCategories,
        );

        expect(ratingResult.categoriesSummary.length, 2);
        expect(ratingResult.categoriesSummary.containsKey(Category.sexualContent), false);
        expect(ratingResult.categoriesSummary.containsKey(Category.alcoholDrugs), false);
        expect(ratingResult.categoriesSummary.containsKey(Category.disturbingScenes), false);
      });

      test('should handle boundary values for rating', () {
        final boundaryRatings = [
          AgeRating.zeroPlus,
          AgeRating.eighteenPlus,
        ];

        for (final rating in boundaryRatings) {
          final ratingResult = RatingResult(
            finalRating: rating,
            confidenceScore: 0.5,
            problemScenesCount: 1,
            categoriesSummary: {Category.violence: Severity.none},
          );

          expect(ratingResult.finalRating, rating);
        }
      });
    });

    group('RatingResult Data Integrity', () {
      test('should maintain data consistency between enum values and JSON', () {
        final ageRatingTests = [
          (AgeRating.zeroPlus, '0+'),
          (AgeRating.sixPlus, '6+'),
          (AgeRating.twelvePlus, '12+'),
          (AgeRating.sixteenPlus, '16+'),
          (AgeRating.eighteenPlus, '18+'),
        ];

        for (final (rating, expectedValue) in ageRatingTests) {
          final ratingResult = RatingResult(
            finalRating: rating,
            confidenceScore: 0.5,
            problemScenesCount: 0,
            categoriesSummary: {},
          );

          final json = ratingResult.toJson();
          expect(json['finalRating'], expectedValue);
          
          final roundTrip = RatingResult.fromJson(json);
          expect(roundTrip.finalRating, rating);
        }
      });

      test('should maintain data consistency for severity values', () {
        final severityTests = [
          (Severity.none, 'none'),
          (Severity.mild, 'mild'),
          (Severity.moderate, 'moderate'),
          (Severity.severe, 'severe'),
        ];

        for (final (severity, expectedValue) in severityTests) {
          final ratingResult = RatingResult(
            finalRating: AgeRating.sixPlus,
            confidenceScore: 0.5,
            problemScenesCount: 1,
            categoriesSummary: {Category.violence: severity},
          );

          final json = ratingResult.toJson();
          expect(json['categories_summary']['violence'], expectedValue);
          
          final roundTrip = RatingResult.fromJson(json);
          expect(roundTrip.categoriesSummary[Category.violence], severity);
        }
      });
    });
  });
}

