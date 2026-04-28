import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/focus/request_initial_focus.dart';

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
  Widget build(BuildContext context) =>
      RequestInitialFocus(child: _buildContent(context));

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borders = ThemeRegistry.active.borders;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.fromBorderSide(
                borders.cardBorder.copyWith(
                  color: pluginAvailable
                      ? colorScheme.primary.withValues(alpha: 0.35)
                      : colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: pluginAvailable
                            ? colorScheme.primary.withValues(alpha: 0.18)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        pluginAvailable
                            ? Icons.extension
                            : Icons.extension_off,
                        color: pluginAvailable
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pluginAvailable
                                ? l10n.pluginDetected
                                : l10n.pluginNotDetected,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pluginVersion != null && pluginVersion.trim().isNotEmpty
                                ? l10n.pluginStatusVersion(pluginStateText, pluginVersion)
                                : pluginStateText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (availableServices.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.availableServices,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final service in availableServices)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(Icons.check_circle, size: 16, color: AppColorScheme.accent),
                          label: Text(service),
                          backgroundColor: borders.chipBackground,
                          side: borders.chipBorder,
                          shape: RoundedRectangleBorder(borderRadius: borders.chipRadius),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchPreferenceTile(
                  preference: UserPreferences.pluginSyncEnabled,
                  title: l10n.serverPluginSync,
                  subtitle: l10n.syncSettingsWithPlugin,
                  icon: Icons.sync,
                  onChanged: _pushSync,
                ),
                if (showProfileSync)
                  const Divider(height: 1),
                if (showProfileSync)
                  _ProfileSyncSection(
                    syncService: _syncService,
                    profileLabel: (p) => _profileLabel(p, l10n),
                    busy: _profileSyncBusy,
                    onLoad: _pullSelectedProfile,
                    onSave: _pushSelectedProfile,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.whatSyncControls,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.syncControlsDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borders = ThemeRegistry.active.borders;
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
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.customizationProfileDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final profile in profiles)
                ChoiceChip(
                  selected: selected == profile,
                  showCheckmark: false,
                  avatar: currentDeviceProfile == profile
                      ? const Icon(Icons.circle, size: 10, color: Colors.green)
                      : null,
                  label: Text(profileLabel(profile)),
                  side: borders.chipBorder,
                  shape: RoundedRectangleBorder(borderRadius: borders.chipRadius),
                  backgroundColor: borders.chipBackground,
                  selectedColor: AppColorScheme.accent.withValues(alpha: 0.22),
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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: busy ? null : onLoad,
                  icon: const Icon(Icons.cloud_download),
                  label: Text(l10n.loadProfile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
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
