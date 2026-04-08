import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/admin_media_analytics_provider.dart';

const _dashboardMetricKeys = <String>[
  'movies',
  'series',
  'episodes',
  'albums',
  'songs',
  'books',
  'collections',
];

class AdminMediaSummarySection extends StatelessWidget {
  final AdminMediaCountSummary summary;
  final String title;
  final String? subtitle;
  final List<String> metricKeys;
  final VoidCallback? onOpenAnalytics;

  const AdminMediaSummarySection({
    super.key,
    required this.summary,
    this.title = 'Media Overview',
    this.subtitle,
    this.metricKeys = _dashboardMetricKeys,
    this.onOpenAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      if ((subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onOpenAnalytics != null)
                  FilledButton.tonalIcon(
                    onPressed: onOpenAnalytics,
                    icon: const Icon(Icons.insights_outlined),
                    label: Text(l10n.analytics),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                const spacing = 12.0;
                final columns = maxWidth >= 900
                    ? 4
                    : maxWidth >= 640
                        ? 3
                        : maxWidth >= 420
                            ? 2
                            : 1;
                final tileWidth = (maxWidth - ((columns - 1) * spacing)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final metric in adminMediaMetrics.where(
                      (metric) => metricKeys.contains(metric.key),
                    ))
                      SizedBox(
                        width: tileWidth,
                        child: _AdminMediaMetricTile(
                          metric: metric,
                          value: summary.countFor(metric.key),
                          onTap: onOpenAnalytics,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMediaMetricTile extends StatelessWidget {
  final AdminMediaMetricDefinition metric;
  final int value;
  final VoidCallback? onTap;

  const _AdminMediaMetricTile({
    required this.metric,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatAdminCount(value),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            _iconForMetric(metric.key),
            size: 28,
            color: theme.colorScheme.onSurface,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

IconData adminMediaIconForKey(String key) => _iconForMetric(key);

String formatAdminCount(int value) {
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    if (index > 0 && (text.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[index]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}

IconData _iconForMetric(String key) {
  switch (key) {
    case 'movies':
      return Icons.movie_creation_outlined;
    case 'series':
      return Icons.tv_outlined;
    case 'episodes':
      return Icons.live_tv_outlined;
    case 'albums':
      return Icons.album_outlined;
    case 'songs':
      return Icons.music_note_outlined;
    case 'books':
      return Icons.menu_book_outlined;
    case 'audiobooks':
      return Icons.headphones_outlined;
    case 'collections':
      return Icons.collections_bookmark_outlined;
    case 'musicVideos':
      return Icons.music_video_outlined;
    case 'photos':
      return Icons.photo_library_outlined;
    case 'videos':
      return Icons.video_library_outlined;
    default:
      return Icons.perm_media_outlined;
  }
}