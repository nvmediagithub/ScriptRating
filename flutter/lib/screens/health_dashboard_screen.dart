import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/health_service.dart';
import '../models/health_status.dart';
import '../models/error_history.dart';

// Provider for health service
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(Dio());
});

// Provider for auto-refresh settings
final autoRefreshProvider = StateProvider<bool>((ref) => false);

// Provider for refresh interval
final refreshIntervalProvider = StateProvider<Duration>((ref) => const Duration(seconds: 30));

// Provider for error history
final errorHistoryProvider = StateNotifierProvider<ErrorHistoryNotifier, AsyncValue<ErrorHistory>>((ref) {
  final healthService = ref.watch(healthServiceProvider);
  return ErrorHistoryNotifier(healthService);
});

// Provider for health status with auto-refresh
final healthStatusProvider = StateNotifierProvider<HealthStatusNotifier, AsyncValue<HealthStatus>>((ref) {
  final healthService = ref.watch(healthServiceProvider);
  final autoRefresh = ref.watch(autoRefreshProvider);
  final refreshInterval = ref.watch(refreshIntervalProvider);

  final notifier = HealthStatusNotifier(healthService);
  notifier.updateAutoRefresh(autoRefresh, refreshInterval);

  ref.listen(autoRefreshProvider, (previous, next) {
    notifier.updateAutoRefresh(next, refreshInterval);
  });

  ref.listen(refreshIntervalProvider, (previous, next) {
    notifier.updateAutoRefresh(autoRefresh, next);
  });

  return notifier;
});

class ErrorHistoryNotifier extends StateNotifier<AsyncValue<ErrorHistory>> {
  final HealthService _healthService;
  Timer? _refreshTimer;

  ErrorHistoryNotifier(this._healthService) : super(const AsyncValue.loading()) {
    loadErrorHistory();
  }

  Future<void> loadErrorHistory() async {
    try {
      // For now, we'll create mock error history since the backend might not have this endpoint yet
      final mockErrors = [
        ErrorEntry(
          timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          serviceName: 'Qdrant Database',
          error: 'Connection timeout',
          details: 'Failed to connect to Qdrant at localhost:6333',
          resolved: true,
        ),
        ErrorEntry(
          timestamp: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          serviceName: 'Embedding Service',
          error: 'Rate limit exceeded',
          details: 'OpenRouter API rate limit reached',
          resolved: true,
        ),
      ];

      final errorHistory = ErrorHistory(
        errors: mockErrors,
        totalErrors: mockErrors.length,
        resolvedErrors: mockErrors.where((e) => e.resolved).length,
      );

      state = AsyncValue.data(errorHistory);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void startPeriodicRefresh(Duration interval) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => loadErrorHistory());
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}

class HealthStatusNotifier extends StateNotifier<AsyncValue<HealthStatus>> {
  final HealthService _healthService;
  Timer? _refreshTimer;
  bool _autoRefresh = false;
  Duration _refreshInterval = const Duration(seconds: 30);

  HealthStatusNotifier(this._healthService) : super(const AsyncValue.loading()) {
    loadHealthStatus();
  }

  Future<void> loadHealthStatus() async {
    state = const AsyncValue.loading();
    try {
      final healthStatus = await _healthService.getComprehensiveHealth();
      state = AsyncValue.data(healthStatus);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadHealthStatus();
  }

  void updateAutoRefresh(bool autoRefresh, Duration interval) {
    _autoRefresh = autoRefresh;
    _refreshInterval = interval;

    _refreshTimer?.cancel();

    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(_refreshInterval, (_) => loadHealthStatus());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class HealthDashboardScreen extends ConsumerWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthStatusProvider);
    final autoRefresh = ref.watch(autoRefreshProvider);
    final refreshInterval = ref.watch(refreshIntervalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          // Auto-refresh toggle
          IconButton(
            icon: Icon(autoRefresh ? Icons.timer : Icons.timer_off),
            tooltip: autoRefresh ? 'Disable auto-refresh' : 'Enable auto-refresh',
            onPressed: () => ref.read(autoRefreshProvider.notifier).state = !autoRefresh,
          ),
          // Refresh interval selector
          PopupMenuButton<Duration>(
            tooltip: 'Refresh interval',
            icon: const Icon(Icons.more_time),
            onSelected: (interval) => ref.read(refreshIntervalProvider.notifier).state = interval,
            itemBuilder: (context) => [
              const PopupMenuItem(value: Duration(seconds: 10), child: Text('10 seconds')),
              const PopupMenuItem(value: Duration(seconds: 30), child: Text('30 seconds')),
              const PopupMenuItem(value: Duration(seconds: 60), child: Text('1 minute')),
              const PopupMenuItem(value: Duration(seconds: 300), child: Text('5 minutes')),
            ],
            initialValue: refreshInterval,
          ),
          // Manual refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh now',
            onPressed: () => ref.read(healthStatusProvider.notifier).refresh(),
          ),
        ],
      ),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load health status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(healthStatusProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (healthStatus) => _buildHealthDashboard(context, healthStatus, ref),
      ),
    );
  }

  Widget _buildHealthDashboard(BuildContext context, HealthStatus healthStatus, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.read(healthStatusProvider.notifier).refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStatusCard(context, healthStatus),
            const SizedBox(height: 16),
            _buildServicesSection(context, healthStatus, ref),
            const SizedBox(height: 16),
            if (healthStatus.errors.isNotEmpty) ...[
              _buildErrorsSection(context, healthStatus.errors),
              const SizedBox(height: 16),
            ],
            if (healthStatus.warnings.isNotEmpty) ...[
              _buildWarningsSection(context, healthStatus.warnings),
              const SizedBox(height: 16),
            ],
            if (healthStatus.configuration != null) ...[
              _buildConfigurationSection(context, healthStatus.configuration!),
              const SizedBox(height: 16),
            ],
            _buildErrorHistorySection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatusCard(BuildContext context, HealthStatus healthStatus) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  healthStatus.statusIcon,
                  color: healthStatus.statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Status: ${healthStatus.overallStatus.toUpperCase()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: healthStatus.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last updated: ${DateTime.parse(healthStatus.timestamp).toLocal().toString()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context, HealthStatus healthStatus, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Services (${healthStatus.services.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => ref.read(healthStatusProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...healthStatus.services.entries.map((entry) =>
          _buildServiceCard(context, entry.key, entry.value, ref)),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, String serviceName, ServiceStatus serviceStatus, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  serviceStatus.available ? Icons.check_circle : Icons.error,
                  color: serviceStatus.available ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    serviceName.replaceAll('_', ' ').toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Individual refresh button
                IconButton(
                  onPressed: () => ref.read(healthStatusProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  tooltip: 'Refresh ${serviceName}',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: serviceStatus.available ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    serviceStatus.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (serviceStatus.type != null) ...[
              const SizedBox(height: 4),
              Text(
                'Type: ${serviceStatus.type}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (serviceStatus.error != null) ...[
              const SizedBox(height: 4),
              ExpansionTile(
                title: Text(
                  'Error Details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      serviceStatus.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (serviceStatus.detailedHealth != null && serviceStatus.detailedHealth!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: Text(
                  'Health Metrics',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  _buildDetailedHealth(context, serviceStatus.detailedHealth!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedHealth(BuildContext context, Map<String, dynamic> detailedHealth) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: detailedHealth.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorsSection(BuildContext context, List<String> errors) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Errors (${errors.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...errors.map((error) => Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert, size: 16),
                      tooltip: 'Error actions',
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsSection(BuildContext context, List<String> warnings) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Warnings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...warnings.map((warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $warning',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection(BuildContext context, ConfigurationStatus config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RAG Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...config.rag.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getValueColor(entry.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Text(
                  'Environment Variables',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...config.environment.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        color: entry.value ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorHistorySection(BuildContext context, WidgetRef ref) {
    final errorHistoryAsync = ref.watch(errorHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Error History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => ref.read(errorHistoryProvider.notifier).loadErrorHistory(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        errorHistoryAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load error history: $error'),
            ),
          ),
          data: (errorHistory) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Errors (${errorHistory.errors.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (errorHistory.errors.isNotEmpty) ...[
                    ...errorHistory.errors.take(5).map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: error.resolved ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  error.serviceName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  error.error,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: error.resolved ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  error.formattedTime,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (errorHistory.errors.length > 5) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        child: Text('View all ${errorHistory.errors.length} errors'),
                      ),
                    ],
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No errors in history'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getValueColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green : Colors.red;
    } else if (value is String) {
      return value.toLowerCase() == 'true' || value.toLowerCase() == 'enabled' ? Colors.green : Colors.grey;
    }
    return Colors.blue;
  }
}