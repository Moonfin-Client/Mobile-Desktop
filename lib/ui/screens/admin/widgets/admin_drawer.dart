import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../preference/user_preferences.dart';
import '../../../navigation/destinations.dart';

class AdminDrawer extends StatefulWidget {
  final String currentPath;
  final bool isEmbedded;

  const AdminDrawer({
    super.key,
    required this.currentPath,
    this.isEmbedded = false,
  });

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  final _prefs = GetIt.instance<UserPreferences>();
  List<_AdminNavEntry> _entries = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    final saved = _prefs.get(UserPreferences.adminDrawerOrder);
    _entries = _orderedEntries(_buildDefaultEntries(l10n), saved);
  }

  List<_AdminNavEntry> _orderedEntries(
    List<_AdminNavEntry> defaults,
    String savedOrder,
  ) {
    if (savedOrder.isEmpty) {
      return List<_AdminNavEntry>.from(defaults);
    }

    final byId = <String, _AdminNavEntry>{for (final e in defaults) e.id: e};
    final ordered = <_AdminNavEntry>[];
    final seen = <String>{};

    for (final id in savedOrder.split(',')) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) continue;
      final entry = byId[trimmed];
      if (entry == null || seen.contains(trimmed)) continue;
      ordered.add(entry);
      seen.add(trimmed);
    }

    for (final entry in defaults) {
      if (!seen.contains(entry.id)) {
        ordered.add(entry);
      }
    }

    return ordered;
  }

  void _saveOrder() {
    final value = _entries.map((e) => e.id).join(',');
    _prefs.set(UserPreferences.adminDrawerOrder, value);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final moved = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, moved);
    });
    _saveOrder();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = widget.isEmbedded
        ? mediaQuery.padding.bottom + 16
        : mediaQuery.padding.bottom + 88;

    final content = SafeArea(
      bottom: true,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: EdgeInsets.only(bottom: bottomPadding),
        itemCount: _entries.length,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final previousSection = index > 0 ? _entries[index - 1].section : null;
          final showSection = index == 0 || previousSection != entry.section;
          return Column(
            key: ValueKey('admin-drawer-${entry.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEmbedded && index == 0) const SizedBox(height: 8),
              if (showSection) _section(context, entry.section),
              _tile(context, entry, index),
            ],
          );
        },
      ),
    );

    if (widget.isEmbedded) return content;
    return Drawer(child: content);
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    _AdminNavEntry entry,
    int index,
  ) {
    final theme = Theme.of(context);
    final selected = widget.currentPath == entry.destination;
    final iconColor = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.85)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () {
            if (!widget.isEmbedded) {
              Navigator.of(context).pop();
            }
            if (!selected) {
              context.go(entry.destination);
            }
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.35)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                entry.iconBuilder != null
                    ? entry.iconBuilder!(18, iconColor)
                    : Icon(entry.icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: iconColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavEntry {
  final String id;
  final String section;
  final String title;
  final IconData? icon;
  final String destination;
  final Widget Function(double size, Color color)? iconBuilder;

  const _AdminNavEntry({
    required this.id,
    required this.section,
    required this.title,
    required this.icon,
    required this.destination,
    this.iconBuilder,
  });
}

List<_AdminNavEntry> _buildDefaultEntries(AppLocalizations l10n) => [
  _AdminNavEntry(
    id: 'dashboard',
    section: 'Server',
    title: l10n.adminDrawerDashboard,
    icon: Icons.dashboard,
    destination: Destinations.admin,
  ),
  _AdminNavEntry(
    id: 'analytics',
    section: 'Server',
    title: l10n.adminDrawerAnalytics,
    icon: Icons.insights,
    destination: Destinations.adminAnalytics,
  ),
  _AdminNavEntry(
    id: 'settings',
    section: 'Server',
    title: l10n.adminDrawerSettings,
    icon: Icons.settings,
    destination: Destinations.adminSettings,
  ),
  _AdminNavEntry(
    id: 'branding',
    section: 'Server',
    title: l10n.adminDrawerBranding,
    icon: Icons.brush,
    destination: Destinations.adminSettingsBranding,
  ),
  _AdminNavEntry(
    id: 'users',
    section: 'Server',
    title: l10n.adminDrawerUsers,
    icon: Icons.people,
    destination: Destinations.adminUsers,
  ),
  _AdminNavEntry(
    id: 'libraries',
    section: 'Server',
    title: l10n.adminDrawerLibraries,
    icon: null,
    destination: Destinations.adminLibraries,
    iconBuilder: _librariesIcon,
  ),
  _AdminNavEntry(
    id: 'transcoding',
    section: 'Playback',
    title: l10n.adminDrawerTranscoding,
    icon: Icons.swap_horiz,
    destination: Destinations.adminSettingsPlayback,
  ),
  _AdminNavEntry(
    id: 'resume',
    section: 'Playback',
    title: l10n.adminDrawerResume,
    icon: Icons.play_circle_outline,
    destination: Destinations.adminSettingsResume,
  ),
  _AdminNavEntry(
    id: 'streaming',
    section: 'Playback',
    title: l10n.adminDrawerStreaming,
    icon: Icons.stream,
    destination: Destinations.adminSettingsStreaming,
  ),
  _AdminNavEntry(
    id: 'trickplay',
    section: 'Playback',
    title: l10n.adminDrawerTrickplay,
    icon: Icons.view_comfy,
    destination: Destinations.adminSettingsTrickplay,
  ),
  _AdminNavEntry(
    id: 'devices',
    section: 'Devices',
    title: l10n.adminDrawerDevices,
    icon: Icons.devices,
    destination: Destinations.adminDevices,
  ),
  _AdminNavEntry(
    id: 'activity',
    section: 'Devices',
    title: l10n.adminDrawerActivity,
    icon: Icons.history,
    destination: Destinations.adminActivity,
  ),
  _AdminNavEntry(
    id: 'networking',
    section: 'Advanced',
    title: l10n.adminDrawerNetworking,
    icon: Icons.language,
    destination: Destinations.adminSettingsNetworking,
  ),
  _AdminNavEntry(
    id: 'api-keys',
    section: 'Advanced',
    title: l10n.adminDrawerApiKeys,
    icon: Icons.vpn_key,
    destination: Destinations.adminKeys,
  ),
  _AdminNavEntry(
    id: 'backups',
    section: 'Advanced',
    title: l10n.adminDrawerBackups,
    icon: Icons.backup,
    destination: Destinations.adminBackups,
  ),
  _AdminNavEntry(
    id: 'logs',
    section: 'Advanced',
    title: l10n.adminDrawerLogs,
    icon: Icons.article,
    destination: Destinations.adminLogs,
  ),
  _AdminNavEntry(
    id: 'scheduled-tasks',
    section: 'Advanced',
    title: l10n.adminDrawerScheduledTasks,
    icon: Icons.schedule,
    destination: Destinations.adminTasks,
  ),
  _AdminNavEntry(
    id: 'plugins',
    section: 'Plugins',
    title: l10n.adminDrawerPlugins,
    icon: Icons.extension,
    destination: Destinations.adminPlugins,
  ),
  _AdminNavEntry(
    id: 'repositories',
    section: 'Plugins',
    title: l10n.adminDrawerRepositories,
    icon: Icons.source,
    destination: Destinations.adminRepositories,
  ),
  _AdminNavEntry(
    id: 'live-tv',
    section: 'Live TV',
    title: l10n.adminDrawerLiveTv,
    icon: Icons.live_tv,
    destination: Destinations.adminLiveTv,
  ),
];

Widget _librariesIcon(double size, Color color) {
  return Image.asset(
    'assets/icons/clapperboard.png',
    width: size,
    height: size,
    color: color,
    fit: BoxFit.contain,
  );
}
