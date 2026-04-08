import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../navigation/destinations.dart';
import 'providers/admin_websocket_handler.dart';
import 'widgets/admin_drawer.dart';

class AdminShellScreen extends StatelessWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isCompact = width < 430;
    final currentPath = GoRouterState.of(context).uri.path;
    final canGoBack = !isWide &&
      (_isSubPage(currentPath) || currentPath == Destinations.adminAnalytics);

    return AdminWebSocketHandler(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: theme.colorScheme.surface,
          toolbarHeight: isCompact ? kToolbarHeight : 64,
          leading: isWide
              ? null
              : canGoBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (currentPath == Destinations.adminAnalytics) {
                          context.go(Destinations.admin);
                          return;
                        }
                        context.pop();
                      },
                    )
                  : Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
          titleSpacing: 12,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Server Administration',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isCompact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.adminExitTooltip,
              onPressed: () => context.go(Destinations.home),
            ),
          ],
        ),
        drawer: isWide ? null : AdminDrawer(currentPath: currentPath),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: isWide
              ? Row(
                  children: [
                    Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.92),
                        border: Border(
                          right: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: AdminDrawer(
                        currentPath: currentPath,
                        isEmbedded: true,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Material(
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ScrollConfiguration(
                            behavior: const _AdminShellScrollBehavior(),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : child,
        ),
      ),
    );
  }

  static const _topLevelPaths = {
    Destinations.admin,
    Destinations.adminUsers,
    Destinations.adminLibraries,
    Destinations.adminSettings,
    Destinations.adminSettingsBranding,
    Destinations.adminSettingsPlayback,
    Destinations.adminTasks,
    Destinations.adminPlugins,
    Destinations.adminRepositories,
    Destinations.adminActivity,
    Destinations.adminDevices,
    Destinations.adminSettingsNetworking,
    Destinations.adminSettingsResume,
    Destinations.adminSettingsStreaming,
    Destinations.adminSettingsTrickplay,
    Destinations.adminKeys,
    Destinations.adminBackups,
    Destinations.adminLogs,
    Destinations.adminLiveTv,
  };

  static bool _isSubPage(String path) => !_topLevelPaths.contains(path);
}

class _AdminShellScrollBehavior extends MaterialScrollBehavior {
  const _AdminShellScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
