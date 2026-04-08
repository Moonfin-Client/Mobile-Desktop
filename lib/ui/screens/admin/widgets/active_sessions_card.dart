import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../data/services/socket_handler.dart';
import '../../../../l10n/app_localizations.dart';
import 'session_detail_sheet.dart';

class ActiveSessionsCard extends StatefulWidget {
  const ActiveSessionsCard({super.key});

  @override
  State<ActiveSessionsCard> createState() => _ActiveSessionsCardState();
}

class _ActiveSessionsCardState extends State<ActiveSessionsCard> {
  late final SessionApi _sessionApi;
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  bool _fetching = false;
  String? _error;
  Timer? _timer;
  StreamSubscription<ServerWebSocketMessage>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _sessionApi = GetIt.instance<MediaServerClient>().sessionApi;
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    _socketSubscription = GetIt.instance<SocketHandler>().events.listen((event) {
      switch (event) {
        case SessionEndedMessage():
        case PlayMessage():
        case PlaystateMessage():
        case GeneralCommandMessage():
          _load();
        case ServerEventMessage(:final type)
            when type == 'SessionsStart' || type == 'SessionsStop':
          _load();
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final sessions = await _sessionApi.getSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
        _error = null;
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

  void _openDetail(Map<String, dynamic> session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionDetailSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.adminActiveSessions, style: theme.textTheme.titleMedium),
                const Spacer(),
                if (_loading)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text('${_sessions.length}', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(l10n.adminSessionsLoadFailed, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    TextButton(onPressed: _load, child: Text(l10n.retry)),
                  ],
                ),
              )
            else if (!_loading && _sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(l10n.adminNoActiveSessions)),
              )
            else
              ..._sessions.map((session) {
                final userName = session['UserName'] as String? ?? 'Unknown';
                final client = session['Client'] as String? ?? '';
                final device = session['DeviceName'] as String? ?? '';
                final nowPlaying =
                    session['NowPlayingItem'] as Map<String, dynamic>?;
                final playState =
                    session['PlayState'] as Map<String, dynamic>?;
                final isPaused = playState?['IsPaused'] as bool? ?? false;
                final transcodingInfo =
                    session['TranscodingInfo'] as Map<String, dynamic>?;
                final runTimeTicks =
                    (nowPlaying?['RunTimeTicks'] as num?)?.toDouble() ?? 0;
                final positionTicks =
                    (playState?['PositionTicks'] as num?)?.toDouble() ?? 0;
                final progress = (nowPlaying != null && runTimeTicks > 0)
                    ? (positionTicks / runTimeTicks).clamp(0.0, 1.0)
                    : null;

                return InkWell(
                  onTap: () => _openDetail(session),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimaryContainer,
                                ),
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
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _platformIcon(client, theme),
                                    ],
                                  ),
                                  Text(
                                    nowPlaying != null
                                        ? (nowPlaying['Name'] as String? ??
                                            'Unknown')
                                        : '$client · $device',
                                    style: theme.textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _playMethodBadge(
                                transcodingInfo,
                                isPaused,
                                nowPlaying != null,
                                theme),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right,
                                size: 16,
                                color: theme.colorScheme.outline),
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
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _platformIcon(String client, ThemeData theme) {
    final lc = client.toLowerCase();
    final IconData icon;
    if (lc.contains('android tv') ||
        lc.contains('fire tv') ||
        lc.contains('apple tv') ||
        lc.contains('roku')) {
      icon = Icons.tv;
    } else if (lc.contains('android')) {
      icon = Icons.android;
    } else if (lc.contains('ios') ||
        lc.contains('iphone') ||
        lc.contains('ipad') ||
        lc.contains('apple')) {
      icon = Icons.phone_iphone;
    } else if (lc.contains('web') || lc.contains('browser')) {
      icon = Icons.language;
    } else {
      icon = Icons.devices_other;
    }
    return Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant);
  }

  Widget _playMethodBadge(
    Map<String, dynamic>? transcodingInfo,
    bool isPaused,
    bool isPlaying,
    ThemeData theme,
  ) {
    final IconData icon;
    final String label;
    final Color bg;
    final Color fg;
    if (!isPlaying) {
      icon = Icons.stop_circle_outlined;
      label = 'Idle';
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = theme.colorScheme.onSurfaceVariant;
    } else if (isPaused) {
      icon = Icons.pause;
      label = 'Paused';
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = theme.colorScheme.onSurfaceVariant;
    } else if (transcodingInfo != null) {
      final bitrate = transcodingInfo['Bitrate'] as int?;
      final mbps = bitrate != null
          ? ' ${(bitrate / 1000000).toStringAsFixed(1)}M'
          : '';
      icon = Icons.swap_horiz;
      label = 'Transcode$mbps';
      bg = theme.colorScheme.secondaryContainer;
      fg = theme.colorScheme.onSecondaryContainer;
    } else {
      icon = Icons.play_arrow;
      label = 'Direct';
      bg = theme.colorScheme.primaryContainer;
      fg = theme.colorScheme.onPrimaryContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

