import 'package:flutter_test/flutter_test.dart';
import 'package:script_rating_app/models/analysis_result.dart';
import 'package:script_rating_app/models/rating_result.dart';
import 'package:script_rating_app/models/scene_assessment.dart';
import 'package:script_rating_app/models/age_rating.dart';
import 'package:script_rating_app/models/category.dart';
import 'package:script_rating_app/models/severity.dart';

void main() {
  group('AnalysisResult Model Tests', () {
    // Valid test data
    final validRatingResult = RatingResult(
      finalRating: AgeRating.twelvePlus,
      confidenceScore: 0.85,
      problemScenesCount: 3,
      categoriesSummary: {
        Category.violence: Severity.mild,
        Category.language: Severity.moderate,
      },
    );

    final validSceneAssessments = [
      SceneAssessment(
        sceneNumber: 1,
        heading: 'Opening Scene',
        pageRange: '1-5',
        categories: {Category.violence: Severity.none},
        flaggedContent: [],
        ageRating: AgeRating.zeroPlus,
        llmComment: 'Clean opening scene',
      ),
      SceneAssessment(
        sceneNumber: 2,
        heading: 'Conflict Scene',
        pageRange: '6-15',
        categories: {Category.violence: Severity.moderate},
        flaggedContent: ['Fighting scene'],
        justification: 'Moderate violence depicted',
        ageRating: AgeRating.twelvePlus,
        llmComment: 'Moderate violence detected',
      ),
    ];

    const validAnalysisResultJson = {
      'analysis_id': 'analysis-123',
      'document_id': 'doc-456',
      'status': 'completed',
      'rating_result': {
        'finalRating': '12+',
        'confidence_score': 0.85,
        'problem_scenes_count': 3,
        'categories_summary': {
          'violence': 'mild',
          'language': 'moderate',
        },
      },
      'scene_assessments': [
        {
          'scene_number': 1,
          'heading': 'Opening Scene',
          'page_range': '1-5',
          'categories': {'violence': 'none'},
          'flagged_content': [],
          'age_rating': '0+',
          'llm_comment': 'Clean scene',
        },
      ],
      'created_at': '2023-01-01T00:00:00.000Z',
      'recommendations': [
        'Consider reducing violent content',
        'Review language appropriateness',
      ],
    };

    const minimalAnalysisResultJson = {
      'analysis_id': 'minimal-789',
      'document_id': 'doc-minimal',
      'status': 'pending',
      'rating_result': {
        'finalRating': '0+',
        'confidence_score': 0.0,
        'problem_scenes_count': 0,
        'categories_summary': {},
      },
      'scene_assessments': [],
      'created_at': '2023-12-01T00:00:00.000Z',
    };

    const analysisResultWithNullRecommendationsJson = {
      'analysis_id': 'null-rec-101',
      'document_id': 'doc-null-rec',
      'status': 'in_progress',
      'rating_result': {
        'finalRating': '6+',
        'confidence_score': 0.5,
        'problem_scenes_count': 1,
        'categories_summary': {'violence': 'mild'},
      },
      'scene_assessments': [],
      'created_at': '2023-06-15T10:30:00.000Z',
      'recommendations': null,
    };

    group('AnalysisResult Constructor Tests', () {
      test('should create analysis result with all required parameters', () {
        final analysisResult = AnalysisResult(
          analysisId: 'test-analysis',
          documentId: 'test-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: validSceneAssessments,
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          recommendations: ['Test recommendation'],
        );

        expect(analysisResult.analysisId, 'test-analysis');
        expect(analysisResult.documentId, 'test-doc');
        expect(analysisResult.status, 'completed');
        expect(analysisResult.ratingResult, validRatingResult);
        expect(analysisResult.sceneAssessments, validSceneAssessments);
        expect(analysisResult.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
        expect(analysisResult.recommendations, ['Test recommendation']);
      });

      test('should create analysis result with minimal required parameters', () {
        final minimalRatingResult = RatingResult(
          finalRating: AgeRating.zeroPlus,
          confidenceScore: 0.0,
          problemScenesCount: 0,
          categoriesSummary: {},
        );

        final analysisResult = AnalysisResult(
          analysisId: 'minimal-analysis',
          documentId: 'minimal-doc',
          status: 'pending',
          ratingResult: minimalRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        expect(analysisResult.analysisId, 'minimal-analysis');
        expect(analysisResult.documentId, 'minimal-doc');
        expect(analysisResult.status, 'pending');
        expect(analysisResult.ratingResult, minimalRatingResult);
        expect(analysisResult.sceneAssessments, isEmpty);
        expect(analysisResult.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
        expect(analysisResult.recommendations, null);
      });

      test('should handle null recommendations correctly', () {
        final analysisResult = AnalysisResult(
          analysisId: 'null-rec-analysis',
          documentId: 'null-rec-doc',
          status: 'in_progress',
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          recommendations: null,
        );

        expect(analysisResult.recommendations, null);
      });

      test('should handle empty scene assessments list', () {
        final analysisResult = AnalysisResult(
          analysisId: 'empty-scenes-analysis',
          documentId: 'empty-scenes-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        expect(analysisResult.sceneAssessments, isEmpty);
      });

      test('should handle very large scene assessments list', () {
        final largeSceneAssessments = List.generate(1000, (index) => SceneAssessment(
          sceneNumber: index + 1,
          heading: 'Scene $index',
          pageRange: '${index * 10}-${index * 10 + 9}',
          categories: {Category.violence: Severity.none},
          flaggedContent: [],
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Large scene $index',
        ));

        final analysisResult = AnalysisResult(
          analysisId: 'large-scenes-analysis',
          documentId: 'large-scenes-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: largeSceneAssessments,
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        expect(analysisResult.sceneAssessments.length, 1000);
        expect(analysisResult.sceneAssessments.first.sceneNumber, 1);
        expect(analysisResult.sceneAssessments.last.sceneNumber, 1000);
      });
    });

    group('AnalysisResult.fromJson Tests', () {
      test('should create analysis result from valid JSON', () {
        final analysisResult = AnalysisResult.fromJson(validAnalysisResultJson);

        expect(analysisResult.analysisId, 'analysis-123');
        expect(analysisResult.documentId, 'doc-456');
        expect(analysisResult.status, 'completed');
        expect(analysisResult.ratingResult, isA<RatingResult>());
        expect(analysisResult.ratingResult.finalRating, AgeRating.twelvePlus);
        expect(analysisResult.ratingResult.confidenceScore, 0.85);
        expect(analysisResult.ratingResult.problemScenesCount, 3);
        expect(analysisResult.sceneAssessments, isA<List<SceneAssessment>>());
        expect(analysisResult.sceneAssessments.length, 1);
        expect(analysisResult.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
        expect(analysisResult.recommendations, isA<List<String>>());
        expect(analysisResult.recommendations!.length, 2);
        expect(analysisResult.recommendations![0], 'Consider reducing violent content');
      });

      test('should create analysis result from minimal JSON', () {
        final analysisResult = AnalysisResult.fromJson(minimalAnalysisResultJson);

        expect(analysisResult.analysisId, 'minimal-789');
        expect(analysisResult.documentId, 'doc-minimal');
        expect(analysisResult.status, 'pending');
        expect(analysisResult.ratingResult, isA<RatingResult>());
        expect(analysisResult.sceneAssessments, isEmpty);
        expect(analysisResult.recommendations, null);
      });

      test('should handle null recommendations in JSON', () {
        final analysisResult = AnalysisResult.fromJson(analysisResultWithNullRecommendationsJson);

        expect(analysisResult.recommendations, null);
      });

      test('should throw exception for missing required fields', () {
        expect(() => AnalysisResult.fromJson({}), throwsA(isA<TypeError>()));
        expect(() => AnalysisResult.fromJson({'analysis_id': 'test'}), throwsA(isA<TypeError>()));
        expect(() => AnalysisResult.fromJson({'document_id': 'test'}), throwsA(isA<TypeError>()));
        expect(() => AnalysisResult.fromJson({'status': 'test'}), throwsA(isA<TypeError>()));
      });

      test('should handle different status values', () {
        const statusValues = ['pending', 'in_progress', 'completed', 'failed', 'cancelled'];
        
        for (final status in statusValues) {
          final json = Map<String, dynamic>.from(minimalAnalysisResultJson);
          json['status'] = status;
          
          final analysisResult = AnalysisResult.fromJson(json);
          expect(analysisResult.status, status);
        }
      });

      test('should handle multiple scene assessments in JSON', () {
        final jsonWithMultipleScenes = Map<String, dynamic>.from(validAnalysisResultJson);
        jsonWithMultipleScenes['scene_assessments'] = [
          {
            'scene_number': 1,
            'heading': 'Scene 1',
            'page_range': '1-10',
            'categories': {'violence': 'none'},
            'flagged_content': [],
            'age_rating': '0+',
            'llm_comment': 'Clean scene',
          },
          {
            'scene_number': 2,
            'heading': 'Scene 2',
            'page_range': '11-20',
            'categories': {'violence': 'mild'},
            'flagged_content': ['Some content'],
            'justification': 'Mild content detected',
            'age_rating': '6+',
            'llm_comment': 'Mild content',
          },
          {
            'scene_number': 3,
            'heading': 'Scene 3',
            'page_range': '21-30',
            'categories': {'language': 'severe'},
            'flagged_content': ['Strong language'],
            'justification': 'Inappropriate language',
            'age_rating': '16+',
            'llm_comment': 'Severe language',
          },
        ];

        final analysisResult = AnalysisResult.fromJson(jsonWithMultipleScenes);
        
        expect(analysisResult.sceneAssessments.length, 3);
        expect(analysisResult.sceneAssessments[0].sceneNumber, 1);
        expect(analysisResult.sceneAssessments[1].sceneNumber, 2);
        expect(analysisResult.sceneAssessments[2].sceneNumber, 3);
      });
    });

    group('AnalysisResult.toJson Tests', () {
      test('should convert analysis result to JSON correctly', () {
        final analysisResult = AnalysisResult(
          analysisId: 'json-test',
          documentId: 'json-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: validSceneAssessments,
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          recommendations: ['Test rec 1', 'Test rec 2'],
        );

        final json = analysisResult.toJson();
        expect(json['analysis_id'], 'json-test');
        expect(json['document_id'], 'json-doc');
        expect(json['status'], 'completed');
        expect(json['rating_result'], isA<Map<String, dynamic>>());
        expect(json['scene_assessments'], isA<List<Map<String, dynamic>>>());
        expect(json['created_at'], '2023-01-01T00:00:00.000Z');
        expect(json['recommendations'], isA<List<String>>());
        expect(json['recommendations']!.length, 2);
      });

      test('should handle null recommendations in toJson', () {
        final analysisResult = AnalysisResult(
          analysisId: 'null-json-test',
          documentId: 'null-json-doc',
          status: 'pending',
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          recommendations: null,
        );

        final json = analysisResult.toJson();
        expect(json['recommendations'], null);
      });

      test('should handle empty lists in toJson', () {
        final analysisResult = AnalysisResult(
          analysisId: 'empty-json-test',
          documentId: 'empty-json-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        final json = analysisResult.toJson();
        expect(json['scene_assessments'], isEmpty);
        expect(json['recommendations'], null);
      });

      test('should round trip conversion (fromJson -> toJson)', () {
        final originalAnalysisResult = AnalysisResult.fromJson(validAnalysisResultJson);
        final json = originalAnalysisResult.toJson();
        final roundTripAnalysisResult = AnalysisResult.fromJson(json);

        expect(originalAnalysisResult.analysisId, roundTripAnalysisResult.analysisId);
        expect(originalAnalysisResult.documentId, roundTripAnalysisResult.documentId);
        expect(originalAnalysisResult.status, roundTripAnalysisResult.status);
        expect(originalAnalysisResult.ratingResult.finalRating, roundTripAnalysisResult.ratingResult.finalRating);
        expect(originalAnalysisResult.ratingResult.confidenceScore, roundTripAnalysisResult.ratingResult.confidenceScore);
        expect(originalAnalysisResult.sceneAssessments.length, roundTripAnalysisResult.sceneAssessments.length);
        expect(originalAnalysisResult.createdAt, roundTripAnalysisResult.createdAt);
        expect(originalAnalysisResult.recommendations, roundTripAnalysisResult.recommendations);
      });
    });

    group('AnalysisResult Edge Cases', () {
      test('should handle empty strings', () {
        final analysisResult = AnalysisResult(
          analysisId: '',
          documentId: '',
          status: '',
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        expect(analysisResult.analysisId, isEmpty);
        expect(analysisResult.documentId, isEmpty);
        expect(analysisResult.status, isEmpty);
      });

      test('should handle very long strings', () {
        final longString = 'x' * 10000;
        final analysisResult = AnalysisResult(
          analysisId: longString,
          documentId: longString,
          status: longString,
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        expect(analysisResult.analysisId.length, 10000);
        expect(analysisResult.documentId.length, 10000);
        expect(analysisResult.status.length, 10000);
      });

      test('should handle special characters', () {
        final specialChars = r'Special: !@#$%^&*()_+{}|:<>?[]\\;\",./~`';
        final analysisResult = AnalysisResult(
          analysisId: 'special-analysis',
          documentId: 'special-doc',
          status: specialChars,
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        expect(analysisResult.status, specialChars);
      });

      test('should handle empty recommendations list', () {
        final analysisResult = AnalysisResult(
          analysisId: 'empty-rec-analysis',
          documentId: 'empty-rec-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: [],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          recommendations: [],
        );

        final json = analysisResult.toJson();
        expect(json['recommendations'], isEmpty);
      });

      test('should handle complex nested data structures', () {
        final complexRatingResult = RatingResult(
          finalRating: AgeRating.eighteenPlus,
          confidenceScore: 0.99,
          problemScenesCount: 15,
          categoriesSummary: {
            Category.violence: Severity.severe,
            Category.sexualContent: Severity.moderate,
            Category.language: Severity.severe,
            Category.alcoholDrugs: Severity.mild,
            Category.disturbingScenes: Severity.moderate,
          },
        );

        final analysisResult = AnalysisResult(
          analysisId: 'complex-analysis',
          documentId: 'complex-doc',
          status: 'completed',
          ratingResult: complexRatingResult,
          sceneAssessments: [
            SceneAssessment(
              sceneNumber: 1,
              heading: 'Complex Scene',
              pageRange: '1-50',
              categories: {
                Category.violence: Severity.severe,
                Category.sexualContent: Severity.moderate,
              },
              flaggedContent: ['Violent content', 'Sexual content'],
              justification: 'Complex scene with multiple issues',
              ageRating: AgeRating.eighteenPlus,
              llmComment: 'Complex analysis',
            ),
          ],
          createdAt: DateTime.parse('2023-12-31T23:59:59.999Z'),
          recommendations: [
            'Major content revision needed',
            'Consider age restrictions',
            'Remove inappropriate content',
          ],
        );

        expect(analysisResult.ratingResult.categoriesSummary.length, 5);
        expect(analysisResult.sceneAssessments.first.categories.length, 2);
        expect(analysisResult.sceneAssessments.first.flaggedContent.length, 2);
        expect(analysisResult.recommendations!.length, 3);
      });

      test('should handle different confidence score ranges', () {
        const confidenceScores = [0.0, 0.25, 0.5, 0.75, 0.99, 1.0];
        
        for (final score in confidenceScores) {
          final ratingResult = RatingResult(
            finalRating: AgeRating.sixPlus,
            confidenceScore: score,
            problemScenesCount: 0,
            categoriesSummary: {},
          );

          final analysisResult = AnalysisResult(
            analysisId: 'confidence-$score',
            documentId: 'confidence-doc',
            status: 'completed',
            ratingResult: ratingResult,
            sceneAssessments: [],
            createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          );

          expect(analysisResult.ratingResult.confidenceScore, score);
        }
      });

      test('should handle boundary conditions for scene numbers', () {
        final boundarySceneAssessment = SceneAssessment(
          sceneNumber: 0,
          heading: 'Boundary Scene',
          pageRange: '0-0',
          categories: {},
          flaggedContent: [],
          ageRating: AgeRating.zeroPlus,
          llmComment: 'Boundary scene',
        );

        final analysisResult = AnalysisResult(
          analysisId: 'boundary-analysis',
          documentId: 'boundary-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: [boundarySceneAssessment],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        );

        expect(analysisResult.sceneAssessments.first.sceneNumber, 0);
      });

      test('should handle Unicode characters in text fields', () {
        final unicodeAnalysisResult = AnalysisResult(
          analysisId: 'unicode-🚀',
          documentId: 'unicode-doc-🎬',
          status: 'Unicode Status 🎭',
          ratingResult: validRatingResult,
          sceneAssessments: [
            SceneAssessment(
              sceneNumber: 1,
              heading: 'Unicode Scene 🎪',
              pageRange: '1-🎯',
              categories: {},
              flaggedContent: ['Unicode flagged 📝'],
              justification: 'Unicode justification 🎨',
              ageRating: AgeRating.sixPlus,
              llmComment: 'Unicode analysis 🎭',
            ),
          ],
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          recommendations: ['Unicode recommendation 📋'],
        );

        expect(unicodeAnalysisResult.analysisId, contains('🚀'));
        expect(unicodeAnalysisResult.status, contains('🎭'));
        expect(unicodeAnalysisResult.sceneAssessments.first.heading, contains('🎪'));
        expect(unicodeAnalysisResult.recommendations!.first, contains('📋'));
      });
    });

    group('AnalysisResult Property Validation', () {
      test('should correctly identify property types', () {
        final analysisResult = AnalysisResult(
          analysisId: 'types-test',
          documentId: 'types-doc',
          status: 'completed',
          ratingResult: validRatingResult,
          sceneAssessments: validSceneAssessments,
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          recommendations: ['Test'],
        );

        expect(analysisResult.analysisId, isA<String>());
        expect(analysisResult.documentId, isA<String>());
        expect(analysisResult.status, isA<String>());
        expect(analysisResult.ratingResult, isA<RatingResult>());
        expect(analysisResult.sceneAssessments, isA<List<SceneAssessment>>());
        expect(analysisResult.createdAt, isA<DateTime>());
        expect(analysisResult.recommendations, isA<List<String>?>());
      });
    });
  });
}

