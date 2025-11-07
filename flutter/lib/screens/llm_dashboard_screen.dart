import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/llm_service.dart';
import '../models/llm_models.dart';
import '../models/llm_provider.dart';

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
    // Validate API key format
    if (_apiKey.trim().isEmpty) {
      _showValidationError('Please enter an OpenRouter API key');
      return;
    }

    if (!_isValidOpenRouterKey(_apiKey)) {
      _showValidationError('Invalid API key format. OpenRouter keys should start with "sk-or-"');
      return;
    }

    if (_baseUrl.trim().isEmpty) {
      _showValidationError('Please enter a base URL');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Clear previous error state
      setState(() {
        _errorMessage = null;
      });

      await _llmService.configureOpenRouter(
        apiKey: _apiKey.trim(),
        baseUrl: _baseUrl.trim(),
        timeout: 30,
        maxRetries: 3,
      );

      await _loadDashboardData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OpenRouter configured successfully! Models are now available.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        String userFriendlyMessage;
        
        if (errorMessage.contains('401') || errorMessage.contains('unauthorized')) {
          userFriendlyMessage = 'Invalid API key. Please check your OpenRouter API key and try again.';
        } else if (errorMessage.contains('403') || errorMessage.contains('forbidden')) {
          userFriendlyMessage = 'Access denied. Please verify your API key has the necessary permissions.';
        } else if (errorMessage.contains('timeout') || errorMessage.contains('connection')) {
          userFriendlyMessage = 'Connection failed. Please check your internet connection and try again.';
        } else {
          userFriendlyMessage = 'Configuration failed: ${errorMessage.contains('Exception:') ? errorMessage.replaceAll('Exception: ', '') : errorMessage}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Help',
              textColor: Colors.white,
              onPressed: () => _showOpenRouterConfigHelp(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidOpenRouterKey(String key) {
    // OpenRouter keys typically start with "sk-or-" and are quite long
    return key.trim().startsWith('sk-or-') && key.trim().length > 20;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _switchProvider(LLMProvider provider) async {
    // Prevent switching to the same provider
    if (_config!.activeProvider == provider) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _llmService.setActiveProvider(provider);
      await _loadDashboardData();
      
      if (mounted) {
        final providerName = provider.value;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully switched to $providerName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to switch provider';
        if (provider == LLMProvider.openrouter) {
          if (e.toString().contains('api_key') || e.toString().contains('unauthorized')) {
            errorMessage = 'OpenRouter not configured. Please configure your API key first.';
          } else if (e.toString().contains('connection') || e.toString().contains('timeout')) {
            errorMessage = 'Connection failed. Please check your internet connection and OpenRouter status.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: ${e.toString().contains('Exception:') ? e.toString().replaceAll('Exception: ', '') : e}'),
            backgroundColor: Colors.red,
            action: provider == LLMProvider.openrouter ? SnackBarAction(
              label: 'Configure',
              textColor: Colors.white,
              onPressed: () {
                // Scroll to OpenRouter configuration
                Scrollable.ensureVisible(
                  context,
                  duration: const Duration(milliseconds: 500),
                );
              },
            ) : null,
          ),
        );
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
              title: Row(
                children: [
                  Icon(Icons.cloud, color: _config!.providers[LLMProvider.openrouter]?.apiKey != null ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  const Text('OpenRouter Configuration'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _config!.providers[LLMProvider.openrouter]?.apiKey != null ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _config!.providers[LLMProvider.openrouter]?.apiKey != null ? 'Configured' : 'Not Configured',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Configuration Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _config!.providers[LLMProvider.openrouter]?.apiKey != null ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _config!.providers[LLMProvider.openrouter]?.apiKey != null ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _config!.providers[LLMProvider.openrouter]?.apiKey != null ? Icons.check_circle : Icons.info,
                                  color: _config!.providers[LLMProvider.openrouter]?.apiKey != null ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _config!.providers[LLMProvider.openrouter]?.apiKey != null
                                      ? 'OpenRouter is configured and ready to use'
                                      : 'OpenRouter needs to be configured to access cloud-based models',
                                  style: TextStyle(
                                    color: _config!.providers[LLMProvider.openrouter]?.apiKey != null ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (_config!.providers[LLMProvider.openrouter]?.apiKey == null) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Get your API key from: https://openrouter.ai/keys',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // API Key Input
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'OpenRouter API Key',
                          hintText: 'sk-or-...',
                          prefixIcon: const Icon(Icons.key),
                          suffixIcon: _apiKey.isNotEmpty
                              ? (_isValidOpenRouterKey(_apiKey)
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.error, color: Colors.red))
                              : null,
                          border: const OutlineInputBorder(),
                          errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                        ),
                        obscureText: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // Don't show error for empty field initially
                          }
                          if (!_isValidOpenRouterKey(value)) {
                            return 'Invalid format. Should start with "sk-or-" and be at least 20 characters';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _apiKey = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Base URL Input
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Base URL',
                          hintText: 'https://openrouter.ai/api/v1',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(text: _baseUrl),
                        onChanged: (value) {
                          setState(() {
                            _baseUrl = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Configure Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _configureOpenRouter,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_done),
                          label: Text(_isLoading ? 'Configuring...' : 'Configure OpenRouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Quick Help
                      TextButton.icon(
                        onPressed: _showOpenRouterConfigHelp,
                        icon: const Icon(Icons.help, size: 16),
                        label: const Text('Need help getting started?'),
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
              (entry) => Card(
                child: ListTile(
                  leading: Icon(
                    _getProviderIcon(entry.key),
                    color: _getProviderColor(entry.key),
                  ),
                  title: Text(
                    entry.key.value,
                    style: _config!.activeProvider == entry.key
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isProviderConfigured(entry.key) ? 'Configured' : 'Not configured'),
                      if (_config!.activeProvider == entry.key)
                        const Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  trailing: _config!.activeProvider == entry.key
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _isProviderConfigurable(entry.key)
                          ? (entry.key == LLMProvider.openrouter && !_isProviderConfigured(entry.key)
                              ? IconButton(
                                  icon: const Icon(Icons.add, color: Colors.orange),
                                  onPressed: () {
                                    // Scroll to OpenRouter configuration
                                    Scrollable.ensureVisible(
                                      context,
                                      duration: const Duration(milliseconds: 500),
                                    );
                                  },
                                )
                              : null)
                          : null,
                  onTap: _config!.activeProvider == entry.key
                      ? null
                      : () => _switchProvider(entry.key),
                  enabled: _config!.activeProvider != entry.key,
                ),
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

    // Create unique model list to prevent duplicate values
    final uniqueModels = <String>{};
    final uniqueAvailableModels = <LLMModelConfig>[];
    
    for (final model in availableModels) {
      if (uniqueModels.add(model.modelName)) {
        uniqueAvailableModels.add(model);
      } else {
        // Log duplicate found (for debugging)
        debugPrint('Duplicate model found: ${model.modelName} for provider ${model.provider.value}');
      }
    }

    // Ensure active model is included and valid
    String? dropdownValue = _config!.activeModel;
    if (!uniqueAvailableModels.any((model) => model.modelName == dropdownValue)) {
      if (uniqueAvailableModels.isNotEmpty) {
        dropdownValue = uniqueAvailableModels.first.modelName;
        // Update the active model to a valid one
        _switchModel(dropdownValue);
      } else {
        dropdownValue = null;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model Selection', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Check if we have any available models
            if (uniqueAvailableModels.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _config!.activeProvider == LLMProvider.openrouter
                            ? 'No models available. Please configure OpenRouter with a valid API key to load available models.'
                            : 'No local models available. Please load a local model to continue.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () {
                  if (_config!.activeProvider == LLMProvider.openrouter) {
                    // Scroll to OpenRouter configuration
                    _showOpenRouterConfigHelp();
                  } else {
                    // For local provider, suggest loading a model
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please load a local model through the provider status section')),
                    );
                  }
                },
                icon: const Icon(Icons.help),
                label: Text(
                  _config!.activeProvider == LLMProvider.openrouter
                      ? 'Configure OpenRouter'
                      : 'Load Local Model',
                ),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: dropdownValue,
                decoration: const InputDecoration(
                  labelText: 'Select Model',
                  border: OutlineInputBorder(),
                ),
                items: uniqueAvailableModels.map((model) {
                  return DropdownMenuItem<String>(
                    value: model.modelName,
                    child: Tooltip(
                      message: 'Context: ${model.contextWindow}, Max Tokens: ${model.maxTokens}, Temp: ${model.temperature}',
                      child: Text(model.modelName),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != dropdownValue) {
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
                      Text('Provider: ${_config!.activeModelConfig!.provider.value}'),
                      Text('Context Window: ${_config!.activeModelConfig!.contextWindow}'),
                      Text('Max Tokens: ${_config!.activeModelConfig!.maxTokens}'),
                      Text('Temperature: ${_config!.activeModelConfig!.temperature}'),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showOpenRouterConfigHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('OpenRouter Configuration Help'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To configure OpenRouter:'),
              SizedBox(height: 8),
              Text('1. Get your API key from https://openrouter.ai/keys'),
              Text('2. Enter it in the OpenRouter Configuration section above'),
              Text('3. Click "Configure OpenRouter"'),
              Text('4. Models will automatically load after successful configuration'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
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

  /// Check if a provider is configured and ready to use
  bool _isProviderConfigured(LLMProvider provider) {
    final settings = _config!.providers[provider];
    if (settings == null) return false;

    switch (provider) {
      case LLMProvider.local:
        return true; // Local provider is always considered configured
      case LLMProvider.openrouter:
        return settings.apiKey != null &&
               settings.apiKey!.isNotEmpty &&
               settings.apiKey!.startsWith('sk-or-');
    }
  }

  /// Check if a provider can be configured by the user
  bool _isProviderConfigurable(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.local:
        return false; // Local provider doesn't need user configuration
      case LLMProvider.openrouter:
        return true; // OpenRouter can be configured by users
    }
  }
}
