import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/llm_dashboard_state.dart";
import "../models/llm_models.dart";
import "../providers/llm_dashboard_provider.dart";

class LlmDashboardScreen extends ConsumerWidget {
  const LlmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(llmDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Control Center'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await ref
                    .read(llmDashboardProvider.notifier)
                    .refresh(force: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('LLM status refreshed')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Refresh failed: \$error'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          error: error,
          onRetry: () =>
              ref.read(llmDashboardProvider.notifier).refresh(force: true),
        ),
        data: (dashboard) => _DashboardView(dashboard: dashboard),
      ),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView({required this.dashboard});

  final LlmDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(llmDashboardProvider.notifier);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => notifier.refresh(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _ActiveConfigurationCard(dashboard: dashboard),
              const SizedBox(height: 16),
              _ProviderStatusSection(dashboard: dashboard),
              const SizedBox(height: 16),
              _LocalModelsSection(dashboard: dashboard),
              const SizedBox(height: 16),
              _OpenRouterSection(dashboard: dashboard),
              const SizedBox(height: 16),
              _PerformanceSection(dashboard: dashboard),
            ],
          ),
        ),
        if (dashboard.isRefreshing)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveConfigurationCard extends ConsumerWidget {
  const _ActiveConfigurationCard({required this.dashboard});

  final LlmDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = dashboard.config;
    final localLoaded = dashboard.localModels.loadedModels.toSet();
    final isBusy = dashboard.isRefreshing;

    // Create a unique set of dropdown items to prevent duplicate values
    final uniqueValues = <String>{};
    final dropdownItems = config.models.entries.map((entry) {
      final modelName = entry.key;
      final modelConfig = entry.value;
      final provider = modelConfig.provider;
      final isLocal = provider == LLMProvider.local;
      final isAvailable = isLocal
          ? localLoaded.contains(modelName)
          : dashboard.openRouterStatus.connected;
      final indicatorColor = isAvailable
          ? Theme.of(context).colorScheme.primary
          : Colors.grey;
      
      // Create unique value for dropdown
      String dropdownValue = '${provider.name}|$modelName';
      
      // Ensure uniqueness by adding suffix if needed
      int counter = 1;
      while (uniqueValues.contains(dropdownValue)) {
        counter++;
        dropdownValue = '${provider.name}|$modelName#$counter';
      }
      uniqueValues.add(dropdownValue);
      
      return DropdownMenuItem<String>(
        value: dropdownValue, // Use unique value for dropdown
        enabled: isAvailable,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocal ? Icons.computer : Icons.cloud,
              size: 18,
              color: indicatorColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                '${_providerLabel(provider)} • $modelName',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isAvailable)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.lock_clock,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      );
    }).toList();

    // Create unique value for active configuration to match dropdown format
    String activeValue = '${config.activeProvider.name}|${config.activeModel}';
    
    // Check if this exact value would be duplicated and add counter if needed
    final modelCounts = <String, int>{};
    for (final entry in config.models.entries) {
      final modelName = entry.key;
      final provider = entry.value.provider.name;
      final value = '$provider|$modelName';
      modelCounts[value] = (modelCounts[value] ?? 0) + 1;
    }
    
    // If there are duplicates, add counter to make it unique
    if (modelCounts[activeValue] != null && modelCounts[activeValue]! > 1) {
      // Find the index of this specific item
      int index = 0;
      for (final entry in config.models.entries) {
        final modelName = entry.key;
        final provider = entry.value.provider.name;
        final value = '$provider|$modelName';
        
        if (value == activeValue) {
          if (config.activeProvider.name == provider && config.activeModel == modelName) {
            // This is the active model, check its position
            index++;
            if (index > 1) {
              activeValue = '$activeValue#$index';
            }
            break;
          }
        }
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active LLM Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Select the provider and model used for analysis and recommendations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: activeValue,
              decoration: const InputDecoration(
                labelText: 'Provider · Model',
                border: OutlineInputBorder(),
              ),
              items: dropdownItems,
              onChanged: isBusy
                  ? null
                  : (value) async {
                      if (value == null) return;
                      final parts = value.split('|');
                      final provider = LLMProvider.values.firstWhere(
                        (element) => element.name == parts.first,
                      );
                      
                      // Remove any counter suffix from model name
                      final modelNameWithCounter = parts.last;
                      final modelName = modelNameWithCounter.split('#').first;
                      
                      if (provider == LLMProvider.local &&
                          !localLoaded.contains(modelName)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Load the local model into memory before activation.',
                            ),
                            showCloseIcon: true,
                          ),
                        );
                        return;
                      }

                      try {
                        await ref
                            .read(llmDashboardProvider.notifier)
                            .switchActiveModel(provider, modelName);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Active model set to $modelName (${_providerLabel(provider)})',
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switch failed: $error'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryChip(
                  icon: Icons.shield_outlined,
                  color: dashboard.healthSummary.systemHealthy
                      ? Colors.green
                      : Colors.orange,
                  label: dashboard.healthSummary.systemHealthy
                      ? 'System healthy'
                      : 'Attention needed',
                ),
                _SummaryChip(
                  icon: Icons.hub_outlined,
                  color: config.activeProvider == LLMProvider.local
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  label:
                      'Local models loaded: '
                      '${dashboard.localModels.loadedModels.length}'
                      '/${dashboard.localModels.models.length}',
                ),
                _SummaryChip(
                  icon: Icons.cloud_outlined,
                  color: dashboard.openRouterStatus.connected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  label: dashboard.openRouterStatus.connected
                      ? 'OpenRouter connected'
                      : 'OpenRouter offline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _providerLabel(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.local:
        return 'Local';
      case LLMProvider.openrouter:
        return 'OpenRouter';
    }
  }
}

class _ProviderStatusSection extends StatelessWidget {
  const _ProviderStatusSection({required this.dashboard});

  final LlmDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Provider Status', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: dashboard.statuses.map((status) {
            final isActive = dashboard.config.activeProvider == status.provider;
            final colorScheme = Theme.of(context).colorScheme;
            final statusColor = status.healthy ? Colors.green : Colors.red;
            return SizedBox(
              width: 300,
              child: Card(
                elevation: isActive ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            status.provider == LLMProvider.local
                                ? Icons.computer
                                : Icons.cloud,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status.provider == LLMProvider.local
                                  ? 'Local Runtime'
                                  : 'OpenRouter API',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.circle, color: statusColor, size: 14),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status.available ? 'Available' : 'Unavailable',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (status.responseTimeMs != null)
                            Text(
                              '${status.responseTimeMs!.toStringAsFixed(0)} ms',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                      if (status.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          status.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Last check: ${status.lastCheckedAt.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LocalModelsSection extends ConsumerWidget {
  const _LocalModelsSection({required this.dashboard});

  final LlmDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(llmDashboardProvider.notifier);
    final isBusy = dashboard.isRefreshing;
    final activeModel = dashboard.config.activeModel;
    final isActiveLocal = dashboard.config.activeProvider == LLMProvider.local
        ? activeModel
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Local Models', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                '${dashboard.localModels.loadedModels.length} loaded',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: dashboard.localModels.models.map((model) {
            final isLoaded = dashboard.localModels.loadedModels.contains(
              model.modelName,
            );
            final isActive = isActiveLocal == model.modelName;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.memory,
                          color: isLoaded ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            model.modelName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive
                                ? 'Active'
                                : (isLoaded ? 'Loaded' : 'Idle'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Size: ${model.sizeGb.toStringAsFixed(1)} GB',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Context: ${model.contextWindow}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Max tokens: ${model.maxTokens}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (model.lastUsed != null)
                          Text(
                            'Last used: ${model.lastUsed!.toLocal()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(
                              isLoaded ? Icons.remove_circle : Icons.download,
                            ),
                            label: Text(
                              isLoaded ? 'Unload from RAM' : 'Load into RAM',
                            ),
                            onPressed: isBusy
                                ? null
                                : () async {
                                    try {
                                      if (isLoaded) {
                                        await notifier.unloadLocalModel(
                                          model.modelName,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Model ${model.modelName} unloaded',
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        await notifier.loadLocalModel(
                                          model.modelName,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Model ${model.modelName} loaded',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Operation failed: \$error',
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.play_circle),
                            label: Text(
                              isActive ? 'Currently Active' : 'Activate',
                            ),
                            onPressed: isBusy || !isLoaded
                                ? null
                                : () async {
                                    try {
                                      await notifier.switchActiveModel(
                                        LLMProvider.local,
                                        model.modelName,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Activated local model ${model.modelName}',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Activation failed: \$error',
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _OpenRouterSection extends ConsumerWidget {
  const _OpenRouterSection({required this.dashboard});

  final LlmDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(llmDashboardProvider.notifier);
    final isBusy = dashboard.isRefreshing;
    final activeProvider = dashboard.config.activeProvider;
    final activeModel = dashboard.config.activeModel;
    final openRouterConnected = dashboard.openRouterStatus.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'OpenRouter Models',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 8),
            Icon(
              openRouterConnected ? Icons.cloud_done : Icons.cloud_off,
              color: openRouterConnected ? Colors.green : Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          openRouterConnected
              ? 'Credits: ${dashboard.openRouterStatus.creditsRemaining?.toStringAsFixed(2) ?? 'n/a'} • '
                    'Rate limit: ${dashboard.openRouterStatus.rateLimitRemaining ?? 'n/a'}'
              : (dashboard.openRouterStatus.errorMessage ??
                    'Connect to OpenRouter to enable network-based models.'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: dashboard.openRouterModels.models.map((modelName) {
            final isActive =
                activeProvider == LLMProvider.openrouter &&
                activeModel == modelName;

            return ChoiceChip(
              avatar: Icon(
                Icons.bolt,
                size: 18,
                color: isActive ? Colors.white : Colors.orange,
              ),
              label: Text(modelName),
              selected: isActive,
              onSelected: (!openRouterConnected || isBusy)
                  ? null
                  : (selected) async {
                      if (!selected) return;
                      try {
                        await notifier.switchActiveModel(
                          LLMProvider.openrouter,
                          modelName,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Activated OpenRouter model \$modelName',
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Activation failed: \$error'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({required this.dashboard});

  final LlmDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    if (dashboard.performanceReports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: dashboard.performanceReports.map((report) {
            final metrics = report.metrics;
            return SizedBox(
              width: 320,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_providerName(report.provider)} (${report.timeRange})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _MetricChip(
                            icon: Icons.check_circle_outline,
                            label: 'Success',
                            value:
                                '${metrics.successfulRequests}/${metrics.totalRequests}',
                          ),
                          _MetricChip(
                            icon: Icons.speed,
                            label: 'Avg. response',
                            value:
                                '${metrics.averageResponseTimeMs.toStringAsFixed(0)} ms',
                          ),
                          _MetricChip(
                            icon: Icons.error_outline,
                            label: 'Error rate',
                            value: '${metrics.errorRate.toStringAsFixed(1)}%',
                          ),
                          _MetricChip(
                            icon: Icons.timer,
                            label: 'Uptime',
                            value:
                                '${metrics.uptimePercentage.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tokens used: ${metrics.totalTokensUsed}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generated at: ${report.generatedAt.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _providerName(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.local:
        return 'Local runtime';
      case LLMProvider.openrouter:
        return 'OpenRouter';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.85),
      labelStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Failed to load LLM status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
