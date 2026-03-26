import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/services/rating_icon_provider.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];
const _coreRatingSources = {'tomatoes', 'stars'};

class RatingsRow extends StatelessWidget {
  final Map<String, double> ratings;
  final double? communityRating;
  final int? criticRating;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;

  const RatingsRow({
    super.key,
    required this.ratings,
    this.communityRating,
    this.criticRating,
    this.enableAdditionalRatings = false,
    this.enabledRatings = 'tomatoes,stars',
    this.blockedRatings = '',
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = enabledRatings
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final blocked = blockedRatings
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final allRatings = <String, double>{};

    if (communityRating != null) {
      allRatings['stars'] = communityRating!;
    }

    for (final entry in ratings.entries) {
      if (entry.key == 'tomatoes' && criticRating != null) continue;
      allRatings[entry.key] = entry.value;
    }

    if (!allRatings.containsKey('tomatoes') && criticRating != null) {
      allRatings['tomatoes'] = criticRating!.toDouble();
    }

    if (allRatings.isEmpty) return const SizedBox.shrink();

    final filtered = allRatings.entries.where((e) {
      if (blocked.contains(e.key)) return false;
      if (!enabled.contains(e.key)) return false;
      if (!enableAdditionalRatings && !_coreRatingSources.contains(e.key)) {
        return false;
      }
      return true;
    }).toList();

    final enabledList = enabledRatings
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final enabledOrder = {
      for (var i = 0; i < enabledList.length; i++) enabledList[i]: i,
    };
    filtered.sort((a, b) {
      final ai = enabledOrder[a.key] ?? 999;
      final bi = enabledOrder[b.key] ?? 999;
      return ai.compareTo(bi);
    });

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final item in filtered)
          _SingleRating(
            source: item.key,
            value: item.value,
            showLabel: showLabels,
          ),
      ],
    );
  }
}

class _SingleRating extends StatelessWidget {
  final String source;
  final double value;
  final bool showLabel;

  const _SingleRating({
    required this.source,
    required this.value,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLargeLayout = media.size.width >= 1000 ||
        (media.orientation == Orientation.landscape && media.size.width >= 700);
    final valueText = RatingIconProvider.formatRating(source, value);
    final labelText = RatingIconProvider.sourceDisplayName(source);
    final valueFontSize = isLargeLayout ? 16.0 : 13.0;
    final labelFontSize = isLargeLayout ? 9.0 : 8.0;
    final iconHeight = isLargeLayout ? 18.0 : 15.0;
    final starSize = isLargeLayout ? 16.0 : 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeLayout ? 8 : 6,
            vertical: isLargeLayout ? 4 : 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (source == 'stars') ...[
                    Text(
                      '\u2605',
                      style: TextStyle(
                        color: const Color(0xFFFFC107),
                        fontSize: starSize,
                        height: 1,
                        shadows: _textShadows,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    _RatingIcon(source: source, value: value, height: iconHeight),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    valueText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      shadows: _textShadows,
                    ),
                  ),
                ],
              ),
              if (showLabel)
                Text(
                  labelText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    shadows: _textShadows,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingIcon extends StatelessWidget {
  final String source;
  final double value;
  final double height;

  const _RatingIcon({
    required this.source,
    required this.value,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = RatingIconProvider.getIconAssetPath(
      source,
      value.toInt(),
    );

    if (assetPath == null) return const SizedBox.shrink();

    return Image.asset(
      assetPath,
      height: height,
      filterQuality: FilterQuality.medium,
    );
  }
}
