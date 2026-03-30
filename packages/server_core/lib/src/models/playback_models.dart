import 'enums.dart';

class PlaybackInfoRequest {
  final String itemId;
  final String? mediaSourceId;
  final int? startTimeTicks;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final int? maxStreamingBitrate;
  final Map<String, dynamic>? deviceProfile;
  final bool enableDirectPlay;
  final bool enableDirectStream;
  final bool enableTranscoding;
  final bool allowVideoStreamCopy;
  final bool allowAudioStreamCopy;
  final bool autoOpenLiveStream;

  const PlaybackInfoRequest({
    required this.itemId,
    this.mediaSourceId,
    this.startTimeTicks,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.maxStreamingBitrate,
    this.deviceProfile,
    this.enableDirectPlay = true,
    this.enableDirectStream = true,
    this.enableTranscoding = true,
    this.allowVideoStreamCopy = true,
    this.allowAudioStreamCopy = true,
    this.autoOpenLiveStream = true,
  });

  Map<String, dynamic> toJson() => {
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null)
          'SubtitleStreamIndex': subtitleStreamIndex,
        if (maxStreamingBitrate != null)
          'MaxStreamingBitrate': maxStreamingBitrate,
        if (deviceProfile != null) 'DeviceProfile': deviceProfile,
        'EnableDirectPlay': enableDirectPlay,
        'EnableDirectStream': enableDirectStream,
        'EnableTranscoding': enableTranscoding,
        'AllowVideoStreamCopy': allowVideoStreamCopy,
        'AllowAudioStreamCopy': allowAudioStreamCopy,
        'AutoOpenLiveStream': autoOpenLiveStream,
      };
}

class PlaybackInfoResult {
  final List<PlaybackMediaSource> mediaSources;
  final String? playSessionId;
  final PlaybackErrorCode? errorCode;

  const PlaybackInfoResult({
    this.mediaSources = const [],
    this.playSessionId,
    this.errorCode,
  });

  factory PlaybackInfoResult.fromJson(Map<String, dynamic> json) =>
      PlaybackInfoResult(
        mediaSources: (json['MediaSources'] as List<dynamic>?)
                ?.map((e) =>
                    PlaybackMediaSource.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        playSessionId: json['PlaySessionId'] as String?,
        errorCode: json['ErrorCode'] != null
            ? PlaybackErrorCode.fromServerString(json['ErrorCode'] as String)
            : null,
      );
}

enum PlaybackErrorCode {
  noCompatibleStream,
  notAllowed,
  rateLimitExceeded,
  unknown;

  static PlaybackErrorCode fromServerString(String? value) => switch (value) {
        'NoCompatibleStream' => noCompatibleStream,
        'NotAllowed' => notAllowed,
        'RateLimitExceeded' => rateLimitExceeded,
        _ => unknown,
      };
}

class PlaybackMediaSource {
  final String id;
  final String? name;
  final String? container;
  final int? bitrate;
  final bool supportsDirectPlay;
  final bool supportsDirectStream;
  final bool supportsTranscoding;
  final String? transcodingUrl;
  final String? directStreamUrl;
  final String? liveStreamId;
  final PlayMethod? defaultPlayMethod;
  final List<Map<String, dynamic>> mediaStreams;
  final List<String> transcodingReasons;

  const PlaybackMediaSource({
    required this.id,
    this.name,
    this.container,
    this.bitrate,
    this.supportsDirectPlay = false,
    this.supportsDirectStream = false,
    this.supportsTranscoding = false,
    this.transcodingUrl,
    this.directStreamUrl,
    this.liveStreamId,
    this.defaultPlayMethod,
    this.mediaStreams = const [],
    this.transcodingReasons = const [],
  });

  factory PlaybackMediaSource.fromJson(Map<String, dynamic> json) =>
      PlaybackMediaSource(
        id: json['Id'] as String? ?? '',
        name: json['Name'] as String?,
        container: json['Container'] as String?,
        bitrate: json['Bitrate'] as int?,
        supportsDirectPlay: json['SupportsDirectPlay'] as bool? ?? false,
        supportsDirectStream: json['SupportsDirectStream'] as bool? ?? false,
        supportsTranscoding: json['SupportsTranscoding'] as bool? ?? false,
        transcodingUrl: json['TranscodingUrl'] as String?,
        directStreamUrl: json['DirectStreamUrl'] as String?,
        liveStreamId: json['LiveStreamId'] as String?,
        mediaStreams: (json['MediaStreams'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const [],
        transcodingReasons: _parseTranscodingReasons(json),
      );

  static List<String> _parseTranscodingReasons(Map<String, dynamic> json) {
    // Jellyfin may return this as 'TranscodingReasons' or 'TranscodeReasons'.
    final raw = json['TranscodingReasons'] ?? json['TranscodeReasons'];
    if (raw is List) return raw.cast<String>();
    if (raw is String && raw.isNotEmpty) return raw.split(',');
    return const [];
  }
}

class PlaybackStartReport {
  final String itemId;
  final String? mediaSourceId;
  final String? playSessionId;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final PlayMethod? playMethod;
  final int? positionTicks;

  const PlaybackStartReport({
    required this.itemId,
    this.mediaSourceId,
    this.playSessionId,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.playMethod,
    this.positionTicks,
  });

  Map<String, dynamic> toJson() => {
        'ItemId': itemId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        if (playSessionId != null) 'PlaySessionId': playSessionId,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null)
          'SubtitleStreamIndex': subtitleStreamIndex,
        if (playMethod != null) 'PlayMethod': playMethod!.toServerString(),
        if (positionTicks != null) 'PositionTicks': positionTicks,
      };
}

class PlaybackProgressReport {
  final String itemId;
  final String? mediaSourceId;
  final String? playSessionId;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final int? positionTicks;
  final bool isPaused;
  final bool isMuted;

  const PlaybackProgressReport({
    required this.itemId,
    this.mediaSourceId,
    this.playSessionId,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.positionTicks,
    this.isPaused = false,
    this.isMuted = false,
  });

  Map<String, dynamic> toJson() => {
        'ItemId': itemId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        if (playSessionId != null) 'PlaySessionId': playSessionId,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null) 'SubtitleStreamIndex': subtitleStreamIndex,
        if (positionTicks != null) 'PositionTicks': positionTicks,
        'IsPaused': isPaused,
        'IsMuted': isMuted,
      };
}

class PlaybackStopReport {
  final String itemId;
  final String? mediaSourceId;
  final String? playSessionId;
  final int? positionTicks;

  const PlaybackStopReport({
    required this.itemId,
    this.mediaSourceId,
    this.playSessionId,
    this.positionTicks,
  });

  Map<String, dynamic> toJson() => {
        'ItemId': itemId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        if (playSessionId != null) 'PlaySessionId': playSessionId,
        if (positionTicks != null) 'PositionTicks': positionTicks,
      };
}
