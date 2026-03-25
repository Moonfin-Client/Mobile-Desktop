import 'package:dio/dio.dart';

/// YouTube stream resolver with multi-strategy fallback.
/// Tries Piped → Invidious → Innertube API.
/// Returns a direct streamable URL or null if resolution fails.
class YouTubeStreamResolver {
  static const _resolveTimeout = Duration(seconds: 8);
  static const _requestTimeout = Duration(seconds: 5);
  static final Dio _dio = Dio();

  static const _pipedBases = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.moomoo.me',
  ];
  static const _invidiousBases = [
    'https://invidious.fdn.fr',
    'https://invidious.privacyredirect.com',
    'https://invidious.projectsegfau.lt',
  ];

  static const _firefoxUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) '
      'Gecko/20100101 Firefox/140.0';

  static const _youtubeOrigin = 'https://www.youtube.com';
  static const _youtubeReferer = 'https://www.youtube.com/';

  static const Map<String, String> youtubeHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
    'Referer': 'https://www.youtube.com/',
  };

  /// Extracts a YouTube video ID from common URL formats.
  static String? extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();

    if (host.contains('youtu.be')) {
      return uri.pathSegments.firstOrNull?.isNotEmpty == true
          ? uri.pathSegments.first
          : null;
    }

    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;

      final parts = uri.pathSegments;
      for (var i = 0; i < parts.length - 1; i++) {
        if (parts[i] == 'embed' ||
            parts[i] == 'shorts' ||
            parts[i] == 'v') {
          final candidate = parts[i + 1];
          if (candidate.isNotEmpty) return candidate;
        }
      }
    }

    return null;
  }

  /// Resolves a YouTube video ID to a direct streamable URL.
  /// Returns null if resolution fails or times out.
  static Future<String?> resolve(String videoId) async {
    try {
      return await _doResolve(videoId)
          .timeout(_resolveTimeout, onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  /// Resolves a direct playable stream URL from any trailer URL.
  ///
  /// For YouTube URLs this resolves to a direct stream URL.
  /// For non-YouTube URLs this returns the original URL.
  static Future<String?> resolveFromUrl(String trailerUrl) async {
    final videoId = extractVideoId(trailerUrl);
    if (videoId == null) {
      return trailerUrl;
    }
    return resolve(videoId);
  }

  static Future<String?> _doResolve(String videoId) async {
    for (final base in _pipedBases) {
      final piped = await _tryPiped(videoId, base);
      if (piped != null) return piped;
    }

    for (final base in _invidiousBases) {
      final invidious = await _tryInvidious(videoId, base);
      if (invidious != null) return invidious;
    }

    final innertube = await _tryInnertube(videoId);
    if (innertube != null) return innertube;

    return null;
  }

  static Future<String?> _tryPiped(String videoId, String baseUrl) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/streams/$videoId',
        options: Options(
          sendTimeout: _requestTimeout,
          receiveTimeout: _requestTimeout,
          headers: {'User-Agent': _firefoxUa},
        ),
      );

      final data = response.data;
      if (data == null) return null;

      final hls = data['hls'] as String?;
      if (hls != null && hls.isNotEmpty) return hls;

      final videoStreams = (data['videoStreams'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList();
      if (videoStreams == null) return null;

      final muxed = videoStreams
          .where((s) =>
              (s['videoOnly'] as bool? ?? true) == false &&
              (s['url'] as String?) != null)
          .toList();

      return _pickBestUrl(muxed);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _tryInvidious(String videoId, String baseUrl) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/api/v1/videos/$videoId',
        options: Options(
          sendTimeout: _requestTimeout,
          receiveTimeout: _requestTimeout,
        ),
      );

      final data = response.data;
      if (data == null) return null;

      final formatStreams = (data['formatStreams'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .where((s) => (s['url'] as String?) != null)
          .toList();

      if (formatStreams != null && formatStreams.isNotEmpty) {
        return _pickBestUrl(formatStreams);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _tryInnertube(String videoId) async {
    const clients = [
      _InnertubeClient(
        name: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
        nameId: '85',
        version: '2.0',
        userAgent:
            'Mozilla/5.0 (SMART-TV; LINUX; Tizen 6.0) AppleWebKit/538.1 '
            '(KHTML, like Gecko) Version/6.0 TV Safari/538.1',
        apiKey: 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
        platform: 'TV',
        embedContext: true,
      ),
      _InnertubeClient(
        name: 'IOS',
        nameId: '5',
        version: '20.10.4',
        userAgent:
            'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
        apiKey: 'AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc',
        platform: 'MOBILE',
        extra: {
          'deviceMake': 'Apple',
          'deviceModel': 'iPhone16,2',
          'osName': 'iOS',
          'osVersion': '18.3.2.22D82',
        },
      ),
      _InnertubeClient(
        name: 'ANDROID',
        nameId: '3',
        version: '20.10.41',
        userAgent:
            'com.google.android.youtube/20.10.41 (Linux; U; Android 11) gzip',
        apiKey: 'AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w',
        platform: 'MOBILE',
        extra: {
          'deviceMake': 'Google',
          'deviceModel': 'Pixel 5',
          'osName': 'Android',
          'osVersion': '11',
          'androidSdkVersion': '30',
        },
      ),
      _InnertubeClient(
        name: 'WEB',
        nameId: '1',
        version: '2.20250312.04.00',
        userAgent: _firefoxUa,
        apiKey: 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
        platform: 'DESKTOP',
      ),
    ];

    for (final client in clients) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          'https://www.youtube.com/youtubei/v1/player?key=${client.apiKey}&prettyPrint=false',
          data: {
            'videoId': videoId,
            'context': {
              'client': {
                'clientName': client.name,
                'clientVersion': client.version,
                'hl': 'en',
                'gl': 'US',
                'platform': client.platform,
                ...client.extra,
              },
              if (client.embedContext)
                'thirdParty': {'embedUrl': _youtubeReferer},
            },
            'contentCheckOk': true,
            'racyCheckOk': true,
          },
          options: Options(
            sendTimeout: _requestTimeout,
            receiveTimeout: _requestTimeout,
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': client.userAgent,
              'Origin': _youtubeOrigin,
              'Referer': _youtubeReferer,
              'X-YouTube-Client-Name': client.nameId,
              'X-YouTube-Client-Version': client.version,
            },
          ),
        );

        final data = response.data;
        if (data == null) continue;

        final url = _extractInnertubeStreamUrl(data);
        if (url != null) {
          return url;
        }
      } catch (_) {}
    }

    return null;
  }

  static String? _extractInnertubeStreamUrl(Map<String, dynamic> playerResponse) {
    final playability = playerResponse['playabilityStatus'] as Map<String, dynamic>?;
    final status = playability?['status'] as String?;
    if (status != null && status != 'OK') {
      return null;
    }

    final streamingData = playerResponse['streamingData'] as Map<String, dynamic>?;
    if (streamingData == null) return null;

    final hlsUrl = streamingData['hlsManifestUrl'] as String?;
    if (hlsUrl != null && hlsUrl.isNotEmpty) {
      return hlsUrl;
    }

    final formats = (streamingData['formats'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .where((s) => (s['url'] as String?) != null)
            .toList() ??
        const <Map<String, dynamic>>[];
    if (formats.isNotEmpty) {
      return _pickBestUrl(formats);
    }

    final adaptiveFormats = (streamingData['adaptiveFormats'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .where((s) =>
                (s['url'] as String?) != null &&
                ((s['mimeType'] as String?)?.startsWith('video/') ?? false))
            .toList() ??
        const <Map<String, dynamic>>[];
    if (adaptiveFormats.isNotEmpty) {
      return _pickBestUrl(adaptiveFormats);
    }

    return null;
  }

  static String? _pickBestUrl(List<Map<String, dynamic>> streams) {
    if (streams.isEmpty) return null;

    String? bestUrl;
    int bestQuality = 0;
    String? bestUnder720Url;
    int bestUnder720Quality = 0;

    for (final s in streams) {
      final url = s['url'] as String?;
      if (url == null) continue;

      final qualityStr = (s['quality'] as String? ??
              s['qualityLabel'] as String? ??
              '')
          .split(RegExp(r'[p@]'))
          .first
          .trim();
      final quality = int.tryParse(qualityStr) ?? 0;

      if (quality <= 720 && quality > bestUnder720Quality) {
        bestUnder720Quality = quality;
        bestUnder720Url = url;
      }
      if (quality > bestQuality) {
        bestQuality = quality;
        bestUrl = url;
      }
    }

    return bestUnder720Url ?? bestUrl ?? (streams.first['url'] as String?);
  }
}

class _InnertubeClient {
  final String name;
  final String nameId;
  final String version;
  final String userAgent;
  final String apiKey;
  final String platform;
  final Map<String, Object?> extra;
  final bool embedContext;

  const _InnertubeClient({
    required this.name,
    required this.nameId,
    required this.version,
    required this.userAgent,
    required this.apiKey,
    required this.platform,
    this.extra = const {},
    this.embedContext = false,
  });
}
