import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/media_bar_slide_item.dart';
import '../../data/models/media_bar_state.dart';
import '../../data/viewmodels/media_bar_view_model.dart';
import '../../preference/user_preferences.dart';
import '../navigation/destinations.dart';
import 'logo_view.dart';
import 'rating_display.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class MediaBar extends StatefulWidget {
  final MediaBarViewModel viewModel;
  final UserPreferences prefs;

  const MediaBar({
    super.key,
    required this.viewModel,
    required this.prefs,
  });

  @override
  State<MediaBar> createState() => _MediaBarState();
}

class _MediaBarState extends State<MediaBar> with TickerProviderStateMixin {
  final _pageController = PageController();

  Timer? _autoAdvanceTimer;
  bool _isPaused = false;
  int _currentIndex = 0;

  late final AnimationController _kenBurnsController;
  late Animation<double> _scaleAnimation;
  late Animation<Alignment> _alignmentAnimation;

  static const _kenBurnsMinScale = 1.0;
  static const _kenBurnsMaxScale = 1.15;
  static const _kenBurnsDuration = Duration(seconds: 14);

  @override
  void initState() {
    super.initState();
    _kenBurnsController = AnimationController(
      vsync: this,
      duration: _kenBurnsDuration,
    );
    _buildKenBurnsAnimations();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _kenBurnsController.dispose();
    _pageController.dispose();
    widget.viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    final state = widget.viewModel.state;
    if (state is MediaBarReady && state.items.isNotEmpty) {
      _startAutoAdvance();
      _kenBurnsController.forward();
    }
  }

  void _buildKenBurnsAnimations() {
    _scaleAnimation = Tween<double>(
      begin: _kenBurnsMinScale,
      end: _kenBurnsMaxScale,
    ).animate(CurvedAnimation(
      parent: _kenBurnsController,
      curve: Curves.easeInOut,
    ));

    _alignmentAnimation = AlignmentTween(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _kenBurnsController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!widget.prefs.get(UserPreferences.mediaBarAutoAdvance)) return;
    final intervalMs = widget.prefs.get(UserPreferences.mediaBarIntervalMs);
    _autoAdvanceTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        if (_isPaused || !mounted) return;
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
    _kenBurnsController
      ..reset()
      ..forward();
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

  Color _overlayColor() {
    final colorName = widget.prefs.get(UserPreferences.mediaBarOverlayColor);
    return switch (colorName) {
      'black' => Colors.black,
      'dark_blue' => const Color(0xFF1A2332),
      'purple' => const Color(0xFF4A148C),
      'teal' => const Color(0xFF00695C),
      'navy' => const Color(0xFF0D1B2A),
      'charcoal' => const Color(0xFF36454F),
      'brown' => const Color(0xFF3E2723),
      'dark_red' => const Color(0xFF8B0000),
      'dark_green' => const Color(0xFF0B4F0F),
      'slate' => const Color(0xFF475569),
      'indigo' => const Color(0xFF1E3A8A),
      _ => Colors.grey,
    };
  }

  double _overlayOpacity() {
    return widget.prefs.get(UserPreferences.mediaBarOverlayOpacity) / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.viewModel.state;

    return switch (state) {
      MediaBarLoading() => const SizedBox(height: 300),
      MediaBarDisabled() => const SizedBox.shrink(),
      MediaBarError() => const SizedBox.shrink(),
      MediaBarReady(items: final items) => items.isEmpty
          ? const SizedBox.shrink()
          : _buildSlideshow(context, items),
    };
  }

  Widget _buildSlideshow(BuildContext context, List<MediaBarSlideItem> items) {
    final overlayColor = _overlayColor();
    final overlayOpacity = _overlayOpacity();

    return MouseRegion(
      onEnter: (_) => _setPaused(true),
      onExit: (_) => _setPaused(false),
      child: Focus(
        onFocusChange: (focused) => _setPaused(focused),
        onKeyEvent: (node, event) => _handleKeyEvent(event, items),
        child: GestureDetector(
          onTap: () => _navigateToItem(context, items),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BackdropLayer(
                  items: items,
                  pageController: _pageController,
                  onPageChanged: _onPageChanged,
                  kenBurnsController: _kenBurnsController,
                  scaleAnimation: _scaleAnimation,
                  alignmentAnimation: _alignmentAnimation,
                ),
                _GradientOverlay(
                  color: overlayColor,
                  opacity: overlayOpacity,
                ),
                _ContentOverlay(
                  items: items,
                  currentIndex: _currentIndex,
                  overlayColor: overlayColor,
                  overlayOpacity: overlayOpacity,
                  ratings: widget.viewModel.ratingsFor(
                    items.elementAtOrNull(_currentIndex)?.itemId ?? '',
                  ),
                  enableAdditionalRatings: widget.prefs.get(
                    UserPreferences.enableAdditionalRatings,
                  ),
                  enabledRatings: widget.prefs.get(UserPreferences.enabledRatings),
                  blockedRatings: widget.prefs.get(UserPreferences.blockedRatings),
                  showLabels: widget.prefs.get(UserPreferences.showRatingLabels),
                ),
                if (items.length > 1)
                  _IndicatorDots(
                    count: items.length,
                    current: _currentIndex,
                    overlayColor: overlayColor,
                    overlayOpacity: overlayOpacity,
                  ),
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
      context.go(Destinations.item(item.itemId));
    }
  }
}

class _BackdropLayer extends StatelessWidget {
  final List<MediaBarSlideItem> items;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final AnimationController kenBurnsController;
  final Animation<double> scaleAnimation;
  final Animation<Alignment> alignmentAnimation;

  const _BackdropLayer({
    required this.items,
    required this.pageController,
    required this.onPageChanged,
    required this.kenBurnsController,
    required this.scaleAnimation,
    required this.alignmentAnimation,
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
        return AnimatedBuilder(
          animation: kenBurnsController,
          builder: (context, child) {
            return ClipRect(
              child: Transform.scale(
                scale: scaleAnimation.value,
                alignment: alignmentAnimation.value,
                child: child,
              ),
            );
          },
          child: CachedNetworkImage(
            imageUrl: item.backdropUrl!,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
            errorWidget: (_, __, ___) =>
                const ColoredBox(color: Colors.black),
          ),
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

class _ContentOverlay extends StatelessWidget {
  final List<MediaBarSlideItem> items;
  final int currentIndex;
  final Color overlayColor;
  final double overlayOpacity;
  final Map<String, double> ratings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;

  const _ContentOverlay({
    required this.items,
    required this.currentIndex,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.ratings,
    required this.enableAdditionalRatings,
    required this.enabledRatings,
    required this.blockedRatings,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final item = items.elementAtOrNull(currentIndex);
    if (item == null) return const SizedBox.shrink();

    return Positioned(
      left: 48,
      right: 48,
      bottom: 40,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _SlideInfo(
          key: ValueKey(item.itemId),
          item: item,
          overlayColor: overlayColor,
          overlayOpacity: overlayOpacity,
          ratings: ratings,
          enableAdditionalRatings: enableAdditionalRatings,
          enabledRatings: enabledRatings,
          blockedRatings: blockedRatings,
          showLabels: showLabels,
        ),
      ),
    );
  }
}

class _SlideInfo extends StatelessWidget {
  final MediaBarSlideItem item;
  final Color overlayColor;
  final double overlayOpacity;
  final Map<String, double> ratings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;

  const _SlideInfo({
    super.key,
    required this.item,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.ratings,
    required this.enableAdditionalRatings,
    required this.enabledRatings,
    required this.blockedRatings,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: overlayColor.withValues(alpha: overlayOpacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.logoUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LogoView(
                imageUrl: item.logoUrl,
                maxHeight: 60,
                maxWidth: 250,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: _textShadows,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
          if (item.overview != null) ...[
            const SizedBox(height: 8),
            Text(
              item.overview!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                shadows: _textShadows,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Center(
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
      ),
    );
  }
}
