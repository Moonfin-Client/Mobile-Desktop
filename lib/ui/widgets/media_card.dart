import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../preference/preference_constants.dart';
import '../mixins/focus_state_mixin.dart';

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
  final String? seerrMediaType;
  final int? seerrStatus;
  final Color? focusColor;
  final bool cardFocusExpansion;

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
    this.seerrMediaType,
    this.seerrStatus,
    this.focusColor,
    this.cardFocusExpansion = true,
  });

  static IconData iconForType(String? type) {
    switch (type) {
      case 'Folder':
      case 'CollectionFolder':
      case 'UserView':
        return Icons.folder_rounded;
      case 'Series':
        return Icons.tv;
      case 'Season':
        return Icons.format_list_numbered;
      case 'Movie':
        return Icons.movie;
      case 'Episode':
      case 'Video':
      case 'MusicVideo':
        return Icons.play_circle_outline;
      case 'Audio':
        return Icons.music_note;
      case 'MusicAlbum':
        return Icons.album;
      case 'MusicArtist':
      case 'Person':
        return Icons.person;
      case 'Photo':
        return Icons.photo;
      case 'PhotoAlbum':
        return Icons.photo_library;
      case 'BoxSet':
        return Icons.collections_bookmark;
      case 'Playlist':
        return Icons.playlist_play;
      case 'Book':
        return Icons.book;
      default:
        return Icons.movie;
    }
  }

  static double aspectRatioForType(String? type) {
    switch (type) {
      case 'Episode':
      case 'Program':
      case 'Recording':
      case 'Video':
      case 'MusicVideo':
        return 16 / 9;
      case 'MusicAlbum':
      case 'Audio':
      case 'MusicArtist':
      case 'Playlist':
      case 'Person':
        return 1;
      default:
        return 2 / 3;
    }
  }

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final showMarquee = showFocusBorder;
    return SizedBox(
      width: widget.width,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setHovered(true);
          widget.onHoverStart?.call();
        },
        onExit: (_) {
          setHovered(false);
          widget.onHoverEnd?.call();
        },
        child: Focus(
          onFocusChange: (hasFocus) {
            setFocused(hasFocus);
            if (hasFocus) widget.onFocus?.call();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onLongPressStart: (_) => widget.onLongPress?.call(),
            child: AnimatedScale(
              scale: widget.cardFocusExpansion && showFocusBorder ? 1.05 : 1.0,
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
                    focused: focused,
                    hovered: hovered,
                    focusColor: widget.focusColor,
                    isCircular: widget.itemType == 'Person',
                    itemType: widget.itemType,
                    seerrMediaType: widget.seerrMediaType,
                    seerrStatus: widget.seerrStatus,
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
                    SizedBox(
                      height: 16,
                      child: Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(153),
                        ),
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
  final bool hovered;
  final Color? focusColor;
  final bool isCircular;
  final String? itemType;
  final String? seerrMediaType;
  final int? seerrStatus;

  const _CardImage({
    this.imageUrl,
    required this.aspectRatio,
    required this.isFavorite,
    required this.isPlayed,
    this.unplayedCount,
    this.playedPercentage,
    required this.watchedBehavior,
    required this.focused,
    this.hovered = false,
    this.focusColor,
    this.isCircular = false,
    this.itemType,
    this.seerrMediaType,
    this.seerrStatus,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isCircular ? 999.0 : 8.0;
    final showBorder = focused || hovered;
    final borderColor = focusColor ?? Theme.of(context).colorScheme.primary;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
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
                              _PlaceholderIcon(itemType: itemType),
                        )
                      : _PlaceholderIcon(itemType: itemType),
                ),
                if (isFavorite)
                  Positioned(
                    top: _showSeerrMediaTypeBadge ? 28 : 4,
                    left: 4,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                if (_showSeerrMediaTypeBadge)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _buildSeerrMediaTypeBadge(),
                  ),
                if (_showSeerrStatusIndicator)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _buildSeerrStatusIndicator(),
                  )
                else if (_showWatchedIndicator)
                  Positioned(top: 4, right: 4, child: _buildWatchedIndicator()),
                if (playedPercentage != null && playedPercentage! > 0)
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: playedPercentage! / 100,
                        minHeight: 6,
                        backgroundColor: Colors.black54,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00A4DC),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showBorder)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: borderColor, width: 2),
                ),
              ),
            ),
        ],
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

  bool get _showSeerrMediaTypeBadge {
    final type = seerrMediaType?.toLowerCase();
    return type == 'movie' || type == 'tv';
  }

  bool get _showSeerrStatusIndicator =>
      seerrStatus == 3 || seerrStatus == 4 || seerrStatus == 5;

  Widget _buildSeerrMediaTypeBadge() {
    final type = seerrMediaType?.toLowerCase();
    final isMovie = type == 'movie';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isMovie ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6))
            .withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          isMovie ? 'MOVIE' : 'SERIES',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildSeerrStatusIndicator() {
    if (seerrStatus == 5) {
      return _buildStatusCircle(
        borderColor: const Color(0xFF22C55E),
        icon: const Icon(
          Icons.check_rounded,
          size: 12,
          color: Color(0xFF22C55E),
        ),
      );
    }

    if (seerrStatus == 4) {
      return _buildStatusCircle(
        fillColor: const Color(0xFF22C55E),
        icon: const Icon(Icons.remove_rounded, size: 13, color: Colors.white),
      );
    }

    return _buildStatusCircle(
      borderColor: const Color(0xFF9333EA),
      icon: const SizedBox(
        width: 11,
        height: 11,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
        ),
      ),
    );
  }

  Widget _buildStatusCircle({
    required Widget icon,
    Color fillColor = Colors.white,
    Color? borderColor,
  }) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? fillColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: icon,
    );
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
  final String? itemType;

  const _PlaceholderIcon({this.itemType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        MediaCard.iconForType(itemType),
        size: 32,
        color: Colors.white38,
      ),
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
      final duration = Duration(
        milliseconds: (max * 30).toInt().clamp(1500, 8000),
      );
      _anim.duration = duration;
      _anim.addListener(_onTick);
      _anim.repeat(reverse: true);
    }
  }

  void _onTick() {
    if (_controller.hasClients) {
      _controller.jumpTo(_anim.value * _controller.position.maxScrollExtent);
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
      child: Text(widget.text, maxLines: 1, style: widget.style),
    );
  }
}
