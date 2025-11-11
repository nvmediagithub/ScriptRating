import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/llm_models.dart';
import '../../models/llm_provider.dart';

class ProviderStatusCard extends StatefulWidget {
  final List<LLMStatusResponse> statuses;
  final Function(LLMProvider provider) onTestConnection;
  final bool isLoading;
  final bool autoRefresh;

  const ProviderStatusCard({
    super.key,
    required this.statuses,
    required this.onTestConnection,
    this.isLoading = false,
    this.autoRefresh = true,
  });

  @override
  State<ProviderStatusCard> createState() => _ProviderStatusCardState();
}

class _ProviderStatusCardState extends State<ProviderStatusCard> {
  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
                Text('Provider Status', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (widget.autoRefresh)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: widget.isLoading ? null : () => _refreshStatuses(),
                    tooltip: 'Refresh Status',
                  ),
                IconButton(
                  icon: Icon(_getOverallStatusIcon()),
                  onPressed: _showStatusDetails,
                  tooltip: 'System Health',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overall health indicator
            _buildOverallHealthIndicator(),
            const SizedBox(height: 16),

            // Provider status list
            ...widget.statuses.map((status) => _buildProviderStatusTile(status)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallHealthIndicator() {
    final healthyProviders = widget.statuses.where((s) => s.healthy).length;
    final totalProviders = widget.statuses.length;
    final healthPercentage = totalProviders > 0 ? (healthyProviders / totalProviders) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: healthPercentage == 100
            ? Colors.green.shade50
            : healthPercentage >= 50
            ? Colors.orange.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: healthPercentage == 100
              ? Colors.green
              : healthPercentage >= 50
              ? Colors.orange
              : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getOverallStatusIcon(),
            color: healthPercentage == 100
                ? Colors.green
                : healthPercentage >= 50
                ? Colors.orange
                : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Health: ${healthPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: healthPercentage == 100
                        ? Colors.green.shade700
                        : healthPercentage >= 50
                        ? Colors.orange.shade700
                        : Colors.red.shade700,
                  ),
                ),
                Text(
                  '$healthyProviders/$totalProviders providers healthy',
                  style: TextStyle(
                    fontSize: 12,
                    color: healthPercentage == 100
                        ? Colors.green.shade600
                        : healthPercentage >= 50
                        ? Colors.orange.shade600
                        : Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: healthPercentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              healthPercentage == 100
                  ? Colors.green
                  : healthPercentage >= 50
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderStatusTile(LLMStatusResponse status) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(_getStatusIcon(status), color: Colors.white, size: 20),
        ),
        title: Text(
          status.provider.value,
          style: TextStyle(
            fontWeight: _isProviderHealthy(status) ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusText(status)),
            if (status.responseTimeMs != null)
              Text('Response time: ${status.responseTimeMs!.toStringAsFixed(0)}ms'),
            if (status.errorMessage != null)
              Text(
                status.errorMessage!,
                style: const TextStyle(color: Colors.red),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'Last checked: ${_formatTime(status.lastCheckedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: widget.isLoading ? null : () => widget.onTestConnection(status.provider),
              tooltip: 'Test Connection',
            ),
            if (_isProviderHealthy(status)) Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
        onTap: () => _showProviderDetails(status),
        isThreeLine: status.errorMessage != null,
      ),
    );
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

  IconData _getOverallStatusIcon() {
    if (widget.statuses.isEmpty) return Icons.help;
    final healthyCount = widget.statuses.where(_isProviderHealthy).length;
    if (healthyCount == widget.statuses.length) return Icons.check_circle;
    if (healthyCount > 0) return Icons.warning;
    return Icons.error;
  }

  String _getStatusText(LLMStatusResponse status) {
    if (!status.available) return 'Unavailable';
    if (!status.healthy) return 'Unhealthy';
    return 'Healthy';
  }

  bool _isProviderHealthy(LLMStatusResponse status) {
    return status.available && status.healthy;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _refreshStatuses() {
    // This would trigger a refresh of the statuses
    // The actual refresh logic would be handled by the parent component
    widget.onTestConnection(widget.statuses.first.provider);
  }

  void _showProviderDetails(LLMStatusResponse status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status.provider.value} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', _getStatusText(status)),
            _buildDetailRow('Available', status.available ? 'Yes' : 'No'),
            _buildDetailRow('Healthy', status.healthy ? 'Yes' : 'No'),
            if (status.responseTimeMs != null)
              _buildDetailRow('Response Time', '${status.responseTimeMs!.toStringAsFixed(0)}ms'),
            _buildDetailRow('Last Checked', _formatTime(status.lastCheckedAt)),
            if (status.errorMessage != null) ...[
              const SizedBox(height: 8),
              const Text('Error Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(status.errorMessage!),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onTestConnection(status.provider);
            },
            child: const Text('Test Connection'),
          ),
        ],
      ),
    );
  }

  void _showStatusDetails() {
    final healthyCount = widget.statuses.where(_isProviderHealthy).length;
    final totalCount = widget.statuses.length;
    final healthPercentage = totalCount > 0 ? (healthyCount / totalCount) * 100 : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Health Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Overall Health', '${healthPercentage.toStringAsFixed(0)}%'),
            _buildDetailRow('Healthy Providers', '$healthyCount/$totalCount'),
            const SizedBox(height: 16),
            const Text('Provider Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.statuses.map(
              (status) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(status), size: 16, color: _getStatusColor(status)),
                    const SizedBox(width: 8),
                    Text('${status.provider.value}: ${_getStatusText(status)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
