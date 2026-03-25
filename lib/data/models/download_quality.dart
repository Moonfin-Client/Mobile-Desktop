/// Quality presets for downloading media with server-side transcoding.
///
/// When [isTranscoded] is true, the server uses ffmpeg to re-encode the media
/// to the specified bitrate/resolution. The download streams in real-time at
/// encoding speed. Transcoded downloads cannot be resumed if interrupted.
enum DownloadQuality {
  original,
  high1080p,
  medium720p,
  low480p,
  mobile360p;

  String get label => switch (this) {
        original => 'Original',
        high1080p => 'High (1080p)',
        medium720p => 'Medium (720p)',
        low480p => 'Low (480p)',
        mobile360p => 'Mobile (360p)',
      };

  // HEVC (H.265) bitrates deliver equivalent perceived quality to H.264 at
  // roughly half the bitrate, resulting in ~50% smaller files. libmpv/media_kit
  // decodes HEVC natively on all platforms, with hardware acceleration on any
  // device manufactured after ~2015.
  int? get videoBitRate => switch (this) {
        original => null,
        high1080p => 4000000,
        medium720p => 2000000,
        low480p => 1000000,
        mobile360p => 500000,
      };

  int? get maxWidth => switch (this) {
        original => null,
        high1080p => 1920,
        medium720p => 1280,
        low480p => 854,
        mobile360p => 640,
      };

  int? get audioBitRate => switch (this) {
        original => null,
        high1080p => 192000,
        medium720p => 128000,
        low480p => 96000,
        mobile360p => 64000,
      };

  int? get totalBitRate {
    if (!isTranscoded) return null;
    return (videoBitRate ?? 0) + (audioBitRate ?? 0);
  }

  String get estimatedSizePerHour {
    if (!isTranscoded) return 'Varies';
    final bitRate = totalBitRate;
    if (bitRate == null) return 'Varies';
    final bytesPerHour = bitRate * 3600 ~/ 8;
    if (bytesPerHour >= 1024 * 1024 * 1024) {
      return '~${(bytesPerHour / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/hr';
    }
    return '~${(bytesPerHour / (1024 * 1024)).round()} MB/hr';
  }

  String get videoCodec => 'hevc';
  String get audioCodec => 'aac';
  String get container => 'mp4';
  int? get audioChannels => this == original ? null : 2;

  /// Human-readable encoding format string, e.g. "MP4 • HEVC/AAC".
  /// Empty string for [original] since the container and codecs are source-dependent.
  String get encodingInfo => isTranscoded
      ? '${container.toUpperCase()} • ${videoCodec.toUpperCase()}/${audioCodec.toUpperCase()}'
      : '';

  bool get isTranscoded => this != original;
}
