import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../data/services/socket_handler.dart';
import '../../l10n/app_localizations.dart';

void showRemoteControlDialog(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RemoteControlSheet(),
  );
}

class _RemoteControlSheet extends StatefulWidget {
  const _RemoteControlSheet();

  @override
  State<_RemoteControlSheet> createState() => _RemoteControlSheetState();
}

class _RemoteControlSheetState extends State<_RemoteControlSheet> {
  late final SessionApi _sessionApi;
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  bool _fetching = false;
  String? _error;
  Map<String, dynamic>? _selectedSession;
  bool _busy = false;
  double? _seekPosition;
  Timer? _refreshTimer;
  StreamSubscription<ServerWebSocketMessage>? _socketSub;

  @override
  void initState() {
    super.initState();
    _sessionApi = GetIt.instance<MediaServerClient>().sessionApi;
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    _socketSub = GetIt.instance<SocketHandler>().events.listen((event) {
      switch (event) {
        case SessionEndedMessage():
        case PlayMessage():
        case PlaystateMessage():
        case GeneralCommandMessage():
          _refresh();
        case ServerEventMessage(:final type)
            when type == 'SessionsStart' || type == 'SessionsStop':
          _refresh();
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final client = GetIt.instance<MediaServerClient>();
      List<Map<String, dynamic>> strictSessions = const [];
      try {
        strictSessions = await _sessionApi.getSessions(
          controllableByUserId: client.userId,
        );
      } catch (_) {}

      List<Map<String, dynamic>> fallbackSessions = const [];
      if (strictSessions.isEmpty) {
        try {
          fallbackSessions = await _sessionApi.getSessions();
        } catch (_) {}
      }

      final sessions = _mergeUniqueSessions([
        ...strictSessions,
        ...fallbackSessions,
      ]);
      if (!mounted) return;
      final selfDeviceId = client.deviceInfo.id;
      final controllable = sessions.where((s) {
        final deviceId = s['DeviceId'] as String?;
        if (deviceId != null && deviceId == selfDeviceId) {
          return false;
        }

        return _isPotentiallyControllable(s);
      }).toList();
      setState(() {
        _sessions = controllable;
        _loading = false;
        _error = null;
        if (_selectedSession != null) {
          final id = _selectedSession!['Id'];
          _selectedSession = controllable.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['Id'] == id,
            orElse: () => null,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    } finally {
      _fetching = false;
    }
  }

  List<Map<String, dynamic>> _mergeUniqueSessions(
    List<Map<String, dynamic>> sessions,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final session in sessions) {
      final id = session['Id'] as String?;
      if (id == null || id.isEmpty) {
        continue;
      }

      byId.putIfAbsent(id, () => session);
    }

    return byId.values.toList();
  }

  bool _isPotentiallyControllable(Map<String, dynamic> session) {
    final supportsRemote = session['SupportsRemoteControl'];
    if (supportsRemote is bool && supportsRemote) {
      return true;
    }

    final supportsMedia = session['SupportsMediaControl'];
    if (supportsMedia is bool && supportsMedia) {
      return true;
    }

    final commands = session['SupportedCommands'];
    if (commands is List) {
      return commands.whereType<String>().isNotEmpty;
    }

    return false;
  }

  Future<void> _refresh() async {
    if (_fetching) return;
    await _load();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await Future.delayed(const Duration(milliseconds: 300));
      await _refresh();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.remoteCommandFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPlayState(String command, {int? seekTicks}) {
    final id = _selectedSession?['Id'] as String?;
    if (id == null) return Future.value();
    return _run(() => _sessionApi.sendPlayStateCommand(id, command, seekPositionTicks: seekTicks));
  }

  Future<void> _sendGeneral(String commandName, {Map<String, String>? args}) {
    final id = _selectedSession?['Id'] as String?;
    if (id == null) return Future.value();
    return _run(() => _sessionApi.sendGeneralCommand(id, commandName, arguments: args));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.settings_remote_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(l10n.remoteControlTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.remoteFailedToLoadSessions, style: theme.textTheme.bodySmall),
                              const SizedBox(height: 8),
                              TextButton(onPressed: _load, child: Text(l10n.retry)),
                            ],
                          ),
                        )
                      : _sessions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.devices_other, size: 48, color: theme.colorScheme.outline),
                                  const SizedBox(height: 12),
                                  Text(l10n.remoteNoSessions, style: theme.textTheme.bodyMedium),
                                  const SizedBox(height: 4),
                                  Text(l10n.remoteStartPlayback, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                                ],
                              ),
                            )
                          : ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                ..._sessions.map(_buildSessionTile),
                                if (_selectedSession != null) ...[
                                  const SizedBox(height: 16),
                                  ..._buildControls(theme),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sessionId = session['Id'] as String?;
    final isSelected = _selectedSession?['Id'] == sessionId;
    final userName = session['UserName'] as String? ?? l10n.unknownUser;
    final client = session['Client'] as String? ?? '';
    final device = session['DeviceName'] as String? ?? '';
    final nowPlaying = session['NowPlayingItem'] as Map<String, dynamic>?;
    final playState = session['PlayState'] as Map<String, dynamic>?;
    final isPaused = playState?['IsPaused'] as bool? ?? false;
    final runTimeTicks = (nowPlaying?['RunTimeTicks'] as num?)?.toDouble() ?? 0;
    final positionTicks = (playState?['PositionTicks'] as num?)?.toDouble() ?? 0;
    final progress = (nowPlaying != null && runTimeTicks > 0)
        ? (positionTicks / runTimeTicks).clamp(0.0, 1.0)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedSession = isSelected ? null : session),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _platformIcon(client, theme),
                            ],
                          ),
                          Text(
                            nowPlaying != null
                                ? (nowPlaying['Name'] as String? ?? l10n.unknownItem)
                                : '$client · $device',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    if (nowPlaying != null)
                      Icon(
                        isPaused ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 20,
                        color: isPaused ? theme.colorScheme.outline : theme.colorScheme.primary,
                      ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                      ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 42),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildControls(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final session = _selectedSession!;
    final nowPlaying = session['NowPlayingItem'] as Map<String, dynamic>?;
    final playState = session['PlayState'] as Map<String, dynamic>?;
    final isPaused = playState?['IsPaused'] as bool? ?? false;
    final isMuted = playState?['IsMuted'] as bool? ?? false;
    final positionTicks = (playState?['PositionTicks'] as num?)?.toInt();
    final runtimeTicks = (nowPlaying?['RunTimeTicks'] as num?)?.toInt();

    String ticksToTime(int ticks) {
      final duration = Duration(microseconds: ticks ~/ 10);
      final h = duration.inHours;
      final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }

    return [
      if (nowPlaying != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nowPlaying['Name'] as String? ?? '',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if ((nowPlaying['SeriesName'] as String?) != null)
                Text(nowPlaying['SeriesName'] as String, style: theme.textTheme.bodySmall),
              if (positionTicks != null && runtimeTicks != null && runtimeTicks > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(ticksToTime(positionTicks), style: theme.textTheme.labelSmall),
                    Expanded(
                      child: Slider(
                        value: (_seekPosition ?? positionTicks / runtimeTicks).clamp(0.0, 1.0),
                        onChanged: (v) => setState(() => _seekPosition = v),
                        onChangeEnd: (v) {
                          final target = (v * runtimeTicks).round();
                          _seekPosition = null;
                          _sendPlayState('Seek', seekTicks: target);
                        },
                      ),
                    ),
                    Text(ticksToTime(runtimeTicks), style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(icon: Icons.skip_previous, label: l10n.sessionPrev, onTap: () => _sendPlayState('PreviousTrack')),
            const SizedBox(width: 8),
            _ControlButton(icon: Icons.replay_10, label: l10n.sessionRewind, onTap: () => _sendPlayState('Rewind')),
            const SizedBox(width: 8),
            _ControlButton(
              icon: isPaused ? Icons.play_arrow : Icons.pause,
              label: isPaused ? l10n.play : l10n.pause,
              onTap: () => _sendPlayState('PlayPause'),
              primary: true,
            ),
            const SizedBox(width: 8),
            _ControlButton(icon: Icons.forward_10, label: l10n.sessionForward, onTap: () => _sendPlayState('FastForward')),
            const SizedBox(width: 8),
            _ControlButton(icon: Icons.skip_next, label: l10n.sessionNext, onTap: () => _sendPlayState('NextTrack')),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: _ControlButton(
            icon: Icons.stop,
            label: l10n.stop,
            onTap: () => _sendPlayState('Stop'),
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: isMuted ? Icons.volume_off : Icons.volume_up,
              label: isMuted ? l10n.unmute : l10n.mute,
              onTap: () => _sendGeneral(isMuted ? 'Unmute' : 'Mute'),
            ),
            const SizedBox(width: 8),
            _ControlButton(icon: Icons.volume_down, label: l10n.sessionVolumeDown, onTap: () => _sendGeneral('VolumeDown')),
            const SizedBox(width: 8),
            _ControlButton(icon: Icons.volume_up, label: l10n.sessionVolumeUp, onTap: () => _sendGeneral('VolumeUp')),
          ],
        ),
      ] else ...[
        Center(
          child: Column(
            children: [
              Icon(Icons.tv_off, size: 40, color: theme.colorScheme.outline),
              const SizedBox(height: 8),
              Text(l10n.remoteNothingPlaying, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _platformIcon(String client, ThemeData theme) {
    final lc = client.toLowerCase();
    final IconData icon;
    if (lc.contains('android tv') || lc.contains('fire tv') || lc.contains('apple tv') || lc.contains('roku')) {
      icon = Icons.tv;
    } else if (lc.contains('android')) {
      icon = Icons.android;
    } else if (lc.contains('ios') || lc.contains('iphone') || lc.contains('ipad') || lc.contains('apple')) {
      icon = Icons.phone_iphone;
    } else if (lc.contains('web') || lc.contains('browser')) {
      icon = Icons.language;
    } else {
      icon = Icons.devices_other;
    }
    return Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant);
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? (primary ? theme.colorScheme.primary : theme.colorScheme.onSurface);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: primary ? 36 : 28, color: fg),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
