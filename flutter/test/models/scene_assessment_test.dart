import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/scene_assessment.dart';
import 'package:script_rating_app/models/age_rating.dart';
import 'package:script_rating_app/models/normative_reference.dart';
import 'package:script_rating_app/models/category.dart';
import 'package:script_rating_app/models/severity.dart';

void main() {
  group('SceneAssessment Model Tests', () {
    // Valid test data
    final validCategories = {
      Category.violence: Severity.mild,
      Category.language: Severity.moderate,
      Category.sexualContent: Severity.none,
    };

    final validFlaggedContent = [
      'Violent action scene',
      'Strong language detected',
      'Inappropriate content',
    ];

    const validSceneAssessmentJson = {
      'scene_number': 5,
      'heading': 'The Final Confrontation',
      'page_range': '45-67',
      'categories': {
        'violence': 'mild',
        'language': 'moderate',
        'sexual_content': 'none',
      },
      'flagged_content': [
        'Violent action scene',
        'Strong language detected',
      ],
      'justification': 'Scene contains moderate violence and strong language',
      'age_rating': '12+',
      'llm_comment': 'AI analysis result',
      'references': [],
      'text': 'Full scene text for The Final Confrontation',
      'text_preview': 'Full scene text for The Final Confrontation',
      'highlights': [
        {
          'start': 0,
          'end': 10,
          'text': 'Full scene',
          'category': 'violence',
          'severity': 'mild',
        },
      ],
    };

    const minimalSceneAssessmentJson = {
      'scene_number': 1,
      'heading': 'Opening Scene',
      'page_range': '1-10',
      'categories': {},
      'flagged_content': [],
      'age_rating': '0+',
      'llm_comment': 'Clean scene',
      'text': 'Opening scene text content.',
      'text_preview': 'Opening scene text content.',
      'highlights': [],
    };

    const sceneAssessmentWithNullJustificationJson = {
      'scene_number': 2,
      'heading': 'Quiet Scene',
      'page_range': '11-20',
      'categories': {'violence': 'none'},
      'flagged_content': [],
      'justification': null,
      'age_rating': '6+',
      'llm_comment': 'No issues',
      'text': 'Quiet scene text content.',
      'text_preview': 'Quiet scene text content.',
      'highlights': [],
    };

    group('SceneAssessment Constructor Tests', () {
      test('should create scene assessment with all parameters', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 10,
          heading: 'Test Scene',
          pageRange: '100-120',
          categories: validCategories,
          flaggedContent: validFlaggedContent,
          justification: 'Test justification',
          ageRating: AgeRating.twelvePlus,
          llmComment: 'AI analysis comment',
          references: [],
          textPreview: 'Scene preview text',
        );

        expect(sceneAssessment.sceneNumber, 10);
        expect(sceneAssessment.heading, 'Test Scene');
        expect(sceneAssessment.pageRange, '100-120');
        expect(sceneAssessment.categories, validCategories);
        expect(sceneAssessment.flaggedContent, validFlaggedContent);
        expect(sceneAssessment.justification, 'Test justification');
        expect(sceneAssessment.ageRating, AgeRating.twelvePlus);
        expect(sceneAssessment.llmComment, 'AI analysis comment');
        expect(sceneAssessment.references, isEmpty);
        expect(sceneAssessment.textPreview, 'Scene preview text');
      });

      test('should create scene assessment with minimal required parameters', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Minimal Scene',
          pageRange: '1-5',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'No issues found',
        );

        expect(sceneAssessment.sceneNumber, 1);
        expect(sceneAssessment.heading, 'Minimal Scene');
        expect(sceneAssessment.pageRange, '1-5');
        expect(sceneAssessment.categories, isEmpty);
        expect(sceneAssessment.flaggedContent, isEmpty);
        expect(sceneAssessment.justification, null);
        expect(sceneAssessment.ageRating, AgeRating.zeroPlus);
        expect(sceneAssessment.llmComment, 'No issues found');
        expect(sceneAssessment.references, isEmpty);
        expect(sceneAssessment.textPreview, null);
      });

      test('should create scene assessment with default empty flaggedContent', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 3,
          heading: 'Default Scene',
          pageRange: '30-40',
          categories: {Category.violence: Severity.none},
          ageRating: AgeRating.sixPlus,
          llmComment: 'Clean scene',
        );

        expect(sceneAssessment.flaggedContent, isEmpty);
        expect(sceneAssessment.references, isEmpty);
      });

      test('should handle null justification correctly', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 4,
          heading: 'Null Justification Scene',
          pageRange: '41-50',
          categories: {Category.language: Severity.mild},
          justification: null,
          ageRating: AgeRating.twelvePlus,
          llmComment: 'Minor language detected',
        );

        expect(sceneAssessment.justification, null);
      });

      test('should handle all category types', () {
        final allCategories = {
          Category.violence: Severity.mild,
          Category.sexualContent: Severity.moderate,
          Category.language: Severity.severe,
          Category.alcoholDrugs: Severity.none,
          Category.disturbingScenes: Severity.mild,
        };

        final sceneAssessment = SceneAssessment(
          sceneNumber: 5,
          heading: 'All Categories Scene',
          pageRange: '51-70',
          categories: allCategories,
          ageRating: AgeRating.sixteenPlus,
          llmComment: 'Multiple categories detected',
        );

        expect(sceneAssessment.categories.length, 5);
        expect(sceneAssessment.categories[Category.violence], Severity.mild);
        expect(sceneAssessment.categories[Category.sexualContent], Severity.moderate);
        expect(sceneAssessment.categories[Category.language], Severity.severe);
        expect(sceneAssessment.categories[Category.alcoholDrugs], Severity.none);
        expect(sceneAssessment.categories[Category.disturbingScenes], Severity.mild);
      });

      test('should handle empty categories map', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 6,
          heading: 'No Issues Scene',
          pageRange: '71-80',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'No content issues detected',
        );

        expect(sceneAssessment.categories, isEmpty);
      });

      test('should handle large flaggedContent list', () {
        final largeFlaggedContent = List<String>.generate(100, (index) => 'Flagged item $index');

        final sceneAssessment = SceneAssessment(
          sceneNumber: 7,
          heading: 'Many Flags Scene',
          pageRange: '81-100',
          categories: {Category.violence: Severity.severe},
          flaggedContent: largeFlaggedContent,
          ageRating: AgeRating.eighteenPlus,
          llmComment: 'Extensive flagged content',
        );

        expect(sceneAssessment.flaggedContent.length, 100);
        expect(sceneAssessment.flaggedContent.first, 'Flagged item 0');
        expect(sceneAssessment.flaggedContent.last, 'Flagged item 99');
      });

      test('should handle single category', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 8,
          heading: 'Single Category Scene',
          pageRange: '101-110',
          categories: {Category.language: Severity.moderate},
          ageRating: AgeRating.twelvePlus,
          llmComment: 'Moderate language content',
        );

        expect(sceneAssessment.categories.length, 1);
        expect(sceneAssessment.categories.containsKey(Category.language), true);
      });

      test('should handle references parameter', () {
        final references = [
          NormativeReference(
            documentId: 'doc1',
            title: 'Content Guidelines',
            page: 10,
            paragraph: 5,
            excerpt: 'Relevant excerpt',
            score: 0.95,
          ),
        ];

        final sceneAssessment = SceneAssessment(
          sceneNumber: 9,
          heading: 'Scene with References',
          pageRange: '111-120',
          categories: {Category.violence: Severity.mild},
          ageRating: AgeRating.sixPlus,
          llmComment: 'Reference linked content',
          references: references,
        );

        expect(sceneAssessment.references.length, 1);
        expect(sceneAssessment.references.first.documentId, 'doc1');
      });

      test('should handle textPreview parameter', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 10,
          heading: 'Text Preview Scene',
          pageRange: '100-110',
          categories: {Category.language: Severity.moderate},
          ageRating: AgeRating.twelvePlus,
          llmComment: 'Language content detected',
          textPreview: 'This is a preview of the scene text content...',
        );

        expect(sceneAssessment.textPreview, 'This is a preview of the scene text content...');
      });

      test('should handle all AgeRating values', () {
        final ageRatings = [
          AgeRating.zeroPlus,
          AgeRating.sixPlus,
          AgeRating.twelvePlus,
          AgeRating.sixteenPlus,
          AgeRating.eighteenPlus,
        ];

        for (final rating in ageRatings) {
          final sceneAssessment = SceneAssessment(
            sceneNumber: 1,
            heading: 'Age Rating Scene',
            pageRange: '1-10',
            categories: {},
            ageRating: rating,
            llmComment: 'Age appropriate content',
          );

          expect(sceneAssessment.ageRating, rating);
        }
      });
    });

    group('SceneAssessment.fromJson Tests', () {
      test('should create scene assessment from valid JSON', () {
        final sceneAssessment = SceneAssessment.fromJson(validSceneAssessmentJson);

        expect(sceneAssessment.sceneNumber, 5);
        expect(sceneAssessment.heading, 'The Final Confrontation');
        expect(sceneAssessment.pageRange, '45-67');
        expect(sceneAssessment.categories, isA<Map<Category, Severity>>());
        expect(sceneAssessment.categories.length, 3);
        expect(sceneAssessment.categories[Category.violence], Severity.mild);
        expect(sceneAssessment.categories[Category.language], Severity.moderate);
        expect(sceneAssessment.categories[Category.sexualContent], Severity.none);
        expect(sceneAssessment.flaggedContent, isA<List<String>>());
        expect(sceneAssessment.flaggedContent.length, 2);
        expect(sceneAssessment.flaggedContent[0], 'Violent action scene');
        expect(sceneAssessment.flaggedContent[1], 'Strong language detected');
        expect(sceneAssessment.justification, 'Scene contains moderate violence and strong language');
        expect(sceneAssessment.ageRating, AgeRating.twelvePlus);
        expect(sceneAssessment.llmComment, 'AI analysis result');
        expect(sceneAssessment.references, isEmpty);
      });

      test('should create scene assessment from minimal JSON', () {
        final sceneAssessment = SceneAssessment.fromJson(minimalSceneAssessmentJson);

        expect(sceneAssessment.sceneNumber, 1);
        expect(sceneAssessment.heading, 'Opening Scene');
        expect(sceneAssessment.pageRange, '1-10');
        expect(sceneAssessment.categories, isEmpty);
        expect(sceneAssessment.flaggedContent, isEmpty);
        expect(sceneAssessment.justification, null);
        expect(sceneAssessment.ageRating, AgeRating.zeroPlus);
        expect(sceneAssessment.llmComment, 'Clean scene');
        expect(sceneAssessment.references, isEmpty);
      });

      test('should handle null justification in JSON', () {
        final sceneAssessment = SceneAssessment.fromJson(sceneAssessmentWithNullJustificationJson);

        expect(sceneAssessment.justification, null);
      });

      test('should handle empty flaggedContent array', () {
        final jsonWithEmptyArray = Map<String, dynamic>.from(validSceneAssessmentJson);
        jsonWithEmptyArray['flagged_content'] = [];

        final sceneAssessment = SceneAssessment.fromJson(jsonWithEmptyArray);

        expect(sceneAssessment.flaggedContent, isEmpty);
      });

      test('should handle single flaggedContent item', () {
        final jsonWithSingleItem = Map<String, dynamic>.from(validSceneAssessmentJson);
        jsonWithSingleItem['flagged_content'] = ['Single flagged item'];

        final sceneAssessment = SceneAssessment.fromJson(jsonWithSingleItem);

        expect(sceneAssessment.flaggedContent.length, 1);
        expect(sceneAssessment.flaggedContent[0], 'Single flagged item');
      });

      test('should handle multiple flaggedContent items', () {
        final jsonWithMultipleItems = Map<String, dynamic>.from(validSceneAssessmentJson);
        jsonWithMultipleItems['flagged_content'] = [
          'Item 1',
          'Item 2',
          'Item 3',
          'Item 4',
          'Item 5',
        ];

        final sceneAssessment = SceneAssessment.fromJson(jsonWithMultipleItems);

        expect(sceneAssessment.flaggedContent.length, 5);
        expect(sceneAssessment.flaggedContent[0], 'Item 1');
        expect(sceneAssessment.flaggedContent[4], 'Item 5');
      });

      test('should handle all severity types in categories', () {
        final jsonWithAllSeverities = {
          'scene_number': 1,
          'heading': 'All Severities Scene',
          'page_range': '1-20',
          'categories': {
            'violence': 'none',
            'sexual_content': 'mild',
            'language': 'moderate',
            'alcohol_drugs': 'severe',
          },
          'flagged_content': [],
          'age_rating': '16+',
          'llm_comment': 'Comprehensive analysis',
        };

        final sceneAssessment = SceneAssessment.fromJson(jsonWithAllSeverities);

        expect(sceneAssessment.categories[Category.violence], Severity.none);
        expect(sceneAssessment.categories[Category.sexualContent], Severity.mild);
        expect(sceneAssessment.categories[Category.language], Severity.moderate);
        expect(sceneAssessment.categories[Category.alcoholDrugs], Severity.severe);
      });

      test('should handle page ranges with different formats', () {
        const pageRangeFormats = [
          '1-10',
          '100-200',
          '999-1000',
          '1-1', // single page
          'A1-A10', // alphanumeric
          '1-A', // mixed
        ];

        for (final pageRange in pageRangeFormats) {
          final json = Map<String, dynamic>.from(minimalSceneAssessmentJson);
          json['page_range'] = pageRange;

          final sceneAssessment = SceneAssessment.fromJson(json);
          expect(sceneAssessment.pageRange, pageRange);
        }
      });

      test('should throw exception for missing required fields', () {
        expect(() => SceneAssessment.fromJson({}), throwsA(isA<TypeError>()));
        expect(() => SceneAssessment.fromJson({'scene_number': 1}), throwsA(isA<TypeError>()));
        expect(() => SceneAssessment.fromJson({'heading': 'Test'}), throwsA(isA<TypeError>()));
        expect(() => SceneAssessment.fromJson({'page_range': '1-10'}), throwsA(isA<TypeError>()));
        expect(() => SceneAssessment.fromJson({'categories': {}}), throwsA(isA<TypeError>()));
        expect(() => SceneAssessment.fromJson({'age_rating': '0+'}), throwsA(isA<TypeError>()));
        expect(() => SceneAssessment.fromJson({'llm_comment': 'Test'}), throwsA(isA<TypeError>()));
      });
    });

    group('SceneAssessment.toJson Tests', () {
      test('should convert scene assessment to JSON correctly', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 15,
          heading: 'JSON Test Scene',
          pageRange: '150-175',
          categories: {
            Category.violence: Severity.moderate,
            Category.language: Severity.mild,
          },
          flaggedContent: ['Flagged for testing'],
          justification: 'JSON conversion test',
          ageRating: AgeRating.sixteenPlus,
          llmComment: 'JSON test comment',
        );

        final json = sceneAssessment.toJson();
        expect(json['scene_number'], 15);
        expect(json['heading'], 'JSON Test Scene');
        expect(json['page_range'], '150-175');
        expect(json['categories'], isA<Map<String, String>>());
        expect(json['categories']['violence'], 'moderate');
        expect(json['categories']['language'], 'mild');
        expect(json['flagged_content'], isA<List<String>>());
        expect(json['flagged_content'][0], 'Flagged for testing');
        expect(json['justification'], 'JSON conversion test');
        expect(json['age_rating'], '16+');
        expect(json['llm_comment'], 'JSON test comment');
        expect(json['references'], isEmpty);
        expect(json['text_preview'], null);
      });

      test('should handle empty categories in toJson', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 16,
          heading: 'Empty Categories Scene',
          pageRange: '176-180',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'No categories',
        );

        final json = sceneAssessment.toJson();
        expect(json['categories'], isEmpty);
      });

      test('should handle null justification in toJson', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 17,
          heading: 'Null Justification Scene',
          pageRange: '181-190',
          categories: {Category.violence: Severity.none},
          justification: null,
          ageRating: AgeRating.sixPlus,
          llmComment: 'No justification',
        );

        final json = sceneAssessment.toJson();
        expect(json['justification'], null);
      });

      test('should handle empty flaggedContent in toJson', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 18,
          heading: 'Empty Flags Scene',
          pageRange: '191-200',
          categories: {Category.language: Severity.mild},
          flaggedContent: [],
          ageRating: AgeRating.twelvePlus,
          llmComment: 'Clean content',
        );

        final json = sceneAssessment.toJson();
        expect(json['flagged_content'], isEmpty);
      });

      test('should handle single category in toJson', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 19,
          heading: 'Single Category Scene',
          pageRange: '201-210',
          categories: {Category.sexualContent: Severity.severe},
          ageRating: AgeRating.eighteenPlus,
          llmComment: 'Severe content',
        );

        final json = sceneAssessment.toJson();
        expect(json['categories']['sexual_content'], 'severe');
        expect(json['categories'].length, 1);
      });

      test('should round trip conversion (fromJson -> toJson)', () {
        final originalSceneAssessment = SceneAssessment.fromJson(validSceneAssessmentJson);
        final json = originalSceneAssessment.toJson();
        final roundTripSceneAssessment = SceneAssessment.fromJson(json);

        expect(originalSceneAssessment.sceneNumber, roundTripSceneAssessment.sceneNumber);
        expect(originalSceneAssessment.heading, roundTripSceneAssessment.heading);
        expect(originalSceneAssessment.pageRange, roundTripSceneAssessment.pageRange);
        expect(originalSceneAssessment.flaggedContent, roundTripSceneAssessment.flaggedContent);
        expect(originalSceneAssessment.justification, roundTripSceneAssessment.justification);
        expect(originalSceneAssessment.ageRating, roundTripSceneAssessment.ageRating);
        expect(originalSceneAssessment.llmComment, roundTripSceneAssessment.llmComment);
        
        // Check categories
        expect(originalSceneAssessment.categories.length, roundTripSceneAssessment.categories.length);
        for (final category in Category.values) {
          expect(
            originalSceneAssessment.categories[category],
            roundTripSceneAssessment.categories[category],
          );
        }
      });
    });

    group('SceneAssessment Edge Cases', () {
      test('should handle zero scene number', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 0,
          heading: 'Zero Scene',
          pageRange: '0-0',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Zero scene number',
        );

        expect(sceneAssessment.sceneNumber, 0);
      });

      test('should handle negative scene numbers', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: -1,
          heading: 'Negative Scene',
          pageRange: '-1--1',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Negative scene',
        );

        expect(sceneAssessment.sceneNumber, -1);
      });

      test('should handle very large scene numbers', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 999999,
          heading: 'Large Scene',
          pageRange: '999999-1000000',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Large scene number',
        );

        expect(sceneAssessment.sceneNumber, 999999);
      });

      test('should handle empty strings', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: '',
          pageRange: '',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: '',
        );

        expect(sceneAssessment.heading, isEmpty);
        expect(sceneAssessment.pageRange, isEmpty);
        expect(sceneAssessment.llmComment, isEmpty);
      });

      test('should handle very long strings', () {
        final longString = 'x' * 10000;
        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: longString,
          pageRange: longString,
          categories: {},
          flaggedContent: [longString],
          justification: longString,
          ageRating: AgeRating.zeroPlus,
          llmComment: longString,
          textPreview: longString,
        );

        expect(sceneAssessment.heading.length, 10000);
        expect(sceneAssessment.pageRange.length, 10000);
        expect(sceneAssessment.flaggedContent.first.length, 10000);
        expect(sceneAssessment.justification!.length, 10000);
        expect(sceneAssessment.llmComment.length, 10000);
        expect(sceneAssessment.textPreview!.length, 10000);
      });

      test('should handle special characters in text fields', () {
        final specialChars = r'Special: !@#$%^&*()_+{}|:<>?[]\\;\",./~`';
        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: specialChars,
          pageRange: specialChars,
          categories: {},
          flaggedContent: [specialChars],
          justification: specialChars,
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Special characters detected',
        );

        expect(sceneAssessment.heading, specialChars);
        expect(sceneAssessment.pageRange, specialChars);
        expect(sceneAssessment.flaggedContent.first, specialChars);
        expect(sceneAssessment.justification, specialChars);
      });

      test('should handle empty flaggedContent list', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Empty List Scene',
          pageRange: '1-10',
          categories: {},
          flaggedContent: [],
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Empty flags',
        );

        expect(sceneAssessment.flaggedContent, isEmpty);
      });

      test('should handle Unicode characters', () {
        final unicodeScene = SceneAssessment(
          sceneNumber: 1,
          heading: 'Unicode Scene 🎬🎭',
          pageRange: '1-🎯',
          categories: {Category.violence: Severity.none},
          flaggedContent: ['Unicode flagged 📝'],
          justification: 'Unicode justification 🎨',
          ageRating: AgeRating.sixPlus,
          llmComment: 'Unicode content 🎭',
        );

        expect(unicodeScene.heading, contains('🎬'));
        expect(unicodeScene.pageRange, contains('🎯'));
        expect(unicodeScene.flaggedContent.first, contains('📝'));
        expect(unicodeScene.justification, contains('🎨'));
        expect(unicodeScene.llmComment, contains('🎭'));
      });

      test('should handle page ranges with special formats', () {
        const specialPageRanges = [
          'A1-B10', // Letters and numbers
          'I-II', // Roman numerals
          '1-A', // Mixed
          'A1-1A', // Complex
        ];

        for (final pageRange in specialPageRanges) {
          final sceneAssessment = SceneAssessment(
            sceneNumber: 1,
            heading: 'Special Page Range',
            pageRange: pageRange,
            categories: {},
            ageRating: AgeRating.zeroPlus,
            llmComment: 'Special format',
          );

          expect(sceneAssessment.pageRange, pageRange);
        }
      });

      test('should handle large flaggedContent lists efficiently', () {
        final veryLargeFlaggedContent = List<String>.generate(10000, (index) => 'Very large item $index');

        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Very Large List Scene',
          pageRange: '1-100',
          categories: {},
          flaggedContent: veryLargeFlaggedContent,
          ageRating: AgeRating.eighteenPlus,
          llmComment: 'Extensive content analysis',
        );

        expect(sceneAssessment.flaggedContent.length, 10000);
        expect(sceneAssessment.flaggedContent.first, 'Very large item 0');
        expect(sceneAssessment.flaggedContent.last, 'Very large item 9999');
      });
    });

    group('SceneAssessment Property Validation', () {
      test('should correctly identify property types', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Type Test',
          pageRange: '1-10',
          categories: {Category.violence: Severity.mild},
          flaggedContent: ['test'],
          justification: 'test justification',
          ageRating: AgeRating.sixPlus,
          llmComment: 'Type validation test',
        );

        expect(sceneAssessment.sceneNumber, isA<int>());
        expect(sceneAssessment.heading, isA<String>());
        expect(sceneAssessment.pageRange, isA<String>());
        expect(sceneAssessment.categories, isA<Map<Category, Severity>>());
        expect(sceneAssessment.flaggedContent, isA<List<String>>());
        expect(sceneAssessment.justification, isA<String?>());
        expect(sceneAssessment.ageRating, isA<AgeRating>());
        expect(sceneAssessment.llmComment, isA<String>());
        expect(sceneAssessment.references, isA<List<NormativeReference>>());
        expect(sceneAssessment.textPreview, isA<String?>());
      });

      test('should maintain data consistency for enum values', () {
        final sceneAssessment = SceneAssessment(
          sceneNumber: 1,
          heading: 'Enum Test',
          pageRange: '1-10',
          categories: {
            Category.violence: Severity.moderate,
            Category.language: Severity.severe,
          },
          ageRating: AgeRating.twelvePlus,
          llmComment: 'Enum validation test',
        );

        // Test that enum values have correct string representations
        expect(sceneAssessment.categories[Category.violence]!.value, 'moderate');
        expect(sceneAssessment.categories[Category.language]!.value, 'severe');
        expect(sceneAssessment.ageRating.display, '12+');
      });

      test('should handle boundary conditions for scene numbers', () {
        const boundaryNumbers = [0, 1, -1, 999999];

        for (final number in boundaryNumbers) {
          final sceneAssessment = SceneAssessment(
            sceneNumber: number,
            heading: 'Boundary Scene $number',
            pageRange: '$number-${number + 10}',
            categories: {},
            ageRating: AgeRating.zeroPlus,
            llmComment: 'Boundary test',
          );

          expect(sceneAssessment.sceneNumber, number);
        }
      });

      test('should verify all category types can be used', () {
        final allCategoryScene = SceneAssessment(
          sceneNumber: 1,
          heading: 'All Categories Scene',
          pageRange: '1-50',
          categories: {
            Category.violence: Severity.none,
            Category.sexualContent: Severity.mild,
            Category.language: Severity.moderate,
            Category.alcoholDrugs: Severity.severe,
            Category.disturbingScenes: Severity.none,
          },
          ageRating: AgeRating.sixteenPlus,
          llmComment: 'Comprehensive category analysis',
        );

        expect(allCategoryScene.categories.length, Category.values.length);
        
        for (final category in Category.values) {
          expect(allCategoryScene.categories.containsKey(category), true);
          expect(allCategoryScene.categories[category], isA<Severity>());
        }
      });

      test('should handle missing optional fields correctly', () {
        final sceneWithMinimalData = SceneAssessment(
          sceneNumber: 1,
          heading: 'Minimal',
          pageRange: '1-5',
          categories: {},
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Minimal data test',
        );

        expect(sceneWithMinimalData.flaggedContent, isEmpty);
        expect(sceneWithMinimalData.justification, null);
        expect(sceneWithMinimalData.references, isEmpty);
        expect(sceneWithMinimalData.textPreview, null);
      });

      test('should validate page range string format independence', () {
        // SceneAssessment doesn't validate page range format, so any string should work
        const invalidFormats = [
          'invalid-format',
          '999999999-999999999',
          '',
          '   ',
          '1-2-3-4',
        ];

        for (final format in invalidFormats) {
          final sceneAssessment = SceneAssessment(
            sceneNumber: 1,
            heading: 'Format Test',
            pageRange: format,
            categories: {},
            ageRating: AgeRating.zeroPlus,
            llmComment: 'Format validation',
          );

          expect(sceneAssessment.pageRange, format);
        }
      });
    });

    group('SceneAssessment Data Integrity', () {
      test('should maintain data integrity through multiple conversions', () {
        final originalScene = SceneAssessment(
          sceneNumber: 42,
          heading: 'Data Integrity Test',
          pageRange: '420-450',
          categories: {
            Category.violence: Severity.severe,
            Category.language: Severity.moderate,
            Category.sexualContent: Severity.mild,
          },
          flaggedContent: [
            'Severe violence',
            'Strong language',
            'Mild sexual content',
          ],
          justification: 'Multiple content warnings',
          ageRating: AgeRating.eighteenPlus,
          llmComment: 'Comprehensive analysis',
          textPreview: 'Scene preview text',
        );

        // First conversion
        final json1 = originalScene.toJson();
        final scene1 = SceneAssessment.fromJson(json1);

        // Second conversion
        final json2 = scene1.toJson();
        final scene2 = SceneAssessment.fromJson(json2);

        // Verify all data matches
        expect(scene1.sceneNumber, scene2.sceneNumber);
        expect(scene1.heading, scene2.heading);
        expect(scene1.pageRange, scene2.pageRange);
        expect(scene1.flaggedContent, scene2.flaggedContent);
        expect(scene1.justification, scene2.justification);
        expect(scene1.ageRating, scene2.ageRating);
        expect(scene1.llmComment, scene2.llmComment);
        expect(scene1.categories.length, scene2.categories.length);
        expect(scene1.references.length, scene2.references.length);

        // Verify categories match
        for (final category in Category.values) {
          expect(scene1.categories[category], scene2.categories[category]);
        }
      });

      test('should handle concurrent modifications correctly', () {
        final categories1 = {Category.violence: Severity.mild};
        final categories2 = {Category.language: Severity.moderate};
        final flaggedContent1 = ['Content 1'];
        final flaggedContent2 = ['Content 2'];

        final scene1 = SceneAssessment(
          sceneNumber: 1,
          heading: 'Scene 1',
          pageRange: '1-10',
          categories: categories1,
          flaggedContent: flaggedContent1,
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Scene 1 comment',
        );

        final scene2 = SceneAssessment(
          sceneNumber: 2,
          heading: 'Scene 2',
          pageRange: '11-20',
          categories: categories2,
          flaggedContent: flaggedContent2,
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Scene 2 comment',
        );

        // Modify original collections
        categories1[Category.violence] = Severity.severe;
        categories2[Category.language] = Severity.severe;
        flaggedContent1.add('Modified');
        flaggedContent2.add('Modified');

        // Scenes should not be affected by original collection modifications
        expect(scene1.categories[Category.violence], Severity.mild);
        expect(scene2.categories[Category.language], Severity.moderate);
        expect(scene1.flaggedContent, ['Content 1']);
        expect(scene2.flaggedContent, ['Content 2']);
      });
    });
  });
}

