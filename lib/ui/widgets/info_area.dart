import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/repositories/mdblist_repository.dart';
import '../../preference/user_preferences.dart';
import '../../util/platform_detection.dart';
import 'rating_display.dart';
import 'simple_info_row.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class InfoArea extends StatelessWidget {
  final AggregatedItem? item;

  const InfoArea({super.key, this.item});

  static double fixedHeight({required bool isMobile}) {
    return isMobile ? 168.0 : 192.0;
  }

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    final isMobile = PlatformDetection.useMobileUi;
    final fixedHeight = InfoArea.fixedHeight(isMobile: isMobile);

    if (item == null) {
      return SizedBox(width: double.infinity, height: fixedHeight);
    }

    return SizedBox(
      width: double.infinity,
      height: fixedHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _InfoAreaContent(key: ValueKey(item.id), item: item),
      ),
    );
  }
}

class _InfoAreaContent extends StatefulWidget {
  final AggregatedItem item;

  const _InfoAreaContent({super.key, required this.item});

  @override
  State<_InfoAreaContent> createState() => _InfoAreaContentState();
}

class _InfoAreaContentState extends State<_InfoAreaContent> {
  final _prefs = GetIt.instance<UserPreferences>();
  Map<String, double> _ratings = const {};

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);
    _loadRatings();
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRatings() async {
    if (!_prefs.get(UserPreferences.enableAdditionalRatings)) return;

    final tmdbId = widget.item.tmdbId;
    if (tmdbId == null) return;

    final result = await GetIt.instance<MdbListRepository>().getRatings(
      tmdbId: tmdbId,
      mediaType: widget.item.type ?? 'Movie',
    );
    if (mounted && result != null && result.isNotEmpty) {
      setState(() => _ratings = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final isMobile = PlatformDetection.useMobileUi;

    final showRatings = _ratings.isNotEmpty ||
        item.communityRating != null ||
        item.criticRating != null;

    final title = item.type == 'Episode'
        ? [item.seriesName, item.name]
            .where((s) => s != null && s.isNotEmpty)
            .join(' - ')
        : item.displayTitle;

    final overviewStyle = (isMobile
            ? theme.textTheme.bodySmall
            : theme.textTheme.bodyMedium)
        ?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
      shadows: _textShadows,
    );
    final titleStyle = (isMobile
            ? theme.textTheme.titleLarge
            : theme.textTheme.headlineSmall)
        ?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: _textShadows,
    );
    final infoRowHeight = isMobile ? 22.0 : 24.0;
    final spacing = isMobile ? 6.0 : 8.0;
    final overviewTopSpacing = showRatings ? (isMobile ? 12.0 : 14.0) : spacing;
    final titleToMetaSpacing = isMobile ? 4.0 : 6.0;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            title,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: titleToMetaSpacing),
          SizedBox(
            height: infoRowHeight,
            child: ClipRect(
              child: SimpleInfoRow(item: item, showRating: !showRatings),
            ),
          ),
          SizedBox(height: spacing),
          if (showRatings)
            RatingsRow(
              ratings: _ratings,
              communityRating: item.communityRating,
              criticRating: item.criticRating,
              enableAdditionalRatings:
                  _prefs.get(UserPreferences.enableAdditionalRatings),
              enabledRatings: _prefs.get(UserPreferences.enabledRatings),
              showLabels: _prefs.get(UserPreferences.showRatingLabels),
              showBadges: _prefs.get(UserPreferences.showRatingBadges),
            ),
          SizedBox(height: overviewTopSpacing),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                item.overview ?? '',
                style: overviewStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
