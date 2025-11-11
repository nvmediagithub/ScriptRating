import 'package:flutter/material.dart';
import '../../models/llm_models.dart';
import '../../models/llm_provider.dart';

class ModelSelector extends StatefulWidget {
  final LLMConfigResponse config;
  final String activeModel;
  final Function(String modelName) onModelChanged;
  final bool isLoading;

  const ModelSelector({
    super.key,
    required this.config,
    required this.activeModel,
    required this.onModelChanged,
    this.isLoading = false,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  @override
  Widget build(BuildContext context) {
    final availableModels = widget.config.models.values
        .where((model) => model.provider == widget.config.activeProvider)
        .toList();

    // Create unique model list to prevent duplicate values
    final uniqueModels = <String>{};
    final uniqueAvailableModels = <LLMModelConfig>[];

    for (final model in availableModels) {
      if (uniqueModels.add(model.modelName)) {
        uniqueAvailableModels.add(model);
      }
    }

    // Ensure active model is included and valid
    String? dropdownValue = widget.activeModel;
    if (!uniqueAvailableModels.any((model) => model.modelName == dropdownValue)) {
      if (uniqueAvailableModels.isNotEmpty) {
        dropdownValue = uniqueAvailableModels.first.modelName;
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
              _buildNoModelsWidget(context),
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
                      message:
                          'Context: ${model.contextWindow}, Max Tokens: ${model.maxTokens}, Temp: ${model.temperature}',
                      child: Text(model.modelName),
                    ),
                  );
                }).toList(),
                onChanged: widget.isLoading
                    ? null
                    : (String? newValue) {
                        if (newValue != null && newValue != dropdownValue) {
                          widget.onModelChanged(newValue);
                        }
                      },
              ),

              const SizedBox(height: 16),

              // Model configuration display
              if (widget.config.activeModelConfig != null) ...[
                _buildModelConfigWidget(context, widget.config.activeModelConfig!),
              ],

              // Model-specific actions
              _buildModelActionsWidget(context, uniqueAvailableModels),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoModelsWidget(BuildContext context) {
    return Container(
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
              widget.config.activeProvider == LLMProvider.openrouter
                  ? 'No models available. Please configure OpenRouter with a valid API key to load available models.'
                  : 'No local models available. Please load a local model to continue.',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelConfigWidget(BuildContext context, LLMModelConfig modelConfig) {
    return Container(
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
          Row(
            children: [
              Icon(
                _getProviderIcon(modelConfig.provider),
                size: 16,
                color: _getProviderColor(modelConfig.provider),
              ),
              const SizedBox(width: 8),
              Text('Provider: ${modelConfig.provider.value}'),
            ],
          ),
          const SizedBox(height: 4),
          Text('Context Window: ${modelConfig.contextWindow}'),
          const SizedBox(height: 4),
          Text('Max Tokens: ${modelConfig.maxTokens}'),
          const SizedBox(height: 4),
          Text('Temperature: ${modelConfig.temperature}'),
          if (modelConfig.topP != 0.9) ...[
            const SizedBox(height: 4),
            Text('Top P: ${modelConfig.topP}'),
          ],
        ],
      ),
    );
  }

  Widget _buildModelActionsWidget(BuildContext context, List<LLMModelConfig> availableModels) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: widget.isLoading ? null : () => _testCurrentModel(),
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Test Model'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: availableModels.isNotEmpty
                  ? () => _showModelComparison(availableModels)
                  : null,
              icon: const Icon(Icons.compare),
              label: const Text('Compare'),
            ),
          ],
        ),
      ],
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

  void _testCurrentModel() {
    if (widget.config.activeModelConfig == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No model selected')));
      return;
    }

    // Navigate to test interface or show test dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This would open the test interface for:'),
            const SizedBox(height: 8),
            Text(
              widget.config.activeModelConfig!.modelName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showModelComparison(List<LLMModelConfig> availableModels) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Comparison'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableModels.length,
            itemBuilder: (context, index) {
              final model = availableModels[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.modelName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Context: ${model.contextWindow}'),
                      const SizedBox(height: 4),
                      Text('Max Tokens: ${model.maxTokens}'),
                      const SizedBox(height: 4),
                      Text('Temperature: ${model.temperature}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
