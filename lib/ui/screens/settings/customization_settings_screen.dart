import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import 'customization_entries.dart';

import '../../../l10n/app_localizations.dart';

class CustomizationSettingsScreen extends StatefulWidget {
  const CustomizationSettingsScreen({super.key});

  @override
  State<CustomizationSettingsScreen> createState() =>
      _CustomizationSettingsScreenState();
}

class _CustomizationSettingsScreenState extends State<CustomizationSettingsScreen> {
  late final PluginSyncService _syncService;
  late final UserPreferences _prefs;
  late String _selectedProfile;
  bool _profileSyncBusy = false;

  @override
  void initState() {
    super.initState();
    _syncService = GetIt.instance<PluginSyncService>();
    _prefs = GetIt.instance<UserPreferences>();
    _selectedProfile = _syncService.selectedCustomizationProfile;
    _syncService.addListener(_onSyncStateChanged);
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (!mounted) return;
    setState(() {
      _selectedProfile = _syncService.selectedCustomizationProfile;
    });
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
    final ok = await _syncService.pullSettingsForProfile(
      client,
      profile: _selectedProfile,
    );

    if (!mounted) return;
    setState(() => _profileSyncBusy = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.loadedProfileSettings(_profileLabel(_selectedProfile, l10n))
              : l10n.failedToLoadProfileSettings(_profileLabel(_selectedProfile, l10n)),
        ),
      ),
    );
  }

  Future<void> _pushSelectedProfile() async {
    if (_profileSyncBusy || !_syncService.pluginAvailable) return;
    if (!GetIt.instance.isRegistered<MediaServerClient>()) return;

    setState(() => _profileSyncBusy = true);
    final client = GetIt.instance<MediaServerClient>();
    await _syncService.pushSettingsForProfile(
      client,
      profile: _selectedProfile,
    );

    if (!mounted) return;
    setState(() => _profileSyncBusy = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.syncedSettingsToProfile(_profileLabel(_selectedProfile, l10n)),
        ),
      ),
    );
  }

  Widget _buildProfileTab(String profile, String? currentDeviceProfile, AppLocalizations l10n) {
    return _ProfileTabButton(
      label: _profileLabel(profile, l10n),
      selected: _selectedProfile == profile,
      current: currentDeviceProfile == profile,
      onTap: () {
        _syncService.setSelectedCustomizationProfile(profile);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pluginCustomizationEnabled =
        _syncService.pluginAvailable &&
        _prefs.get(UserPreferences.pluginSyncEnabled);
    final currentDeviceProfile = _syncService.currentDeviceProfile;
    final supportedProfiles = PluginSyncService.supportedProfiles;
    final hasGlobalProfile = supportedProfiles.contains('global');
    final deviceProfiles = supportedProfiles
        .where((profile) => profile != 'global')
        .toList(growable: false);
    final entries = buildCustomizationEntries(
      isMobile: PlatformDetection.isMobile,
      l10n: l10n,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customization)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          if (pluginCustomizationEnabled)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.customizationProfile,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.customizationProfileDescription,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          if (hasGlobalProfile)
                            _buildProfileTab('global', currentDeviceProfile, l10n),
                          if (deviceProfiles.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                for (var i = 0;
                                    i < deviceProfiles.length;
                                    i++) ...[
                                  if (i > 0) const SizedBox(width: 4),
                                  Expanded(
                                    child: _buildProfileTab(
                                      deviceProfiles[i],
                                      currentDeviceProfile,
                                      l10n,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _profileSyncBusy ? null : _pullSelectedProfile,
                            icon: const Icon(Icons.download),
                            label: Text(l10n.loadProfile),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _profileSyncBusy ? null : _pushSelectedProfile,
                            icon: const Icon(Icons.upload),
                            label:
                                Text(_profileSyncBusy ? l10n.syncing : l10n.syncToProfile),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.profileSyncHidden),
                subtitle: Text(
                  l10n.enablePluginSyncDescription,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  ListTile(
                    leading: Icon(entries[i].icon),
                    title: Text(entries[i].title),
                    subtitle: Text(entries[i].subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(entries[i].destination),
                  ),
                  if (i != entries.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  const _ProfileTabButton({
    required this.label,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (current) ...[
                const SizedBox(width: 6),
                const Icon(Icons.circle, color: Colors.green, size: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
