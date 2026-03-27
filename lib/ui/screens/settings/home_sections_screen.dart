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

  void _save() {
    for (var i = 0; i < _sections.length; i++) {
      _sections[i] = _sections[i].copyWith(order: i);
    }
    final toSave = [..._sections];
    if (_mediaBarConfig != null) toSave.add(_mediaBarConfig!);
    _prefs.setHomeSectionsConfig(toSave);

    final syncService = GetIt.instance<PluginSyncService>();
    if (syncService.pluginAvailable) {
      final client = GetIt.instance<MediaServerClient>();
      syncService.pushSettings(client);
    }
  }

  String _labelFor(HomeSectionType type) => switch (type) {
    HomeSectionType.mediaBar => 'Media Bar',
    HomeSectionType.latestMedia => 'Latest Media',
    HomeSectionType.recentlyReleased => 'Recently Released',
    HomeSectionType.libraryTilesSmall => 'My Media',
    HomeSectionType.libraryButtons => 'My Media (Small)',
    HomeSectionType.resume => 'Continue Watching',
    HomeSectionType.resumeAudio => 'Resume Audio',
    HomeSectionType.resumeBook => 'Resume Books',
    HomeSectionType.activeRecordings => 'Active Recordings',
    HomeSectionType.nextUp => 'Next Up',
    HomeSectionType.playlists => 'Playlists',
    HomeSectionType.liveTv => 'Live TV',
    HomeSectionType.none => 'None',
  };

  String _posterSizeLabel(PosterSize size) => switch (size) {
    PosterSize.small => 'Small',
    PosterSize.medium => 'Medium',
    PosterSize.large => 'Large',
    PosterSize.extraLarge => 'Extra Large',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Sections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
            onPressed: () {
              setState(() => _sections = HomeSectionConfig.defaults());
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
              title: const Text('Home Row Poster Size'),
              subtitle: Text(_posterSizeLabel(_prefs.get(UserPreferences.posterSize))),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPosterSizeDialog,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Per Row Image Type Selection'),
              subtitle: const Text('Configure image type for each enabled home row'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Destinations.settingsHomeRowsImageType),
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
            title: Text(_labelFor(section.type)),
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
