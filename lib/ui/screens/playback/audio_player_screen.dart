import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _manager = GetIt.instance<PlaybackManager>();
  final _client = GetIt.instance<MediaServerClient>();
  final _subs = <StreamSubscription>[];
  bool _showQueue = false;

  PlayerState get _state => _manager.state;
  QueueService get _queue => _manager.queueService;

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      _state.playingStream.listen((_) => _rebuild()),
      _state.positionStream.listen((_) => _rebuild()),
      _state.durationStream.listen((_) => _rebuild()),
      _state.repeatModeStream.listen((_) => _rebuild()),
      _state.shuffleStream.listen((_) => _rebuild()),
      _queue.queueChangedStream.listen((_) => _rebuild()),
    ]);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  String? _getArtUrl(AggregatedItem item) {
    final albumTag = item.albumPrimaryImageTag;
    final albumId = item.albumId;
    if (item.type == 'Audio' && albumTag != null && albumId != null) {
      return _client.imageApi
          .getPrimaryImageUrl(albumId, maxHeight: 600, tag: albumTag);
    }
    if (item.primaryImageTag != null) {
      return _client.imageApi
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

  @override
  Widget build(BuildContext context) {
    final currentItem = _queue.currentItem;
    final item = currentItem is AggregatedItem ? currentItem : null;
    final artUrl = item != null ? _getArtUrl(item) : null;

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (artUrl != null)
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
                _buildTopBar(context),
                Expanded(
                  child: _showQueue
                      ? _buildQueueList()
                      : _buildNowPlaying(item, artUrl),
                ),
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

  Widget _buildTopBar(BuildContext context) {
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
          IconButton(
            icon: Icon(
              _showQueue ? Icons.album : Icons.queue_music,
              size: 24,
            ),
            onPressed: () => setState(() => _showQueue = !_showQueue),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying(AggregatedItem? item, String? artUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
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
              child: artUrl != null
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
      return const Center(
        child: Text('Queue is empty', style: TextStyle(color: Colors.white54)),
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
            item?.name ?? 'Track ${index + 1}',
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
