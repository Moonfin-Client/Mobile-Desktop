
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

class JellyfinMediaStreamResolver implements MediaStreamResolver {
  final MediaServerClient _client;

  JellyfinMediaStreamResolver(this._client);

  @override
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
  }) async {
    final itemId = MediaStreamResolver.extractItemId(mediaItem);

    final request = PlaybackInfoRequest(
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      deviceProfile: deviceProfile,
      maxStreamingBitrate: maxStreamingBitrate,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      startTimeTicks: startTimeTicks,
      enableDirectPlay: enableDirectPlay,
      enableDirectStream: enableDirectStream,
    );

    final rawInfo = await _client.playbackApi.getPlaybackInfo(
      itemId,
      requestBody: request.toJson(),
      userId: _client.userId,
    );

    final info = PlaybackInfoResult.fromJson(rawInfo);

    if (info.errorCode != null) {
      throw Exception('Playback error: ${info.errorCode}');
    }
    if (info.mediaSources.isEmpty) {
      throw Exception('No media sources available for item $itemId');
    }

    final source = _selectBestSource(info.mediaSources, preferredId: mediaSourceId);
    var (url, playMethod) = _resolveStreamUrl(itemId, source);

    if (playMethod == StreamPlayMethod.transcode) {
      url = MediaStreamResolver.applyStreamIndices(url, audioStreamIndex, subtitleStreamIndex);
      if (startTimeTicks != null) {
        final sttRegex = RegExp(r'StartTimeTicks=\d+');
        if (sttRegex.hasMatch(url)) {
          url = url.replaceFirst(sttRegex, 'StartTimeTicks=$startTimeTicks');
        } else {
          url = '$url&StartTimeTicks=$startTimeTicks';
        }
      }
      // Force burn-in when direct play was disabled for subtitle encoding.
      if (!enableDirectPlay && subtitleStreamIndex != null && subtitleStreamIndex >= 0) {
        final smRegex = RegExp(r'SubtitleMethod=\w+');
        if (smRegex.hasMatch(url)) {
          url = url.replaceFirst(smRegex, 'SubtitleMethod=Encode');
        } else {
          url = '$url&SubtitleMethod=Encode';
        }
      }
    }

    // Append auth token for mpv (which doesn't use our Dio interceptors).
    url = _appendAuth(url);

    final externalSubs = MediaStreamResolver.extractExternalSubtitles(source.mediaStreams, _client.baseUrl);
    final authedSubs = externalSubs.map((s) => ExternalSubtitle(
      deliveryUrl: _appendAuth(s.deliveryUrl),
      title: s.title,
      language: s.language,
      codec: s.codec,
      isDefault: s.isDefault,
      isForced: s.isForced,
      streamIndex: s.streamIndex,
    )).toList();

    return StreamResolutionResult(
      streamUrl: url,
      mediaSourceId: source.id,
      playSessionId: info.playSessionId,
      playMethod: playMethod,
      externalSubtitles: authedSubs,
      mediaStreams: source.mediaStreams,
    );
  }

  PlaybackMediaSource _selectBestSource(
    List<PlaybackMediaSource> sources, {
    String? preferredId,
  }) {
    if (preferredId != null) {
      final preferred = sources.where((s) => s.id == preferredId).firstOrNull;
      if (preferred != null) return preferred;
    }
    PlaybackMediaSource? directStream;
    PlaybackMediaSource? transcode;
    for (final s in sources) {
      if (s.supportsDirectPlay) return s;
      directStream ??= s.supportsDirectStream ? s : null;
      transcode ??= s.supportsTranscoding ? s : null;
    }
    return directStream ?? transcode ?? sources.first;
  }

  String _appendAuth(String url) {
    final token = _client.accessToken;
    if (token == null || token.isEmpty) return url;
    if (url.toLowerCase().contains('api_key=') || url.toLowerCase().contains('apikey=')) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}api_key=${Uri.encodeComponent(token)}';
  }

  (String, StreamPlayMethod) _resolveStreamUrl(
    String itemId,
    PlaybackMediaSource source,
  ) {
    if (source.supportsDirectPlay) {
      return (
        _client.playbackApi.getStreamUrl(itemId, mediaSourceId: source.id, liveStreamId: source.liveStreamId),
        StreamPlayMethod.directPlay,
      );
    }
    if (source.supportsDirectStream && source.directStreamUrl != null) {
      var dsUrl = '${_client.baseUrl}${source.directStreamUrl}';
      if (source.liveStreamId != null) {
        dsUrl = '$dsUrl${dsUrl.contains('?') ? '&' : '?'}LiveStreamId=${Uri.encodeComponent(source.liveStreamId!)}';
      }
      return (dsUrl, StreamPlayMethod.directStream);
    }
    if (source.supportsTranscoding && source.transcodingUrl != null) {
      var tcUrl = '${_client.baseUrl}${source.transcodingUrl}';
      if (source.liveStreamId != null) {
        tcUrl = '$tcUrl${tcUrl.contains('?') ? '&' : '?'}LiveStreamId=${Uri.encodeComponent(source.liveStreamId!)}';
      }
      return (tcUrl, StreamPlayMethod.transcode);
    }
    return (
      _client.playbackApi.getStreamUrl(itemId, mediaSourceId: source.id, liveStreamId: source.liveStreamId),
      StreamPlayMethod.directPlay,
    );
  }
}
