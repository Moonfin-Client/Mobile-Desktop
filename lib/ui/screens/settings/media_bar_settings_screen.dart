import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

class MediaBarSettingsScreen extends StatefulWidget {
  const MediaBarSettingsScreen({super.key});

  @override
  State<MediaBarSettingsScreen> createState() => _MediaBarSettingsScreenState();
}

class _MediaBarSettingsScreenState extends State<MediaBarSettingsScreen> {
  final _store = GetIt.instance<PreferenceStore>();

  List<String> _splitCsv(Preference<String> pref) {
    return _store
        .get(pref)
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _saveCsv(Preference<String> pref, List<String> values) {
    _store.set(pref, values.join(','));
    _pushSync();
    setState(() {});
  }

  void _pushSync() {
    final syncService = GetIt.instance<PluginSyncService>();
    if (syncService.pluginAvailable) {
      final client = GetIt.instance<MediaServerClient>();
      syncService.pushSettings(client);
    }
  }

  Future<void> _showLibrarySelector() async {
    final client = GetIt.instance<MediaServerClient>();
    final selected = _splitCsv(UserPreferences.mediaBarLibraryIds).toSet();

    try {
      final response = await client.userViewsApi.getUserViews();
      final items = (response['Items'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((item) {
        final type = item['CollectionType'] as String?;
        return type == 'movies' || type == 'tvshows' || type == null;
      }).toList();

      if (!mounted) return;
      final result = await _showMultiSelectDialog(
        title: 'Source Libraries',
        items: {
          for (final item in items)
            item['Id'] as String: item['Name'] as String? ?? 'Unknown',
        },
        selected: selected,
      );
      if (result != null) {
        _saveCsv(UserPreferences.mediaBarLibraryIds, result.toList());
      }
    } catch (_) {}
  }

  Future<void> _showCollectionSelector() async {
    final client = GetIt.instance<MediaServerClient>();
    final selected = _splitCsv(UserPreferences.mediaBarCollectionIds).toSet();

    try {
      final response = await client.itemsApi.getItems(
        includeItemTypes: ['BoxSet'],
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        recursive: true,
        limit: 200,
      );
      final items = (response['Items'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      final result = await _showMultiSelectDialog(
        title: 'Source Collections',
        items: {
          for (final item in items)
            item['Id'] as String: item['Name'] as String? ?? 'Unknown',
        },
        selected: selected,
      );
      if (result != null) {
        _saveCsv(UserPreferences.mediaBarCollectionIds, result.toList());
      }
    } catch (_) {}
  }

  Future<void> _showGenreSelector() async {
    final client = GetIt.instance<MediaServerClient>();
    final selected = _splitCsv(UserPreferences.mediaBarExcludedGenres).toSet();

    try {
      final response = await client.itemsApi.getGenres(
        sortBy: 'SortName',
        sortOrder: 'Ascending',
      );
      final items = (response['Items'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      final result = await _showMultiSelectDialog(
        title: 'Excluded Genres',
        items: {
          for (final item in items)
            item['Name'] as String: item['Name'] as String? ?? 'Unknown',
        },
        selected: selected,
      );
      if (result != null) {
        _saveCsv(UserPreferences.mediaBarExcludedGenres, result.toList());
      }
    } catch (_) {}
  }

  Future<Set<String>?> _showMultiSelectDialog({
    required String title,
    required Map<String, String> items,
    required Set<String> selected,
  }) {
    final working = Set<String>.from(selected);
    return showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() => working.addAll(items.keys));
                      },
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() => working.clear());
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: items.entries.map((e) {
                      return CheckboxListTile(
                        title: Text(e.value),
                        value: working.contains(e.key),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              working.add(e.key);
                            } else {
                              working.remove(e.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, working),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceSubtitle(Preference<String> pref, String noneLabel) {
    final items = _splitCsv(pref);
    if (items.isEmpty) return noneLabel;
    return '${items.length} selected';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Bar')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarEnabled,
            title: 'Enable Media Bar',
            subtitle: 'Show featured content slideshow on home',
            icon: Icons.featured_play_list,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarContentType,
            title: 'Content Type',
            icon: Icons.category,
            options: const {
              'both': 'Movies & TV Shows',
              'movies': 'Movies Only',
              'tvshows': 'TV Shows Only',
            },
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarItemCount,
            title: 'Item Count',
            icon: Icons.format_list_numbered,
            options: const {
              '5': '5',
              '10': '10',
              '15': '15',
              '20': '20',
            },
          ),
          const Divider(),
          ListTile(
            leading: Image.asset(
              'assets/icons/clapperboard.png',
              width: 24,
              height: 24,
              color: Colors.white,
              fit: BoxFit.contain,
            ),
            title: const Text('Source Libraries'),
            subtitle: Text(
              _sourceSubtitle(
                  UserPreferences.mediaBarLibraryIds, 'All libraries'),
            ),
            onTap: _showLibrarySelector,
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark),
            title: const Text('Source Collections'),
            subtitle: Text(
              _sourceSubtitle(
                  UserPreferences.mediaBarCollectionIds, 'None selected'),
            ),
            onTap: _showCollectionSelector,
          ),
          ListTile(
            leading: const Icon(Icons.label_off),
            title: const Text('Excluded Genres'),
            subtitle: Text(
              _sourceSubtitle(
                  UserPreferences.mediaBarExcludedGenres, 'None excluded'),
            ),
            onTap: _showGenreSelector,
          ),
          const Divider(),
          SliderPreferenceTile(
            preference: UserPreferences.mediaBarOverlayOpacity,
            title: 'Overlay Opacity',
            icon: Icons.opacity,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarOverlayColor,
            title: 'Overlay Color',
            icon: Icons.color_lens,
            options: const {
              'black': 'Black',
              'gray': 'Gray',
              'blue': 'Blue',
              'purple': 'Purple',
              'red': 'Red',
              'green': 'Green',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarAutoAdvance,
            title: 'Auto Advance',
            subtitle: 'Automatically advance to next slide',
            icon: Icons.skip_next,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.mediaBarIntervalMs,
            title: 'Auto Advance Interval',
            icon: Icons.timer,
            min: 3000,
            max: 15000,
            divisions: 12,
            labelOf: (v) => '${(v / 1000).toStringAsFixed(0)}s',
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.episodePreviewEnabled,
            title: 'Episode Preview',
            subtitle:
                'Play a 30-second inline preview on focused, hovered, or long-pressed cards',
            icon: Icons.ondemand_video,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.previewAudioEnabled,
            title: 'Preview Audio',
            subtitle: 'Enable audio for episode previews',
            icon: Icons.volume_up,
          ),
        ],
      ),
    );
  }
}
