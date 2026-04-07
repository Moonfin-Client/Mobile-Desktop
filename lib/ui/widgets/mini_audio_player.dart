import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/services/media_server_client_factory.dart';
import '../navigation/app_router.dart';
import '../navigation/destinations.dart';

class MiniAudioPlayer extends StatefulWidget {
  const MiniAudioPlayer({super.key});

  @override
  State<MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends State<MiniAudioPlayer> {
  final _manager = GetIt.instance<PlaybackManager>();
  final _clientFactory = GetIt.instance<MediaServerClientFactory>();
  final _subs = <StreamSubscription>[];
  String? _dismissedItemId;

  PlayerState get _state => _manager.state;
  QueueService get _queue => _manager.queueService;

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      _state.playingStream.listen((_) => _rebuild()),
      _queue.queueChangedStream.listen((_) => _rebuild()),
    ]);
  }

  void _rebuild() {
    final item = _currentItem;
    if (item == null || item.id != _dismissedItemId) {
      _dismissedItemId = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  AggregatedItem? get _currentItem {
    final raw = _queue.currentItem;
    return raw is AggregatedItem ? raw : null;
  }

  String? _artUrl(AggregatedItem item) {
    try {
      final client = _clientFactory.getClientIfExists(item.serverId) ??
          GetIt.instance<MediaServerClient>();
      final albumTag = item.albumPrimaryImageTag;
      final albumId = item.albumId;
      if (item.type == 'Audio' && albumTag != null && albumId != null) {
        return client.imageApi
            .getPrimaryImageUrl(albumId, maxHeight: 120, tag: albumTag);
      }
      if (item.primaryImageTag != null) {
        return client.imageApi
            .getPrimaryImageUrl(item.id, maxHeight: 120, tag: item.primaryImageTag);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;
    if (item == null || !_isAudioLikeItem(item)) {
      return const SizedBox.shrink();
    }
    if (_dismissedItemId == item.id) {
      return const SizedBox.shrink();
    }

    final isPlaying = _state.isPlaying;
    final artUrl = _artUrl(item);

    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Dismissible(
      key: ValueKey('mini-player-${item.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        setState(() => _dismissedItemId = item.id);
        unawaited(_manager.stop());
      },
      child: GestureDetector(
        onTap: () => appRouter.push(Destinations.audioPlayer),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomPad),
          color: AppColorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProgressSliver(state: _state),
              SizedBox(
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _ArtThumbnail(artUrl: artUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TrackInfo(item: item),
                      ),
                      _TransportButtons(
                        isPlaying: isPlaying,
                        onPrev: _manager.previous,
                        onPlayPause: isPlaying ? _manager.pause : _manager.resume,
                        onNext: _manager.next,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isAudioLikeItem(AggregatedItem item) {
    final mediaType = item.rawData['MediaType'] as String?;
    return item.type == 'Audio' || item.type == 'AudioBook' || mediaType == 'Audio';
  }
}

class _ProgressSliver extends StatefulWidget {
  final PlayerState state;
  const _ProgressSliver({required this.state});

  @override
  State<_ProgressSliver> createState() => _ProgressSliverState();
}

class _ProgressSliverState extends State<_ProgressSliver> {
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _position = widget.state.position;
    _duration = widget.state.duration;
    _posSub = widget.state.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = widget.state.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _duration.inMilliseconds.toDouble();
    final value = maxMs > 0
        ? (_position.inMilliseconds.toDouble().clamp(0, maxMs) / maxMs)
        : 0.0;

    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.white12,
      color: AppColorScheme.accent,
      minHeight: 2,
    );
  }
}

class _ArtThumbnail extends StatelessWidget {
  final String? artUrl;
  const _ArtThumbnail({this.artUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 44,
        height: 44,
        child: artUrl != null
            ? CachedNetworkImage(
                imageUrl: artUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: AppColorScheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.music_note, size: 22, color: Colors.white38),
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final AggregatedItem item;
  const _TrackInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    final artist = item.artists.isNotEmpty
        ? item.artists.join(', ')
        : item.albumArtist ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (artist.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            artist,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _TransportButtons extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPrev;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  const _TransportButtons({
    required this.isPlaying,
    required this.onPrev,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 24, color: Colors.white),
          onPressed: onPrev,
        ),
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 28,
            color: Colors.white,
          ),
          onPressed: onPlayPause,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 24, color: Colors.white),
          onPressed: onNext,
        ),
      ],
    );
  }
}
