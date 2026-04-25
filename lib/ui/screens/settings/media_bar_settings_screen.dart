import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/focus/dpad_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';
import 'settings_app_bar.dart';
import '../../widgets/focus/request_initial_focus.dart';

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

      final availableIds = items.map((i) => i['Id'] as String).toSet();
      final pruned = selected.intersection(availableIds);
      if (pruned.length != selected.length) {
        _saveCsv(UserPreferences.mediaBarLibraryIds, pruned.toList());
      }

      if (!mounted) return;
      final result = await _showMultiSelectDialog(
        title: l10n.sourceLibraries,
        items: {
          for (final item in items)
            item['Id'] as String: item['Name'] as String? ?? l10n.unknown,
        },
        selected: pruned,
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

      final availableIds = items.map((i) => i['Id'] as String).toSet();
      final pruned = selected.intersection(availableIds);
      if (pruned.length != selected.length) {
        _saveCsv(UserPreferences.mediaBarCollectionIds, pruned.toList());
      }

      if (!mounted) return;
      final result = await _showMultiSelectDialog(
        title: l10n.sourceCollections,
        items: {
          for (final item in items)
            item['Id'] as String: item['Name'] as String? ?? l10n.unknown,
        },
        selected: pruned,
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
    var closed = false;
    return showFocusRestoringDialog<Set<String>>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
          if (closed) return KeyEventResult.handled;
          if (event is KeyDownEvent || event is KeyUpEvent) {
            closed = true;
            Navigator.pop(ctx);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusScope(
          autofocus: true,
          child: StatefulBuilder(
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
  Widget build(BuildContext context) =>
      RequestInitialFocus(child: _buildContent(context));

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: buildSettingsAppBar(
        context,
        const Text('Media Bar & Local Previews'),
      ),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarEnabled,
            title: l10n.enableMediaBar,
            subtitle: l10n.showFeaturedContentSlideshow,
            icon: Icons.featured_play_list,
          ),
          _MediaBarContentTypePickerTile(onChanged: _pushSync),
          _MediaBarItemCountPickerTile(onChanged: _pushSync),
          const Divider(),
          _MediaBarActionTile(
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
          _MediaBarActionTile(
            leading: const Icon(Icons.collections_bookmark),
            title: Text(l10n.sourceCollections),
            subtitle: Text(
              _sourceSubtitle(
                  UserPreferences.mediaBarCollectionIds, l10n.noneSelected, l10n),
            ),
            onTap: _showCollectionSelector,
          ),
          _MediaBarActionTile(
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
            title: 'Media Preview',
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

class _MediaBarContentTypePickerTile extends StatefulWidget {
  final VoidCallback? onChanged;

  const _MediaBarContentTypePickerTile({this.onChanged});

  @override
  State<_MediaBarContentTypePickerTile> createState() =>
      _MediaBarContentTypePickerTileState();
}

class _MediaBarContentTypePickerTileState
    extends State<_MediaBarContentTypePickerTile> {
  static const _validKeys = <String>{
    'both',
    'movies',
    'tvshows',
  };

  late final PreferenceBinding<String> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      UserPreferences.mediaBarContentType,
    );
    final normalized = _normalize(_binding.value);
    if (normalized != _binding.value) {
      _binding.value = normalized;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged?.call();
      });
    }
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  String _normalize(String key) => _validKeys.contains(key) ? key : 'both';

  String _labelOf(String key, AppLocalizations l10n) => switch (key) {
    'both' => l10n.moviesAndTvShows,
    'movies' => l10n.moviesOnly,
    'tvshows' => l10n.tvShowsOnly,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<String>(
      valueListenable: _binding,
      builder: (context, value, _) {
        final normalized = _normalize(value);
        if (normalized != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_binding.value != normalized) {
              _binding.value = normalized;
              widget.onChanged?.call();
            }
          });
        }
        return TvFocusHighlight(
          builder: (ctx, _) => ListTile(
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            leading: const Icon(Icons.category),
            title: Text(l10n.contentType),
            subtitle: Text(_labelOf(normalized, l10n)),
            onTap: () => _showPicker(context, normalized),
          ),
        );
      },
    );
  }

  Future<void> _showPicker(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context);
    final normalizedCurrent = _normalize(current);
    final options = <String, String>{
      'both': l10n.moviesAndTvShows,
      'movies': l10n.moviesOnly,
      'tvshows': l10n.tvShowsOnly,
    };
    final entries = options.entries.toList();
    final selectedIndex = entries.indexWhere((e) => e.key == normalizedCurrent);
    final autofocusIndex = selectedIndex >= 0 ? selectedIndex : 0;

    final result = await showFocusRestoringDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        var closed = false;
        void closeOnce() {
          if (closed) return;
          closed = true;
          Navigator.pop(ctx);
        }
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, event) {
            if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
            if (event is KeyDownEvent || event is KeyUpEvent) {
              closeOnce();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: FocusScope(
            autofocus: true,
            child: SimpleDialog(
              title: Text(l10n.contentType),
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final selected = e.key == normalizedCurrent;
                return TvFocusHighlight(
                  builder: (_, __) => ListTile(
                    autofocus: i == autofocusIndex,
                    title: Text(e.value),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(ctx, e.key),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null || result == _binding.value) return;
    _binding.value = result;
    widget.onChanged?.call();
  }
}

class _MediaBarItemCountPickerTile extends StatefulWidget {
  final VoidCallback? onChanged;

  const _MediaBarItemCountPickerTile({this.onChanged});

  @override
  State<_MediaBarItemCountPickerTile> createState() =>
      _MediaBarItemCountPickerTileState();
}

class _MediaBarItemCountPickerTileState
    extends State<_MediaBarItemCountPickerTile> {
  static const _options = <String, String>{
    '5': '5',
    '10': '10',
    '15': '15',
    '20': '20',
  };

  late final PreferenceBinding<String> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      UserPreferences.mediaBarItemCount,
    );
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<String>(
      valueListenable: _binding,
      builder: (context, value, _) => TvFocusHighlight(
        builder: (ctx, _) => ListTile(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          leading: const Icon(Icons.format_list_numbered),
          title: Text(l10n.itemCount),
          subtitle: Text(_options[value] ?? value),
          onTap: () => _showPicker(context, value),
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context);
    final entries = _options.entries.toList();
    final selectedIndex = entries.indexWhere((e) => e.key == current);
    final autofocusIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final result = await showFocusRestoringDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        var closed = false;
        void closeOnce() {
          if (closed) return;
          closed = true;
          Navigator.pop(ctx);
        }
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, event) {
            if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
            if (event is KeyDownEvent || event is KeyUpEvent) {
              closeOnce();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: FocusScope(
            autofocus: true,
            child: SimpleDialog(
              title: Text(l10n.itemCount),
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final selected = e.key == current;
                return TvFocusHighlight(
                  builder: (_, __) => ListTile(
                    autofocus: i == autofocusIndex,
                    title: Text(e.value),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(ctx, e.key),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null || result == _binding.value) return;
    _binding.value = result;
    widget.onChanged?.call();
  }
}

class _MediaBarActionTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final VoidCallback? onTap;

  const _MediaBarActionTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusHighlight(
      builder: (ctx, _) => ListTile(
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        leading: leading,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
