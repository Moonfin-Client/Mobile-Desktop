import '../util/platform_detection.dart';

class DeviceProfileBuilder {
  const DeviceProfileBuilder._();

  static Map<String, dynamic> build({
    int? maxBitrateMbps,
    bool ac3Enabled = true,
    bool trueHdEnabled = false,
    bool stereoDownmix = false,
    bool useProgressiveTranscode = false,
    bool subtitlesInManifest = true,
    bool pgsDirectPlay = false,
    bool assDirectPlay = true,
  }) {
    final bitrate = maxBitrateMbps == null ? null : maxBitrateMbps * 1000000;
    final streamingBitrate = bitrate == null
        ? null
        : useProgressiveTranscode
        ? (bitrate < 20000000 ? bitrate : 20000000)
        : bitrate;
    return {
      'Name': _profileName(),
      if (bitrate != null) 'MaxStaticBitrate': bitrate,
      if (streamingBitrate != null) 'MaxStreamingBitrate': streamingBitrate,
      'MusicStreamingTranscodingBitrate': 384000,
      'DirectPlayProfiles': _directPlayProfiles(
        ac3Enabled: ac3Enabled,
        trueHdEnabled: trueHdEnabled,
      ),
      'TranscodingProfiles': _transcodingProfiles(
        ac3Enabled: ac3Enabled,
        useProgressiveTranscode: useProgressiveTranscode,
        subtitlesInManifest: subtitlesInManifest,
      ),
      'ContainerProfiles': <Map<String, dynamic>>[],
      'CodecProfiles': _codecProfiles(stereoDownmix: stereoDownmix),
      'SubtitleProfiles': _subtitleProfiles(
        pgsDirectPlay: pgsDirectPlay,
        assDirectPlay: assDirectPlay,
      ),
    };
  }

  static String _profileName() {
    if (PlatformDetection.isAndroid) return 'Moonfin for Android';
    if (PlatformDetection.isIOS) return 'Moonfin iOS';
    if (PlatformDetection.isMacOS) return 'Moonfin macOS';
    if (PlatformDetection.isWindows) return 'Moonfin Windows';
    if (PlatformDetection.isLinux) return 'Moonfin Linux';
    return 'Moonfin';
  }

  static const _videoCodecs = 'h264,hevc,vp8,vp9,av1,mpeg2video,mpeg4,vc1';

  static String _audioCodecs({
    required bool ac3Enabled,
    required bool trueHdEnabled,
  }) {
    return [
      'aac',
      if (ac3Enabled) ...['ac3', 'eac3'],
      'mp3',
      'flac',
      'vorbis',
      'opus',
      'dts',
      if (trueHdEnabled) 'truehd',
      'pcm_s16le',
      'pcm_s24le',
    ].join(',');
  }

  static String _hlsAudioCodecs({required bool ac3Enabled}) {
    return [
      'aac',
      if (ac3Enabled) ...['ac3', 'eac3'],
      'mp3',
    ].join(',');
  }

  static List<Map<String, dynamic>> _directPlayProfiles({
    required bool ac3Enabled,
    bool trueHdEnabled = false,
  }) {
    final audio = _audioCodecs(
      ac3Enabled: ac3Enabled,
      trueHdEnabled: trueHdEnabled,
    );
    return [
      {
        'Container': 'mp4,m4v,mkv,avi,mov',
        'Type': 'Video',
        'VideoCodec': _videoCodecs,
        'AudioCodec': audio,
      },
      {
        'Container': 'webm',
        'Type': 'Video',
        'VideoCodec': 'vp8,vp9,av1',
        'AudioCodec': 'vorbis,opus',
      },
      {
        'Container': 'ts,m2ts,mpegts',
        'Type': 'Video',
        'VideoCodec': 'h264,hevc,mpeg2video',
        'AudioCodec': ac3Enabled ? 'aac,ac3,eac3,dts,mp3' : 'aac,dts,mp3',
      },
      {
        'Container': 'wmv,asf',
        'Type': 'Video',
        'VideoCodec': 'vc1,mpeg4',
        'AudioCodec': ac3Enabled ? 'aac,ac3,mp3' : 'aac,mp3',
      },
      {
        'Container': 'mp3',
        'Type': 'Audio',
      },
      {
        'Container': 'aac',
        'Type': 'Audio',
      },
      {
        'Container': 'flac',
        'Type': 'Audio',
      },
      {
        'Container': 'ogg',
        'Type': 'Audio',
        'AudioCodec': 'vorbis,opus',
      },
      {
        'Container': 'wav',
        'Type': 'Audio',
      },
    ];
  }

  static List<Map<String, dynamic>> _transcodingProfiles({
    required bool ac3Enabled,
    bool useProgressiveTranscode = false,
    bool subtitlesInManifest = true,
  }) {
    final hlsAudio = _hlsAudioCodecs(ac3Enabled: ac3Enabled);
    final protocol = useProgressiveTranscode ? 'http' : 'hls';
    final enableSubs = useProgressiveTranscode ? false : subtitlesInManifest;
    return [
      {
        'Container': useProgressiveTranscode ? 'mp4' : 'ts',
        'Type': 'Video',
        'VideoCodec': 'h264',
        'AudioCodec': hlsAudio,
        'Protocol': protocol,
        'Context': 'Streaming',
        'CopyTimestamps': false,
        'EnableSubtitlesInManifest': enableSubs,
        'BreakOnNonKeyFrames': false,
      },
      {
        'Container': 'mp4',
        'Type': 'Video',
        'VideoCodec': 'h264',
        'AudioCodec': hlsAudio,
        'Protocol': protocol,
        'Context': 'Streaming',
        'CopyTimestamps': false,
        'EnableSubtitlesInManifest': enableSubs,
        'BreakOnNonKeyFrames': false,
      },
      {
        'Container': 'mp3',
        'Type': 'Audio',
        'AudioCodec': 'mp3',
        'Protocol': 'http',
        'Context': 'Streaming',
      },
    ];
  }

  static List<Map<String, dynamic>> _codecProfiles({
    required bool stereoDownmix,
  }) {
    return [
      {
        'Type': 'Video',
        'Codec': 'h264',
        'Conditions': [
          {
            'Condition': 'LessThanEqual',
            'Property': 'VideoLevel',
            'Value': '52',
            'IsRequired': false,
          },
        ],
      },
      {
        'Type': 'Video',
        'Codec': 'hevc',
        'Conditions': [
          {
            'Condition': 'LessThanEqual',
            'Property': 'VideoLevel',
            'Value': '183',
            'IsRequired': false,
          },
        ],
      },
      {
        'Type': 'Video',
        'Codec': 'vp9',
        'Conditions': [
          {
            'Condition': 'LessThanEqual',
            'Property': 'VideoLevel',
            'Value': '62',
            'IsRequired': false,
          },
        ],
      },
      if (stereoDownmix)
        {
          'Type': 'VideoAudio',
          'Conditions': [
            {
              'Condition': 'LessThanEqual',
              'Property': 'AudioChannels',
              'Value': '2',
              'IsRequired': false,
            },
          ],
        },
    ];
  }

  static List<Map<String, dynamic>> _subtitleProfiles({
    required bool pgsDirectPlay,
    required bool assDirectPlay,
  }) {
    return [
      {'Format': 'srt', 'Method': 'External'},
      {'Format': 'srt', 'Method': 'Embed'},
      {'Format': 'subrip', 'Method': 'External'},
      {'Format': 'subrip', 'Method': 'Embed'},
      {'Format': 'ass', 'Method': 'External'},
      if (assDirectPlay) {'Format': 'ass', 'Method': 'Embed'},
      {'Format': 'ssa', 'Method': 'External'},
      if (assDirectPlay) {'Format': 'ssa', 'Method': 'Embed'},
      {'Format': 'vtt', 'Method': 'External'},
      {'Format': 'vtt', 'Method': 'Embed'},
      {'Format': 'webvtt', 'Method': 'External'},
      {'Format': 'webvtt', 'Method': 'Embed'},
      {'Format': 'sub', 'Method': 'External'},
      {'Format': 'sub', 'Method': 'Embed'},
      if (pgsDirectPlay) ...[
        {'Format': 'pgs', 'Method': 'Embed'},
        {'Format': 'pgssub', 'Method': 'Embed'},
        {'Format': 'dvbsub', 'Method': 'Embed'},
        {'Format': 'dvdsub', 'Method': 'Embed'},
      ],
      {'Format': 'ttml', 'Method': 'External'},
      {'Format': 'ttml', 'Method': 'Embed'},
    ];
  }
}
