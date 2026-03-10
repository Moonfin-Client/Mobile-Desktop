import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../preference/preference_constants.dart';

class MediaCard extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final double width;
  final double aspectRatio;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final VoidCallback? onHoverStart;
  final VoidCallback? onHoverEnd;
  final VoidCallback? onLongPress;
  final bool isFavorite;
  final bool isPlayed;
  final int? unplayedCount;
  final double? playedPercentage;
  final WatchedIndicatorBehavior watchedBehavior;
  final String? itemType;

  const MediaCard({
    super.key,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.width = 150,
    this.aspectRatio = 2 / 3,
    this.onTap,
    this.onFocus,
    this.onHoverStart,
    this.onHoverEnd,
    this.onLongPress,
    this.isFavorite = false,
    this.isPlayed = false,
    this.unplayedCount,
    this.playedPercentage,
    this.watchedBehavior = WatchedIndicatorBehavior.always,
    this.itemType,
  });

  static double aspectRatioForType(String? type) {
    switch (type) {
      case 'Episode':
      case 'Program':
      case 'Recording':
        return 16 / 9;
      case 'MusicAlbum':
      case 'Audio':
      case 'MusicArtist':
      case 'Person':
        return 1;
      default:
        return 2 / 3;
    }
  }

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showMarquee = _focused || _hovered;
    return SizedBox(
      width: widget.width,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hovered = true);
          widget.onHoverStart?.call();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          widget.onHoverEnd?.call();
        },
        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() => _focused = hasFocus);
            if (hasFocus) widget.onFocus?.call();
          },
          child: GestureDetector(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: AnimatedScale(
              scale: _focused ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardImage(
                    imageUrl: widget.imageUrl,
                    aspectRatio: widget.aspectRatio,
                    isFavorite: widget.isFavorite,
                    isPlayed: widget.isPlayed,
                    unplayedCount: widget.unplayedCount,
                    playedPercentage: widget.playedPercentage,
                    watchedBehavior: widget.watchedBehavior,
                    focused: _focused,
                    isCircular: widget.itemType == 'Person',
                    itemType: widget.itemType,
                  ),
                  if (widget.title != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 16,
                      child: showMarquee
                          ? _MarqueeText(
                              text: widget.title!,
                              style: Theme.of(context).textTheme.bodySmall!,
                            )
                          : Text(
                              widget.title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                    ),
                  ],
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;
  final double aspectRatio;
  final bool isFavorite;
  final bool isPlayed;
  final int? unplayedCount;
  final double? playedPercentage;
  final WatchedIndicatorBehavior watchedBehavior;
  final bool focused;
  final bool isCircular;
  final String? itemType;

  const _CardImage({
    this.imageUrl,
    required this.aspectRatio,
    required this.isFavorite,
    required this.isPlayed,
    this.unplayedCount,
    this.playedPercentage,
    required this.watchedBehavior,
    required this.focused,
    this.isCircular = false,
    this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isCircular ? 999.0 : 8.0;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: focused
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(radius + 2),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              )
            : const BoxDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        errorWidget: (_, __, ___) =>
                            const _PlaceholderIcon(),
                      )
                    : const _PlaceholderIcon(),
              ),
              if (isFavorite)
                const Positioned(
                  top: 4,
                  left: 4,
                  child: Icon(Icons.favorite, color: Colors.red, size: 18),
                ),
              if (_showWatchedIndicator)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildWatchedIndicator(),
                ),
              if (playedPercentage != null && playedPercentage! > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: playedPercentage! / 100,
                    minHeight: 4,
                    backgroundColor: Colors.black54,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF00A4DC)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _showWatchedIndicator {
    switch (watchedBehavior) {
      case WatchedIndicatorBehavior.always:
        return isPlayed || (unplayedCount != null && unplayedCount! > 0);
      case WatchedIndicatorBehavior.hideUnwatched:
        return isPlayed;
      case WatchedIndicatorBehavior.episodesOnly:
        return itemType == 'Episode' &&
            (isPlayed || (unplayedCount != null && unplayedCount! > 0));
      case WatchedIndicatorBehavior.never:
        return false;
    }
  }

  Widget _buildWatchedIndicator() {
    if (isPlayed) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF00A4DC),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: EdgeInsets.all(2),
          child: Icon(Icons.check, color: Colors.white, size: 12),
        ),
      );
    }
    if (unplayedCount != null && unplayedCount! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF00A4DC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$unplayedCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.movie, size: 32, color: Colors.white38),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _controller;
  late final AnimationController _anim;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _anim = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    if (!mounted || !_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    if (max > 0) {
      _needsScroll = true;
      final duration = Duration(milliseconds: (max * 30).toInt().clamp(1500, 8000));
      _anim.duration = duration;
      _anim.addListener(_onTick);
      _anim.repeat(reverse: true);
    }
  }

  void _onTick() {
    if (_controller.hasClients) {
      _controller.jumpTo(
        _anim.value * _controller.position.maxScrollExtent,
      );
    }
  }

  @override
  void dispose() {
    _anim.removeListener(_onTick);
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        maxLines: 1,
        style: widget.style,
      ),
    );
  }
}
