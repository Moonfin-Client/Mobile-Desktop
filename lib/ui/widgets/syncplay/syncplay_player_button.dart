import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../../syncplay/syncplay_manager.dart';
import '../overlay_sheet.dart';

/// Compact in-player overlay control surfacing core SyncPlay actions
/// (leave group, toggle ignore-wait, view participants) without forcing
/// the user out of the player. Returns an empty widget when not in a group.
class SyncPlayPlayerButton extends StatelessWidget {
  const SyncPlayPlayerButton({
    super.key,
    this.size = 24,
    this.extent = 48,
  });

  final double size;
  final double extent;

  SyncPlayManager get _manager => GetIt.instance<SyncPlayManager>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        if (!_manager.state.enabled) return const SizedBox.shrink();
        return SizedBox(
          width: extent,
          height: extent,
          child: IconButton(
            tooltip: 'SyncPlay group',
            onPressed: () => _showSheet(context),
            icon: Icon(Icons.groups_rounded,
                color: Colors.white, size: size),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        );
      },
    );
  }

  void _showSheet(BuildContext context) {
    showFocusRestoringModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColorScheme.surface,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _manager,
          builder: (ctx, _) {
            final state = _manager.state;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.groups_rounded,
                          color: Colors.white),
                      title: Text(
                        state.groupName ?? 'SyncPlay group',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${state.participants.length} participant${state.participants.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    SwitchListTile(
                      value: _manager.ignoreWaitEnabled,
                      onChanged: (v) => _manager.requestSetIgnoreWait(v),
                      title: const Text('Ignore wait',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'Continue locally without waiting for slow members',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    if (state.participants.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final p in state.participants)
                              Chip(
                                label: Text(p,
                                    style: const TextStyle(
                                        color: Colors.white)),
                                backgroundColor: ThemeRegistry.active.borders.chipBackground,
                                side: ThemeRegistry.active.borders.chipBorder,
                                shape: RoundedRectangleBorder(
                                  borderRadius: ThemeRegistry.active.borders.chipRadius,
                                ),
                              ),
                          ],
                        ),
                      ),
                    Divider(
                      color: ThemeRegistry.active.borders.chipBorder.color,
                      height: 1,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent),
                      title: const Text('Leave group',
                          style: TextStyle(color: Colors.redAccent)),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _manager.leaveGroup();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
