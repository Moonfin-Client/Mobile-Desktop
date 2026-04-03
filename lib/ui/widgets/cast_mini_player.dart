import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:server_core/server_core.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/services/cast/cast_service.dart';
import '../../data/services/cast/cast_target.dart';
import '../../data/services/media_server_client_factory.dart';
import '../../util/audio_labels.dart';

class CastMiniPlayer extends StatelessWidget {
  const CastMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final castService = GetIt.instance<CastService>();
    return ValueListenableBuilder<CastTargetKind?>(
      valueListenable: castService.activeKindNotifier,
      builder: (context, kind, _) => ValueListenableBuilder<AggregatedItem?>(
        valueListenable: castService.castItemNotifier,
        builder: (context, item, _) {
          if (kind == null || item == null) {
            return const SizedBox.shrink();
          }
          return _CastMiniPlayerContent(
            castService: castService,
            kind: kind,
            item: item,
          );
        },
      ),
    );
  }
}

class _CastMiniPlayerContent extends StatefulWidget {
  final CastService castService;
  final CastTargetKind kind;
  final AggregatedItem item;

  const _CastMiniPlayerContent({
    required this.castService,
    required this.kind,
    required this.item,
  });

  @override
  State<_CastMiniPlayerContent> createState() => _CastMiniPlayerContentState();
}

class _CastMiniPlayerContentState extends State<_CastMiniPlayerContent> {
  bool _isSeeking = false;
  double _seekValue = 0;

  CastService get _castService => widget.castService;
  CastTargetKind get _kind => widget.kind;

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  IconData get _kindIcon => switch (_kind) {
        CastTargetKind.googleCast => Icons.cast_connected,
        CastTargetKind.airPlay => Icons.airplay,
        CastTargetKind.dlna => Icons.router,
        CastTargetKind.jellyfinSession => Icons.devices,
      };

  String get _kindLabel => switch (_kind) {
        CastTargetKind.googleCast => 'Google Cast',
        CastTargetKind.airPlay => 'AirPlay',
        CastTargetKind.dlna => 'DLNA',
        CastTargetKind.jellyfinSession => 'Remote Playback',
      };

  Future<void> _doAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cast control failed: $e')),
      );
    }
  }

  void _onSeekEnd(double value, double maxValue) {
    setState(() => _isSeeking = false);
    if (maxValue <= 0) return;
    final ticks = value.round();
    _doAction(() => _castService.seek(_kind, positionTicks: ticks));
  }

  void _showFullControls() {
    final stateVal = _castService.remoteStateNotifier.value;
    final positionTicks = _castService.remotePositionNotifier.value;
    final volume = _castService.remoteVolumeNotifier.value;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColorScheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '$_kindLabel Controls',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: stateVal != null
                    ? Text(
                        '${stateVal[0].toUpperCase()}${stateVal.substring(1)}'
                        ' · ${_formatDuration(Duration(microseconds: positionTicks ~/ 10))}',
                        style: const TextStyle(color: Colors.white54),
                      )
                    : null,
              ),
              if (_kind == CastTargetKind.googleCast || _kind == CastTargetKind.dlna)
                ListTile(
                  leading: const Icon(Icons.volume_up_rounded, color: Colors.white),
                  title: const Text('Device Volume', style: TextStyle(color: Colors.white)),
                  subtitle: volume == null
                      ? const Text('Unavailable', style: TextStyle(color: Colors.white54))
                      : ValueListenableBuilder<double?>(
                          valueListenable: _castService.remoteVolumeNotifier,
                          builder: (context, vol, _) => SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColorScheme.accent,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white24,
                            ),
                            child: Slider(
                              value: (vol ?? 0).clamp(0.0, 1.0),
                              min: 0,
                              max: 1,
                              onChanged: (value) {
                                _castService.remoteVolumeNotifier.value = value;
                                _doAction(
                                  () => _castService.setVolume(_kind, volume: value),
                                );
                              },
                            ),
                          ),
                        ),
                  trailing: volume == null
                      ? null
                      : ValueListenableBuilder<double?>(
                          valueListenable: _castService.remoteVolumeNotifier,
                          builder: (context, vol, _) => Text(
                            '${((vol ?? 0) * 100).round()}%',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                ),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                title: const Text('Play', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _doAction(() => _castService.play(_kind));
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_rounded, color: Colors.white),
                title: const Text('Pause', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _doAction(() => _castService.pause(_kind));
                },
              ),
              ListTile(
                leading: const Icon(Icons.stop_rounded, color: Colors.white),
                title: Text('Stop $_kindLabel', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _doAction(() => _castService.stop(_kind));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackSelector({required bool audio}) {
    final item = _castService.castItemNotifier.value;
    if (item == null) return;
    final target = _castService.activeTargetNotifier.value;
    if (target == null) return;

    final allStreams = item.mediaStreams;
    final streamType = audio ? 'Audio' : 'Subtitle';
    final streams = allStreams.where((s) => s['Type'] == streamType).toList();

    final MediaServerClientFactory clientFactory =
        GetIt.instance<MediaServerClientFactory>();
    final MediaServerClient client =
        clientFactory.getClientIfExists(item.serverId) ??
            GetIt.instance<MediaServerClient>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColorScheme.surface,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spaceLg),
                child: Text(
                  audio ? 'Audio' : 'Subtitles',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...streams.asMap().entries.map((e) {
                      final stream = e.value;
                      final streamIndex = stream['Index'] as int? ?? e.key;
                      final displayTitle = stream['DisplayTitle'] as String?;
                      final title = stream['Title'] as String?;
                      final language = stream['Language'] as String?;
                      final codec = stream['Codec'] as String?;
                      final codecLabel = audioLabelFromProfileCodec(
                        stream['Profile'] as String?,
                        codec,
                      );
                      final label =
                          displayTitle ?? title ?? language ?? '$streamType ${e.key + 1}';
                      final subtitle = [
                        if (language != null && displayTitle != null) language,
                        if (codecLabel != null) codecLabel,
                        if (stream['Channels'] != null) '${stream['Channels']}ch',
                      ].join(' · ');

                      return ListTile(
                        title: Text(label, style: const TextStyle(color: Colors.white)),
                        subtitle: subtitle.isNotEmpty
                            ? Text(subtitle,
                                style: const TextStyle(color: Colors.white54))
                            : null,
                        leading: const Icon(Icons.radio_button_unchecked,
                            color: Colors.white38),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          final positionTicks =
                              _castService.remotePositionNotifier.value;
                          _doAction(() async {
                            await client.sessionApi.sendPlayCommand(
                              target.id,
                              playCommand: 'PlayNow',
                              itemIds: [item.id],
                              startPositionTicks: positionTicks,
                              audioStreamIndex: audio ? streamIndex : null,
                              subtitleStreamIndex: !audio ? streamIndex : null,
                            );
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final title = widget.item.name.isNotEmpty ? widget.item.name : _kindLabel;
    final durationTicks = (widget.item.runTimeTicks ?? 0).toDouble();

    return Dismissible(
      key: ValueKey('cast-mini-player-${_kind.name}-${widget.item.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        _doAction(() => _castService.stop(_kind));
      },
      child: GestureDetector(
        onTap: _showFullControls,
        child: Material(
          color: AppColorScheme.surface,
          child: Container(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SeekSliver(
                  castService: _castService,
                  durationTicks: durationTicks,
                  isSeeking: _isSeeking,
                  seekValue: _seekValue,
                  onSeekStart: (v) => setState(() {
                    _isSeeking = true;
                    _seekValue = v;
                  }),
                  onSeekChanged: (v) => setState(() => _seekValue = v),
                  onSeekEnd: (v) => _onSeekEnd(v, durationTicks),
                ),
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(_kindIcon, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppTypography.fontSizeSm,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ValueListenableBuilder<String?>(
                          valueListenable: _castService.remoteStateNotifier,
                          builder: (context, state, _) {
                            final isPlaying = state == 'playing';
                            return IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => isPlaying
                                  ? _doAction(() => _castService.pause(_kind))
                                  : _doAction(() => _castService.play(_kind)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop_rounded, color: Colors.white),
                          onPressed: () => _doAction(() => _castService.stop(_kind)),
                        ),
                        if (_kind == CastTargetKind.jellyfinSession) ...[
                          IconButton(
                            icon: const Icon(Icons.subtitles_outlined, color: Colors.white),
                            onPressed: () => _showTrackSelector(audio: false),
                          ),
                          IconButton(
                            icon: const Icon(Icons.audiotrack_outlined, color: Colors.white),
                            onPressed: () => _showTrackSelector(audio: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeekSliver extends StatelessWidget {
  final CastService castService;
  final double durationTicks;
  final bool isSeeking;
  final double seekValue;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;

  const _SeekSliver({
    required this.castService,
    required this.durationTicks,
    required this.isSeeking,
    required this.seekValue,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (durationTicks <= 0) {
      return LinearProgressIndicator(
        value: null,
        backgroundColor: Colors.white12,
        color: AppColorScheme.accent,
        minHeight: 2,
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: castService.remotePositionNotifier,
      builder: (context, positionTicks, _) {
        final double posValue =
            isSeeking ? seekValue : positionTicks.toDouble();
        final double maxValue = durationTicks;

        return Material(
          type: MaterialType.transparency,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColorScheme.accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColorScheme.accent,
              overlayColor: AppColorScheme.accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: posValue.clamp(0.0, maxValue),
              max: maxValue,
              onChangeStart: onSeekStart,
              onChanged: onSeekChanged,
              onChangeEnd: onSeekEnd,
            ),
          ),
        );
      },
    );
  }
}
