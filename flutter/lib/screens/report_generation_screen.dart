import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  bool _isGenerating = false;
  bool _isGenerated = false;
  String? _error;
  String _selectedFormat = 'PDF';

  final List<Map<String, dynamic>> _formats = [
    {
      'name': 'PDF',
      'description': 'Portable Document Format - Best for printing and sharing',
      'icon': Icons.picture_as_pdf,
      'color': Colors.red,
    },
    {
      'name': 'DOCX',
      'description': 'Microsoft Word Document - Editable format',
      'icon': Icons.description,
      'color': Colors.blue,
    },
    {
      'name': 'HTML',
      'description': 'Web page format - Viewable in browsers',
      'icon': Icons.web,
      'color': Colors.green,
    },
    {
      'name': 'JSON',
      'description': 'Structured data format - For developers',
      'icon': Icons.code,
      'color': Colors.orange,
    },
  ];

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      // Mock generation delay
      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _isGenerated = true;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report generated successfully in $_selectedFormat format!',
          ),
          action: SnackBarAction(
            label: 'Download',
            onPressed: () {
              // Mock download action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download would start here')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to generate report: $e';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/results'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Report Format',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the format that best suits your needs',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ..._formats.map(
              (format) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<String>(
                  title: Row(
                    children: [
                      Icon(format['icon'], color: format['color']),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              format['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              format['description'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  value: format['name'],
                  groupValue: _selectedFormat,
                  onChanged: (value) {
                    setState(() {
                      _selectedFormat = value!;
                      _isGenerated =
                          false; // Reset generated state when format changes
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _isGenerating
                  ? const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating report...'),
                      ],
                    )
                  : _isGenerated
                  ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Report generated in $_selectedFormat format',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _isGenerated = false),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Generate Another'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Mock download
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Download would start here',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Download'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.file_download),
                      label: Text('Generate $_selectedFormat Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/results'),
                child: const Text('Back to Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
