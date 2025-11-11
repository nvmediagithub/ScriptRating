import 'package:flutter/material.dart';
import '../../models/llm_models.dart';
import '../../models/llm_provider.dart';

class ProviderConfigCard extends StatefulWidget {
  final LLMConfigResponse config;
  final LLMProviderSettings? providerSettings;
  final Function(LLMProvider provider) onSwitchProvider;
  final Function(String apiKey, String baseUrl) onConfigureProvider;
  final bool isLoading;

  const ProviderConfigCard({
    super.key,
    required this.config,
    required this.providerSettings,
    required this.onSwitchProvider,
    required this.onConfigureProvider,
    this.isLoading = false,
  });

  @override
  State<ProviderConfigCard> createState() => _ProviderConfigCardState();
}

class _ProviderConfigCardState extends State<ProviderConfigCard> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  bool _showConfiguration = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
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
            Text('Provider Configuration', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Provider List
            ...widget.config.providers.entries.map(
              (entry) => _buildProviderTile(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(LLMProvider provider, LLMProviderSettings settings) {
    final isActive = widget.config.activeProvider == provider;
    final isConfigured = _isProviderConfigured(provider, settings);

    return Card(
      child: ListTile(
        leading: Icon(_getProviderIcon(provider), color: _getProviderColor(provider)),
        title: Text(
          provider.value,
          style: isActive ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isConfigured ? 'Configured' : 'Not configured'),
            if (isActive)
              const Text(
                'Active',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
              ),
            if (provider == LLMProvider.openrouter && !isConfigured && !widget.isLoading)
              const Text(
                'Click to configure OpenRouter API key',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : widget.isLoading
            ? const SizedBox(
                width: 80,
                height: 32,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : isConfigured
            ? _buildSwitchButton(provider)
            : _buildConfigButton(provider),
        onTap: isActive ? null : () => _onProviderTapped(provider, isConfigured),
        enabled: !isActive,
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

  bool _isProviderConfigured(LLMProvider provider, LLMProviderSettings settings) {
    switch (provider) {
      case LLMProvider.local:
        return true; // Local provider is always considered configured
      case LLMProvider.openrouter:
        // Check for configured status - the backend returns "configured" as the api_key value when it's set
        return settings.apiKey != null &&
            (settings.apiKey == "configured" ||
                (settings.apiKey!.isNotEmpty && settings.apiKey!.startsWith('sk-or-')));
    }
  }

  Widget _buildSwitchButton(LLMProvider provider) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : () => widget.onSwitchProvider(provider),
      child: Text('Switch'),
    );
  }

  Widget _buildConfigButton(LLMProvider provider) {
    if (provider == LLMProvider.openrouter) {
      return ElevatedButton(
        onPressed: () => setState(() => _showConfiguration = true),
        child: const Text('Configure'),
      );
    }
    return const SizedBox.shrink();
  }

  void _onProviderTapped(LLMProvider provider, bool isConfigured) {
    if (provider == LLMProvider.openrouter && !isConfigured) {
      setState(() => _showConfiguration = true);
    } else {
      widget.onSwitchProvider(provider);
    }
  }

  void _handleConfiguration() {
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an API key')));
      return;
    }

    if (!_isValidOpenRouterKey(apiKey)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid API key format')));
      return;
    }

    widget.onConfigureProvider(apiKey, baseUrl);
    setState(() => _showConfiguration = false);
    _apiKeyController.clear();
    _baseUrlController.clear();
  }

  bool _isValidOpenRouterKey(String key) {
    return key.startsWith('sk-or-') && key.length > 20;
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure OpenRouter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-or-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL (optional)',
                hintText: 'https://openrouter.ai/api/v1',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showConfiguration = false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _handleConfiguration,
            child: widget.isLoading ? const Text('Configuring...') : const Text('Configure'),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(ProviderConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_showConfiguration && !widget.isLoading) {
      _showConfigurationDialog();
    }
  }
}
