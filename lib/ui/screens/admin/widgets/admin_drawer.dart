import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/destinations.dart';

class AdminDrawer extends StatelessWidget {
  final String currentPath;
  final bool isEmbedded;

  const AdminDrawer({
    super.key,
    required this.currentPath,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = isEmbedded
      ? mediaQuery.padding.bottom + 16
      : mediaQuery.padding.bottom + 88;

    final content = SafeArea(
      bottom: true,
      child: ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        if (!isEmbedded) const SizedBox(height: 8),
        _section(context, 'Server'),
        _tile(context, 'Dashboard', Icons.dashboard, Destinations.admin),
        _tile(context, 'Settings', Icons.settings, Destinations.adminSettings),
        _tile(context, 'Branding', Icons.brush, Destinations.adminSettingsBranding),
        _tile(context, 'Users', Icons.people, Destinations.adminUsers),
        _tile(
          context,
          'Libraries',
          null,
          Destinations.adminLibraries,
          iconBuilder: (size, color) => Image.asset(
            'assets/icons/clapperboard.png',
            width: size,
            height: size,
            color: color,
            fit: BoxFit.contain,
          ),
        ),
        _section(context, 'Playback'),
        _tile(context, 'Transcoding', Icons.swap_horiz,
          Destinations.adminSettingsPlayback),
        _tile(context, 'Resume', Icons.play_circle_outline,
          Destinations.adminSettingsResume),
        _tile(context, 'Streaming', Icons.stream,
          Destinations.adminSettingsStreaming),
        _tile(context, 'Trickplay', Icons.view_comfy,
          Destinations.adminSettingsTrickplay),
        _section(context, 'Devices'),
        _tile(context, 'Devices', Icons.devices, Destinations.adminDevices),
        _tile(context, 'Activity', Icons.history, Destinations.adminActivity),
        _section(context, 'Advanced'),
        _tile(context, 'Networking', Icons.language,
          Destinations.adminSettingsNetworking),
        _tile(context, 'API Keys', Icons.vpn_key, Destinations.adminKeys),
        _tile(context, 'Backups', Icons.backup, Destinations.adminBackups),
        _tile(context, 'Logs', Icons.article, Destinations.adminLogs),
        _tile(context, 'Scheduled Tasks', Icons.schedule,
          Destinations.adminTasks),
        _section(context, 'Plugins'),
        _tile(context, 'Plugins', Icons.extension, Destinations.adminPlugins),
        _tile(context, 'Repositories', Icons.source,
          Destinations.adminRepositories),
        _section(context, 'Live TV'),
        _tile(context, 'Live TV', Icons.live_tv, Destinations.adminLiveTv),
      ],
      ),
    );

    if (isEmbedded) return content;
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
    String title,
    IconData? icon,
    String destination,
    {Widget Function(double size, Color color)? iconBuilder,
    }
  ) {
    final selected = currentPath == destination;
    final iconColor = selected
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).iconTheme.color ?? Colors.white;
    return ListTile(
      leading: iconBuilder != null
          ? iconBuilder(24, iconColor)
          : Icon(icon),
      title: Text(title),
      selected: selected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      dense: true,
      onTap: () {
        if (!isEmbedded) Navigator.of(context).pop();
        if (!selected) context.go(destination);
      },
    );
  }
}
