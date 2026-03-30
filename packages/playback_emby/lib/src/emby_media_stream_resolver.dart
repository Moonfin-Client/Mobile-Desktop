
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

class EmbyMediaStreamResolver implements MediaStreamResolver {
  final MediaServerClient _client;

  EmbyMediaStreamResolver(this._client);

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
    }

    final externalSubs = MediaStreamResolver.extractExternalSubtitles(source.mediaStreams, _client.baseUrl);

    return StreamResolutionResult(
      streamUrl: url,
      mediaSourceId: source.id,
      playSessionId: info.playSessionId,
      playMethod: playMethod,
      externalSubtitles: externalSubs,
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

  (String, StreamPlayMethod) _resolveStreamUrl(
    String itemId,
    PlaybackMediaSource source,
  ) {
    if (source.supportsDirectPlay) {
      return (
        _client.playbackApi.getStreamUrl(itemId, mediaSourceId: source.id),
        StreamPlayMethod.directPlay,
      );
    }
    if (source.supportsDirectStream && source.directStreamUrl != null) {
      return (
        '${_client.baseUrl}${source.directStreamUrl}',
        StreamPlayMethod.directStream,
      );
    }
    if (source.supportsTranscoding && source.transcodingUrl != null) {
      return (
        '${_client.baseUrl}${source.transcodingUrl}',
        StreamPlayMethod.transcode,
      );
    }
    return (
      _client.playbackApi.getStreamUrl(itemId, mediaSourceId: source.id),
      StreamPlayMethod.directPlay,
    );
  }
}
