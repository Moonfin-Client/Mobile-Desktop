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
        _tile(context, 'Analytics', Icons.insights, Destinations.adminAnalytics),
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
    final theme = Theme.of(context);
    final selected = currentPath == destination;
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
            if (!isEmbedded) {
              Navigator.of(context).pop();
            }
            if (!selected) {
              context.go(destination);
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
                iconBuilder != null
                    ? iconBuilder(18, iconColor)
                    : Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: iconColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
