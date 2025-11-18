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
  List<dynamic> _blocks = [];
  List<String>? _recommendations;
  String? _error;

  // Simple per-scene rule-based check state
  bool _sceneCheckRunning = false;
  double _sceneCheckProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final AnalysisStatus status = await _apiService.getAnalysisStatus(widget.analysisId);
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

      if (status.status == 'completed') {
        _pollingTimer?.cancel();
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

    final double progressValue =
        _sceneCheckRunning ? _sceneCheckProgress : (_progress / 100).clamp(0.0, 1.0);
    final String progressLabel = _sceneCheckRunning
        ? '${(_sceneCheckProgress * 100).toStringAsFixed(1)}% (scene check)'
        : '${_progress.toStringAsFixed(1)}%';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ сценария'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/')),
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
                  color: isFailed ? Colors.red : (isCompleted ? Colors.green : Colors.blue),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    isFailed
                        ? 'Анализ завершился с ошибкой'
                        : isCompleted
                        ? 'Анализ завершён'
                        : 'Выполняется анализ...',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                SelectableText(
                  progressLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: isFailed ? Colors.red : (isCompleted ? Colors.green : Colors.blue),
            ),
            const SizedBox(height: 24),
            if (isCompleted)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.go('/results', extra: {'analysisId': widget.analysisId}),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Перейти к результатам'),
                ),
              ),
            const SizedBox(height: 16),
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
                      child: SelectableText(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              )
            else
              Expanded(child: _blocks.isEmpty ? _buildIdleState(isCompleted) : _buildBlocksList()),
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
          SelectableText(
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
        return SceneDetailWidget(assessment: assessment, showReferences: true, dense: true);
      },
    );
  }

  Future<void> _runSceneChecks() async {
    if (_blocks.isEmpty) return;

    setState(() {
      _sceneCheckRunning = true;
      _sceneCheckProgress = 0.0;
    });

    try {
      final scenes = _blocks.cast<SceneAssessment>();
      final total = scenes.length;

      for (var i = 0; i < total; i++) {
        final scene = scenes[i];

        try {
          await _apiService.checkScene(
            scriptId: widget.documentId,
            sceneId: scene.sceneNumber.toString(),
            sceneText: scene.text,
          );
        } catch (e) {
          // Для первой версии просто логируем/игнорируем ошибку конкретной сцены.
        }

        if (!mounted) return;
        setState(() {
          _sceneCheckProgress = (i + 1) / total;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sceneCheckRunning = false;
        });
      }
    }
  }
}
