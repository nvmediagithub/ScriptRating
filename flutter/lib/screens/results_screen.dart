import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/analysis_result.dart';
import '../models/rating_result.dart';
import '../models/scene_assessment.dart';
import '../models/age_rating.dart';
import '../models/category.dart';
import '../models/severity.dart';
import '../widgets/analysis_result_widget.dart';
import '../widgets/scene_detail_widget.dart';
import '../widgets/category_summary_widget.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = false;
  AnalysisResult? _analysisResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Mock loading delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock data
      _analysisResult = AnalysisResult(
        analysisId: 'mock-analysis-123',
        documentId: 'mock-doc-456',
        status: 'completed',
        ratingResult: RatingResult(
          finalRating: AgeRating.sixteenPlus,
          confidenceScore: 0.85,
          problemScenesCount: 3,
          categoriesSummary: {
            Category.violence: Severity.moderate,
            Category.language: Severity.mild,
            Category.sexualContent: Severity.severe,
            Category.alcoholDrugs: Severity.none,
          },
        ),
        sceneAssessments: [
          SceneAssessment(
            sceneNumber: 1,
            heading: 'Opening Scene',
            pageRange: '1-3',
            categories: {
              Category.violence: Severity.mild,
            },
            flaggedContent: ['Action sequences'],
            justification: 'Contains action sequences without graphic violence',
          ),
          SceneAssessment(
            sceneNumber: 5,
            heading: 'Romantic Scene',
            pageRange: '12-15',
            categories: {
              Category.sexualContent: Severity.moderate,
            },
            flaggedContent: ['Suggestive dialogue'],
            justification: 'Suggestive dialogue and situations',
          ),
          SceneAssessment(
            sceneNumber: 12,
            heading: 'Battle Scene',
            pageRange: '45-52',
            categories: {
              Category.violence: Severity.severe,
              Category.language: Severity.moderate,
            },
            flaggedContent: ['Intense combat', 'Strong language'],
            justification: 'Intense combat with strong language',
          ),
        ],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load results: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.feedback),
            onPressed: () => context.go('/feedback'),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => context.go('/report'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadResults,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _analysisResult == null
                  ? const Center(child: Text('No results available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnalysisResultWidget(result: _analysisResult!),
                          const SizedBox(height: 24),
                          const Text(
                            'Category Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CategorySummaryWidget(
                            categories: _analysisResult!.ratingResult.categoriesSummary.map(
                              (key, value) => MapEntry(key.name, value.index / Severity.values.length.toDouble()),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Scene Assessments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._analysisResult!.sceneAssessments.map(
                            (assessment) => SceneDetailWidget(
                              assessment: assessment,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/upload'),
                              icon: const Icon(Icons.upload),
                              label: const Text('Analyze Another Script'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}