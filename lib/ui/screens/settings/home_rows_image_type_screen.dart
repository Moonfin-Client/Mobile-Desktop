import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../l10n/app_localizations.dart';
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

  String _sectionLabel(HomeSectionType type, AppLocalizations l10n) => switch (type) {
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

  String _imageTypeLabel(ImageType type, AppLocalizations l10n) => switch (type) {
    ImageType.poster => l10n.posterLabel,
    ImageType.thumb => l10n.thumbnailLabel,
    ImageType.banner => l10n.bannerLabel,
  };

  Future<void> _setPerRowImageType(HomeSectionType type, ImageType value) async {
    await _prefs.set(UserPreferences.homeRowImageType(type), value);
    await _pushSync();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      appBar: AppBar(title: Text(l10n.perRowImageType)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.view_stream),
            title: Text(l10n.perRowSettings),
          ),
          for (final section in enabledSections)
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(_sectionLabel(section.type, l10n)),
              subtitle: Text(_imageTypeLabel(_prefs.get(UserPreferences.homeRowImageType(section.type)), l10n)),
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
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text(l10n.imageType),
          children: ImageType.values.map((v) {
            return ListTile(
              title: Text(_imageTypeLabel(v, l10n)),
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
