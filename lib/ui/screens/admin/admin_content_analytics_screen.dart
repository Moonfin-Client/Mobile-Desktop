import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'libraries/admin_libraries_screen.dart';
import 'providers/admin_media_analytics_provider.dart';
import 'widgets/admin_media_summary_section.dart';

class AdminContentAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminContentAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminContentAnalyticsScreen> createState() =>
      _AdminContentAnalyticsScreenState();
}

class _AdminContentAnalyticsScreenState
    extends ConsumerState<AdminContentAnalyticsScreen> {
  String _selectedTabKey = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final analyticsAsync = ref.watch(adminMediaAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to Load Media Analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('$error', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(adminMediaAnalyticsProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (analytics) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminMediaSummaryProvider);
          ref.invalidate(adminMediaAnalyticsProvider);
          await ref.read(adminMediaAnalyticsProvider.future);
        },
        child: _buildBody(context, analytics),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminMediaAnalyticsDetail analytics) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isMobileLayout = mediaQuery.size.width < 700;
    final bottomInset = isMobileLayout
      ? mediaQuery.padding.bottom + 28
      : mediaQuery.padding.bottom + 8;

    final libraries = analytics.libraries
        .where((library) => !_isExcludedLibraryType(library.collectionType))
        .toList();

    final tabs = <_LibraryTabItem>[
      _LibraryTabItem(
        key: 'all',
        title: l10n.all,
        collectionType: null,
      ),
      ...libraries.map(
        (library) => _LibraryTabItem(
          key: library.itemId,
          title: library.name,
          collectionType: library.collectionType,
        ),
      ),
    ];

    final activeTabKey = tabs.any((tab) => tab.key == _selectedTabKey)
        ? _selectedTabKey
        : 'all';

    if (activeTabKey != _selectedTabKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _selectedTabKey = activeTabKey);
      });
    }

    final selectedLibrary = activeTabKey == 'all'
        ? null
        : libraries.where((library) => library.itemId == activeTabKey).firstOrNull;

    final scopedSummary = selectedLibrary == null
        ? _sumLibraries(libraries)
        : AdminMediaCountSummary(totals: selectedLibrary.counts);
    final scopedMetrics = _metricsForCollectionType(
      selectedLibrary?.collectionType,
      scopedSummary,
    );
    final scopedVisibleTotal = scopedMetrics.fold<int>(
      0,
      (sum, metric) => sum + scopedSummary.countFor(metric.key),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      children: [
        _LibraryTabGrid(
          tabs: tabs,
          selectedKey: activeTabKey,
          onSelected: (value) => setState(() => _selectedTabKey = value),
        ),
        const SizedBox(height: 16),
        _ScopeHeaderCard(
          title: selectedLibrary?.name ?? l10n.allLibraries,
          subtitle: selectedLibrary == null
              ? 'Combined Analytics Across All Media Libraries.'
              : AdminLibrariesScreen.labelForType(selectedLibrary.collectionType),
          totalTrackedItems: scopedVisibleTotal,
          libraryCount: selectedLibrary == null ? libraries.length : 1,
          icon: selectedLibrary == null
              ? Icons.dashboard_customize_outlined
              : AdminLibrariesScreen.iconForType(selectedLibrary.collectionType),
        ),
        const SizedBox(height: 16),
        _MetricDistributionCard(
          title: l10n.analyticsMediaDistribution,
          summary: scopedSummary,
          metrics: scopedMetrics,
        ),
        const SizedBox(height: 16),
        if (selectedLibrary != null) ..._buildLibraryInsightCards(selectedLibrary, l10n),
        if (selectedLibrary == null) ...[
          _TokenDistributionCard(
            title: l10n.analyticsVideoCodecs,
            values: analytics.technicalProfile.videoCodecs,
          ),
          const SizedBox(height: 16),
          _TokenDistributionCard(
            title: l10n.analyticsAudioCodecs,
            values: analytics.technicalProfile.audioCodecs,
          ),
          const SizedBox(height: 16),
          _TokenDistributionCard(
            title: l10n.analyticsContainers,
            values: analytics.technicalProfile.containers,
          ),
          const SizedBox(height: 16),
        ],
        if (selectedLibrary == null)
          _LibraryBreakdownCard(
            libraries: libraries,
          ),
      ],
    );
  }

  List<Widget> _buildLibraryInsightCards(AdminLibraryMediaAnalytics library, AppLocalizations l10n) {
    final type = (library.collectionType ?? '').toLowerCase();
    final insights = library.insights;
    if (!insights.hasData) {
      return const [];
    }

    final cards = <Widget>[];

    if (insights.genres.isNotEmpty) {
      cards.add(
        _TokenDistributionCard(
          title: l10n.analyticsTopGenres,
          values: insights.genres,
          formatLabels: false,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    if (insights.contributors.isNotEmpty) {
      final title = switch (type) {
        'music' => 'Top Artists',
        'books' => 'Top Authors',
        _ => 'Top Contributors',
      };
      cards.add(
        _TokenDistributionCard(
          title: title,
          values: insights.contributors,
          formatLabels: false,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    if (insights.years.isNotEmpty) {
      cards.add(
        _TokenDistributionCard(
          title: l10n.analyticsReleaseYears,
          values: insights.years,
          formatLabels: false,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    if ((type == 'movies' || type == 'tvshows') && insights.ratings.isNotEmpty) {
      cards.add(
        _TokenDistributionCard(
          title: l10n.analyticsContentRatings,
          values: insights.ratings,
          formatLabels: false,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    if ((type == 'movies' || type == 'tvshows') &&
        insights.runtimeBuckets.isNotEmpty) {
      cards.add(
        _TokenDistributionCard(
          title: l10n.analyticsRuntimeBuckets,
          values: insights.runtimeBuckets,
          formatLabels: false,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    if ((type == 'movies' ||
            type == 'tvshows' ||
            type == 'music' ||
            type == 'books') &&
        insights.containers.isNotEmpty) {
      cards.add(
        _TokenDistributionCard(
          title: l10n.analyticsFileFormats,
          values: insights.containers,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    if ((type == 'movies' ||
            type == 'tvshows' ||
            type == 'music' ||
            type == 'books') &&
        insights.videoCodecs.isNotEmpty) {
      cards.add(
        _TokenDistributionCard(
          title: l10n.analyticsVideoCodecs,
          values: insights.videoCodecs,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    if ((type == 'movies' ||
            type == 'tvshows' ||
            type == 'music' ||
            type == 'books') &&
        insights.audioCodecs.isNotEmpty) {
      cards.add(
        _TokenDistributionCard(
          title: l10n.analyticsAudioCodecs,
          values: insights.audioCodecs,
        ),
      );
      cards.add(const SizedBox(height: 16));
    }

    return cards;
  }

  AdminMediaCountSummary _sumLibraries(List<AdminLibraryMediaAnalytics> libraries) {
    final totals = <String, int>{
      for (final metric in adminMediaMetrics) metric.key: 0,
    };

    for (final library in libraries) {
      for (final metric in adminMediaMetrics) {
        totals[metric.key] =
            (totals[metric.key] ?? 0) + library.countFor(metric.key);
      }
    }

    return AdminMediaCountSummary(totals: totals);
  }
}

class _LibraryTabItem {
  final String key;
  final String title;
  final String? collectionType;

  const _LibraryTabItem({
    required this.key,
    required this.title,
    required this.collectionType,
  });
}

class _LibraryTabGrid extends StatelessWidget {
  final List<_LibraryTabItem> tabs;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const _LibraryTabGrid({
    required this.tabs,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            const spacing = 8.0;
            final columns = maxWidth >= 1200
                ? 6
                : maxWidth >= 900
                    ? 5
                    : maxWidth >= 700
                        ? 4
                        : maxWidth >= 520
                            ? 3
                            : 2;
            final tileWidth = (maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final tab in tabs)
                  SizedBox(
                    width: tileWidth,
                    child: _LibraryTabBox(
                      item: tab,
                      selected: selectedKey == tab.key,
                      onTap: () => onSelected(tab.key),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LibraryTabBox extends StatelessWidget {
  final _LibraryTabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _LibraryTabBox({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.collectionType == null
                    ? Icons.dashboard_outlined
                    : AdminLibrariesScreen.iconForType(item.collectionType),
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int totalTrackedItems;
  final int libraryCount;
  final IconData icon;

  const _ScopeHeaderCard({
    required this.title,
    required this.subtitle,
    required this.totalTrackedItems,
    required this.libraryCount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 22, child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatAdminCount(totalTrackedItems),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  libraryCount == 1 ? '1 Library' : '$libraryCount Libraries',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricDistributionCard extends StatelessWidget {
  final String title;
  final AdminMediaCountSummary summary;
  final List<AdminMediaMetricDefinition> metrics;

  const _MetricDistributionCard({
    required this.title,
    required this.summary,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nonZeroMetrics = metrics
        .where((metric) => summary.countFor(metric.key) > 0)
        .toList();
    final total = nonZeroMetrics.fold<int>(
      0,
      (sum, metric) => sum + summary.countFor(metric.key),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (nonZeroMetrics.isEmpty)
              Text(
                'No Indexed Media Totals Are Available for This Selection Yet.',
                style: theme.textTheme.bodyMedium,
              )
            else
              for (final metric in nonZeroMetrics) ...[
                _DistributionRow(
                  label: metric.label,
                  icon: adminMediaIconForKey(metric.key),
                  value: summary.countFor(metric.key),
                  fraction:
                      total == 0 ? 0 : summary.countFor(metric.key) / total,
                ),
                if (metric != nonZeroMetrics.last) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _TokenDistributionCard extends StatelessWidget {
  final String title;
  final Map<String, int> values;
  final bool formatLabels;

  const _TokenDistributionCard({
    required this.title,
    required this.values,
    this.formatLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sorted = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(8).toList();
    final total = topEntries.fold<int>(0, (sum, entry) => sum + entry.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (topEntries.isEmpty)
              Text(l10n.analyticsNoData, style: theme.textTheme.bodyMedium)
            else
              for (final entry in topEntries) ...[
                _DistributionRow(
                  label: formatLabels ? _prettyToken(entry.key) : entry.key,
                  icon: Icons.bar_chart,
                  value: entry.value,
                  fraction: total == 0 ? 0 : entry.value / total,
                ),
                if (entry != topEntries.last) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final double fraction;

  const _DistributionRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text(
              formatAdminCount(value),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(fraction * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: fraction),
      ],
    );
  }
}

class _LibraryBreakdownCard extends StatelessWidget {
  final List<AdminLibraryMediaAnalytics> libraries;

  const _LibraryBreakdownCard({required this.libraries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              libraries.length == 1 ? 'Library Details' : 'Library Breakdown',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (libraries.isEmpty)
              Text(
                'No Libraries Are Available.',
                style: theme.textTheme.bodyMedium,
              )
            else
              for (final library in libraries) ...[
                _LibraryAnalyticsTile(library: library),
                if (library != libraries.last) const Divider(height: 24),
              ],
          ],
        ),
      ),
    );
  }
}

class _LibraryAnalyticsTile extends StatelessWidget {
  final AdminLibraryMediaAnalytics library;

  const _LibraryAnalyticsTile({required this.library});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = AdminMediaCountSummary(totals: library.counts);
    final visibleMetrics = _metricsForCollectionType(library.collectionType, summary);
    final visibleTotal = visibleMetrics.fold<int>(
      0,
      (sum, metric) => sum + summary.countFor(metric.key),
    );
    final nonZero = visibleMetrics
        .where((metric) => summary.countFor(metric.key) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Icon(
                AdminLibrariesScreen.iconForType(library.collectionType),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    library.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AdminLibrariesScreen.labelForType(library.collectionType),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatAdminCount(visibleTotal),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (nonZero.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in nonZero)
                Chip(
                  avatar: Icon(adminMediaIconForKey(metric.key), size: 16),
                  label: Text(
                    '${metric.label} ${formatAdminCount(library.countFor(metric.key))}',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

String _prettyToken(String token) {
  if (token.isEmpty) {
    return 'Unknown';
  }

  const known = <String, String>{
    'h264': 'H.264',
    'avc': 'AVC',
    'h265': 'H.265',
    'hevc': 'HEVC',
    'av1': 'AV1',
    'vp8': 'VP8',
    'vp9': 'VP9',
    'aac': 'AAC',
    'ac3': 'AC3',
    'eac3': 'EAC3',
    'dts': 'DTS',
    'truehd': 'TrueHD',
    'flac': 'FLAC',
    'mp3': 'MP3',
    'opus': 'Opus',
    'vorbis': 'Vorbis',
    'alac': 'ALAC',
    'pcm': 'PCM',
    'wav': 'WAV',
    'mkv': 'MKV',
    'webm': 'WebM',
    'mp4': 'MP4',
    'm4v': 'M4V',
    'mov': 'MOV',
    'avi': 'AVI',
    'ts': 'TS',
    'm2ts': 'M2TS',
    'mpegts': 'MPEG-TS',
    'asf': 'ASF',
    'wmv': 'WMV',
    'sdr': 'SDR',
    'hdr10': 'HDR10',
    'dv': 'Dolby Vision',
  };

  final normalized = token.trim().toLowerCase();
  final exact = known[normalized];
  if (exact != null) {
    return exact;
  }

  if (RegExp(r'^[a-z0-9]{2,5}$').hasMatch(normalized)) {
    return normalized.toUpperCase();
  }

  return token
      .split(RegExp(r'[_\- ]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

bool _isExcludedLibraryType(String? collectionType) {
  final normalized = (collectionType ?? '').toLowerCase();
  return normalized == 'livetv' ||
      normalized == 'live tv' ||
      normalized == 'boxsets' ||
      normalized == 'collections';
}

const _excludedMetricKeys = <String>{'collections'};

List<AdminMediaMetricDefinition> _metricsForCollectionType(
  String? collectionType,
  AdminMediaCountSummary summary,
) {
  List<String> keys;
  switch ((collectionType ?? '').toLowerCase()) {
    case 'movies':
      keys = const ['movies'];
    case 'tvshows':
      keys = const ['series', 'episodes'];
    case 'music':
      keys = const ['albums', 'songs'];
    case 'musicvideos':
      keys = const ['musicVideos'];
    case 'books':
      keys = const ['books', 'audiobooks'];
    case 'photos':
      keys = const ['photos'];
    case 'homevideos':
      keys = const ['videos'];
    default:
      keys = adminMediaMetrics
          .map((metric) => metric.key)
          .where((key) => !_excludedMetricKeys.contains(key))
          .toList();
  }

  return adminMediaMetrics
      .where((metric) => keys.contains(metric.key))
      .where((metric) => !_excludedMetricKeys.contains(metric.key))
      .where((metric) => summary.countFor(metric.key) > 0)
      .toList();
}
