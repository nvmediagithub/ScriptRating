import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/llm_dashboard_provider.dart';
import '../widgets/llm_dashboard/simple_provider_switcher.dart';
import '../widgets/llm_dashboard/provider_status_card.dart';
import '../widgets/llm_dashboard/test_connection_widget.dart';
import '../widgets/llm_dashboard/stats_display.dart';

class LlmDashboardScreen extends ConsumerStatefulWidget {
  const LlmDashboardScreen({super.key});

  @override
  ConsumerState<LlmDashboardScreen> createState() => _LlmDashboardScreenState();
}

class _LlmDashboardScreenState extends ConsumerState<LlmDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _showFloatingActionButton = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
        _showFloatingActionButton = _selectedTabIndex == 2; // Show FAB only for chat tab
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final llmDashboardState = ref.watch(llmDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Provider Configuration'),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'Provider Setup'),
            Tab(icon: Icon(Icons.speed), text: 'Status & Testing'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(llmDashboardProvider.notifier).refresh(),
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAboutDialog,
            tooltip: 'About',
          ),
        ],
      ),
      body: llmDashboardState.when(
        data: (state) => _buildDashboardContent(state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error),
      ),
      floatingActionButton: _showFloatingActionButton
          ? FloatingActionButton(
              onPressed: () => _showQuickTestDialog(),
              tooltip: 'Quick Test',
              child: const Icon(Icons.play_arrow),
            )
          : null,
    );
  }

  Widget _buildDashboardContent(dynamic state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildConfigurationTab(state),
        _buildStatusTestingTab(state),
        _buildAnalyticsTab(state),
      ],
    );
  }

  Widget _buildConfigurationTab(dynamic state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overview Card
          _buildOverviewCard(state),
          const SizedBox(height: 16),

          // Simple Provider Switcher
          SimpleProviderSwitcher(
            currentProvider: state.config['active_provider'] as String,
            openRouterConfigured: _isOpenRouterConfigured(state),
            isLoading: state.isRefreshing,
            onSwitchProvider: (provider) => _switchProvider(provider),
          ),
          const SizedBox(height: 16),

          // System Status
          _buildSystemStatusCard(state),
        ],
      ),
    );
  }

  Widget _buildStatusTestingTab(dynamic state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Provider Status
          ProviderStatusCard(
            statuses: state.statuses,
            onTestConnection: (provider) => _testConnection(provider),
            isLoading: state.isRefreshing,
          ),
          const SizedBox(height: 16),

          // Test Connection Widget
          if (state.config['active_provider'] != null)
            TestConnectionWidget(
              provider: state.config['active_provider'],
              modelName: state.config['active_model'],
              onTestComplete: (prompt, response) => _handleTestComplete(prompt, response),
              onTestConnection: (provider) => _testConnection(provider),
              isLoading: state.isRefreshing,
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(dynamic state) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(llmDashboardProvider.notifier).getUsageStats(),
      builder: (context, snapshot) {
        final usageStats = snapshot.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StatsDisplay(
            providerStatuses: _getProviderStatusMap(state.statuses),
            usageStats: usageStats,
            performanceReports: [],
            isLoading: state.isRefreshing,
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(dynamic state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('System Overview', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isSystemHealthy(state) ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isSystemHealthy(state) ? 'Healthy' : 'Issues Detected',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Active Provider',
                    state.config['active_provider'] as String,
                    Icons.tune,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetric(
                    'Active Model',
                    state.config['active_model'] as String,
                    Icons.model_training,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard(dynamic state) {
    final openRouterConfigured = _isOpenRouterConfigured(state);
    final activeProvider = state.config['active_provider'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Configuration', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  activeProvider == 'local' ? Icons.computer : Icons.cloud,
                  color: activeProvider == 'local' ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mode: ${activeProvider.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: activeProvider == 'local' ? Colors.blue : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  openRouterConfigured ? Icons.check_circle : Icons.warning,
                  color: openRouterConfigured ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  openRouterConfigured ? 'OpenRouter API configured' : 'OpenRouter not configured',
                  style: TextStyle(
                    color: openRouterConfigured ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              activeProvider == 'local'
                  ? 'Using local models. Future integration with Ollama planned.'
                  : 'Using OpenRouter API with cloud-based models.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(llmDashboardProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool _isOpenRouterConfigured(dynamic state) {
    try {
      final providers = state.config['providers'] as Map<String, dynamic>;
      final openRouterConfig = providers['openrouter'] as Map<String, dynamic>;
      return openRouterConfig['configured'] as bool;
    } catch (e) {
      return false;
    }
  }

  bool _isSystemHealthy(dynamic state) {
    try {
      final healthSummary = state.healthSummary as Map<String, dynamic>;
      return healthSummary['system_healthy'] as bool;
    } catch (e) {
      return false;
    }
  }

  Map<String, Map<String, dynamic>> _getProviderStatusMap(List<Map<String, dynamic>> statuses) {
    return {for (final status in statuses) status['provider'] as String: status};
  }

  // Action handlers (simplified to work with string providers)
  Future<void> _switchProvider(String provider) async {
    try {
      await ref.read(llmDashboardProvider.notifier).switchActiveProvider(provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to $provider'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch provider: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _switchModel(String modelName) async {
    try {
      await ref.read(llmDashboardProvider.notifier).switchActiveModel(modelName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to model: $modelName'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch model: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testConnection(String provider) async {
    try {
      final isConnected = await ref
          .read(llmDashboardProvider.notifier)
          .testProviderConnection(provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$provider connection: ${isConnected ? 'Successful' : 'Failed'}'),
            backgroundColor: isConnected ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Test failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _handleTestComplete(String prompt, String response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test completed successfully'), backgroundColor: Colors.green),
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LLM Provider Dashboard'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 3.0.0 - Simplified'),
            SizedBox(height: 8),
            Text('Features:'),
            Text('• Simple two-mode provider switching'),
            Text('• Local and OpenRouter modes'),
            Text('• Real-time status monitoring'),
            Text('• Connection testing'),
            Text('• Usage analytics'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showQuickTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Test'),
        content: const Text(
          'This would open a quick test interface for the current configuration.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement quick test logic
            },
            child: const Text('Start Test'),
          ),
        ],
      ),
    );
  }
}
