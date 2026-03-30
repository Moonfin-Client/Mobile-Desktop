import 'stream_resolution_result.dart';

abstract class MediaStreamResolver {
  static String extractItemId(dynamic mediaItem) {
    if (mediaItem is Map) return mediaItem['Id'] as String;
    return mediaItem.id as String;
  }

  static String applyStreamIndices(String url, int? audioStreamIndex, int? subtitleStreamIndex) {
    var result = url;

    if (audioStreamIndex != null) {
      final audioRegex = RegExp(r'AudioStreamIndex=\d+');
      if (audioRegex.hasMatch(result)) {
        result = result.replaceFirst(audioRegex, 'AudioStreamIndex=$audioStreamIndex');
      } else {
        result = '$result&AudioStreamIndex=$audioStreamIndex';
      }
    }

    if (subtitleStreamIndex != null && subtitleStreamIndex >= 0) {
      final subRegex = RegExp(r'SubtitleStreamIndex=\d+');
      if (subRegex.hasMatch(result)) {
        result = result.replaceFirst(subRegex, 'SubtitleStreamIndex=$subtitleStreamIndex');
      } else {
        result = '$result&SubtitleStreamIndex=$subtitleStreamIndex';
      }
    } else if (subtitleStreamIndex == -1) {
      result = result.replaceAll(RegExp(r'[&?]SubtitleStreamIndex=\d+'), '');
    }

    return result;
  }

  static List<ExternalSubtitle> extractExternalSubtitles(
    List<Map<String, dynamic>> mediaStreams,
    String baseUrl,
  ) {
    final subs = <ExternalSubtitle>[];
    for (final stream in mediaStreams) {
      if (stream['Type'] != 'Subtitle') continue;
      final deliveryUrl = stream['DeliveryUrl'] as String?;
      if (deliveryUrl == null || deliveryUrl.isEmpty) continue;
      final isExternal = stream['IsExternal'] == true;
      final supportsExternal = stream['SupportsExternalStream'] == true;
      if (!isExternal && !supportsExternal) continue;
      subs.add(ExternalSubtitle(
        deliveryUrl: '$baseUrl$deliveryUrl',
        title: stream['DisplayTitle'] as String? ??
            stream['Title'] as String?,
        language: stream['Language'] as String?,
        codec: (stream['Codec'] as String?) ?? 'srt',
        isDefault: stream['IsDefault'] as bool? ?? false,
        isForced: stream['IsForced'] as bool? ?? false,
        streamIndex: stream['Index'] as int?,
      ));
    }
    return subs;
  }

  Future<StreamResolutionResult> resolve(
    dynamic mediaItem, {
    Map<String, dynamic>? deviceProfile,
    int? maxStreamingBitrate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
    String? mediaSourceId,
    bool enableDirectPlay = true,
    bool enableDirectStream = true,
  });
}
