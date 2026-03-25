import '../data/models/aggregated_item.dart';
import '../data/models/download_quality.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

int sourceSizeBytes(AggregatedItem item) {
  if (item.mediaSources.isEmpty) {
    return 0;
  }

  return item.mediaSources.first['Size'] as int? ?? 0;
}

Duration? runtimeForEstimate(AggregatedItem item) {
  final runtime = item.runtime;
  if (runtime != null && runtime.inMilliseconds > 0) {
    return runtime;
  }

  if (item.mediaSources.isEmpty) {
    return null;
  }

  final runTimeTicks = item.mediaSources.first['RunTimeTicks'] as int?;
  if (runTimeTicks == null || runTimeTicks <= 0) {
    return null;
  }

  return Duration(microseconds: runTimeTicks ~/ 10);
}

int? estimateTranscodedSizeBytes(AggregatedItem item, DownloadQuality quality) {
  if (!quality.isTranscoded) {
    return null;
  }

  final runtime = runtimeForEstimate(item);
  final totalBitRate = quality.totalBitRate;
  if (runtime == null || totalBitRate == null || totalBitRate <= 0) {
    return null;
  }

  return ((runtime.inMilliseconds * totalBitRate / 8000) * 1.03).round();
}

int estimateDownloadSizeBytes(AggregatedItem item, DownloadQuality quality) {
  if (!quality.isTranscoded) {
    return sourceSizeBytes(item);
  }

  return estimateTranscodedSizeBytes(item, quality) ?? sourceSizeBytes(item);
}
