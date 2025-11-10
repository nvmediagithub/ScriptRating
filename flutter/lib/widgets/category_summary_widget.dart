import 'package:flutter/material.dart';

class CategorySummaryWidget extends StatelessWidget {
  final Map<String, double> categories;

  const CategorySummaryWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Категории содержания',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categories.entries.map(
              (entry) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      SelectableText(
                        '${(entry.value * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(entry.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(entry.value)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: SelectableText(
                      'Чем выше показатель, тем заметнее проявление категории в сценарии. Значения выше 60% обычно повышают возрастной рейтинг.',
                      style: TextStyle(fontSize: 12, color: Colors.blue, height: 1.3),
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

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.red;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.4) return Colors.yellow.shade700;
    return Colors.green;
  }
}
