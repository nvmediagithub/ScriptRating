import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/locator.dart';
import '../models/analysis_status.dart';
import '../models/rating_result.dart';
import '../models/scene_assessment.dart';
import '../services/api_service.dart';
import '../widgets/scene_detail_widget.dart';

class AnalysisScreen extends StatefulWidget {
  final String analysisId;
  final String documentId;
  final String? criteriaDocumentId;

  const AnalysisScreen({
    super.key,
    required this.analysisId,
    required this.documentId,
    this.criteriaDocumentId,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ApiService _apiService = locator<ApiService>();
  Timer? _pollingTimer;

  double _progress = 0;
  String _status = 'processing';
  RatingResult? _ratingResult;
  List<SceneAssessment> _blocks = [];
  List<String>? _recommendations;
  String? _error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final AnalysisStatus status =
          await _apiService.getAnalysisStatus(widget.analysisId);
      if (!mounted) return;

      setState(() {
        _progress = status.progress ?? _progress;
        _status = status.status;
        _ratingResult = status.ratingResult ?? _ratingResult;
        _recommendations = status.recommendations ?? _recommendations;
        if (status.processedBlocks.isNotEmpty) {
          _blocks = status.processedBlocks;
        }
        _error = status.errors;
      });

      if (status.status == 'completed' && !_navigated) {
        _pollingTimer?.cancel();
        _navigated = true;
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          context.go('/results', extra: {'analysisId': widget.analysisId});
        }
      } else if (status.status == 'failed') {
        _pollingTimer?.cancel();
      }
    } catch (e) {
      setState(() => _error = 'Не удалось получить статус: $e');
      _pollingTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFailed = _status == 'failed';
    final bool isCompleted = _status == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ сценария'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isFailed
                          ? Icons.error
                          : Icons.sync,
                  color: isFailed
                      ? Colors.red
                      : (isCompleted ? Colors.green : Colors.blue),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFailed
                        ? 'Анализ завершился с ошибкой'
                        : isCompleted
                            ? 'Анализ завершён'
                            : 'Выполняется анализ...',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_progress.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_progress / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: isFailed
                  ? Colors.red
                  : (isCompleted ? Colors.green : Colors.blue),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: _blocks.isEmpty
                    ? _buildIdleState(isCompleted)
                    : _buildBlocksList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState(bool isCompleted) {
    final message = isCompleted
        ? 'Собираем финальные рекомендации...'
        : 'Формируем смысловые блоки сценария и обращаемся к RAG-хранилищу.';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBlocksList() {
    return ListView.separated(
      itemCount: _blocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assessment = _blocks[index];
        return SceneDetailWidget(
          assessment: assessment,
          showReferences: true,
          dense: true,
        );
      },
    );
  }
}
