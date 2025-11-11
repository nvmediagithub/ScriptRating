import 'package:flutter/material.dart';

class SimpleProviderSwitcher extends StatefulWidget {
  final String currentProvider;
  final bool openRouterConfigured;
  final bool isLoading;
  final Function(String provider) onSwitchProvider;

  const SimpleProviderSwitcher({
    super.key,
    required this.currentProvider,
    required this.openRouterConfigured,
    required this.isLoading,
    required this.onSwitchProvider,
  });

  @override
  State<SimpleProviderSwitcher> createState() => _SimpleProviderSwitcherState();
}

class _SimpleProviderSwitcherState extends State<SimpleProviderSwitcher> {
  String? _lastSwitchResult;
  bool _isSwitching = false;

  Future<void> _handleProviderSwitch(String provider) async {
    if (_isSwitching || widget.isLoading) return;

    setState(() {
      _isSwitching = true;
      _lastSwitchResult = null;
    });

    try {
      await widget.onSwitchProvider(provider);
      setState(() {
        _lastSwitchResult = 'Successfully switched to $provider';
      });
    } catch (e) {
      setState(() {
        _lastSwitchResult = 'Switch failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIsLoading = widget.isLoading || _isSwitching;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('LLM Provider Mode', style: Theme.of(context).textTheme.headlineSmall),
                if (_isSwitching) ...[
                  const SizedBox(width: 8),
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Simple toggle switch between Local and OpenRouter
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      'local',
                      Icons.computer,
                      'Local',
                      Colors.blue,
                      widget.currentProvider == 'local',
                      currentIsLoading,
                    ),
                  ),
                  Expanded(
                    child: _buildModeButton(
                      'openrouter',
                      Icons.cloud,
                      'OpenRouter',
                      Colors.orange,
                      widget.currentProvider == 'openrouter',
                      currentIsLoading,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status indicator
            _buildStatusIndicator(),

            // Info text
            const SizedBox(height: 8),
            _buildInfoText(),

            // Result message
            if (_lastSwitchResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lastSwitchResult!.startsWith('Successfully')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _lastSwitchResult!.startsWith('Successfully')
                        ? Colors.green
                        : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  _lastSwitchResult!,
                  style: TextStyle(
                    color: _lastSwitchResult!.startsWith('Successfully')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    String provider,
    IconData icon,
    String label,
    Color color,
    bool isActive,
    bool isLoading,
  ) {
    final isDisabled = provider == 'openrouter' && !widget.openRouterConfigured;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled || isLoading ? null : () => widget.onSwitchProvider(provider),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isActive ? color : Colors.transparent, width: 1),
          ),
          child: Column(
            children: [
              if (isLoading && isActive)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(isActive ? Colors.white : color),
                  ),
                )
              else
                Icon(
                  icon,
                  color: isActive ? Colors.white : (isDisabled ? Colors.grey : color),
                  size: 24,
                ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : (isDisabled ? Colors.grey : color),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (isDisabled) ...[
                const SizedBox(height: 2),
                Text(
                  'Not configured',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isActiveLocal = widget.currentProvider == 'local';
    final statusColor = isActiveLocal ? Colors.green : Colors.orange;
    final statusText = isActiveLocal ? 'Local Mode Active' : 'OpenRouter Mode Active';
    final statusIcon = isActiveLocal ? Icons.computer : Icons.cloud;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText() {
    final isActiveLocal = widget.currentProvider == 'local';

    if (isActiveLocal) {
      return const Text(
        'Using local models (mocked for now, will use Ollama later). '
        'Fast and private, no API calls required.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (widget.openRouterConfigured) {
      return const Text(
        'Using OpenRouter API with models from .env configuration. '
        'Access to powerful cloud-based models.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else {
      return Text(
        'OpenRouter not configured. Set OPENROUTER_API_KEY in your .env file.',
        style: TextStyle(fontSize: 12, color: Colors.red.shade600),
      );
    }
  }
}
