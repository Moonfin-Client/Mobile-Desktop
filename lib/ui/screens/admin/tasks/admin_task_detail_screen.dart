import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../providers/admin_user_providers.dart';
import '../../../../l10n/app_localizations.dart';

class AdminTaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const AdminTaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<AdminTaskDetailScreen> createState() =>
      _AdminTaskDetailScreenState();
}

class _AdminTaskDetailScreenState
    extends ConsumerState<AdminTaskDetailScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(adminTaskProvider(widget.taskId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  AdminTasksApi get _api =>
      GetIt.instance<MediaServerClient>().adminTasksApi;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taskAsync = ref.watch(adminTaskProvider(widget.taskId));

    return taskAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminTaskLoadFailed(error.toString())),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(adminTaskProvider(widget.taskId)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (task) => _buildContent(context, task),
    );
  }

  Widget _buildContent(BuildContext context, TaskInfo task) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRunning = task.state == 'Running';
    final isCancelling = task.state == 'Cancelling';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(task.name, style: theme.textTheme.headlineSmall),
        if (task.description != null) ...[
          const SizedBox(height: 4),
          Text(task.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
        if (task.category != null) ...[
          const SizedBox(height: 4),
          Chip(label: Text(task.category!)),
        ],
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.status, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isRunning
                          ? Icons.sync
                          : isCancelling
                              ? Icons.hourglass_top
                              : Icons.check_circle_outline,
                      color: isRunning
                          ? theme.colorScheme.primary
                          : isCancelling
                              ? Colors.orange
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(task.state, style: theme.textTheme.bodyLarge),
                    const Spacer(),
                    if (isRunning || isCancelling)
                      FilledButton.tonalIcon(
                        onPressed: isCancelling
                            ? null
                            : () => _stopTask(task.id),
                        icon: const Icon(Icons.stop),
                        label: Text(l10n.adminTaskStop),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: () => _startTask(task.id),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.adminRunNow),
                      ),
                  ],
                ),
                if ((isRunning || isCancelling) &&
                    task.currentProgressPercentage != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                      value: task.currentProgressPercentage! / 100),
                  const SizedBox(height: 4),
                  Text(
                      '${task.currentProgressPercentage!.toStringAsFixed(1)}%'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (task.lastExecutionResult != null) ...[
          _LastExecutionCard(result: task.lastExecutionResult!),
          const SizedBox(height: 12),
        ],

        _TriggersSection(
          triggers: task.triggers,
          onAdd: () => _showAddTriggerDialog(task),
          onRemove: (index) => _removeTrigger(task, index),
        ),
      ],
    );
  }

  Future<void> _startTask(String taskId) async {
    try {
      await _api.startTask(taskId);
      ref.invalidate(adminTaskProvider(widget.taskId));
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
      ref.invalidate(adminTaskProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adminTaskStopFailed(e.toString()))));
      }
    }
  }

  Future<void> _removeTrigger(TaskInfo task, int index) async {
    final triggers = List<TaskTriggerInfo>.from(task.triggers)
      ..removeAt(index);
    try {
      await _api.updateTaskTriggers(
        task.id,
        triggers.map((t) => t.toJson()).toList(),
      );
      ref.invalidate(adminTaskProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adminTriggerRemoveFailed(e.toString()))));
      }
    }
  }

  Future<void> _showAddTriggerDialog(TaskInfo task) async {
    final trigger = await showDialog<TaskTriggerInfo>(
      context: context,
      builder: (context) => const _AddTriggerDialog(),
    );
    if (trigger == null || !mounted) return;

    final triggers = [...task.triggers, trigger];
    try {
      await _api.updateTaskTriggers(
        task.id,
        triggers.map((t) => t.toJson()).toList(),
      );
      ref.invalidate(adminTaskProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adminTriggerAddFailed(e.toString()))));
      }
    }
  }
}

class _LastExecutionCard extends StatelessWidget {
  final TaskResult result;
  const _LastExecutionCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final duration = result.endTime.difference(result.startTime);

    Color statusColor;
    switch (result.status) {
      case 'Completed':
        statusColor = Colors.green;
      case 'Failed':
        statusColor = theme.colorScheme.error;
      case 'Cancelled':
      case 'Aborted':
        statusColor = Colors.orange;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminTaskDetailLastExecution, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Text(result.status,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(l10n.adminTaskDetailStarted, _formatDateTime(result.startTime)),
            _infoRow(l10n.adminTaskDetailEnded, _formatDateTime(result.endTime)),
            _infoRow(l10n.adminTaskDetailDuration, _formatDuration(duration)),
            if (result.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(l10n.adminTaskDetailErrorLabel,
                  style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 4),
              Text(result.errorMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            Text(value),
          ],
        ),
      );

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_p(local.month)}-${_p(local.day)} '
        '${_p(local.hour)}:${_p(local.minute)}:${_p(local.second)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}

class _TriggersSection extends StatelessWidget {
  final List<TaskTriggerInfo> triggers;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _TriggersSection({
    required this.triggers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.adminTriggers, style: theme.textTheme.titleMedium),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.adminAddTrigger),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (triggers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.adminNoTriggers,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              )
            else
              ...triggers.asMap().entries.map((entry) {
                final i = entry.key;
                final trigger = entry.value;
                return ListTile(
                  leading: Icon(_triggerIcon(trigger.type)),
                  title: Text(_triggerDescription(trigger, l10n)),
                  subtitle: trigger.maxRuntimeTicks != null
                      ? Text(
                          l10n.adminTimeLimitDuration(l10n.adminTaskTriggerHours(trigger.maxRuntimeTicks! ~/ (60 * 600000000))))
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onRemove(i),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  IconData _triggerIcon(String type) {
    switch (type) {
      case 'DailyTrigger':
        return Icons.today;
      case 'WeeklyTrigger':
        return Icons.calendar_view_week;
      case 'IntervalTrigger':
        return Icons.timer;
      case 'StartupTrigger':
        return Icons.power_settings_new;
      default:
        return Icons.schedule;
    }
  }

  String _triggerDescription(TaskTriggerInfo trigger, AppLocalizations l10n) {
    switch (trigger.type) {
      case 'DailyTrigger':
        return l10n.adminTaskTriggerDaily(_ticksToTime(trigger.timeOfDayTicks ?? 0));
      case 'WeeklyTrigger':
        return l10n.adminTaskTriggerWeekly(trigger.dayOfWeek ?? 'Unknown', _ticksToTime(trigger.timeOfDayTicks ?? 0));
      case 'IntervalTrigger':
        return l10n.adminTaskTriggerInterval(_ticksToDuration(trigger.intervalTicks ?? 0));
      case 'StartupTrigger':
        return l10n.adminTaskTriggerStartup;
      default:
        return trigger.type;
    }
  }

  String _ticksToTime(int ticks) {
    final totalMinutes = ticks ~/ 600000000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours);
    return '$displayHour:${minutes.toString().padLeft(2, '0')} $period';
  }

  String _ticksToDuration(int ticks) {
    final totalMinutes = ticks ~/ 600000000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }
}

class _AddTriggerDialog extends StatefulWidget {
  const _AddTriggerDialog();

  @override
  State<_AddTriggerDialog> createState() => _AddTriggerDialogState();
}

class _AddTriggerDialogState extends State<_AddTriggerDialog> {
  String _type = 'IntervalTrigger';
  TimeOfDay _time = const TimeOfDay(hour: 3, minute: 0);
  String _dayOfWeek = 'Sunday';
  int _intervalHours = 24;
  int? _maxRuntimeHours;

  static const _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final triggerTypes = {
      'DailyTrigger': l10n.adminTaskTriggerTypeDaily,
      'WeeklyTrigger': l10n.adminTaskTriggerTypeWeekly,
      'IntervalTrigger': l10n.adminTaskTriggerTypeInterval,
      'StartupTrigger': l10n.adminTaskTriggerStartup,
    };
    return AlertDialog(
      title: Text(l10n.adminAddTrigger),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(labelText: l10n.adminTriggerType),
              items: triggerTypes.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            ..._buildTypeFields(),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _maxRuntimeHours,
              decoration: InputDecoration(
                  labelText: l10n.adminTimeLimit),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.adminNoLimit)),
                ...[1, 2, 3, 6, 12, 24].map((h) => DropdownMenuItem(
                    value: h,
                    child: Text(l10n.adminTaskTriggerHours(h)))),
              ],
              onChanged: (v) => setState(() => _maxRuntimeHours = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  List<Widget> _buildTypeFields() {
    final l10n = AppLocalizations.of(context)!;
    switch (_type) {
      case 'DailyTrigger':
        return [_buildTimePicker()];
      case 'WeeklyTrigger':
        return [
          DropdownButtonFormField<String>(
            value: _dayOfWeek,
            decoration: InputDecoration(labelText: l10n.adminDayOfWeek),
            items: _daysOfWeek
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _dayOfWeek = v!),
          ),
          const SizedBox(height: 16),
          _buildTimePicker(),
        ];
      case 'IntervalTrigger':
        final intervalOptions = {
          1: l10n.adminTaskTriggerEveryHour,
          6: l10n.adminTaskTriggerEvery6Hours,
          12: l10n.adminTaskTriggerEvery12Hours,
          24: l10n.adminTaskTriggerEvery24Hours,
          48: l10n.adminTaskTriggerEvery2Days,
        };
        return [
          DropdownButtonFormField<int>(
            value: _intervalHours,
            decoration: InputDecoration(labelText: l10n.adminTaskTriggerIntervalLabel),
            items: intervalOptions.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _intervalHours = v!),
          ),
        ];
      case 'StartupTrigger':
        return [];
      default:
        return [];
    }
  }

  Widget _buildTimePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(AppLocalizations.of(context)!.adminTaskTriggerTime),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _time,
          );
          if (picked != null) setState(() => _time = picked);
        },
        child: Text(_time.format(context)),
      ),
    );
  }

  void _save() {
    int? timeOfDayTicks;
    if (_type == 'DailyTrigger' || _type == 'WeeklyTrigger') {
      timeOfDayTicks = (_time.hour * 60 + _time.minute) * 600000000;
    }

    int? intervalTicks;
    if (_type == 'IntervalTrigger') {
      intervalTicks = _intervalHours * 60 * 600000000;
    }

    final trigger = TaskTriggerInfo(
      type: _type,
      timeOfDayTicks: timeOfDayTicks,
      intervalTicks: intervalTicks,
      dayOfWeek: _type == 'WeeklyTrigger' ? _dayOfWeek : null,
      maxRuntimeTicks:
          _maxRuntimeHours != null ? _maxRuntimeHours! * 60 * 600000000 : null,
    );

    Navigator.pop(context, trigger);
  }
}
