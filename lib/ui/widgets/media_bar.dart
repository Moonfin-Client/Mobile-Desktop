import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/media_bar_slide_item.dart';
import '../../data/models/media_bar_state.dart';
import '../../data/viewmodels/media_bar_view_model.dart';
import '../../preference/user_preferences.dart';
import '../navigation/destinations.dart';
import '../../util/platform_detection.dart';
import 'rating_display.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class MediaBar extends StatefulWidget {
  final MediaBarViewModel viewModel;
  final UserPreferences prefs;
  final bool externallyPaused;
  final double height;

  const MediaBar({
    super.key,
    required this.viewModel,
    required this.prefs,
    this.externallyPaused = false,
    this.height = 220,
  });

  @override
  State<MediaBar> createState() => _MediaBarState();
}

class _MediaBarState extends State<MediaBar> {
  final _pageController = PageController();

  Timer? _autoAdvanceTimer;
  bool _isPaused = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
    widget.prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    widget.viewModel.removeListener(_onStateChanged);
    widget.prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(MediaBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externallyPaused != oldWidget.externallyPaused) {
      if (widget.externallyPaused) {
        _autoAdvanceTimer?.cancel();
      } else {
        _startAutoAdvance();
      }
    }
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    final state = widget.viewModel.state;
    if (state is MediaBarReady && state.items.isNotEmpty) {
      _startAutoAdvance();
    }
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!widget.prefs.get(UserPreferences.mediaBarAutoAdvance)) return;
    if (widget.externallyPaused) return;
    final intervalMs = widget.prefs.get(UserPreferences.mediaBarIntervalMs);
    _autoAdvanceTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        if (_isPaused || !mounted || widget.externallyPaused) return;
        final items = widget.viewModel.items;
        if (items.isEmpty) return;
        final nextIndex = (_currentIndex + 1) % items.length;
        _goToPage(nextIndex);
      },
    );
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _startAutoAdvance();
  }

  void _setPaused(bool paused) {
    if (_isPaused == paused) return;
    _isPaused = paused;
    if (paused) {
      _autoAdvanceTimer?.cancel();
    } else {
      _startAutoAdvance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.viewModel.state;

    return switch (state) {
      MediaBarLoading() => SizedBox(height: widget.height),
      MediaBarDisabled() => const SizedBox.shrink(),
      MediaBarError() => SizedBox(height: widget.height),
      MediaBarReady(items: final items) => items.isEmpty
          ? const SizedBox.shrink()
          : _buildSlideshow(context, items),
    };
  }

  Widget _buildSlideshow(BuildContext context, List<MediaBarSlideItem> items) {
    const overlayColor = Colors.black;
    const overlayOpacity = 0.7;
    final currentItem = items.elementAtOrNull(_currentIndex);

    return MouseRegion(
      onEnter: (_) => _setPaused(true),
      onExit: (_) => _setPaused(false),
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        onFocusChange: (focused) => _setPaused(focused),
        onKeyEvent: (node, event) => _handleKeyEvent(event, items),
        child: GestureDetector(
          onTap: () => _navigateToItem(context, items),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BackdropLayer(
                  items: items,
                  pageController: _pageController,
                  onPageChanged: _onPageChanged,
                ),
                _GradientOverlay(
                  color: overlayColor,
                  opacity: overlayOpacity,
                ),
                if (items.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: _IndicatorDots(
                      count: items.length,
                      current: _currentIndex,
                      overlayColor: overlayColor,
                      overlayOpacity: overlayOpacity,
                    ),
                  ),
                if (currentItem != null && currentItem.logoUrl != null && !PlatformDetection.useMobileUi)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 16,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        key: ValueKey('logo_${currentItem.itemId}'),
                        width: 280,
                        height: 120,
                        child: _buildLogoWithShadow(currentItem.logoUrl!),
                      ),
                    ),
                  ),
                if (currentItem != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: PlatformDetection.useMobileUi
                          ? HitTestBehavior.translucent
                          : HitTestBehavior.deferToChild,
                      onHorizontalDragEnd: PlatformDetection.useMobileUi
                          ? (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              if (velocity < -300 && _currentIndex < items.length - 1) {
                                _goToPage(_currentIndex + 1);
                              } else if (velocity > 300 && _currentIndex > 0) {
                                _goToPage(_currentIndex - 1);
                              }
                            }
                          : null,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey(currentItem.itemId),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (PlatformDetection.useMobileUi && currentItem.logoUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 8),
                                child: SizedBox(
                                  width: 180,
                                  height: 70,
                                  child: _buildLogoWithShadow(currentItem.logoUrl!),
                                ),
                              ),
                            _SlideInfo(
                              item: currentItem,
                              ratings: widget.viewModel.ratingsFor(currentItem.itemId),
                              enableAdditionalRatings: widget.prefs.get(
                                UserPreferences.enableAdditionalRatings,
                              ),
                              enabledRatings: widget.prefs.get(UserPreferences.enabledRatings),
                              blockedRatings: widget.prefs.get(UserPreferences.blockedRatings),
                              showLabels: widget.prefs.get(UserPreferences.showRatingLabels),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (items.length > 1 && !PlatformDetection.useMobileUi) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_left,
                        onTap: _currentIndex > 0
                            ? () => _goToPage(_currentIndex - 1)
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_right,
                        onTap: _currentIndex < items.length - 1
                            ? () => _goToPage(_currentIndex + 1)
                            : null,
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

  KeyEventResult _handleKeyEvent(
    KeyEvent event,
    List<MediaBarSlideItem> items,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_currentIndex > 0) _goToPage(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (_currentIndex < items.length - 1) _goToPage(_currentIndex + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      _navigateToItem(context, items);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _navigateToItem(BuildContext context, List<MediaBarSlideItem> items) {
    final item = items.elementAtOrNull(_currentIndex);
    if (item != null) {
      context.push(Destinations.item(item.itemId, serverId: item.serverId));
    }
  }

  Widget _buildLogoWithShadow(String url) {
    Widget image() => CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      fadeInDuration: Duration.zero,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 2,
          bottom: -2,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.4),
                BlendMode.srcATop,
              ),
              child: image(),
            ),
          ),
        ),
        image(),
      ],
    );
  }
}

class _BackdropLayer extends StatelessWidget {
  final List<MediaBarSlideItem> items;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _BackdropLayer({
    required this.items,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.backdropUrl == null) {
          return const ColoredBox(color: Colors.black);
        }
        return CachedNetworkImage(
          imageUrl: item.backdropUrl!,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
          errorWidget: (_, __, ___) =>
              const ColoredBox(color: Colors.black),
        );
      },
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  final Color color;
  final double opacity;

  const _GradientOverlay({required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: opacity * 0.3),
              color.withValues(alpha: opacity * 0.1),
              color.withValues(alpha: opacity * 0.8),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          customBorder: const CircleBorder(),
          child: AnimatedOpacity(
            opacity: onTap != null ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideInfo extends StatelessWidget {
  final MediaBarSlideItem item;
  final Map<String, double> ratings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;

  const _SlideInfo({
    required this.item,
    required this.ratings,
    required this.enableAdditionalRatings,
    required this.enabledRatings,
    required this.blockedRatings,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = PlatformDetection.useMobileUi;

    return Padding(
      padding: EdgeInsets.only(left: 8, right: 8, bottom: isMobile ? 24 : 36),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MetadataRow(item: item),
                if (ratings.isNotEmpty || item.communityRating != null) ...[
                  const SizedBox(height: 6),
                  RatingsRow(
                    ratings: ratings,
                    communityRating: item.communityRating,
                    criticRating: item.criticRating,
                    enableAdditionalRatings: enableAdditionalRatings,
                    enabledRatings: enabledRatings,
                    blockedRatings: blockedRatings,
                    showLabels: showLabels,
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: ((isMobile
                          ? theme.textTheme.bodySmall?.fontSize
                          : theme.textTheme.bodyMedium?.fontSize) ??
                      14) *
                      1.4 *
                      (isMobile ? 2 : 3),
                  child: Text(
                    item.overview ?? '',
                    style: (isMobile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      shadows: _textShadows,
                    ),
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
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

class _MetadataRow extends StatelessWidget {
  final MediaBarSlideItem item;

  const _MetadataRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <Widget>[];

    if (item.year != null) {
      parts.add(_infoText(theme, item.year.toString()));
    }

    if (item.officialRating != null) {
      parts.add(_ratingBadge(theme, item.officialRating!));
    }

    if (item.itemType != 'Series' && item.runtime != null) {
      final h = item.runtime!.inHours;
      final m = item.runtime!.inMinutes.remainder(60);
      parts.add(_infoText(theme, h > 0 ? '${h}h ${m}m' : '${m}m'));
    }

    if (item.genres.isNotEmpty) {
      parts.add(_infoText(theme, item.genres.join(' \u2022 ')));
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    final separated = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      separated.add(parts[i]);
      if (i < parts.length - 1) {
        separated.add(Text(
          ' \u2022 ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            shadows: _textShadows,
          ),
        ));
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: separated,
    );
  }

  Widget _infoText(ThemeData theme, String value) {
    return Text(
      value,
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        fontWeight: FontWeight.w600,
        shadows: _textShadows,
      ),
    );
  }

  Widget _ratingBadge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          shadows: _textShadows,
        ),
      ),
    );
  }
}

class _IndicatorDots extends StatelessWidget {
  final int count;
  final int current;
  final Color overlayColor;
  final double overlayOpacity;

  const _IndicatorDots({
    required this.count,
    required this.current,
    required this.overlayColor,
    required this.overlayOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: overlayColor.withValues(alpha: overlayOpacity * 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) {
            final isActive = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 10 : 8,
              height: isActive ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            );
          }),
        ),
      ),
    );
  }
}
