import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/locator.dart';
import '../models/analysis_result.dart';
import '../models/document_type.dart';
import '../services/api_service.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ApiService _apiService = locator<ApiService>();

  bool _uploadingCriteria = false;
  bool _uploadingScript = false;
  String? _criteriaDocumentId;
  String? _criteriaFilename;
  int? _criteriaChunks;
  String? _scriptFilename;
  String? _error;

  Future<void> _handleUpload(DocumentType type) async {
    final allowedExtensions = ['pdf', 'docx', 'txt'];
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        return;
      }

      final fileBytes = result.files.single.bytes!;
      final filename = result.files.single.name;

      setState(() {
        _error = null;
        if (type == DocumentType.criteria) {
          _uploadingCriteria = true;
        } else {
          _uploadingScript = true;
        }
      });

      final response = await _apiService.uploadDocument(
        filename,
        fileBytes,
        documentType: type,
      );

      if (type == DocumentType.criteria) {
        setState(() {
          _criteriaFilename = filename;
          _criteriaDocumentId = response['document_id'] as String;
          _criteriaChunks = response['chunks_indexed'] as int?;
        });
      } else {
        _scriptFilename = filename;
        final AnalysisResult analysis =
            await _apiService.analyzeScript(
          response['document_id'] as String,
          criteriaDocumentId: _criteriaDocumentId,
        );
        if (!mounted) return;
        context.go(
          '/analysis',
          extra: {
            'analysisId': analysis.analysisId,
            'documentId': analysis.documentId,
            'criteriaDocumentId': _criteriaDocumentId,
          },
        );
      }
    } catch (e) {
      setState(() => _error = 'Ошибка загрузки: $e');
    } finally {
      setState(() {
        _uploadingCriteria = false;
        _uploadingScript = false;
      });
    }
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isLoading,
    required VoidCallback onPressed,
    Widget? status,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onPressed,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(isLoading ? 'Загрузка...' : 'Выбрать файл'),
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 12),
              status,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Загрузка документов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Подготовьте нормативные критерии и сценарий',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Загрузите выдержки из ФЗ-436 (или других регламентов) для построения RAG, затем отправьте сценарий для оценки возрастного рейтинга.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildUploadCard(
              icon: Icons.menu_book_outlined,
              title: 'Нормативный документ (ФЗ-436, методики и т.п.)',
              description:
                  'PDF/DOCX/TXT до 10 МБ. Параграфы будут проиндексированы для ссылок в отчёте.',
              isLoading: _uploadingCriteria,
              onPressed: () => _handleUpload(DocumentType.criteria),
              status: _criteriaDocumentId == null
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Файл $_criteriaFilename загружен',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_criteriaChunks != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Индексировано фрагментов: $_criteriaChunks',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
            ),
            _buildUploadCard(
              icon: Icons.movie_filter_outlined,
              title: 'Сценарий для оценки',
              description:
                  'PDF/DOCX/TXT до 10 МБ. После загрузки начнётся пошаговый анализ с прогрессом.',
              isLoading: _uploadingScript,
              onPressed: () => _handleUpload(DocumentType.script),
              status: _scriptFilename == null
                  ? null
                  : Row(
                      children: [
                        const Icon(Icons.play_circle, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Сценарий $_scriptFilename отправлен на анализ',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Подсказки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Сначала загрузите нормативный документ, чтобы блоки сценария получили корректные ссылки.\n'
              '• Можно переиспользовать ранее загруженный регламент — просто загружайте сразу сценарий.\n'
              '• Поддерживаются документы на русском языке; страницы и параграфы будут указаны в результатах.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
