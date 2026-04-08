import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class PluginSettingsScreen extends StatefulWidget {
  const PluginSettingsScreen({super.key});

  @override
  State<PluginSettingsScreen> createState() => _PluginSettingsScreenState();
}

class _PluginSettingsScreenState extends State<PluginSettingsScreen> {
  late final PluginSyncService _syncService;

  @override
  void initState() {
    super.initState();
    _syncService = GetIt.instance<PluginSyncService>();
    _syncService.addListener(_onSyncStateChanged);
    _refreshPluginStatus();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshPluginStatus() async {
    if (!GetIt.instance.isRegistered<MediaServerClient>()) return;
    final client = GetIt.instance<MediaServerClient>();
    await _syncService.refreshAvailability(client);
  }

  void _pushSync() {
    if (_syncService.pluginAvailable) {
      final client = GetIt.instance<MediaServerClient>();
      _syncService.pushSettings(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pluginAvailable = _syncService.pluginAvailable;
    final pluginVersion = _syncService.pluginVersion;
    final pluginStateText = pluginAvailable
        ? l10n.pluginDetectedDescription
        : l10n.pluginNotDetectedDescription;
    final availableServices = <String>[
      if (_syncService.mdblistAvailable) 'MDBList',
      if (_syncService.tmdbAvailable) 'TMDB',
      if (_syncService.seerrEnabled) 'Seerr',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pluginLabel)),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              pluginAvailable ? Icons.extension : Icons.extension_off,
              color: pluginAvailable ? Colors.green : null,
            ),
            title: Text(pluginAvailable ? l10n.pluginDetected : l10n.pluginNotDetected),
            subtitle: Text(
              pluginVersion != null && pluginVersion.trim().isNotEmpty
                  ? l10n.pluginStatusVersion(pluginStateText, pluginVersion)
                  : pluginStateText,
            ),
          ),
          if (availableServices.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.hub),
              title: Text(l10n.availableServices),
              subtitle: Text(availableServices.join(', ')),
            ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.pluginSyncEnabled,
            title: l10n.serverPluginSync,
            subtitle: l10n.syncSettingsWithPlugin,
            icon: Icons.sync,
            onChanged: _pushSync,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.whatSyncControls),
            subtitle: Text(
              l10n.syncControlsDescription,
            ),
          ),
        ],
      ),
    );
  }
}
