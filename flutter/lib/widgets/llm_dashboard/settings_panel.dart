import 'package:flutter/material.dart';
import '../../models/llm_models.dart';
import '../../models/llm_provider.dart';

class SettingsPanel extends StatefulWidget {
  final LLMConfigResponse config;
  final Map<String, dynamic> configurationSettings;
  final Function(Map<String, dynamic> settings) onSettingsUpdated;
  final bool isLoading;

  const SettingsPanel({
    super.key,
    required this.config,
    required this.configurationSettings,
    required this.onSettingsUpdated,
    this.isLoading = false,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _editableSettings;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _editableSettings = Map.from(widget.configurationSettings);
  }

  @override
  void didUpdateWidget(SettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.configurationSettings != oldWidget.configurationSettings) {
      setState(() {
        _editableSettings = Map.from(widget.configurationSettings);
        _hasUnsavedChanges = false;
      });
    }
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
                Text('Settings Panel', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (_hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unsaved changes',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // General Settings
                  _buildSectionHeader('General Settings'),
                  const SizedBox(height: 8),
                  _buildGeneralSettings(),

                  const SizedBox(height: 16),

                  // Provider-specific Settings
                  _buildSectionHeader('Provider Settings'),
                  const SizedBox(height: 8),
                  _buildProviderSettings(),

                  const SizedBox(height: 16),

                  // Performance Settings
                  _buildSectionHeader('Performance Settings'),
                  const SizedBox(height: 8),
                  _buildPerformanceSettings(),

                  const SizedBox(height: 16),

                  // Advanced Settings
                  _buildSectionHeader('Advanced Settings'),
                  const SizedBox(height: 8),
                  _buildAdvancedSettings(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _hasUnsavedChanges ? _resetToDefaults : null,
                  child: const Text('Reset to Defaults'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _hasUnsavedChanges && !widget.isLoading ? _saveSettings : null,
                  child: widget.isLoading ? const Text('Saving...') : const Text('Save Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(Icons.settings, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return Column(
      children: [
        // Auto-save settings
        SwitchListTile(
          title: const Text('Auto-save configurations'),
          subtitle: const Text('Automatically save configuration changes'),
          value: _editableSettings['auto_save'] ?? true,
          onChanged: (value) => _updateSetting('auto_save', value),
        ),

        // Default provider
        ListTile(
          title: const Text('Default Provider'),
          subtitle: Text(widget.config.activeProvider.value),
          trailing: DropdownButton<String>(
            value: _getDefaultProviderValue(),
            items: _getDefaultProviderItems(),
            onChanged: (value) {
              if (value != null) {
                _updateSetting('default_provider', value);
              }
            },
          ),
        ),

        // Default model
        ListTile(
          title: const Text('Default Model'),
          subtitle: Text(widget.config.activeModel),
          trailing: DropdownButton<String>(
            value: _getDefaultModelValue(),
            items: _getDefaultModelItems(),
            onChanged: (value) {
              if (value != null) {
                _updateSetting('default_model', value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSettings() {
    return Column(
      children: [
        // Timeout settings
        ListTile(
          title: const Text('Request Timeout (seconds)'),
          subtitle: const Text('Maximum time to wait for provider responses'),
          trailing: SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: (_editableSettings['request_timeout'] ?? 30).toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: (value) => _updateSetting('request_timeout', int.tryParse(value) ?? 30),
            ),
          ),
        ),

        // Max retries
        ListTile(
          title: const Text('Max Retries'),
          subtitle: const Text('Maximum number of retry attempts'),
          trailing: SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: (_editableSettings['max_retries'] ?? 3).toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: (value) => _updateSetting('max_retries', int.tryParse(value) ?? 3),
            ),
          ),
        ),

        // Rate limiting
        SwitchListTile(
          title: const Text('Enable Rate Limiting'),
          subtitle: const Text('Automatically rate limit requests'),
          value: _editableSettings['rate_limiting'] ?? false,
          onChanged: (value) => _updateSetting('rate_limiting', value),
        ),
      ],
    );
  }

  Widget _buildPerformanceSettings() {
    return Column(
      children: [
        // Caching
        SwitchListTile(
          title: const Text('Enable Response Caching'),
          subtitle: const Text('Cache LLM responses for faster processing'),
          value: _editableSettings['caching_enabled'] ?? true,
          onChanged: (value) => _updateSetting('caching_enabled', value),
        ),

        // Cache duration
        ListTile(
          title: const Text('Cache Duration (hours)'),
          subtitle: const Text('How long to keep cached responses'),
          trailing: SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: (_editableSettings['cache_duration'] ?? 24).toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: (value) => _updateSetting('cache_duration', int.tryParse(value) ?? 24),
            ),
          ),
        ),

        // Batch processing
        SwitchListTile(
          title: const Text('Enable Batch Processing'),
          subtitle: const Text('Process multiple requests in batches'),
          value: _editableSettings['batch_processing'] ?? false,
          onChanged: (value) => _updateSetting('batch_processing', value),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      children: [
        // Debug mode
        SwitchListTile(
          title: const Text('Debug Mode'),
          subtitle: const Text('Enable detailed logging and debugging'),
          value: _editableSettings['debug_mode'] ?? false,
          onChanged: (value) => _updateSetting('debug_mode', value),
        ),

        // Log level
        ListTile(
          title: const Text('Log Level'),
          subtitle: const Text('Minimum log level to display'),
          trailing: DropdownButton<String>(
            value: _editableSettings['log_level'] ?? 'info',
            items: ['debug', 'info', 'warning', 'error'].map((level) {
              return DropdownMenuItem<String>(value: level, child: Text(level.toUpperCase()));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateSetting('log_level', value);
              }
            },
          ),
        ),

        // Auto-refresh status
        SwitchListTile(
          title: const Text('Auto-refresh Provider Status'),
          subtitle: const Text('Automatically check provider health every 30 seconds'),
          value: _editableSettings['auto_refresh_status'] ?? true,
          onChanged: (value) => _updateSetting('auto_refresh_status', value),
        ),
      ],
    );
  }

  String _getDefaultProviderValue() {
    final defaultProvider = _editableSettings['default_provider'];
    final availableProviders = widget.config.providers.keys.toList();

    // If the stored default provider exists in the available providers, use it
    if (defaultProvider != null) {
      final provider = LLMProvider.values.firstWhere(
        (p) => p.value == defaultProvider,
        orElse: () => widget.config.activeProvider,
      );
      if (availableProviders.contains(provider)) {
        return defaultProvider;
      }
    }

    // Otherwise, fall back to the active provider's value
    return widget.config.activeProvider.value;
  }

  List<DropdownMenuItem<String>> _getDefaultProviderItems() {
    return widget.config.providers.keys.map((provider) {
      return DropdownMenuItem<String>(value: provider.value, child: Text(provider.value));
    }).toList();
  }

  String _getDefaultModelValue() {
    final defaultModel = _editableSettings['default_model'];
    final availableModels = widget.config.models.keys.toList();

    // If the stored default model exists in the available models, use it
    if (defaultModel != null && availableModels.contains(defaultModel)) {
      return defaultModel;
    }

    // Otherwise, fall back to the active model
    return widget.config.activeModel;
  }

  List<DropdownMenuItem<String>> _getDefaultModelItems() {
    return widget.config.models.keys.take(10).map((model) {
      return DropdownMenuItem<String>(
        value: model,
        child: Text(model, overflow: TextOverflow.ellipsis),
      );
    }).toList();
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _editableSettings[key] = value;
      _hasUnsavedChanges = true;
    });
  }

  void _resetToDefaults() {
    setState(() {
      _editableSettings = {
        'auto_save': true,
        'request_timeout': 30,
        'max_retries': 3,
        'caching_enabled': true,
        'cache_duration': 24,
        'log_level': 'info',
        'auto_refresh_status': true,
      };
      _hasUnsavedChanges = true;
    });
  }

  void _saveSettings() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSettingsUpdated(_editableSettings);
      setState(() => _hasUnsavedChanges = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
      );
    }
  }
}
