import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../data/models/aggregated_item.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class SimpleInfoRow extends StatelessWidget {
  final AggregatedItem item;
  final bool showRating;

  const SimpleInfoRow({super.key, required this.item, this.showRating = true});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (item.productionYear != null) {
      children.add(_text(context, item.productionYear.toString()));
    }

    if (item.type == 'Episode') {
      final s = item.parentIndexNumber;
      final e = item.indexNumber;
      if (s != null && e != null) {
        children.add(_text(context, 'S$s:E$e'));
      }
    }

    if (item.officialRating != null) {
      children.add(_badge(context, item.officialRating!));
    }

    final runtime = item.runtime;
    if (runtime != null) {
      final hours = runtime.inHours;
      final minutes = runtime.inMinutes.remainder(60);
      final label = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      children.add(_text(context, label));
    }

    final resolution = item.videoResolution;
    if (resolution != null) {
      children.add(_badge(context, resolution));
    }

    if (showRating && item.communityRating != null) {
      children.add(_ratingChip(context, item.communityRating!));
    }

    final genres = item.genres;
    if (genres.isNotEmpty) {
      children.add(_text(context, genres.take(3).join(', ')));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) {
        separated.add(_dot(context));
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: separated,
    );
  }

  Widget _text(BuildContext context, String value) {
    return Text(
      value,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            shadows: _textShadows,
          ),
    );
  }

  Widget _dot(BuildContext context) {
    return Text(
      ' \u2022 ',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            shadows: _textShadows,
          ),
    );
  }

  Widget _badge(BuildContext context, String label) {
    final borders = ThemeRegistry.active.borders;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: borders.chipBackground,
        border: Border.fromBorderSide(borders.chipBorder),
        borderRadius: borders.chipRadius,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColorScheme.onSurface.withValues(alpha: 0.8),
              shadows: _textShadows,
            ),
      ),
    );
  }

  Widget _ratingChip(BuildContext context, double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                shadows: _textShadows,
              ),
        ),
      ],
    );
  }
}
