import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/repositories/mdblist_repository.dart';
import '../../preference/user_preferences.dart';
import 'logo_view.dart';
import 'rating_display.dart';
import 'simple_info_row.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class InfoArea extends StatelessWidget {
  final AggregatedItem? item;

  const InfoArea({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _InfoAreaContent(key: ValueKey(item.id), item: item),
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
  Map<String, double> _ratings = const {};

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final prefs = GetIt.instance<UserPreferences>();
    if (!prefs.get(UserPreferences.enableAdditionalRatings)) return;

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
    final hasLogo = item.logoImageTag != null;
    final prefs = GetIt.instance<UserPreferences>();

    final showRatings = _ratings.isNotEmpty ||
        item.communityRating != null ||
        item.criticRating != null;

    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasLogo)
            LogoView(
              imageUrl: _logoUrl,
              maxHeight: 100,
              maxWidth: 400,
            )
          else
            Text(
              item.displayTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: _textShadows,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          SimpleInfoRow(item: item, showRating: !showRatings),
          if (showRatings) ...[
            const SizedBox(height: 8),
            RatingsRow(
              ratings: _ratings,
              communityRating: item.communityRating,
              criticRating: item.criticRating,
              enableAdditionalRatings:
                  prefs.get(UserPreferences.enableAdditionalRatings),
              enabledRatings: prefs.get(UserPreferences.enabledRatings),
              blockedRatings: prefs.get(UserPreferences.blockedRatings),
              showLabels: prefs.get(UserPreferences.showRatingLabels),
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
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String? get _logoUrl {
    final tag = widget.item.logoImageTag;
    if (tag == null) return null;
    final client = GetIt.instance<MediaServerClient>();
    return client.imageApi.getLogoImageUrl(widget.item.id, maxWidth: 400, tag: tag);
  }
}
