import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/home_section_config.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../widgets/poster_size_settings_dialog.dart';
import '../../../l10n/app_localizations.dart';

class HomeSectionsScreen extends StatefulWidget {
  const HomeSectionsScreen({super.key});

  @override
  State<HomeSectionsScreen> createState() => _HomeSectionsScreenState();
}

class _HomeSectionsScreenState extends State<HomeSectionsScreen> {
  final _prefs = GetIt.instance<UserPreferences>();
  late List<HomeSectionConfig> _sections;
  HomeSectionConfig? _mediaBarConfig;

  @override
  void initState() {
    super.initState();
    final all = _prefs.homeSectionsConfig;
    _mediaBarConfig = all.where((s) => s.type == HomeSectionType.mediaBar).firstOrNull;
    _sections = all.where((s) => s.type != HomeSectionType.mediaBar).toList();
  }

  void _pushSyncSettings() {
    final syncService = GetIt.instance<PluginSyncService>();
    if (syncService.pluginAvailable) {
      final client = GetIt.instance<MediaServerClient>();
      syncService.pushSettings(client);
    }
  }

  void _setMergeContinueWatchingNextUp(bool value, {bool pushSync = true}) {
    _prefs.set(UserPreferences.mergeContinueWatchingNextUp, value);
    if (pushSync) {
      _pushSyncSettings();
    }
  }

  void _save() {
    for (var i = 0; i < _sections.length; i++) {
      _sections[i] = _sections[i].copyWith(order: i);
    }
    final toSave = [..._sections];
    if (_mediaBarConfig != null) toSave.add(_mediaBarConfig!);
    _prefs.setHomeSectionsConfig(toSave);
    _pushSyncSettings();
  }

  String _labelFor(HomeSectionType type, AppLocalizations l10n) => switch (type) {
    HomeSectionType.mediaBar => l10n.mediaBar,
    HomeSectionType.latestMedia => l10n.latestMedia,
    HomeSectionType.recentlyReleased => l10n.recentlyReleased,
    HomeSectionType.libraryTilesSmall => l10n.myMedia,
    HomeSectionType.libraryButtons => l10n.myMediaSmall,
    HomeSectionType.resume => l10n.continueWatching,
    HomeSectionType.resumeAudio => l10n.resumeAudio,
    HomeSectionType.resumeBook => l10n.resumeBooks,
    HomeSectionType.activeRecordings => l10n.activeRecordings,
    HomeSectionType.nextUp => l10n.nextUp,
    HomeSectionType.playlists => l10n.playlists,
    HomeSectionType.liveTv => l10n.liveTV,
    HomeSectionType.none => l10n.none,
  };

  String _posterSizeLabel(PosterSize size, AppLocalizations l10n) => switch (size) {
    PosterSize.small => l10n.small,
    PosterSize.medium => l10n.medium,
    PosterSize.large => l10n.large,
    PosterSize.extraLarge => l10n.extraLarge,
  };

  Future<void> _showPosterSizeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => PosterSizeSettingsDialog(
        prefs: _prefs,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeSections),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: l10n.resetToDefaults,
            onPressed: () {
              setState(() {
                _sections = HomeSectionConfig.defaults();
                _setMergeContinueWatchingNextUp(
                  UserPreferences.mergeContinueWatchingNextUp.defaultValue,
                  pushSync: false,
                );
              });
              _save();
            },
          ),
        ],
      ),
      body: ReorderableListView.builder(
        header: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_size_select_large),
              title: Text(l10n.homeRowPosterSize),
              subtitle: Text(_posterSizeLabel(_prefs.get(UserPreferences.posterSize), l10n)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPosterSizeDialog,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(l10n.perRowImageTypeSelection),
              subtitle: Text(l10n.configureImageTypeForEachRow),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Destinations.settingsHomeRowsImageType),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.merge_type),
              title: Text(l10n.mergeContinueWatchingAndNextUp),
              subtitle: Text(
                l10n.combineBothRows,
              ),
              value: _prefs.get(UserPreferences.mergeContinueWatchingNextUp),
              onChanged: (value) {
                _setMergeContinueWatchingNextUp(value);
                setState(() {});
              },
            ),
            const Divider(),
          ],
        ),
        itemCount: _sections.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _sections.removeAt(oldIndex);
            _sections.insert(newIndex, item);
          });
          _save();
        },
        itemBuilder: (context, index) {
          final section = _sections[index];
          return ListTile(
            key: ValueKey(section.type),
            leading: Checkbox(
              value: section.enabled,
              onChanged: (enabled) {
                setState(() {
                  _sections[index] = section.copyWith(enabled: enabled ?? false);
                });
                _save();
              },
            ),
            title: Text(_labelFor(section.type, l10n)),
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
