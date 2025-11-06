import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/locator.dart';
import '../models/analysis_result.dart';
import '../models/category.dart';
import '../models/severity.dart';
import '../services/api_service.dart';
import '../widgets/analysis_result_widget.dart';
import '../widgets/category_summary_widget.dart';
import '../widgets/scene_detail_widget.dart';

class ResultsScreen extends StatefulWidget {
  final String? analysisId;

  const ResultsScreen({super.key, this.analysisId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = locator<ApiService>();

  bool _isLoading = false;
  AnalysisResult? _analysisResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (widget.analysisId == null) {
      setState(() => _error = 'Не передан идентификатор анализа');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final AnalysisResult result =
          await _apiService.getAnalysisResult(widget.analysisId!);
      if (!mounted) return;
      setState(() => _analysisResult = result);
    } catch (e) {
      setState(() {
        _error = 'Не удалось получить результат: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты анализа'),
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
              ? _buildError()
              : _analysisResult == null
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Неизвестная ошибка',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadResults,
            child: const Text('Повторить запрос'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Данных анализа пока нет. Вернитесь позже.'),
    );
  }

  Widget _buildContent() {
    final result = _analysisResult!;
    final categorySummary = result.ratingResult.categoriesSummary.map(
      (Category key, Severity value) => MapEntry(
        key.value,
        value.index / (Severity.values.length - 1),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalysisResultWidget(result: result),
          if (result.recommendations != null &&
              result.recommendations!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Рекомендации',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...result.recommendations!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Сводка по категориям',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CategorySummaryWidget(categories: categorySummary),
          const SizedBox(height: 24),
          const Text(
            'Смысловые блоки',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...result.sceneAssessments.map(
            (assessment) => SceneDetailWidget(
              assessment: assessment,
              showReferences: true,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => context.go('/upload'),
              icon: const Icon(Icons.upload),
              label: const Text('Анализировать ещё сценарий'),
            ),
          ),
        ],
      ),
    );
  }
}
