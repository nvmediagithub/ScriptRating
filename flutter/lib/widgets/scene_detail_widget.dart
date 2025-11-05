import 'package:flutter/material.dart';
import '../models/scene_assessment.dart';
import '../models/severity.dart';

class SceneDetailWidget extends StatelessWidget {
  final SceneAssessment assessment;

  const SceneDetailWidget({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final highestSeverity = assessment.categories.values
        .reduce((a, b) => a.index > b.index ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getSeverityColor(highestSeverity),
                  radius: 16,
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
                      Text(
                        assessment.heading,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pages: ${assessment.pageRange}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(highestSeverity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getSeverityColor(highestSeverity).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    highestSeverity.name,
                    style: TextStyle(
                      color: _getSeverityColor(highestSeverity),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (assessment.flaggedContent.isNotEmpty) ...[
              const Text(
                'Flagged Content:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assessment.flaggedContent.map((content) {
                  return Chip(
                    label: Text(
                      content,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.red.shade50,
                    side: const BorderSide(color: Colors.red),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      assessment.justification ?? 'No justification provided',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.none:
        return Colors.green;
      case Severity.mild:
        return Colors.yellow.shade700;
      case Severity.moderate:
        return Colors.orange;
      case Severity.severe:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'G':
        return Colors.green;
      case 'PG':
        return Colors.blue;
      case 'PG-13':
        return Colors.orange;
      case 'R':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}