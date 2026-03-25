import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import 'customization_entries.dart';

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

  String _profileLabel(String profile) {
    switch (profile) {
      case 'global':
        return 'Global';
      case 'desktop':
        return 'Desktop';
      case 'mobile':
        return 'Mobile';
      case 'tv':
        return 'TV';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Loaded ${_profileLabel(_selectedProfile)} profile settings.'
              : 'Failed to load ${_profileLabel(_selectedProfile)} profile settings.',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Synced local settings to ${_profileLabel(_selectedProfile)} profile.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pluginCustomizationEnabled =
        _syncService.pluginAvailable &&
        _prefs.get(UserPreferences.pluginSyncEnabled);
    final currentDeviceProfile = _syncService.currentDeviceProfile;
    final entries = buildCustomizationEntries(
      isMobile: PlatformDetection.isMobile,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Customization')),
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
                    const Text(
                      'Customization Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose the profile to load, edit, and sync. Global applies everywhere unless a device profile overrides it. The green dot marks your current device profile.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0;
                              i < PluginSyncService.supportedProfiles.length;
                              i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: _ProfileTabButton(
                                label: _profileLabel(
                                  PluginSyncService.supportedProfiles[i],
                                ),
                                selected: _selectedProfile ==
                                    PluginSyncService.supportedProfiles[i],
                                current:
                                    currentDeviceProfile == PluginSyncService.supportedProfiles[i],
                                onTap: () {
                                  _syncService.setSelectedCustomizationProfile(
                                    PluginSyncService.supportedProfiles[i],
                                  );
                                },
                              ),
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
                            label: const Text('Load Profile'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _profileSyncBusy ? null : _pushSelectedProfile,
                            icon: const Icon(Icons.upload),
                            label:
                                Text(_profileSyncBusy ? 'Syncing...' : 'Sync To Profile'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Profile Sync Hidden'),
                subtitle: Text(
                  'Enable Server Plugin Sync in Plugin settings to show profile controls here.',
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
