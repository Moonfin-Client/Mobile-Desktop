import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../navigation/destinations.dart';
import '../providers/admin_user_providers.dart';
import '../../../../l10n/app_localizations.dart';

class AdminTasksScreen extends ConsumerStatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen> {
  Timer? _refreshTimer;
  String? _categoryFilter;

  AdminTasksApi get _api =>
      GetIt.instance<MediaServerClient>().adminTasksApi;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(adminTasksProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(adminTasksProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminTasksLoadFailed(error.toString())),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminTasksProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (tasks) {
        final grouped = <String, List<TaskInfo>>{};
        for (final task in tasks) {
          final category = task.category ?? 'Other';
          grouped.putIfAbsent(category, () => []).add(task);
        }
        final categories = grouped.keys.toList()..sort();
        final visibleCategories = _categoryFilter == null
            ? categories
            : categories.where((category) => category == _categoryFilter).toList();

        if (categories.isEmpty) {
          return Center(child: Text(l10n.adminTasksEmpty));
        }

        return Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.all),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setState(() => _categoryFilter = null),
                    ),
                  ),
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _categoryFilter == category,
                        onSelected: (_) => setState(() {
                          _categoryFilter = _categoryFilter == category ? null : category;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleCategories.isEmpty
                  ? Center(child: Text(l10n.adminTasksNoFilterMatch))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: visibleCategories.length,
                      itemBuilder: (context, index) {
                        final category = visibleCategories[index];
                        final categoryTasks = grouped[category]!;
                        return _CategorySection(
                          category: category,
                          tasks: categoryTasks,
                          onStart: _startTask,
                          onStop: _stopTask,
                          onTap: (task) =>
                              context.push(Destinations.adminTask(task.id)),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startTask(String taskId) async {
    try {
      await _api.startTask(taskId);
      ref.invalidate(adminTasksProvider);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adminTaskStartFailed(e.toString()))));
      }
    }
  }

  Future<void> _stopTask(String taskId) async {
    try {
      await _api.stopTask(taskId);
      ref.invalidate(adminTasksProvider);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adminTaskStopFailed(e.toString()))));
      }
    }
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<TaskInfo> tasks;
  final Future<void> Function(String taskId) onStart;
  final Future<void> Function(String taskId) onStop;
  final void Function(TaskInfo task) onTap;

  const _CategorySection({
    required this.category,
    required this.tasks,
    required this.onStart,
    required this.onStop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _TaskRow(
              task: task,
              onStart: () => onStart(task.id),
              onStop: () => onStop(task.id),
              onTap: () => onTap(task),
            )),
        const Divider(height: 1),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskInfo task;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onTap;

  const _TaskRow({
    required this.task,
    required this.onStart,
    required this.onStop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRunning = task.state == 'Running';
    final isCancelling = task.state == 'Cancelling';
    final result = task.lastExecutionResult;

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 36,
        height: 36,
        child: Center(child: _buildLeading(theme)),
      ),
      title: Text(task.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRunning || isCancelling) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.currentProgressPercentage != null
                        ? task.currentProgressPercentage! / 100
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isCancelling
                      ? l10n.adminTaskCancelling
                      : task.currentProgressPercentage != null
                          ? '${task.currentProgressPercentage!.toStringAsFixed(0)}%'
                          : l10n.adminTaskRunning,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ] else if (result != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  _resultIcon(result.status),
                  size: 14,
                  color: _resultColor(result.status, theme),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _resultText(result),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _resultColor(result.status, theme),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              l10n.adminTaskNeverRun,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      trailing: isRunning || isCancelling
          ? IconButton(
              icon: const Icon(Icons.stop),
              tooltip: l10n.adminTaskStop,
              onPressed: isCancelling ? null : onStop,
            )
          : IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: l10n.adminTaskRun,
              onPressed: onStart,
            ),
    );
  }

  Widget _buildLeading(ThemeData theme) {
    if (task.state == 'Running') {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (task.state == 'Cancelling') {
      return const Icon(Icons.stop_circle_outlined,
          color: Colors.orange, size: 22);
    }
    final result = task.lastExecutionResult;
    if (result == null) {
      return Icon(Icons.schedule,
          color: theme.colorScheme.onSurfaceVariant, size: 22);
    }
    return Icon(
      _resultIcon(result.status),
      color: _resultColor(result.status, theme),
      size: 22,
    );
  }

  IconData _resultIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Failed':
        return Icons.error;
      case 'Cancelled':
      case 'Aborted':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _resultColor(String status, ThemeData theme) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Failed':
        return theme.colorScheme.error;
      case 'Cancelled':
      case 'Aborted':
        return Colors.orange;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _resultText(TaskResult result) {
    final duration = result.endTime.difference(result.startTime);
    final durationStr = _formatDuration(duration);
    final timeAgo = _timeAgo(result.endTime);
    if (result.status == 'Failed' && result.errorMessage != null) {
      return 'Failed $timeAgo ($durationStr) — ${result.errorMessage}';
    }
    return '${result.status} $timeAgo ($durationStr)';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
