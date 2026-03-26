import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

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

const _sourceLabels = {
  'tomatoes': 'Rotten Tomatoes (Critics)',
  'tomatoes_audience': 'Rotten Tomatoes (Audience)',
  'imdb': 'IMDb',
  'tmdb': 'TMDB',
  'metacritic': 'Metacritic',
  'metacriticuser': 'Metacritic (User)',
  'trakt': 'Trakt',
  'letterboxd': 'Letterboxd',
  'myanimelist': 'MyAnimeList',
  'anilist': 'AniList',
  'stars': 'Community Rating',
};

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
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
              title: 'Additional Ratings',
              subtitle: 'Show MDBList and TMDB ratings',
              icon: Icons.star,
              onChanged: _save,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.showRatingLabels,
              title: 'Rating Labels',
              subtitle: 'Show labels next to rating icons',
              icon: Icons.label,
              onChanged: _save,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.enableEpisodeRatings,
              title: 'Episode Ratings',
              subtitle: 'Show ratings on individual episodes',
              icon: Icons.stars,
              onChanged: _save,
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.reorder),
              title: Text('Rating Sources'),
              subtitle: Text('Enable and reorder the rating sources shown throughout the app'),
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
            title: Text(_sourceLabels[item.key] ?? item.key),
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
