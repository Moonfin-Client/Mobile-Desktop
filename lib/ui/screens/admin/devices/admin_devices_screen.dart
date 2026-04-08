import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/admin_user_providers.dart';

class AdminDevicesScreen extends ConsumerStatefulWidget {
  const AdminDevicesScreen({super.key});

  @override
  ConsumerState<AdminDevicesScreen> createState() => _AdminDevicesScreenState();
}

class _AdminDevicesScreenState extends ConsumerState<AdminDevicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _userFilter;

  AdminDevicesApi get _api => GetIt.instance<MediaServerClient>().adminDevicesApi;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editDeviceName(DeviceInfoDto device) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: device.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminEditDeviceName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.adminCustomName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || !mounted) return;

    try {
      final options = DeviceOptionsDto(
        customName: newName.isEmpty ? null : newName,
      );
      await _api.updateDeviceOptions(device.id, options);
      ref.invalidate(adminDevicesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminDeviceNameUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminDeviceUpdateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteDevice(DeviceInfoDto device) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteDevice),
        content: Text(
          "Remove device '${device.displayName}'?\n\n"
          'The user will need to sign in again on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.deleteDevice(device.id);
      ref.invalidate(adminDevicesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminDeviceDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminDeviceDeleteFailed(e.toString()))),
        );
      }
    }
  }

  Color _lastSeenColor(DateTime? date, ThemeData theme) {
    if (date == null) return theme.colorScheme.onSurfaceVariant;
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return Colors.green;
    if (diff.inDays < 1) return Colors.orange.shade700;
    return theme.colorScheme.onSurfaceVariant;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final local = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(adminDevicesProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentDeviceId = GetIt.instance<MediaServerClient>().deviceInfo.id;

    return devicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminDevicesLoadFailed, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$e', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(adminDevicesProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (devices) {
        final users = devices
            .map((device) => device.lastUserName)
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        final filtered = devices.where((device) {
          if (_userFilter != null && device.lastUserName != _userFilter) {
            return false;
          }
          if (_searchQuery.isEmpty) {
            return true;
          }
          final query = _searchQuery.toLowerCase();
          return device.displayName.toLowerCase().contains(query) ||
              (device.appName ?? '').toLowerCase().contains(query) ||
              (device.lastUserName ?? '').toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: l10n.adminSearchDevices,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (users.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(l10n.all),
                        selected: _userFilter == null,
                        onSelected: (_) => setState(() => _userFilter = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    ...users.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(user),
                          selected: _userFilter == user,
                          onSelected: (_) => setState(
                            () => _userFilter = _userFilter == user ? null : user,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filtered.isEmpty
          ? Center(
              child: Text(
                devices.isEmpty ? 'No devices found' : 'No devices match the current filters',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final device = filtered[index];
                final isCurrentDevice = device.id == currentDeviceId;
                final appInfo = [device.appName, device.appVersion]
                    .where((v) => v != null && v.isNotEmpty)
                    .join(' ');

                return Card(
                  child: ListTile(
                    leading: Icon(
                      _deviceIcon(device.appName),
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    title: Row(
                      children: [
                        Flexible(child: Text(device.displayName)),
                        if (isCurrentDevice) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(l10n.adminThisDevice),
                            labelStyle: theme.textTheme.labelSmall,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (appInfo.isNotEmpty) Text(appInfo),
                        Row(
                          children: [
                            if (device.lastUserName != null) ...[
                              Icon(Icons.person, size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(device.lastUserName!,
                                  style: theme.textTheme.bodySmall),
                              const SizedBox(width: 12),
                            ],
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: _lastSeenColor(device.dateLastActivity, theme),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(device.dateLastActivity),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _lastSeenColor(device.dateLastActivity, theme),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: l10n.adminEditName,
                          onPressed: () => _editDeviceName(device),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: l10n.delete,
                          color: isCurrentDevice ? theme.disabledColor : theme.colorScheme.error,
                          onPressed: isCurrentDevice ? null : () => _deleteDevice(device),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),
          ],
        );
      },
    );
  }

  static IconData _deviceIcon(String? appName) {
    if (appName == null) return Icons.devices;
    final lower = appName.toLowerCase();
    if (lower.contains('android')) return Icons.phone_android;
    if (lower.contains('ios') || lower.contains('iphone') || lower.contains('ipad')) return Icons.phone_iphone;
    if (lower.contains('tv') || lower.contains('tizen') || lower.contains('webos') || lower.contains('roku')) return Icons.tv;
    if (lower.contains('web') || lower.contains('chrome') || lower.contains('firefox') || lower.contains('safari')) return Icons.language;
    if (lower.contains('windows') || lower.contains('linux') || lower.contains('mac')) return Icons.computer;
    return Icons.devices;
  }
}
