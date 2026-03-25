import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/download_quality.dart';
import '../../../data/providers/offline_providers.dart';
import '../../../data/services/download_service.dart';
import '../../../data/services/storage_path_service.dart';
import '../../../di/providers.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/download_utils.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';

class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final qualityName = prefs.get(UserPreferences.defaultDownloadQuality);
    final wifiOnly = prefs.get(UserPreferences.downloadWifiOnly);
    final storageLimitMb = prefs.get(UserPreferences.downloadStorageLimitMb);
    final customPath = prefs.get(UserPreferences.customDownloadPath);
    final storage = ref.watch(storageUsedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: ListView(
        children: [
          const _Section(title: 'Quality'),
          ListTile(
            leading: const Icon(Icons.high_quality),
            title: const Text('Default Download Quality'),
            subtitle: Text(_qualityLabel(qualityName)),
            onTap: () => _pickQuality(context, prefs, qualityName),
          ),

          const _Section(title: 'Network'),
          if (!PlatformDetection.isDesktop)
            SwitchListTile(
              secondary: const Icon(Icons.wifi),
              title: const Text('WiFi-Only Downloads'),
              subtitle: const Text('Only download when connected to WiFi'),
              value: wifiOnly,
              onChanged: (v) => prefs.set(UserPreferences.downloadWifiOnly, v),
            ),
          const _Section(title: 'Storage'),
          storage.when(
            data: (bytes) => ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Storage Used'),
              subtitle: Text(formatBytes(bytes)),
              trailing: TextButton(
                child: const Text('Manage'),
                onPressed: () => context.push(Destinations.storageManagement),
              ),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.storage),
              title: Text('Storage Used'),
              subtitle: Text('Calculating...'),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Storage Limit'),
            subtitle: Text(storageLimitMb == 0 ? 'No limit' : '${(storageLimitMb / 1024).toStringAsFixed(1)} GB'),
            onTap: () => _pickStorageLimit(context, prefs, storageLimitMb),
          ),
          if (PlatformDetection.isDesktop)
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Download Location'),
              subtitle: Text(customPath.isEmpty ? 'Default' : customPath),
              onTap: () => _pickFolder(context, prefs),
            ),

          const _Section(title: 'Danger Zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Clear All Downloads', style: TextStyle(color: Colors.redAccent)),
            onTap: () => _confirmClearAll(context),
          ),
        ],
      ),
    );
  }

  String _qualityLabel(String name) {
    return DownloadQuality.values
        .where((q) => q.name == name)
        .map((q) => q.label)
        .firstOrNull ?? 'Original';
  }

  void _pickQuality(BuildContext context, UserPreferences prefs, String current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: DownloadQuality.values.map((q) => RadioListTile<String>(
            title: Text(q.label),
            subtitle: Text(q.estimatedSizePerHour),
            value: q.name,
            groupValue: current,
            onChanged: (v) {
              if (v != null) prefs.set(UserPreferences.defaultDownloadQuality, v);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _pickStorageLimit(BuildContext context, UserPreferences prefs, int current) {
    final values = [0, 1024, 2048, 5120, 10240, 20480, 51200, 102400];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: values.map((mb) => RadioListTile<int>(
            title: Text(mb == 0 ? 'No limit' : '${(mb / 1024).toStringAsFixed(0)} GB'),
            value: mb,
            groupValue: current,
            onChanged: (v) {
              if (v != null) prefs.set(UserPreferences.downloadStorageLimitMb, v);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _pickFolder(BuildContext context, UserPreferences prefs) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await prefs.set(UserPreferences.customDownloadPath, result);
      GetIt.instance<StoragePathService>().clearCache();
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text('This will delete all downloaded media and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final downloadService = GetIt.instance<DownloadService>();
    await downloadService.clearAllDownloads();
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
