import 'package:flutter/material.dart';

class TestConnectionWidget extends StatefulWidget {
  final String provider;
  final String? modelName;
  final Function(String prompt, String response) onTestComplete;
  final Function(String provider) onTestConnection;
  final bool isLoading;

  const TestConnectionWidget({
    super.key,
    required this.provider,
    this.modelName,
    required this.onTestComplete,
    required this.onTestConnection,
    this.isLoading = false,
  });

  @override
  State<TestConnectionWidget> createState() => _TestConnectionWidgetState();
}

class _TestConnectionWidgetState extends State<TestConnectionWidget> {
  final _promptController = TextEditingController();
  final _responseController = TextEditingController();
  bool _isTestRunning = false;
  String? _lastTestResult;
  DateTime? _lastTestTime;
  double? _responseTime;

  @override
  void dispose() {
    _promptController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Connection Testing', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isTestRunning ? null : () => _testConnectionOnly(),
                  tooltip: 'Test Connection',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Provider info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _getProviderIcon(widget.provider),
                    color: _getProviderColor(widget.provider),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provider: ${widget.provider}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (widget.modelName != null) Text('Model: ${widget.modelName}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick connection test
            _buildConnectionTestSection(),
            const SizedBox(height: 16),

            // LLM response test
            _buildResponseTestSection(),
            const SizedBox(height: 16),

            // Test history
            if (_lastTestResult != null) _buildTestHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connection Test', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isTestRunning ? null : _testConnectionOnly,
          icon: _isTestRunning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.network_check),
          label: const Text('Test Connection'),
        ),
        const SizedBox(height: 8),
        if (_lastTestTime != null)
          Text(
            'Last tested: ${_formatTime(_lastTestTime!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildResponseTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Response Test', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _promptController,
          decoration: const InputDecoration(
            labelText: 'Test Prompt',
            hintText: 'Enter a test message for the LLM',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isTestRunning || _promptController.text.trim().isEmpty
              ? null
              : _testFullResponse,
          icon: _isTestRunning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Send Test Message'),
        ),
        const SizedBox(height: 8),
        if (_responseController.text.isNotEmpty) ...[
          Text('Response:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text(_responseController.text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ],
    );
  }

  Widget _buildTestHistory() {
    final isSuccess = _lastTestResult == 'success';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSuccess ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isSuccess ? 'Connection Successful' : 'Connection Failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (_responseTime != null) ...[
            const SizedBox(height: 4),
            Text(
              'Response time: ${_responseTime!.toStringAsFixed(0)}ms',
              style: TextStyle(
                fontSize: 12,
                color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'local':
        return Icons.computer;
      case 'openrouter':
        return Icons.cloud;
      default:
        return Icons.settings;
    }
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'local':
        return Colors.blue;
      case 'openrouter':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _testConnectionOnly() async {
    setState(() {
      _isTestRunning = true;
      _lastTestResult = null;
    });

    try {
      final stopwatch = Stopwatch()..start();
      widget.onTestConnection(widget.provider);
      stopwatch.stop();

      setState(() {
        _lastTestResult = 'success';
        _lastTestTime = DateTime.now();
        _responseTime = stopwatch.elapsedMilliseconds.toDouble();
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'failed';
        _lastTestTime = DateTime.now();
        _responseTime = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection test failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isTestRunning = false);
    }
  }

  Future<void> _testFullResponse() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isTestRunning = true;
      _responseController.clear();
    });

    try {
      final stopwatch = Stopwatch()..start();

      // This would call the actual LLM test
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      final response = 'This is a test response to: "$prompt"';

      stopwatch.stop();

      setState(() {
        _responseController.text = response;
        _lastTestResult = 'success';
        _lastTestTime = DateTime.now();
        _responseTime = stopwatch.elapsedMilliseconds.toDouble();
        _isTestRunning = false;
      });

      widget.onTestComplete(prompt, response);
    } catch (e) {
      setState(() {
        _responseController.text = 'Error: $e';
        _lastTestResult = 'failed';
        _lastTestTime = DateTime.now();
        _responseTime = null;
        _isTestRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Response test failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
