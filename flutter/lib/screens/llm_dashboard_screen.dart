import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/llm_service.dart';
import '../models/llm_provider.dart';
import '../models/llm_config_response.dart';
import '../models/llm_status_response.dart';

class LlmDashboardScreen extends StatefulWidget {
  const LlmDashboardScreen({super.key});

  @override
  State<LlmDashboardScreen> createState() => _LlmDashboardScreenState();
}

class _LlmDashboardScreenState extends State<LlmDashboardScreen> {
  final LlmService _llmService = LlmService(Dio());
  bool _isLoading = false;
  String? _errorMessage;
  LLMConfigResponse? _config;
  List<LLMStatusResponse>? _statuses;
  String _testPrompt = '';
  String _testResponse = '';
  String _apiKey = '';
  String _baseUrl = 'https://openrouter.ai/api/v1';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await _llmService.getLLMConfig();
      final statuses = await _llmService.getAllProvidersStatus();

      setState(() {
        _config = config;
        _statuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _configureOpenRouter() async {
    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an OpenRouter API key')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _llmService.configureOpenRouter(
        apiKey: _apiKey,
        baseUrl: _baseUrl,
        timeout: 30,
        maxRetries: 3,
      );

      await _loadDashboardData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OpenRouter configured successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Configuration failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchProvider(LLMProvider provider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _llmService.setActiveProvider(provider);
      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to switch provider: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchModel(String modelName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _llmService.setActiveModel(modelName);
      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to switch model: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testLLM() async {
    if (_testPrompt.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a test prompt')));
      return;
    }

    setState(() {
      _isLoading = true;
      _testResponse = '';
    });

    try {
      final testResponse = await _llmService.testLLM(_testPrompt);
      setState(() {
        _testResponse = testResponse.response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResponse = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildDashboardView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadDashboardData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    if (_config == null || _statuses == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 16),
          _buildProviderConfigurationCard(),
          const SizedBox(height: 16),
          _buildModelSelectionCard(),
          const SizedBox(height: 16),
          _buildStatusMonitoringCard(),
          const SizedBox(height: 16),
          _buildTestInterfaceCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Overview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getProviderIcon(_config!.activeProvider),
                  color: _getProviderColor(_config!.activeProvider),
                ),
                const SizedBox(width: 8),
                Text('Active Provider: ${_config!.activeProvider.value}'),
              ],
            ),
            const SizedBox(height: 4),
            Text('Active Model: ${_config!.activeModel}'),
            const SizedBox(height: 4),
            Text('Available Models: ${_config!.models.length}'),
            const SizedBox(height: 4),
            Text('Configured Providers: ${_config!.providers.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider Configuration', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // OpenRouter Configuration
            ExpansionTile(
              title: const Text('OpenRouter Configuration'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'OpenRouter API Key',
                          hintText: 'sk-or-...',
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          setState(() {
                            _apiKey = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Base URL',
                          hintText: 'https://openrouter.ai/api/v1',
                        ),
                        controller: TextEditingController(text: _baseUrl),
                        onChanged: (value) {
                          setState(() {
                            _baseUrl = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _configureOpenRouter,
                        child: const Text('Configure OpenRouter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Provider List
            const SizedBox(height: 16),
            Text('Available Providers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._config!.providers.entries.map(
              (entry) => ListTile(
                leading: Icon(_getProviderIcon(entry.key), color: _getProviderColor(entry.key)),
                title: Text(entry.key.value),
                subtitle: Text(entry.value.apiKey != null ? 'Configured' : 'Not configured'),
                trailing: _config!.activeProvider == entry.key
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: _config!.activeProvider == entry.key
                    ? null
                    : () => _switchProvider(entry.key),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelectionCard() {
    final availableModels = _config!.models.values
        .where((model) => model.provider == _config!.activeProvider)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model Selection', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _config!.activeModel,
              decoration: const InputDecoration(
                labelText: 'Select Model',
                border: OutlineInputBorder(),
              ),
              items: availableModels.map((model) {
                return DropdownMenuItem<String>(
                  value: model.modelName,
                  child: Text(model.modelName),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _switchModel(newValue);
                }
              },
            ),

            if (_config!.activeModelConfig != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Model Configuration', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text('Provider: ${_config!.activeModelConfig.provider.value}'),
                    Text('Context Window: ${_config!.activeModelConfig.contextWindow}'),
                    Text('Max Tokens: ${_config!.activeModelConfig.maxTokens}'),
                    Text('Temperature: ${_config!.activeModelConfig.temperature}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMonitoringCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider Status', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            ..._statuses!
                .map(
                  (status) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status),
                      child: Icon(_getStatusIcon(status), color: Colors.white),
                    ),
                    title: Text(status.provider.value),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getStatusText(status)),
                        if (status.responseTimeMs != null)
                          Text('Response time: ${status.responseTimeMs!.toStringAsFixed(0)}ms'),
                        if (status.errorMessage != null)
                          Text(status.errorMessage!, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    trailing: Text(
                      _formatTime(status.lastCheckedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInterfaceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Interface', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Test Prompt',
                hintText: 'Enter a test prompt for the LLM...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _testPrompt = value;
                });
              },
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLLM,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Test LLM'),
            ),

            if (_testResponse.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Response:', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SelectableText(_testResponse, style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.local:
        return Icons.computer;
      case LLMProvider.openrouter:
        return Icons.cloud;
    }
  }

  Color _getProviderColor(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.local:
        return Colors.blue;
      case LLMProvider.openrouter:
        return Colors.orange;
    }
  }

  Color _getStatusColor(LLMStatusResponse status) {
    if (!status.available) return Colors.red;
    if (!status.healthy) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(LLMStatusResponse status) {
    if (!status.available) return Icons.error;
    if (!status.healthy) return Icons.warning;
    return Icons.check_circle;
  }

  String _getStatusText(LLMStatusResponse status) {
    if (!status.available) return 'Unavailable';
    if (!status.healthy) return 'Unhealthy';
    return 'Healthy';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
