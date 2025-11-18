import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/locator.dart';
import '../models/analysis_result.dart';
import '../models/document_type.dart';
import '../services/api_service.dart';
import '../models/rag_processing_details.dart';

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
  RagProcessingDetails? _ragProcessingDetails;
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
      
      // Validate file extension
      final extension = filename.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        setState(() => _error = 'Неподдерживаемый тип файла. Разрешены: ${allowedExtensions.join(', ')}');
        return;
      }
      
      // Validate file size (10MB limit)
      if (fileBytes.length > 10 * 1024 * 1024) {
        setState(() => _error = 'Файл слишком большой. Максимальный размер: 10 МБ');
        return;
      }

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
          _criteriaDocumentId = response.documentId;
          _criteriaChunks = response.chunksIndexed;
          _ragProcessingDetails = response.ragProcessingDetails;
        });
      } else {
        _scriptFilename = filename;
        final AnalysisResult analysis =
            await _apiService.analyzeScript(
          response.documentId,
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

  Widget _buildCriteriaStatus() {
    return Column(
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
        if (_ragProcessingDetails != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Отчёт обработки RAG',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildProcessingMetric(
                  'Фрагменты',
                  '${_ragProcessingDetails!.chunksProcessed}/${_ragProcessingDetails!.totalChunks}',
                  _ragProcessingDetails!.chunksProcessed == _ragProcessingDetails!.totalChunks
                      ? Colors.green
                      : Colors.orange,
                ),
                _buildProcessingMetric(
                  'Генерация эмбеддингов',
                  _ragProcessingDetails!.embeddingGenerationStatus == null
                      ? 'Неизвестно'
                      : _ragProcessingDetails!.embeddingGenerationStatus == 'success'
                          ? 'Успешно'
                          : _ragProcessingDetails!.embeddingGenerationStatus == 'partial'
                              ? 'Частично'
                              : 'Ошибка',
                  _ragProcessingDetails!.embeddingGenerationStatus == null
                      ? Colors.grey
                      : _ragProcessingDetails!.embeddingGenerationStatus == 'success'
                          ? Colors.green
                          : _ragProcessingDetails!.embeddingGenerationStatus == 'partial'
                              ? Colors.orange
                              : Colors.red,
                ),
                _buildProcessingMetric(
                  'Индексация БД',
                  _ragProcessingDetails!.vectorDbIndexingStatus == null
                      ? 'Неизвестно'
                      : _ragProcessingDetails!.vectorDbIndexingStatus == 'success'
                          ? 'Успешно'
                          : _ragProcessingDetails!.vectorDbIndexingStatus == 'partial'
                              ? 'Частично'
                              : 'Ошибка',
                  _ragProcessingDetails!.vectorDbIndexingStatus == null
                      ? Colors.grey
                      : _ragProcessingDetails!.vectorDbIndexingStatus == 'success'
                          ? Colors.green
                          : _ragProcessingDetails!.vectorDbIndexingStatus == 'partial'
                              ? Colors.orange
                              : Colors.red,
                ),
                if (_ragProcessingDetails!.embeddingModelUsed != null)
                  _buildProcessingMetric(
                    'Модель эмбеддингов',
                    _ragProcessingDetails!.embeddingModelUsed!,
                    Colors.blue,
                  ),
                if (_ragProcessingDetails!.indexingTimeMs != null)
                  _buildProcessingMetric(
                    'Время обработки',
                    _ragProcessingDetails!.processingTimeFormatted,
                    Colors.blue,
                  ),
                if (_ragProcessingDetails!.hasErrors)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ошибки обработки:',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...(_ragProcessingDetails!.processingErrors ?? []).map(
                          (error) => Text(
                            '• $error',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProcessingMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
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
                  : _buildCriteriaStatus(),
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
