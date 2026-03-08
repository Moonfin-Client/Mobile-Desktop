import 'enums.dart';

class PlaybackInfoRequest {
  final String itemId;
  final int? startTimeTicks;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final int? maxStreamingBitrate;
  final Map<String, dynamic>? deviceProfile;

  const PlaybackInfoRequest({
    required this.itemId,
    this.startTimeTicks,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.maxStreamingBitrate,
    this.deviceProfile,
  });

  Map<String, dynamic> toJson() => {
        if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null)
          'SubtitleStreamIndex': subtitleStreamIndex,
        if (maxStreamingBitrate != null)
          'MaxStreamingBitrate': maxStreamingBitrate,
        if (deviceProfile != null) 'DeviceProfile': deviceProfile,
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
  final PlayMethod? defaultPlayMethod;

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
    this.defaultPlayMethod,
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
      );
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
  final int? positionTicks;
  final bool isPaused;
  final bool isMuted;

  const PlaybackProgressReport({
    required this.itemId,
    this.mediaSourceId,
    this.playSessionId,
    this.positionTicks,
    this.isPaused = false,
    this.isMuted = false,
  });

  Map<String, dynamic> toJson() => {
        'ItemId': itemId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        if (playSessionId != null) 'PlaySessionId': playSessionId,
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
