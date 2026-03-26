import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';

class HomeRowsImageTypeScreen extends StatefulWidget {
  const HomeRowsImageTypeScreen({super.key});

  @override
  State<HomeRowsImageTypeScreen> createState() => _HomeRowsImageTypeScreenState();
}

class _HomeRowsImageTypeScreenState extends State<HomeRowsImageTypeScreen> {
  final _prefs = GetIt.instance<UserPreferences>();
  final _syncService = GetIt.instance<PluginSyncService>();

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pushSync() async {
    if (!_syncService.pluginAvailable) return;
    if (!GetIt.instance.isRegistered<MediaServerClient>()) return;
    final client = GetIt.instance<MediaServerClient>();
    await _syncService.pushSettings(client);
  }

  String _sectionLabel(HomeSectionType type) => switch (type) {
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

  String _imageTypeLabel(ImageType type) => switch (type) {
    ImageType.poster => 'Poster',
    ImageType.thumb => 'Thumbnail',
    ImageType.banner => 'Banner',
  };

  Future<void> _setPerRowImageType(HomeSectionType type, ImageType value) async {
    await _prefs.set(UserPreferences.homeRowImageType(type), value);
    await _pushSync();
  }

  @override
  Widget build(BuildContext context) {
    final enabledSections = _prefs.homeSectionsConfig
        .where((c) =>
            c.enabled &&
            c.type != HomeSectionType.none &&
            c.type != HomeSectionType.mediaBar &&
            c.type != HomeSectionType.resumeAudio &&
            c.type != HomeSectionType.libraryButtons)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Per Row Image Type')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.view_stream),
            title: Text('Per-Row Settings'),
          ),
          for (final section in enabledSections)
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(_sectionLabel(section.type)),
              subtitle: Text(_imageTypeLabel(_prefs.get(UserPreferences.homeRowImageType(section.type)))),
              onTap: () => _showImageTypePicker(
                context,
                current: _prefs.get(UserPreferences.homeRowImageType(section.type)),
                onSelected: (value) => _setPerRowImageType(section.type, value),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showImageTypePicker(
    BuildContext context, {
    required ImageType current,
    required Future<void> Function(ImageType value) onSelected,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Image Type'),
          children: ImageType.values.map((v) {
            return ListTile(
              title: Text(_imageTypeLabel(v)),
              trailing: v == current ? const Icon(Icons.check) : null,
              onTap: () async {
                await onSelected(v);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
