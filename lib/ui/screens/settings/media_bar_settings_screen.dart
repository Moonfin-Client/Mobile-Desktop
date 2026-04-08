import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
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
        title: l10n.sourceLibraries,
        items: {
          for (final item in items)
            item['Id'] as String: item['Name'] as String? ?? l10n.unknown,
        },
        selected: selected,
      );
      if (result != null) {
        _saveCsv(UserPreferences.mediaBarLibraryIds, result.toList());
      }
    } catch (_) {}
  }

  Future<void> _showCollectionSelector() async {
    final l10n = AppLocalizations.of(context);
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
        title: l10n.sourceCollections,
        items: {
          for (final item in items)
            item['Id'] as String: item['Name'] as String? ?? l10n.unknown,
        },
        selected: selected,
      );
      if (result != null) {
        _saveCsv(UserPreferences.mediaBarCollectionIds, result.toList());
      }
    } catch (_) {}
  }

  Future<void> _showGenreSelector() async {
    final l10n = AppLocalizations.of(context);
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
        title: l10n.excludedGenres,
        items: {
          for (final item in items)
            item['Name'] as String: item['Name'] as String? ?? l10n.unknown,
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
    final l10n = AppLocalizations.of(context);
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
                      child: Text(l10n.selectAll),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() => working.clear());
                      },
                      child: Text(l10n.clear),
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
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, working),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceSubtitle(Preference<String> pref, String noneLabel, AppLocalizations l10n) {
    final items = _splitCsv(pref);
    if (items.isEmpty) return noneLabel;
    return l10n.itemsSelected(items.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mediaBar)),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarEnabled,
            title: l10n.enableMediaBar,
            subtitle: l10n.showFeaturedContentSlideshow,
            icon: Icons.featured_play_list,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarContentType,
            title: l10n.contentType,
            icon: Icons.category,
            options: {
              'both': l10n.moviesAndTvShows,
              'movies': l10n.moviesOnly,
              'tvshows': l10n.tvShowsOnly,
            },
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarItemCount,
            title: l10n.itemCount,
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
            title: Text(l10n.sourceLibraries),
            subtitle: Text(
              _sourceSubtitle(
                  UserPreferences.mediaBarLibraryIds, l10n.allLibraries, l10n),
            ),
            onTap: _showLibrarySelector,
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark),
            title: Text(l10n.sourceCollections),
            subtitle: Text(
              _sourceSubtitle(
                  UserPreferences.mediaBarCollectionIds, l10n.noneSelected, l10n),
            ),
            onTap: _showCollectionSelector,
          ),
          ListTile(
            leading: const Icon(Icons.label_off),
            title: Text(l10n.excludedGenres),
            subtitle: Text(
              _sourceSubtitle(
                  UserPreferences.mediaBarExcludedGenres, l10n.noneExcluded, l10n),
            ),
            onTap: _showGenreSelector,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarAutoAdvance,
            title: l10n.autoAdvance,
            subtitle: l10n.autoAdvanceSlides,
            icon: Icons.skip_next,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.mediaBarIntervalMs,
            title: l10n.autoAdvanceInterval,
            icon: Icons.timer,
            min: 3000,
            max: 15000,
            divisions: 12,
            labelOf: (v) => l10n.secondsValue((v / 1000).round()),
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarTrailerPreview,
            title: l10n.trailerPreview,
            subtitle: l10n.autoPlayTrailers,
            icon: Icons.movie_outlined,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.episodePreviewEnabled,
            title: l10n.episodePreview,
            subtitle: l10n.episodePreviewDescription,
            icon: Icons.ondemand_video,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.previewAudioEnabled,
            title: l10n.previewAudio,
            subtitle: l10n.enablePreviewAudio,
            icon: Icons.volume_up,
          ),
        ],
      ),
    );
  }
}
