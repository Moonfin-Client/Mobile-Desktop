import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/services/rating_icon_provider.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class RatingsRow extends StatelessWidget {
  final Map<String, double> ratings;
  final String baseUrl;
  final double? communityRating;
  final int? criticRating;
  final bool enableAdditionalRatings;

  const RatingsRow({
    super.key,
    required this.ratings,
    required this.baseUrl,
    this.communityRating,
    this.criticRating,
    this.enableAdditionalRatings = false,
  });

  @override
  Widget build(BuildContext context) {
    final allRatings = LinkedHashMap<String, double>();

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

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: allRatings.entries.where((e) {
        if (!enableAdditionalRatings && e.key != 'stars' && e.key != 'tomatoes') {
          return false;
        }
        return true;
      }).map((e) {
        return _SingleRating(
          source: e.key,
          value: e.value,
          baseUrl: baseUrl,
        );
      }).toList(),
    );
  }
}

class _SingleRating extends StatelessWidget {
  final String source;
  final double value;
  final String baseUrl;

  const _SingleRating({
    required this.source,
    required this.value,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = RatingIconProvider.formatRating(source, value);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (source == 'stars') ...[
          const Text(
            '\u2605',
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 16,
              shadows: _textShadows,
            ),
          ),
          const SizedBox(width: 4),
        ] else ...[
          _RatingIcon(source: source, value: value, baseUrl: baseUrl),
          const SizedBox(width: 6),
        ],
        Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            shadows: _textShadows,
          ),
        ),
      ],
    );
  }
}

class _RatingIcon extends StatelessWidget {
  final String source;
  final double value;
  final String baseUrl;

  const _RatingIcon({
    required this.source,
    required this.value,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final iconUrl = RatingIconProvider.getIconUrl(
      baseUrl,
      source,
      value.toInt(),
    );

    if (iconUrl == null) return const SizedBox.shrink();

    return SizedBox(
      width: 20,
      height: 20,
      child: SvgPicture.network(
        iconUrl,
        width: 20,
        height: 20,
        placeholderBuilder: (_) => const SizedBox.shrink(),
      ),
    );
  }
}
