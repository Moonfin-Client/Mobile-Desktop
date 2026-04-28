import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:server_core/server_core.dart';

import '../../../di/providers.dart';
import '../../../syncplay/syncplay_manager.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/focus/request_initial_focus.dart';

class SyncPlayScreen extends ConsumerStatefulWidget {
  const SyncPlayScreen({super.key});

  @override
  ConsumerState<SyncPlayScreen> createState() => _SyncPlayScreenState();
}

class _SyncPlayScreenState extends ConsumerState<SyncPlayScreen> {
  final _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncPlayManagerProvider).fetchGroups();
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RequestInitialFocus(child: _buildContent(context));

  Widget _buildContent(BuildContext context) {
    final manager = ref.watch(syncPlayManagerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SyncPlay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: manager.isLoading ? null : () => manager.fetchGroups(),
          ),
        ],
      ),
      body: _buildBody(context, manager),
    );
  }

  Widget _buildBody(BuildContext context, SyncPlayManager manager) {
    if (!manager.syncPlayConfigured) {
      return const _Message(
        icon: Icons.toggle_off,
        title: 'SyncPlay disabled',
        message: 'Enable SyncPlay in Settings to use synchronized playback.',
      );
    }
    if (!manager.syncPlayServerSupported) {
      return const _Message(
        icon: Icons.cloud_off,
        title: 'Server unsupported',
        message:
            'SyncPlay requires a Jellyfin server. The current server does not support it.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (manager.errorMessage != null)
          _ErrorBanner(message: manager.errorMessage!),
        if (manager.state.enabled) _ActiveGroupSection(manager: manager),
        if (!manager.state.enabled) _CreateGroupSection(
          controller: _groupNameController,
          manager: manager,
        ),
        const SizedBox(height: 16),
        _AvailableGroupsSection(manager: manager),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ActiveGroupSection extends StatelessWidget {
  final SyncPlayManager manager;
  const _ActiveGroupSection({required this.manager});

  @override
  Widget build(BuildContext context) {
    final s = manager.state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.groupName ?? 'SyncPlay Group',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _GroupStateChip(state: s.groupState),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${s.participants.length} participant'
              '${s.participants.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            if (s.participants.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: s.participants
                    .map((p) => Chip(label: Text(p)))
                    .toList(),
              ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ignore wait'),
              subtitle: const Text(
                  "Don't hold the group up while this device buffers"),
              value: manager.ignoreWaitEnabled,
              onChanged: (v) => manager.requestSetIgnoreWait(v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: const Text('Repeat'),
              subtitle: Text(_repeatLabel(s.repeatMode)),
              onTap: manager.cycleRepeatMode,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                s.shuffleMode == SyncPlayShuffleMode.shuffle
                    ? Icons.shuffle_on_outlined
                    : Icons.shuffle,
              ),
              title: const Text('Shuffle'),
              subtitle: Text(s.shuffleMode == SyncPlayShuffleMode.shuffle
                  ? 'Shuffled'
                  : 'Sorted'),
              onTap: manager.toggleShuffleMode,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.queue_play_next),
              title: const Text('Sync current playback queue'),
              subtitle: const Text(
                  'Replace the group queue with what is playing locally'),
              onTap: () => manager.syncCurrentPlaybackQueueToGroup(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => manager.leaveGroup(),
                icon: const Icon(Icons.logout),
                label: const Text('Leave group'),
              ),
            ),
            if (s.queue.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Group queue',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...List.generate(s.queue.length, (i) {
                final item = s.queue[i];
                final isCurrent = i == s.currentItemIndex;
                final title = manager.itemTitleFor(item.itemId) ??
                    'Item ${i + 1}';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    isCurrent ? Icons.play_circle : Icons.circle_outlined,
                    color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(title,
                      style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : null)),
                  subtitle: Text(item.itemId,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'play':
                          manager.requestSetCurrentItem(item.playlistItemId);
                          break;
                        case 'remove':
                          manager.requestRemoveFromQueue(item.playlistItemId);
                          break;
                        case 'up':
                          manager.requestMoveQueueItem(
                              item.playlistItemId, i - 1);
                          break;
                        case 'down':
                          manager.requestMoveQueueItem(
                              item.playlistItemId, i + 1);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (!isCurrent)
                        const PopupMenuItem(
                            value: 'play', child: Text('Play now')),
                      if (i > 0)
                        const PopupMenuItem(
                            value: 'up', child: Text('Move up')),
                      if (i < s.queue.length - 1)
                        const PopupMenuItem(
                            value: 'down', child: Text('Move down')),
                      const PopupMenuItem(
                          value: 'remove', child: Text('Remove')),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _repeatLabel(SyncPlayRepeatMode mode) => switch (mode) {
        SyncPlayRepeatMode.repeatNone => 'Off',
        SyncPlayRepeatMode.repeatOne => 'One',
        SyncPlayRepeatMode.repeatAll => 'All',
      };
}

class _GroupStateChip extends StatelessWidget {
  final SyncPlayGroupState state;
  const _GroupStateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      SyncPlayGroupState.idle => ('Idle', Colors.grey),
      SyncPlayGroupState.waiting => ('Waiting', Colors.orange),
      SyncPlayGroupState.paused => ('Paused', Colors.blueGrey),
      SyncPlayGroupState.playing => ('Playing', Colors.green),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: ThemeRegistry.active.borders.chipBorder.copyWith(color: color),
    );
  }
}

class _CreateGroupSection extends StatelessWidget {
  final TextEditingController controller;
  final SyncPlayManager manager;
  const _CreateGroupSection({
    required this.controller,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a new group',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Group name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: manager.isLoading
                    ? null
                    : () async {
                        final name = controller.text.trim().isEmpty
                            ? 'My SyncPlay Group'
                            : controller.text.trim();
                        await _confirmIfNeeded(
                          context,
                          manager,
                          () => manager.createGroup(name),
                        );
                      },
                icon: const Icon(Icons.add),
                label: const Text('Create group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableGroupsSection extends StatelessWidget {
  final SyncPlayManager manager;
  const _AvailableGroupsSection({required this.manager});

  @override
  Widget build(BuildContext context) {
    final groups = manager.availableGroups;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Available groups',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (manager.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No groups available'),
              )
            else
              ...groups.map(
                (g) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.group),
                  title: Text(g.groupName ?? g.groupId),
                  subtitle: Text(
                      '${g.participants.length} participants • '
                      '${g.state?.serverValue ?? 'Idle'}'),
                  trailing: const Icon(Icons.login),
                  enabled: !manager.isLoading,
                  onTap: () => _confirmIfNeeded(
                    context,
                    manager,
                    () => manager.joinGroup(g.groupId),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmIfNeeded(
  BuildContext context,
  SyncPlayManager manager,
  Future<void> Function() action,
) async {
  if (manager.state.enabled) {
    await action();
    return;
  }
  final proceed = await showFocusRestoringDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Join SyncPlay group?'),
      content: const Text(
          'Joining a SyncPlay group may replace your current playback queue. Continue?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Join')),
      ],
    ),
  );
  if (proceed == true) {
    await action();
  }
}
