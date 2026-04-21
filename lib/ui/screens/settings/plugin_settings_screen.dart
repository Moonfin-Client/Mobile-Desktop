import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class PluginSettingsSection extends StatefulWidget {
  const PluginSettingsSection({super.key});

  @override
  State<PluginSettingsSection> createState() => _PluginSettingsSectionState();
}

class _PluginSettingsSectionState extends State<PluginSettingsSection> {
  late final PluginSyncService _syncService;
  late final UserPreferences _prefs;
  bool _profileSyncBusy = false;

  @override
  void initState() {
    super.initState();
    _syncService = GetIt.instance<PluginSyncService>();
    _prefs = GetIt.instance<UserPreferences>();
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

  String _profileLabel(String profile, AppLocalizations l10n) {
    switch (profile) {
      case 'global':
        return l10n.global;
      case 'desktop':
        return l10n.desktop;
      case 'mobile':
        return l10n.mobile;
      case 'tv':
        return l10n.tv;
      default:
        return profile;
    }
  }

  Future<void> _pullSelectedProfile() async {
    if (_profileSyncBusy || !_syncService.pluginAvailable) return;
    if (!GetIt.instance.isRegistered<MediaServerClient>()) return;

    setState(() => _profileSyncBusy = true);
    final client = GetIt.instance<MediaServerClient>();
    final profile = _syncService.selectedCustomizationProfile;
    final ok = await _syncService.pullSettingsForProfile(
      client,
      profile: profile,
    );

    if (!mounted) return;
    setState(() => _profileSyncBusy = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.loadedProfileSettings(_profileLabel(profile, l10n))
              : l10n.failedToLoadProfileSettings(_profileLabel(profile, l10n)),
        ),
      ),
    );
  }

  Future<void> _pushSelectedProfile() async {
    if (_profileSyncBusy || !_syncService.pluginAvailable) return;
    if (!GetIt.instance.isRegistered<MediaServerClient>()) return;

    setState(() => _profileSyncBusy = true);
    final client = GetIt.instance<MediaServerClient>();
    final profile = _syncService.selectedCustomizationProfile;
    await _syncService.pushSettingsForProfile(
      client,
      profile: profile,
    );

    if (!mounted) return;
    setState(() => _profileSyncBusy = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(l10n.syncedSettingsToProfile(_profileLabel(profile, l10n))),
      ),
    );
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
    final pluginSyncEnabled = _prefs.get(UserPreferences.pluginSyncEnabled);
    final showProfileSync = pluginAvailable && pluginSyncEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        if (showProfileSync) ...[
          const Divider(),
          _ProfileSyncSection(
            syncService: _syncService,
            profileLabel: (p) => _profileLabel(p, l10n),
            busy: _profileSyncBusy,
            onLoad: _pullSelectedProfile,
            onSave: _pushSelectedProfile,
          ),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.whatSyncControls),
          subtitle: Text(
            l10n.syncControlsDescription,
          ),
        ),
      ],
    );
  }
}

class _ProfileSyncSection extends StatelessWidget {
  const _ProfileSyncSection({
    required this.syncService,
    required this.profileLabel,
    required this.busy,
    required this.onLoad,
    required this.onSave,
  });

  final PluginSyncService syncService;
  final String Function(String profile) profileLabel;
  final bool busy;
  final VoidCallback onLoad;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = syncService.selectedCustomizationProfile;
    final currentDeviceProfile = syncService.currentDeviceProfile;
    final profiles = PluginSyncService.supportedProfiles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.customizationProfile,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(l10n.customizationProfileDescription),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final profile in profiles)
                ChoiceChip(
                  selected: selected == profile,
                  avatar: currentDeviceProfile == profile
                      ? const Icon(Icons.circle, size: 10, color: Colors.green)
                      : null,
                  label: Text(profileLabel(profile)),
                  onSelected: (_) {
                    syncService.setSelectedCustomizationProfile(profile);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onLoad,
                  icon: const Icon(Icons.cloud_download),
                  label: Text(l10n.loadProfile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : onSave,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(l10n.serverPluginSync),
                ),
              ),
            ],
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
