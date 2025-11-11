import 'package:flutter/material.dart';
import 'dart:math';

class StatsDisplay extends StatefulWidget {
  final Map<String, Map<String, dynamic>> providerStatuses;
  final Map<String, dynamic> usageStats;
  final List<Map<String, dynamic>> performanceReports;
  final bool isLoading;

  const StatsDisplay({
    super.key,
    required this.providerStatuses,
    required this.usageStats,
    required this.performanceReports,
    this.isLoading = false,
  });

  @override
  State<StatsDisplay> createState() => _StatsDisplayState();
}

class _StatsDisplayState extends State<StatsDisplay> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '24h';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                Text('Usage Statistics', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedTimeRange,
                  items: const [
                    DropdownMenuItem(value: '1h', child: Text('Last Hour')),
                    DropdownMenuItem(value: '24h', child: Text('Last 24 Hours')),
                    DropdownMenuItem(value: '7d', child: Text('Last 7 Days')),
                    DropdownMenuItem(value: '30d', child: Text('Last 30 Days')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTimeRange = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.speed), text: 'Performance'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab content
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [_buildOverviewTab(), _buildPerformanceTab(), _buildAnalyticsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalRequests = widget.usageStats['total_requests'] ?? 0;
    final successfulRequests = widget.usageStats['successful_requests'] ?? 0;
    final failedRequests = widget.usageStats['failed_requests'] ?? 0;
    final totalTokens = widget.usageStats['total_tokens_used'] ?? 0;
    final avgResponseTime = widget.usageStats['average_response_time_ms'] ?? 0.0;

    return Column(
      children: [
        // Key metrics row
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Requests',
                  totalRequests.toString(),
                  Icons.request_quote,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${totalRequests > 0 ? ((successfulRequests / totalRequests) * 100).toStringAsFixed(1) : '0.0'}%',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Tokens', totalTokens.toString(), Icons.data_usage),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Avg Response',
                  '${avgResponseTime.toStringAsFixed(0)}ms',
                  Icons.speed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Provider breakdown
        Expanded(child: _buildProviderBreakdown()),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    return Column(
      children: [
        // Performance summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Performance',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                    Text(
                      'Overall system health and performance metrics',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Performance reports
        Expanded(
          child: widget.performanceReports.isEmpty
              ? Center(
                  child: Text(
                    'No performance reports available',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.performanceReports.length,
                  itemBuilder: (context, index) {
                    final report = widget.performanceReports[index];
                    return _buildPerformanceReportCard(report);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return Column(
      children: [
        // Usage trends
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Trends',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                    Text(
                      'Request patterns and usage analytics',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Charts would go here in a real implementation
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Analytics charts will be implemented\nwith real data visualization',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBreakdown() {
    if (widget.providerStatuses.isEmpty) {
      return Center(
        child: Text('No provider data available', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Provider Status Breakdown', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: widget.providerStatuses.length,
            itemBuilder: (context, index) {
              final provider = widget.providerStatuses.keys.elementAt(index);
              final status = widget.providerStatuses[provider]!;
              return _buildProviderStatusRow(provider, status);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderStatusRow(String provider, Map<String, dynamic> status) {
    final available = status['available'] as bool? ?? false;
    final healthy = status['healthy'] as bool? ?? false;
    final isHealthy = available && healthy;
    final healthColor = isHealthy ? Colors.green : (available ? Colors.orange : Colors.red);
    final responseTimeMs = status['response_time_ms'] as double?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: healthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: healthColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getProviderIcon(provider), color: healthColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider,
                  style: TextStyle(fontWeight: FontWeight.bold, color: healthColor),
                ),
                Text(
                  isHealthy ? 'Healthy' : (available ? 'Unhealthy' : 'Unavailable'),
                  style: TextStyle(fontSize: 12, color: healthColor),
                ),
              ],
            ),
          ),
          if (responseTimeMs != null)
            Text(
              '${responseTimeMs.toStringAsFixed(0)}ms',
              style: TextStyle(fontSize: 12, color: healthColor),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceReportCard(Map<String, dynamic> report) {
    final provider = report['provider'] as String? ?? 'unknown';
    final metrics = report['metrics'] as Map<String, dynamic>? ?? {};
    final timeRange = report['time_range'] as String? ?? 'unknown';
    final generatedAt = report['generated_at'] != null
        ? DateTime.parse(report['generated_at'] as String)
        : DateTime.now();

    final totalRequests = metrics['total_requests'] as int? ?? 0;
    final successfulRequests = metrics['successful_requests'] as int? ?? 0;
    final avgResponseTimeMs = metrics['average_response_time_ms'] as double? ?? 0.0;

    final successRate = totalRequests > 0 ? ((successfulRequests / totalRequests) * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getProviderIcon(provider), color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$provider - $timeRange',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMiniMetric('Requests', totalRequests.toString())),
                Expanded(
                  child: _buildMiniMetric('Success Rate', '${successRate.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMiniMetric(
                    'Avg Response',
                    '${avgResponseTimeMs.toStringAsFixed(0)}ms',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generated: ${_formatTime(generatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
