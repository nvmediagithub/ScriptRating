import 'package:flutter/material.dart';

import '../models/age_rating.dart';
import '../models/normative_reference.dart';
import '../models/scene_assessment.dart';
import '../models/severity.dart';

class SceneDetailWidget extends StatelessWidget {
  final SceneAssessment assessment;
  final bool showReferences;
  final bool dense;

  const SceneDetailWidget({
    super.key,
    required this.assessment,
    this.showReferences = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final Severity highestSeverity = assessment.categories.isEmpty
        ? Severity.none
        : assessment.categories.values.reduce((a, b) => a.index >= b.index ? a : b);

    return Card(
      margin: EdgeInsets.only(bottom: dense ? 8 : 12),
      child: Padding(
        padding: EdgeInsets.all(dense ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _severityColor(highestSeverity),
                  radius: dense ? 14 : 16,
                  child: Text(
                    assessment.sceneNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        assessment.heading,
                        style: TextStyle(fontSize: dense ? 15 : 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'Страницы: ${assessment.pageRange}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (assessment.textPreview != null && assessment.textPreview!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          'Фрагмент: ${assessment.textPreview}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildChip(
                      label: assessment.ageRating.display,
                      color: _ratingColor(assessment.ageRating),
                    ),
                    const SizedBox(height: 6),
                    _buildChip(label: highestSeverity.name, color: _severityColor(highestSeverity)),
                  ],
                ),
              ],
            ),
            if (assessment.flaggedContent.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Обнаруженные элементы:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assessment.flaggedContent
                    .map(
                      (content) => Chip(
                        label: Text(content, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.red.shade50,
                        side: const BorderSide(color: Colors.redAccent),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            _buildCommentPanel(assessment.llmComment),
            if (assessment.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildHighlightedScript(context),
            ],
            if (showReferences && assessment.references.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReferencesSection(assessment.references),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color.darken(0.2), fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildCommentPanel(String comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              comment,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedScript(BuildContext context) {
    final text = assessment.text;
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4);
    final spans = <TextSpan>[];
    int cursor = 0;
    final sortedHighlights = [...assessment.highlights]..sort((a, b) => a.start.compareTo(b.start));

    for (final highlight in sortedHighlights) {
      final start = highlight.start.clamp(0, text.length);
      final end = highlight.end.clamp(0, text.length);
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start), style: baseStyle));
      }
      if (end > start) {
        final color = _highlightSeverityColor(highlight.severity);
        spans.add(
          TextSpan(
            text: text.substring(start, end),
            style: baseStyle?.copyWith(
              backgroundColor: color.withOpacity(0.18),
              color: color.darken(0.2),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      cursor = end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фрагмент сценария',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: dense ? 160 : 240),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(child: SelectableText.rich(TextSpan(children: spans))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferencesSection(List<NormativeReference> references) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Нормативные ссылки:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        ...references.map(
          (ref) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  ref.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  'Стр. ${ref.page}, п. ${ref.paragraph}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  ref.excerpt,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _severityColor(Severity severity) {
    switch (severity) {
      case Severity.none:
        return Colors.green;
      case Severity.mild:
        return Colors.amber;
      case Severity.moderate:
        return Colors.orange;
      case Severity.severe:
        return Colors.red;
    }
  }

  Color _ratingColor(AgeRating rating) {
    switch (rating) {
      case AgeRating.zeroPlus:
        return Colors.green;
      case AgeRating.sixPlus:
        return Colors.lightGreen;
      case AgeRating.twelvePlus:
        return Colors.orange;
      case AgeRating.sixteenPlus:
        return Colors.deepOrange;
      case AgeRating.eighteenPlus:
        return Colors.red;
    }
  }

  Color _highlightSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.none:
        return Colors.green;
      case Severity.mild:
        return Colors.lightGreen;
      case Severity.moderate:
        return Colors.orange;
      case Severity.severe:
        return Colors.redAccent;
    }
  }
}

extension _ColorShade on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
