import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../navigation/destinations.dart';
import '../admin_plugin_version_utils.dart';
import '../providers/admin_user_providers.dart';

class AdminPluginsScreen extends ConsumerStatefulWidget {
  const AdminPluginsScreen({super.key});

  @override
  ConsumerState<AdminPluginsScreen> createState() => _AdminPluginsScreenState();
}

class _AdminPluginsScreenState extends ConsumerState<AdminPluginsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;
  _InstalledPluginFilter _installedFilter = _InstalledPluginFilter.all;

  AdminPluginsApi get _api =>
      GetIt.instance<MediaServerClient>().adminPluginsApi;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).adminSearchPlugins,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context).adminPluginsInstalled),
                  Tab(text: AppLocalizations.of(context).adminPluginsCatalog),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _InstalledTab(
                searchQuery: _searchQuery,
                statusFilter: _installedFilter,
                onStatusChanged: (filter) => setState(() => _installedFilter = filter),
                onToggle: _togglePlugin,
                onUninstall: _uninstallPlugin,
                onInstallUpdate: _installPluginUpdate,
              ),
              _CatalogTab(
                searchQuery: _searchQuery,
                categoryFilter: _categoryFilter,
                onCategoryChanged: (c) =>
                    setState(() => _categoryFilter = c),
                onInstall: _installPackage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _togglePlugin(PluginInfo plugin) async {
    try {
      if (plugin.status == PluginStatus.disabled) {
        await _api.enablePlugin(plugin.id, plugin.version);
      } else {
        await _api.disablePlugin(plugin.id, plugin.version);
      }
      ref.invalidate(adminInstalledPluginsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).adminPluginToggleFailed(e.toString()))));
      }
    }
  }

  Future<void> _uninstallPlugin(PluginInfo plugin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).adminUninstallPlugin),
        content: Text(AppLocalizations.of(context).adminUninstallPluginConfirm(plugin.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).uninstall),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.uninstallPlugin(plugin.id, plugin.version);
      ref.invalidate(adminInstalledPluginsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context).adminPluginRemoveAfterRestart(plugin.name))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).adminPluginUninstallFailed(e.toString()))));
      }
    }
  }

  Future<void> _installPackage(PackageInfo package, VersionInfo version) async {
    try {
      await _api.installPackage(
        package.name,
        assemblyGuid: package.id,
        version: version.version,
        repositoryUrl: version.repositoryUrl.isNotEmpty
            ? version.repositoryUrl
            : null,
      );
      ref.invalidate(adminInstalledPluginsProvider);
      ref.invalidate(adminAvailablePackagesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).adminPluginsInstalling(package.name))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).adminPackageInstallFailed(e.toString()))));
      }
    }
  }

  Future<void> _installPluginUpdate(
    PluginInfo plugin,
    PackageInfo package,
    VersionInfo version,
  ) async {
    try {
      await _api.installPackage(
        package.name,
        assemblyGuid: package.id,
        version: version.version,
        repositoryUrl:
            version.repositoryUrl.isNotEmpty ? version.repositoryUrl : null,
      );
      ref.invalidate(adminInstalledPluginsProvider);
      ref.invalidate(adminAvailablePackagesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).adminPluginUpdating(plugin.name, version.version),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).adminPluginUpdateFailed(e.toString()))),
        );
      }
    }
  }
}

enum _InstalledPluginFilter { all, active, restart }

class _InstalledTab extends ConsumerWidget {
  final String searchQuery;
  final _InstalledPluginFilter statusFilter;
  final ValueChanged<_InstalledPluginFilter> onStatusChanged;
  final Future<void> Function(PluginInfo) onToggle;
  final Future<void> Function(PluginInfo) onUninstall;
  final Future<void> Function(PluginInfo, PackageInfo, VersionInfo)
      onInstallUpdate;

  const _InstalledTab({
    required this.searchQuery,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.onToggle,
    required this.onUninstall,
    required this.onInstallUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginsAsync = ref.watch(adminInstalledPluginsProvider);
    final packagesAsync = ref.watch(adminAvailablePackagesProvider);

    return pluginsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).adminPluginsLoadFailed(error.toString())),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminInstalledPluginsProvider),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (plugins) {
        final client = GetIt.instance<MediaServerClient>();
        final imageUrlsByPluginId = {
          for (final plugin in plugins)
            if (plugin.hasImage && plugin.id.isNotEmpty)
              plugin.id: _pluginImageUrl(client, plugin),
        };
        final availableById = {
          for (final package in packagesAsync.valueOrNull ?? <PackageInfo>[])
            if (package.id.isNotEmpty) package.id: package,
        };
        final updateInfoByPluginId = {
          for (final plugin in plugins)
            plugin.id: _pluginUpdateInfo(plugin, availableById[plugin.id]),
        };

        var filtered = plugins;
        filtered = filtered.where((plugin) {
          switch (statusFilter) {
            case _InstalledPluginFilter.all:
              return true;
            case _InstalledPluginFilter.active:
              return plugin.status == PluginStatus.active;
            case _InstalledPluginFilter.restart:
              return plugin.status == PluginStatus.restart ||
                  plugin.status == PluginStatus.deleted;
          }
        }).toList();
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          filtered = filtered
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q))
              .toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Text(searchQuery.isNotEmpty
                ? AppLocalizations.of(context).adminPluginsNoSearchResults
                : AppLocalizations.of(context).adminPluginsNoneInstalled),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: _InstalledFilterTabs(
                statusFilter: statusFilter,
                onStatusChanged: onStatusChanged,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final plugin = filtered[index];
                  final updateInfo =
                      updateInfoByPluginId[plugin.id] ?? const _PluginUpdateInfo();
                  return _InstalledPluginTile(
                    plugin: plugin,
                    hasUpdate: updateInfo.latestVersion != null,
                    latestVersion: updateInfo.latestVersion,
                    imageUrl: imageUrlsByPluginId[plugin.id],
                    onUpdate: updateInfo.package != null &&
                            updateInfo.latestVersionInfo != null
                        ? () => onInstallUpdate(
                              plugin,
                              updateInfo.package!,
                              updateInfo.latestVersionInfo!,
                            )
                        : null,
                    onTap: () =>
                        context.push(Destinations.adminPlugin(plugin.id)),
                    onToggle: () => onToggle(plugin),
                    onUninstall: () => onUninstall(plugin),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  _PluginUpdateInfo _pluginUpdateInfo(PluginInfo plugin, PackageInfo? package) {
    if (package == null || plugin.version.isEmpty) {
      return const _PluginUpdateInfo();
    }

    final latestVersion = latestVersionAfter(plugin.version, package.versions);
    final latestVersionInfo = latestVersionInfoAfter(
      plugin.version,
      package.versions,
    );

    return _PluginUpdateInfo(
      latestVersion: latestVersion,
      latestVersionInfo: latestVersionInfo,
      package: package,
    );
  }

  String _pluginImageUrl(MediaServerClient client, PluginInfo plugin) {
    final base = client.baseUrl;
    final token = client.accessToken;
    final pluginId = Uri.encodeComponent(plugin.id);
    final version = Uri.encodeComponent(plugin.version);
    final apiKeySuffix = token == null || token.isEmpty
        ? ''
        : '?api_key=${Uri.encodeQueryComponent(token)}';
    return '$base/Plugins/$pluginId/$version/Image$apiKeySuffix';
  }
}

class _PluginUpdateInfo {
  final String? latestVersion;
  final VersionInfo? latestVersionInfo;
  final PackageInfo? package;

  const _PluginUpdateInfo({
    this.latestVersion,
    this.latestVersionInfo,
    this.package,
  });
}

class _InstalledFilterTabs extends StatelessWidget {
  final _InstalledPluginFilter statusFilter;
  final ValueChanged<_InstalledPluginFilter> onStatusChanged;

  const _InstalledFilterTabs({
    required this.statusFilter,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _InstalledFilterTab(
            label: AppLocalizations.of(context).all,
            selected: statusFilter == _InstalledPluginFilter.all,
            onTap: () => onStatusChanged(_InstalledPluginFilter.all),
          ),
          _InstalledFilterTab(
            label: AppLocalizations.of(context).adminPluginsActive,
            selected: statusFilter == _InstalledPluginFilter.active,
            onTap: () => onStatusChanged(_InstalledPluginFilter.active),
          ),
          _InstalledFilterTab(
            label: AppLocalizations.of(context).adminPluginsRestart,
            selected: statusFilter == _InstalledPluginFilter.restart,
            onTap: () => onStatusChanged(_InstalledPluginFilter.restart),
          ),
        ],
      ),
    );
  }
}

class _InstalledFilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InstalledFilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: SizedBox(
              height: 34,
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstalledPluginTile extends StatelessWidget {
  final PluginInfo plugin;
  final bool hasUpdate;
  final String? latestVersion;
  final String? imageUrl;
  final VoidCallback? onUpdate;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onUninstall;

  const _InstalledPluginTile({
    required this.plugin,
    required this.hasUpdate,
    this.latestVersion,
    this.imageUrl,
    this.onUpdate,
    required this.onTap,
    required this.onToggle,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: imageUrl == null
              ? Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.extension,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(2),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.extension,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(plugin.name, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'v${plugin.version}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (plugin.description.trim().isNotEmpty)
            Text(
              plugin.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          if (hasUpdate)
            Text(
              latestVersion != null
                  ? AppLocalizations.of(context).adminPluginsUpdateAvailable(latestVersion!)
                  : AppLocalizations.of(context).adminPluginsUpdateAvailableGeneric,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (plugin.status == PluginStatus.restart ||
              plugin.status == PluginStatus.deleted)
            Text(
              plugin.status == PluginStatus.deleted
                  ? AppLocalizations.of(context).adminPluginsPendingRemoval
                  : AppLocalizations.of(context).adminPluginsChangesPending,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'toggle':
              onToggle();
              return;
            case 'update':
              onUpdate?.call();
              return;
            case 'uninstall':
              onUninstall();
              return;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'toggle',
            child: Text(plugin.status == PluginStatus.disabled
                ? AppLocalizations.of(context).adminPluginsEnable
                : AppLocalizations.of(context).adminPluginsDisable),
          ),
          if (hasUpdate && onUpdate != null)
            PopupMenuItem(
              value: 'update',
              child: Text(
                latestVersion != null
                    ? AppLocalizations.of(context).adminPluginsInstallUpdateVersioned(latestVersion!)
                    : AppLocalizations.of(context).adminPluginsInstallUpdate,
              ),
            ),
          if (plugin.canUninstall)
            PopupMenuItem(
              value: 'uninstall',
              child: Text(AppLocalizations.of(context).uninstall),
            ),
        ],
      ),
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  final String searchQuery;
  final String? categoryFilter;
  final ValueChanged<String?> onCategoryChanged;
  final Future<void> Function(PackageInfo, VersionInfo) onInstall;

  const _CatalogTab({
    required this.searchQuery,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(adminAvailablePackagesProvider);

    return packagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).adminPluginsLoadFailed(error.toString())),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminAvailablePackagesProvider),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (packages) {
        final categories = packages
            .map((p) => p.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        var filtered = packages;
        if (categoryFilter != null) {
          filtered = filtered
              .where((p) => p.category == categoryFilter)
              .toList();
        }
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          filtered = filtered
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.overview.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            if (categories.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(AppLocalizations.of(context).all),
                        selected: categoryFilter == null,
                        onSelected: (_) => onCategoryChanged(null),
                      ),
                    ),
                    ...categories.map((c) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(c),
                            selected: categoryFilter == c,
                            onSelected: (_) => onCategoryChanged(
                                categoryFilter == c ? null : c),
                          ),
                        )),
                  ],
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(searchQuery.isNotEmpty
                          ? AppLocalizations.of(context).adminPluginsCatalogNoSearchResults
                          : AppLocalizations.of(context).adminPluginsCatalogEmpty),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final pkg = filtered[index];
                        return _CatalogPackageTile(
                          package: pkg,
                          onInstall: (version) =>
                              onInstall(pkg, version),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogPackageTile extends StatelessWidget {
  final PackageInfo package;
  final void Function(VersionInfo version) onInstall;

  const _CatalogPackageTile({
    required this.package,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestVersion =
        package.versions.isNotEmpty ? package.versions.first : null;

    final initials =
        package.name.isNotEmpty ? package.name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            package.name,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (package.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              package.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (package.overview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        package.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (package.owner.isNotEmpty)
                          Text(
                            package.owner,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        if (latestVersion != null) ...[
                          if (package.owner.isNotEmpty)
                            Text(
                              ' · ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          Text(
                            'v${latestVersion.version}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (latestVersion != null) ...[
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => onInstall(latestVersion),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: Text(AppLocalizations.of(context).install),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
