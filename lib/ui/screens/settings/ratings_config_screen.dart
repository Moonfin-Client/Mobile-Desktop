import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

const _allSources = [
  'tomatoes',
  'tomatoes_audience',
  'imdb',
  'tmdb',
  'metacritic',
  'metacriticuser',
  'trakt',
  'letterboxd',
  'myanimelist',
  'anilist',
  'stars',
];

class _RatingItem {
  final String key;
  bool enabled;

  _RatingItem({required this.key, required this.enabled});
}

class RatingsConfigScreen extends StatefulWidget {
  const RatingsConfigScreen({super.key});

  @override
  State<RatingsConfigScreen> createState() => _RatingsConfigScreenState();
}

class _RatingsConfigScreenState extends State<RatingsConfigScreen> {
  String _sourceLabel(String key, AppLocalizations l10n) => switch (key) {
    'tomatoes' => l10n.rottenTomatoesCritics,
    'tomatoes_audience' => l10n.rottenTomatoesAudience,
    'imdb' => l10n.imdb,
    'tmdb' => l10n.tmdb,
    'metacritic' => l10n.metacritic,
    'metacriticuser' => l10n.metacriticUser,
    'trakt' => l10n.trakt,
    'letterboxd' => l10n.letterboxd,
    'myanimelist' => l10n.myAnimeList,
    'anilist' => l10n.aniList,
    'stars' => l10n.communityRating,
    _ => key,
  };

  final _store = GetIt.instance<PreferenceStore>();
  final _prefs = GetIt.instance<UserPreferences>();
  String _lastEnabledRatingsCsv = '';
  late List<_RatingItem> _items;

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
    _prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    final currentCsv = _store.get(UserPreferences.enabledRatings);
    if (currentCsv == _lastEnabledRatingsCsv) return;
    setState(_loadFromPrefs);
  }

  void _loadFromPrefs() {
    final csv = _store.get(UserPreferences.enabledRatings);
    _lastEnabledRatingsCsv = csv;
    final enabled = csv
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();

    final items = <_RatingItem>[];
    for (final key in enabled) {
      if (_allSources.contains(key)) {
        items.add(_RatingItem(key: key, enabled: true));
      }
    }
    final addedKeys = items.map((i) => i.key).toSet();
    for (final key in _allSources) {
      if (!addedKeys.contains(key)) {
        items.add(_RatingItem(key: key, enabled: false));
      }
    }
    _items = items;
  }

  void _save() {
    final csv = _items
        .where((i) => i.enabled)
        .map((i) => i.key)
        .join(',');
    _store.set(UserPreferences.enabledRatings, csv);

    final syncService = GetIt.instance<PluginSyncService>();
    if (syncService.pluginAvailable) {
      final client = GetIt.instance<MediaServerClient>();
      syncService.pushSettings(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ratings),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: l10n.resetToDefaults,
            onPressed: () {
              setState(() {
                _store.set(
                    UserPreferences.enabledRatings,
                    UserPreferences.enabledRatings.defaultValue);
                _loadFromPrefs();
              });
              _save();
            },
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        header: Column(
          children: [
            SwitchPreferenceTile(
              preference: UserPreferences.enableAdditionalRatings,
              title: l10n.additionalRatings,
              subtitle: l10n.showMdbListAndTmdbRatings,
              icon: Icons.star,
              onChanged: _save,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.showRatingLabels,
              title: l10n.ratingLabels,
              subtitle: l10n.showLabelsNextToIcons,
              icon: Icons.label,
              onChanged: _save,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.showRatingBadges,
              title: l10n.ratingBadges,
              subtitle: l10n.showDecorativeBadges,
              icon: Icons.style,
              onChanged: _save,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.enableEpisodeRatings,
              title: l10n.episodeRatings,
              subtitle: l10n.showRatingsOnEpisodes,
              icon: Icons.stars,
              onChanged: _save,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.reorder),
              title: Text(l10n.ratingSources),
              subtitle: Text(l10n.ratingSourcesDescription),
            ),
          ],
        ),
        itemCount: _items.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
          _save();
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            key: ValueKey(item.key),
            leading: Checkbox(
              value: item.enabled,
              onChanged: (enabled) {
                setState(() => item.enabled = enabled ?? false);
                _save();
              },
            ),
            title: Text(_sourceLabel(item.key, l10n)),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          );
        },
      ),
    );
  }
}
