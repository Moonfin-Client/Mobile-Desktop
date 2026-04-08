import 'package:flutter/material.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

class ServerPathsCard extends StatelessWidget {
  final StorageInfo storageInfo;

  const ServerPathsCard({super.key, required this.storageInfo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pathRows = <Widget>[];
    for (final row in [
      _pathTile(
        'Data',
        storageInfo.programDataPath,
        storageInfo.programDataFolder,
      ),
      _pathTile(
        'Image Cache',
        storageInfo.imageCacheFolder?.path ?? '',
        storageInfo.imageCacheFolder,
      ),
      _pathTile(
        'Cache',
        storageInfo.cachePath,
        storageInfo.cacheFolder,
      ),
      _pathTile(
        'Logs',
        storageInfo.logPath,
        storageInfo.logFolder,
      ),
      _pathTile(
        'Metadata',
        storageInfo.internalMetadataPath,
        storageInfo.internalMetadataFolder,
      ),
      _pathTile(
        'Transcode',
        storageInfo.transcodingTempPath,
        storageInfo.transcodingTempFolder,
      ),
      _pathTile(
        'Web',
        storageInfo.webFolder?.path ?? '',
        storageInfo.webFolder,
      ),
    ]) {
      if (row != null) {
        pathRows.add(row);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.adminServerPaths, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (pathRows.isEmpty)
              Text(
                'No server paths returned by this server.',
                style: theme.textTheme.bodySmall,
              )
            else
              ...pathRows,
          ],
        ),
      ),
    );
  }

  Widget? _pathTile(String label, String path, FolderStorageInfo? storage) {
    if (path.trim().isEmpty) return null;

    final hasCapacity = storage != null && storage.totalSpace > 0;
    final double usageFrac =
        hasCapacity ? storage.usageFraction.clamp(0.0, 1.0) : 0;
    final bool critical = usageFrac >= 0.90;
    final bool warning = usageFrac >= 0.75;
    final Color barColor = critical
        ? Colors.red.shade400
        : warning
            ? Colors.orange
            : Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (critical) ...[
                const SizedBox(width: 6),
                const Icon(Icons.warning_amber,
                    size: 13, color: Colors.orange),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            path,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          if (hasCapacity) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: usageFrac,
                color: barColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(usageFrac * 100).round()}% used',
                  style: TextStyle(
                    fontSize: 11,
                    color: barColor,
                    fontWeight:
                        warning ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Text(
                  '${_formatBytes(storage.usedSpace)} / ${_formatBytes(storage.totalSpace)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final fraction = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(fraction)} ${units[unitIndex]}';
  }
}
