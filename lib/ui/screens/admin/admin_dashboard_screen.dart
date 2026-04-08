import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../navigation/destinations.dart';
import 'providers/admin_media_analytics_provider.dart';
import 'providers/admin_status_providers.dart';
import 'widgets/admin_media_summary_section.dart';
import 'widgets/server_info_card.dart';
import 'widgets/server_paths_card.dart';
import 'widgets/active_sessions_card.dart';
import 'widgets/activity_log_card.dart';
import 'widgets/server_actions_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late final MediaServerClient _client;
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _systemInfo;
  StorageInfo? _storageInfo;
  ActivityLogResult? _activityLog;
  List<Map<String, dynamic>> _sessions = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _client = GetIt.instance<MediaServerClient>();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target = (position.pixels + event.scrollDelta.dy)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    if (target != position.pixels) {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        _client.systemApi.getSystemInfo(),
        _client.adminSystemApi.getStorageInfo(),
        _client.adminSystemApi.getActivityLog(limit: 10),
        _loadSessions(),
      ]);
      if (!mounted) return;
      final systemInfo =
          Map<String, dynamic>.from(results[0] as Map<String, dynamic>);
      final storageInfo = results[1] as StorageInfo;
      final sessions = results[3] as List<Map<String, dynamic>>;

      final osDisplay =
          (systemInfo['OperatingSystemDisplayName'] ?? '').toString().trim();
      final osValue = (systemInfo['OperatingSystem'] ?? '').toString().trim();
      if (osDisplay.isEmpty && osValue.isEmpty) {
        final inferred = _inferOsFromStorage(storageInfo);
        if (inferred.isNotEmpty) {
          systemInfo['OperatingSystemDisplayName'] = inferred;
        }
      }

      setState(() {
        _systemInfo = systemInfo;
        _storageInfo = storageInfo;
        _activityLog = results[2] as ActivityLogResult;
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadSessions() async {
    try {
      return await _client.sessionApi.getSessions();
    } catch (_) {
      return const [];
    }
  }

  String _inferOsFromStorage(StorageInfo storage) {
    final paths = [
      storage.programDataPath,
      storage.cachePath,
      storage.logPath,
      storage.internalMetadataPath,
      storage.transcodingTempPath,
    ].where((p) => p.trim().isNotEmpty).toList();

    if (paths.isEmpty) {
      return '';
    }

    final joined = paths.join(' | ');
    if (RegExp(r'^[A-Za-z]:\\').hasMatch(paths.first) || joined.contains('\\')) {
      return 'Windows';
    }
    if (joined.startsWith('/')) {
      if (joined.contains('/Users/')) {
        return 'macOS';
      }
      return 'Linux/Unix';
    }

    return '';
  }

  double? _worstStorageFill(StorageInfo storage) {
    final fractions = [
      storage.programDataFolder?.usageFraction,
      storage.cacheFolder?.usageFraction,
      storage.transcodingTempFolder?.usageFraction,
      storage.logFolder?.usageFraction,
    ].whereType<double>().where((f) => f > 0).toList();
    if (fractions.isEmpty) return null;
    return fractions.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaSummary = ref.watch(adminMediaSummaryProvider);
    final notificationSummary = ref.watch(adminNotificationSummaryProvider);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminDashboardLoadFailed, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return Listener(
      onPointerSignal: _onPointerSignal,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            if (notificationSummary.valueOrNull case final summary?
                when summary.count > 0) ...[
              _AdminAttentionCard(summary: summary),
              const SizedBox(height: 16),
            ],
            _DashboardKpiStrip(
              sessionCount: _sessions.length,
              errorCount: _activityLog!.items
                  .where((e) => e.severity.toLowerCase() == 'error')
                  .length,
              warningCount: _activityLog!.items.where((e) {
                final s = e.severity.toLowerCase();
                return s == 'warning' || s == 'warn';
              }).length,
              worstStorageFill: _worstStorageFill(_storageInfo!),
            ),
            const SizedBox(height: 16),
            ServerInfoCard(systemInfo: _systemInfo!),
            const SizedBox(height: 16),
            ServerActionsCard(
              client: _client,
              canSelfRestart: _systemInfo!['CanSelfRestart'] as bool? ?? false,
              onActionComplete: _loadData,
            ),
            const SizedBox(height: 16),
            mediaSummary.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) => Card(
                child: ListTile(
                  leading: const Icon(Icons.perm_media_outlined),
                  title: Text(l10n.adminMediaOverview),
                  subtitle: Text(l10n.adminMediaTotalsError),
                  trailing: FilledButton.tonal(
                    onPressed: () => ref.invalidate(adminMediaSummaryProvider),
                    child: Text(l10n.retry),
                  ),
                ),
              ),
              data: (summary) => AdminMediaSummarySection(
                summary: summary,
                subtitle: l10n.adminMediaOverviewSubtitle,
                onOpenAnalytics: () => context.push(Destinations.adminAnalytics),
              ),
            ),
            const SizedBox(height: 16),
            const ActiveSessionsCard(),
            const SizedBox(height: 16),
            ActivityLogCard(activityLog: _activityLog!),
            const SizedBox(height: 16),
            ServerPathsCard(storageInfo: _storageInfo!),
          ],
        ),
      ),
    );
  }
}

class _AdminAttentionCard extends StatelessWidget {
  final AdminNotificationSummary summary;

  const _AdminAttentionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.22),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notification_important,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Needs Attention',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (summary.hasPluginUpdates)
              Text(l10n.adminPluginUpdatesAvailable(summary.pluginUpdateCount)),
            if (summary.hasRestartPendingPlugins)
              Text(l10n.adminPluginsRequiringRestart(summary.restartPendingPluginCount)),
            if (summary.restartPendingPlugins.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                summary.restartPendingPlugins.take(3).join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (summary.hasFailedTasks)
              Text(l10n.adminFailedScheduledTasks(summary.failedTaskCount)),
            if (summary.hasAlerts)
              Text(l10n.adminRecentAlertEntries(summary.alertCount)),
            if ((summary.latestAlertText ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Latest alert: ${summary.latestAlertText}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardKpiStrip extends StatelessWidget {
  final int sessionCount;
  final int errorCount;
  final int warningCount;
  final double? worstStorageFill;

  const _DashboardKpiStrip({
    required this.sessionCount,
    required this.errorCount,
    required this.warningCount,
    this.worstStorageFill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = worstStorageFill;
    final Color storageColor = fill == null
        ? theme.colorScheme.primary
        : fill >= 0.90
            ? theme.colorScheme.error
            : fill >= 0.75
                ? Colors.orange
                : Colors.green.shade600;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_outlined,
            label: 'Sessions',
            value: '$sessionCount',
            color: theme.colorScheme.primary,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.error_outline,
            label: 'Errors',
            value: '$errorCount',
            color: errorCount > 0
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
            highlight: errorCount > 0,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber_outlined,
            label: 'Warnings',
            value: '$warningCount',
            color: warningCount > 0
                ? Colors.orange
                : theme.colorScheme.onSurfaceVariant,
            highlight: warningCount > 0,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.storage_outlined,
            label: 'Disk',
            value: fill != null ? '${(fill * 100).round()}%' : '—',
            color: storageColor,
            highlight: (fill ?? 0) >= 0.90,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool highlight;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight
          ? color.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
