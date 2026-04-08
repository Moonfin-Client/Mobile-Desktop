import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/models/lyrics.dart';
import '../../../data/repositories/item_mutation_repository.dart';
import '../../../data/services/cast/cast_service.dart';
import '../../../data/services/cast/cast_target.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/remote_play_to_session_dialog.dart';
import '../../widgets/playback/lyrics_view.dart';
import '../../../l10n/app_localizations.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _manager = GetIt.instance<PlaybackManager>();
  final _castService = GetIt.instance<CastService>();
  final _clientFactory = GetIt.instance<MediaServerClientFactory>();
  final _mutations = GetIt.instance<ItemMutationRepository>();
  final _subs = <StreamSubscription>[];
  bool _showQueue = false;
  bool _showLyrics = false;
  bool? _localFavorite;
  String? _favoriteItemId;
  LyricsData? _lyrics;
  String? _lyricsItemId;

  PlayerState get _state => _manager.state;
  QueueService get _queue => _manager.queueService;

  MediaServerClient _clientForItem(AggregatedItem item) {
    return _clientFactory.getClientIfExists(item.serverId) ??
        GetIt.instance<MediaServerClient>();
  }

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      _state.playingStream.listen((_) => _rebuild()),
      _state.positionStream.listen((_) => _rebuild()),
      _state.durationStream.listen((_) => _rebuild()),
      _state.repeatModeStream.listen((_) => _rebuild()),
      _state.shuffleStream.listen((_) => _rebuild()),
      _queue.queueChangedStream.listen((_) {
        _rebuild();
        _loadLyricsIfNeeded();
      }),
    ]);
    _loadLyricsIfNeeded();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  bool _getIsFavorite(AggregatedItem item) {
    if (_favoriteItemId == item.id) return _localFavorite ?? item.isFavorite;
    return item.isFavorite;
  }

  Future<void> _toggleFavorite(AggregatedItem item) async {
    final current = _getIsFavorite(item);
    final newVal = !current;
    setState(() {
      _favoriteItemId = item.id;
      _localFavorite = newVal;
    });
    try {
      await _mutations.setFavorite(item.id, isFavorite: newVal);
    } catch (_) {
      if (mounted) setState(() => _localFavorite = current);
    }
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  AggregatedItem? _resolveCurrentItem() {
    final currentItem = _queue.currentItem;
    if (currentItem is AggregatedItem) return currentItem;
    final meta = _manager.currentOfflineMetadata;
    if (meta == null) return null;
    final id = meta['Id'] as String? ?? '';
    final serverId = meta['ServerId'] as String? ?? '';
    return AggregatedItem(id: id, serverId: serverId, rawData: meta);
  }

  String? _offlinePosterPath() {
    final meta = _manager.currentOfflineMetadata;
    return meta?['_localPosterPath'] as String?;
  }

  Future<void> _loadLyricsIfNeeded() async {
    final resolved = _resolveCurrentItem();
    if (resolved == null) return;
    if (resolved.id == _lyricsItemId) return;
    _lyricsItemId = resolved.id;

    final meta = _manager.currentOfflineMetadata;
    final lyricsPath = meta?['_localLyricsPath'] as String?;
    if (lyricsPath != null) {
      try {
        final file = File(lyricsPath);
        if (await file.exists()) {
          final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          if (mounted && _lyricsItemId == resolved.id) {
            setState(() => _lyrics = LyricsData.fromJson(data));
          }
          return;
        }
      } catch (_) {}
    }

    if (_manager.isOfflinePlayback) {
      if (mounted) setState(() => _lyrics = LyricsData.empty);
      return;
    }
    try {
      final client = _clientForItem(resolved);
      final data = await client.itemsApi.getLyrics(resolved.id);
      if (mounted && _lyricsItemId == resolved.id) {
        setState(() => _lyrics = LyricsData.fromJson(data));
      }
    } catch (_) {
      if (mounted) setState(() => _lyrics = LyricsData.empty);
    }
  }

  String? _getArtUrl(AggregatedItem item) {
    final client = _clientForItem(item);
    final albumTag = item.albumPrimaryImageTag;
    final albumId = item.albumId;
    if (item.type == 'Audio' && albumTag != null && albumId != null) {
      return client.imageApi
          .getPrimaryImageUrl(albumId, maxHeight: 600, tag: albumTag);
    }
    if (item.primaryImageTag != null) {
      return client.imageApi
          .getPrimaryImageUrl(item.id, maxHeight: 600, tag: item.primaryImageTag);
    }
    return null;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _shouldUseSplitLyricsLayout(BuildContext context) {
    if (_showQueue || _lyrics == null || _lyrics!.isEmpty) {
      return false;
    }
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    return !PlatformDetection.useMobileUi || isLandscape;
  }

  @override
  Widget build(BuildContext context) {
    final item = _resolveCurrentItem();
    final localPoster = _offlinePosterPath();
    final artUrl = item != null && !_manager.isOfflinePlayback ? _getArtUrl(item) : null;
    final useSplitLyricsLayout = _shouldUseSplitLyricsLayout(context);

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (localPoster != null && File(localPoster).existsSync())
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Image.file(
                  File(localPoster),
                  fit: BoxFit.cover,
                  color: Colors.black54,
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            )
          else if (artUrl != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: CachedNetworkImage(
                  imageUrl: artUrl,
                  fit: BoxFit.cover,
                  color: Colors.black54,
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, item),
                Expanded(
                  child: _showQueue
                      ? _buildQueueList()
                      : useSplitLyricsLayout
                          ? _buildNowPlayingWithLyrics(
                              item,
                              artUrl,
                              localPoster: localPoster,
                            )
                      : _showLyrics && _lyrics != null && _lyrics!.isNotEmpty
                          ? LyricsView(
                              lyrics: _lyrics!,
                              positionStream: _state.positionStream,
                              position: _state.position,
                            )
                          : _buildNowPlaying(item, artUrl, localPoster: localPoster),
                ),
                if (item != null && !_showQueue && !_showLyrics)
                  _buildFavoriteRow(item),
                _buildProgressBar(),
                _buildTransportControls(),
                const SizedBox(height: AppSpacing.spaceLg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AggregatedItem? item) {
    final useSplitLyricsLayout = _shouldUseSplitLyricsLayout(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceSm,
        vertical: AppSpacing.spaceXs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          if (_lyrics != null && _lyrics!.isNotEmpty && !useSplitLyricsLayout)
            IconButton(
              icon: Icon(
                Icons.lyrics_outlined,
                size: 24,
                color: _showLyrics ? AppColorScheme.accent : null,
              ),
              onPressed: () => setState(() {
                _showLyrics = !_showLyrics;
                if (_showLyrics) _showQueue = false;
              }),
            ),
          if (item != null)
            ValueListenableBuilder<CastTargetKind?>(
              valueListenable: _castService.activeKindNotifier,
              builder: (context, kind, _) => IconButton(
                icon: Icon(
                  _castIcon(kind),
                  size: 24,
                  color: kind != null ? AppColorScheme.accent : null,
                ),
                onPressed: () => _castToDevice(item),
              ),
            ),
          ValueListenableBuilder<CastTargetKind?>(
            valueListenable: _castService.activeKindNotifier,
            builder: (context, kind, _) {
              if (kind == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.settings_remote_rounded, size: 24),
                onPressed: _showCastControls,
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showQueue ? Icons.album : Icons.queue_music,
              size: 24,
              color: _showQueue ? AppColorScheme.accent : null,
            ),
            onPressed: () => setState(() {
              _showQueue = !_showQueue;
              if (_showQueue) _showLyrics = false;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingWithLyrics(
    AggregatedItem? item,
    String? artUrl, {
    String? localPoster,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: _buildNowPlaying(item, artUrl, localPoster: localPoster),
          ),
          const SizedBox(width: AppSpacing.spaceLg),
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceSm),
              child: LyricsView(
                lyrics: _lyrics!,
                positionStream: _state.positionStream,
                position: _state.position,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying(AggregatedItem? item, String? artUrl, {String? localPoster}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxArtByWidth = (constraints.maxWidth - (AppSpacing.space2xl * 2))
            .clamp(160.0, 560.0);
        final maxArtByHeight = (constraints.maxHeight * 0.62)
            .clamp(160.0, 560.0);
        final artSize = maxArtByWidth < maxArtByHeight ? maxArtByWidth : maxArtByHeight;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: artSize,
                  height: artSize,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: localPoster != null && File(localPoster).existsSync()
                        ? Image.file(
                            File(localPoster),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _artPlaceholder(),
                          )
                        : artUrl != null
                            ? CachedNetworkImage(
                                imageUrl: artUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _artPlaceholder(),
                                errorWidget: (_, __, ___) => _artPlaceholder(),
                              )
                            : _artPlaceholder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceXl),
                Text(
                  item?.name ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spaceXs),
                Text(
                  _artistLine(item),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (item?.album != null) ...[
                  const SizedBox(height: AppSpacing.space2xs),
                  Text(
                    item!.album!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: AppColorScheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.music_note, size: 64, color: Colors.white38),
      ),
    );
  }

  Widget _queueArtPlaceholder() {
    return Container(
      color: AppColorScheme.surfaceVariant,
      child: const Icon(Icons.music_note, size: 24, color: Colors.white38),
    );
  }

  String _artistLine(AggregatedItem? item) {
    if (item == null) return '';
    if (item.artists.isNotEmpty) return item.artists.join(', ');
    if (item.albumArtist != null) return item.albumArtist!;
    return '';
  }

  Future<void> _castToDevice(AggregatedItem item) async {
    if (_manager.isOfflinePlayback) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.castingUnavailableOffline)),
      );
      return;
    }

    final positionTicks = _state.position.inMicroseconds * 10;
    final startIndex = _queue.currentIndex < 0 ? 0 : _queue.currentIndex;
    final queueItems = _queue.items
        .skip(startIndex)
        .whereType<AggregatedItem>()
        .toList(growable: false);

    await showRemotePlayToSessionDialog(
      context,
      item: item,
      queueItems: queueItems.length > 1 ? queueItems : null,
      startPositionTicks: positionTicks,
      audioStreamIndex: _manager.audioStreamIndex,
      subtitleStreamIndex: _manager.subtitleStreamIndex,
    );
  }

  IconData _castIcon(CastTargetKind? kind) => switch (kind) {
    CastTargetKind.googleCast => Icons.cast_connected,
    CastTargetKind.airPlay => Icons.airplay,
    CastTargetKind.dlna => Icons.router,
    CastTargetKind.jellyfinSession => Icons.devices,
    null => Icons.cast,
  };

  Future<void> _runCastAction(
    Future<void> Function(CastTargetKind kind) action,
  ) async {
    final kind = _castService.activeKind;
    if (kind == null || !mounted) return;
    try {
      await action(kind);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final label = switch (kind) {
        CastTargetKind.googleCast => 'Google Cast',
        CastTargetKind.airPlay => 'AirPlay',
        CastTargetKind.dlna => 'DLNA',
        CastTargetKind.jellyfinSession => l10n.remotePlayback,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.castActionFailed(label, '$e'))));
    }
  }

  Future<void> _refreshRemoteVolume() async {
    final kind = _castService.activeKind;
    if (kind == null || !mounted) return;
    try {
      _castService.remoteVolumeNotifier.value = await _castService.getVolume(kind);
    } catch (_) {
      _castService.remoteVolumeNotifier.value = null;
    }
  }

  Future<void> _setRemoteVolume(double volume) async {
    final kind = _castService.activeKind;
    if (kind == null || !mounted) return;
    _castService.remoteVolumeNotifier.value = volume;
    try {
      await _castService.setVolume(kind, volume: volume);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.failedToSetCastVolume('$e'))));
    }
  }

  void _showCastControls() {
    final kind = _castService.activeKind;
    if (kind == null) return;

    _refreshRemoteVolume();

    final l10n = AppLocalizations.of(context);
    final label = switch (kind) {
      CastTargetKind.googleCast => 'Google Cast',
      CastTargetKind.airPlay => 'AirPlay',
      CastTargetKind.dlna => 'DLNA',
      CastTargetKind.jellyfinSession => l10n.remotePlayback,
    };

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _castService.remoteStateNotifier,
              builder: (context, stateVal, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: _castService.remotePositionNotifier,
                  builder: (context, ticks, _) => ListTile(
                    title: Text(
                      l10n.castControlsTitle(label),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: stateVal != null
                        ? Text(
                            '${stateVal[0].toUpperCase()}${stateVal.substring(1)}'
                            ' · ${_formatDuration(Duration(microseconds: ticks ~/ 10))}',
                            style: const TextStyle(color: Colors.white54),
                          )
                        : null,
                  ),
                );
              },
            ),
            if (kind == CastTargetKind.googleCast || kind == CastTargetKind.dlna)
              ListTile(
                leading: const Icon(Icons.volume_up_rounded, color: Colors.white),
                title: Text(l10n.deviceVolume, style: const TextStyle(color: Colors.white)),
                subtitle: ValueListenableBuilder<double?>(
                  valueListenable: _castService.remoteVolumeNotifier,
                  builder: (context, vol, _) => vol == null
                      ? Text(l10n.unavailable, style: const TextStyle(color: Colors.white54))
                      : SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColorScheme.accent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white24,
                          ),
                          child: Slider(
                            value: vol.clamp(0.0, 1.0),
                            min: 0,
                            max: 1,
                            onChanged: _setRemoteVolume,
                          ),
                        ),
                ),
                trailing: ValueListenableBuilder<double?>(
                  valueListenable: _castService.remoteVolumeNotifier,
                  builder: (context, vol, _) => vol == null
                      ? const SizedBox.shrink()
                      : Text(
                          '${(vol * 100).round()}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              title: Text(l10n.play, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _runCastAction((k) => _castService.play(k));
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_rounded, color: Colors.white),
              title: Text(l10n.pause, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _runCastAction((k) => _castService.pause(k));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: Colors.white),
              title: Text(l10n.syncPosition, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                final positionTicks = _state.position.inMicroseconds * 10;
                _runCastAction((k) => _castService.seek(k, positionTicks: positionTicks));
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop_rounded, color: Colors.white),
              title: Text(l10n.stopCast(label), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _runCastAction((k) => _castService.stop(k));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteRow(AggregatedItem item) {
    final isFav = _getIsFavorite(item);
    return IconButton(
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        size: 28,
        color: isFav ? AppColorScheme.accent : Colors.white.withValues(alpha: 0.7),
      ),
      onPressed: () => _toggleFavorite(item),
    );
  }

  Widget _buildProgressBar() {
    final pos = _state.position;
    final dur = _state.duration;
    final maxMs = dur.inMilliseconds.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColorScheme.accent,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColorScheme.accent,
              overlayColor: AppColorScheme.accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: maxMs > 0
                  ? pos.inMilliseconds.toDouble().clamp(0, maxMs)
                  : 0,
              max: maxMs > 0 ? maxMs : 1,
              onChanged: (v) {
                _manager.seekTo(Duration(milliseconds: v.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(pos),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  _formatDuration(dur),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportControls() {
    final isPlaying = _state.isPlaying;
    final repeatMode = _queue.repeatMode;
    final isShuffled = _queue.isShuffled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              size: 24,
              color: isShuffled
                  ? AppColorScheme.accent
                  : Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: () => _manager.toggleShuffle(),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
            onPressed: () => _manager.previous(),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColorScheme.accent,
            ),
            child: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 36,
                color: Colors.white,
              ),
              onPressed: () {
                if (isPlaying) {
                  _manager.pause();
                } else {
                  _manager.resume();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
            onPressed: () => _manager.next(),
          ),
          IconButton(
            icon: Icon(
              repeatMode == RepeatMode.repeatOne
                  ? Icons.repeat_one
                  : Icons.repeat,
              size: 24,
              color: repeatMode != RepeatMode.none
                  ? AppColorScheme.accent
                  : Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: () => _manager.toggleRepeat(),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    final items = _queue.items;
    final currentIdx = _queue.currentIndex;

    if (items.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).queueIsEmpty, style: const TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final raw = items[index];
        final item = raw is AggregatedItem ? raw : null;
        final isCurrent = index == currentIdx;
        final artUrl = item != null ? _getArtUrl(item) : null;

        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: artUrl != null
                  ? CachedNetworkImage(
                      imageUrl: artUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _queueArtPlaceholder(),
                      errorWidget: (_, __, ___) => _queueArtPlaceholder(),
                    )
                  : _queueArtPlaceholder(),
            ),
          ),
          title: Text(
            item?.name ?? AppLocalizations.of(context).trackNumber(index + 1),
            style: TextStyle(
              color: isCurrent ? AppColorScheme.accent : Colors.white,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _artistLine(item),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isCurrent
              ? const Icon(Icons.equalizer, color: AppColorScheme.accent, size: 20)
              : null,
          onTap: () => _manager.playFromQueue(index),
        );
      },
    );
  }
}
