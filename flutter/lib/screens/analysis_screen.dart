import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  double _progress = 0.0;
  bool _isAnalyzing = false;
  bool _isCompleted = false;
  String _currentStep = 'Initializing analysis...';

  final List<String> _analysisSteps = [
    'Parsing document...',
    'Segmenting scenes...',
    'Analyzing content...',
    'Evaluating ratings...',
    'Generating report...',
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _progress = 0.0;
    });

    for (int i = 0; i < _analysisSteps.length; i++) {
      setState(() {
        _currentStep = _analysisSteps[i];
        _progress = (i + 1) / _analysisSteps.length;
      });

      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return; // Check if widget is still mounted
    }

    setState(() {
      _isAnalyzing = false;
      _isCompleted = true;
    });

    // Navigate to results after a short delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      context.go('/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzing Script'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Script Analysis in Progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${(_progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAnalyzing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_isCompleted)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else
                      const Icon(Icons.hourglass_empty, color: Colors.orange),
                    const SizedBox(width: 16),
                    Text(
                      _currentStep,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_isCompleted)
                const Text(
                  'Analysis completed successfully!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}