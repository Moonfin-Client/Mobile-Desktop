import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../../data/database/offline_database.dart';
import '../../../data/providers/offline_providers.dart';
import '../../../data/repositories/offline_repository.dart';
import '../../../data/services/download_service.dart';
import '../../../data/services/storage_path_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../preference/user_preferences.dart';
import '../../../di/providers.dart';
import '../../../util/download_utils.dart';

class StorageManagementScreen extends ConsumerStatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  ConsumerState<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends ConsumerState<StorageManagementScreen> {
  List<_StorageBreakdownItem>? _breakdown;
  List<DownloadedItem>? _itemsBySize;
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    final repo = GetIt.instance<OfflineRepository>();
    final allItems = await repo.getItems();

    int movieBytes = 0, tvBytes = 0, musicBytes = 0, bookBytes = 0, imageBytes = 0;
    for (final item in allItems) {
      final size = item.fileSizeBytes;
      if (item.type == 'Movie') {
        movieBytes += size;
      } else if (item.type == 'Episode') {
        tvBytes += size;
      } else if (item.type == 'Audio' || item.type == 'AudioBook') {
        musicBytes += size;
      } else if (item.type == 'Book') {
        bookBytes += size;
      }
    }

    final storagePath = GetIt.instance<StoragePathService>();
    final imageDir = await storagePath.getImageCacheDir();
    if (await imageDir.exists()) {
      await for (final entity in imageDir.list(recursive: true)) {
        if (entity is File) {
          imageBytes += await entity.length();
        }
      }
    }

    final dbFile = await storagePath.getDatabaseFile();
    final dbBytes = await dbFile.exists() ? await dbFile.length() : 0;

    const downloadableTypes = {'Movie', 'Episode', 'Audio', 'AudioBook', 'Book'};
    final downloadable = allItems
        .where((i) => i.fileSizeBytes > 0 && downloadableTypes.contains(i.type))
        .toList()
      ..sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));

    if (mounted) {
      setState(() {
        _breakdown = [
          _StorageBreakdownItem(AppLocalizations.of(context).movies, movieBytes, const Color(0xFF00A4DC)),
          _StorageBreakdownItem(AppLocalizations.of(context).tvShows, tvBytes, const Color(0xFF4CAF50)),
          _StorageBreakdownItem(AppLocalizations.of(context).musicAndAudiobooks, musicBytes, const Color(0xFFAB47BC)),
          _StorageBreakdownItem(AppLocalizations.of(context).books, bookBytes, const Color(0xFFEF5350)),
          _StorageBreakdownItem(AppLocalizations.of(context).images, imageBytes, const Color(0xFFFFA726)),
          _StorageBreakdownItem(AppLocalizations.of(context).database, dbBytes, const Color(0xFF9E9E9E)),
        ];
        _itemsBySize = downloadable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageUsedProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final storageLimitMb = prefs.get(UserPreferences.downloadStorageLimitMb);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context).storageManagement),
        actions: [
          if (_selectMode && _selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _bulkDelete,
            ),
          if (_itemsBySize != null && _itemsBySize!.isNotEmpty)
            IconButton(
              icon: Icon(_selectMode ? Icons.close : Icons.checklist),
              onPressed: () => setState(() {
                _selectMode = !_selectMode;
                if (!_selectMode) _selected.clear();
              }),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          storage.when(
            data: (bytes) => _TotalStorageHeader(
              totalBytes: bytes,
              limitMb: storageLimitMb,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          if (_breakdown != null) _buildBreakdownSection(),
          const SizedBox(height: 24),
          if (_itemsBySize != null && _itemsBySize!.isNotEmpty) _buildItemsSection(),
          const SizedBox(height: 24),
          _buildStorageLimitSetting(storageLimitMb),
          const SizedBox(height: 16),
          _buildDeleteAllButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    final total = _breakdown!.fold<int>(0, (sum, item) => sum + item.bytes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).storageBreakdown, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (total > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                children: _breakdown!
                    .where((b) => b.bytes > 0)
                    .map((b) => Expanded(
                          flex: b.bytes,
                          child: Container(color: b.color),
                        ))
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 12),
        ..._breakdown!.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b.label, style: const TextStyle(color: Colors.white70))),
                  Text(formatBytes(b.bytes), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).downloadedItems, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._itemsBySize!.map((item) {
          final isSelected = _selected.contains(item.itemId);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _selectMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => setState(() {
                      isSelected ? _selected.remove(item.itemId) : _selected.add(item.itemId);
                    }),
                  )
                : Icon(
                    switch (item.type) {
                      'Audio' || 'AudioBook' => Icons.music_note_outlined,
                      'Book' => Icons.menu_book_outlined,
                      _ => Icons.movie_outlined,
                    },
                    color: Colors.white38,
                  ),
            title: Text(item.name, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${item.type} • ${item.qualityPreset}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            trailing: Text(formatBytes(item.fileSizeBytes), style: const TextStyle(color: Colors.white54)),
            onTap: _selectMode
                ? () => setState(() {
                      isSelected ? _selected.remove(item.itemId) : _selected.add(item.itemId);
                    })
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildStorageLimitSetting(int currentLimitMb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).storageLimit, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          currentLimitMb == 0 ? AppLocalizations.of(context).noLimit : '${(currentLimitMb / 1024).toStringAsFixed(1)} GB',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Slider(
          value: currentLimitMb.toDouble(),
          min: 0,
          max: 102400,
          divisions: 20,
          label: currentLimitMb == 0 ? AppLocalizations.of(context).noLimit : '${(currentLimitMb / 1024).toStringAsFixed(1)} GB',
          onChanged: (value) {
            ref.read(userPreferencesProvider).set(UserPreferences.downloadStorageLimitMb, value.round());
          },
        ),
      ],
    );
  }

  Widget _buildDeleteAllButton() {
    return Center(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
        label: Text(AppLocalizations.of(context).deleteAllDownloads, style: const TextStyle(color: Colors.redAccent)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
        onPressed: _confirmDeleteAll,
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSelected),
        content: Text(l10n.deleteSelectedCount(_selected.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = GetIt.instance<OfflineRepository>();
    final storagePath = GetIt.instance<StoragePathService>();
    final imageDir = await storagePath.getImageCacheDir();

    for (final itemId in _selected) {
      final item = await repo.getItem(itemId);
      if (item == null) continue;
      if (item.localFilePath != null) {
        final f = File(item.localFilePath!);
        if (await f.exists()) await f.delete();
      }
      final imgDir = Directory('${imageDir.path}/$itemId');
      if (await imgDir.exists()) await imgDir.delete(recursive: true);
      await repo.deleteItem(itemId);
    }

    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    _loadBreakdown();
  }

  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllDownloads),
        content: Text(l10n.deleteAllDownloadsWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final downloadService = GetIt.instance<DownloadService>();
    await downloadService.clearAllDownloads();
    _loadBreakdown();
  }
}

class _TotalStorageHeader extends StatelessWidget {
  final int totalBytes;
  final int limitMb;

  const _TotalStorageHeader({required this.totalBytes, required this.limitMb});

  @override
  Widget build(BuildContext context) {
    final limitBytes = limitMb * 1024 * 1024;
    final fraction = limitBytes > 0 ? (totalBytes / limitBytes).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatBytes(totalBytes),
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        if (limitMb > 0) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: fraction,
            backgroundColor: Colors.white12,
            color: fraction > 0.9 ? Colors.redAccent : const Color(0xFF00A4DC),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).ofStorageLimit(formatBytes(limitBytes)),
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _StorageBreakdownItem {
  final String label;
  final int bytes;
  final Color color;
  const _StorageBreakdownItem(this.label, this.bytes, this.color);
}
