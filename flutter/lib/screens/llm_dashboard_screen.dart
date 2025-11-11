import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/llm_dashboard_provider.dart';
import '../models/llm_models.dart';
import '../models/llm_provider.dart';
import '../widgets/llm_dashboard/provider_config_card.dart';
import '../widgets/llm_dashboard/model_selector.dart';
import '../widgets/llm_dashboard/provider_status_card.dart';
import '../widgets/llm_dashboard/test_connection_widget.dart';
import '../widgets/llm_dashboard/settings_panel.dart';
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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
        _showFloatingActionButton = _selectedTabIndex == 3; // Show FAB only for chat tab
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
        title: const Text('LLM Configuration & Testing Dashboard'),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Configuration'),
            Tab(icon: Icon(Icons.speed), text: 'Status & Testing'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.chat), text: 'Chat Interface'),
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
        _buildChatInterfaceTab(state),
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

          // Provider Configuration
          ProviderConfigCard(
            config: state.config,
            providerSettings: state.config.activeProviderSettings,
            onSwitchProvider: (provider) => _switchProvider(provider),
            onConfigureProvider: (apiKey, baseUrl) => _configureProvider(apiKey, baseUrl),
            isLoading: state.isRefreshing,
          ),
          const SizedBox(height: 16),

          // Model Selection
          ModelSelector(
            config: state.config,
            activeModel: state.config.activeModel,
            onModelChanged: (modelName) => _switchModel(modelName),
            isLoading: state.isRefreshing,
          ),
          const SizedBox(height: 16),

          // Settings Panel
          SettingsPanel(
            config: state.config,
            configurationSettings: state.configurationSettings,
            onSettingsUpdated: (settings) => _updateSettings(settings),
            isLoading: state.isRefreshing,
          ),
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
          if (state.config.activeProvider != null)
            TestConnectionWidget(
              provider: state.config.activeProvider,
              modelName: state.config.activeModel,
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
            performanceReports: state.performanceReports,
            isLoading: state.isRefreshing,
          ),
        );
      },
    );
  }

  Widget _buildChatInterfaceTab(dynamic state) {
    return const Center(child: Text('Chat Interface - Coming Soon'));
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
                    color: state.healthSummary.systemHealthy ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.healthSummary.systemHealthy ? 'Healthy' : 'Issues Detected',
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
                    state.config.activeProvider.value,
                    Icons.cloud,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetric(
                    'Active Model',
                    state.config.activeModel,
                    Icons.model_training,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetric(
                    'Available Models',
                    state.config.models.length.toString(),
                    Icons.list,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Healthy Providers',
                    '${state.statuses.where((LLMStatusResponse s) => s.healthy).length}/${state.statuses.length}',
                    Icons.health_and_safety,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetric(
                    'Configured Providers',
                    state.config.providers.length.toString(),
                    Icons.settings,
                  ),
                ),
              ],
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

  // Action handlers
  Future<void> _switchProvider(LLMProvider provider) async {
    try {
      await ref.read(llmDashboardProvider.notifier).switchActiveProvider(provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to ${provider.value}'), backgroundColor: Colors.green),
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

  Future<void> _configureProvider(String apiKey, String baseUrl) async {
    try {
      await ref
          .read(llmDashboardProvider.notifier)
          .configureProvider(LLMProvider.openrouter, apiKey, baseUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider configured successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to configure provider: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testConnection(LLMProvider provider) async {
    try {
      final isConnected = await ref
          .read(llmDashboardProvider.notifier)
          .testProviderConnection(provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.value} connection: ${isConnected ? 'Successful' : 'Failed'}'),
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

  Future<void> _updateSettings(Map<String, dynamic> settings) async {
    try {
      await ref.read(llmDashboardProvider.notifier).updateConfigurationSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleTestComplete(String prompt, String response) {
    // Handle test completion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test completed successfully'), backgroundColor: Colors.green),
      );
    }
  }

  Map<LLMProvider, LLMStatusResponse> _getProviderStatusMap(List<LLMStatusResponse> statuses) {
    return {for (final status in statuses) status.provider: status};
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LLM Dashboard'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 2.0.0'),
            SizedBox(height: 8),
            Text('Features:'),
            Text('• Provider Configuration & Management'),
            Text('• Real-time Status Monitoring'),
            Text('• Model Selection & Testing'),
            Text('• Connection Testing'),
            Text('• Analytics & Statistics'),
            Text('• Chat Interface Integration'),
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
