import 'package:get_it/get_it.dart';
import 'package:playback_core/playback_core.dart';
import 'package:playback_emby/playback_emby.dart';
import 'package:playback_jellyfin/playback_jellyfin.dart';
import 'package:server_core/server_core.dart';

import '../../../util/platform_detection.dart';
import '../../models/aggregated_item.dart';
import '../media_server_client_factory.dart';
import 'cast_provider.dart';
import 'cast_target.dart';
import 'cast_transport_controls.dart';
import 'native_cast_channel.dart';

class GoogleCastProvider implements CastProvider, CastTransportControls {
  final NativeCastChannel _native;
  final MediaServerClientFactory _clientFactory;

  const GoogleCastProvider(this._native, this._clientFactory);

  MediaStreamResolver _resolverForClient(MediaServerClient client) {
    return switch (client.serverType) {
      ServerType.jellyfin => JellyfinPlugin(client).createStreamResolver(),
      ServerType.emby => EmbyPlugin(client).createStreamResolver(),
    };
  }

  Future<String> _streamUrlForItem(
    MediaServerClient client,
    AggregatedItem item,
    {String? mediaSourceId,}
  ) async {
    final resolution = await _resolverForClient(client).resolve(
      item,
      mediaSourceId: mediaSourceId,
    );
    return resolution.streamUrl;
  }

  @override
  Set<CastTargetKind> get supportedKinds => {CastTargetKind.googleCast};

  @override
  Set<CastTargetKind> get controllableKinds => {CastTargetKind.googleCast};

  @override
  Future<List<CastTarget>> discoverTargets(AggregatedItem item) async {
    if (!PlatformDetection.isAndroid && !PlatformDetection.isIOS) {
      return const [];
    }

    try {
      return await _native.discoverGoogleCastTargets();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> playToTarget(
    CastTarget target, {
    required AggregatedItem item,
    List<AggregatedItem>? queueItems,
    int? startPositionTicks,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final client =
        _clientFactory.getClientIfExists(item.serverId) ?? GetIt.instance<MediaServerClient>();
    final streamUrl = await _streamUrlForItem(
      client,
      item,
      mediaSourceId: mediaSourceId,
    );
    final effectiveQueueItems =
        (queueItems == null || queueItems.isEmpty)
            ? <AggregatedItem>[item]
            : queueItems;
    final queuePayload = <Map<String, dynamic>>[];
    for (final entry in effectiveQueueItems) {
      final entryStreamUrl =
          entry.id == item.id ? streamUrl : await _streamUrlForItem(client, entry);
      queuePayload.add(
        <String, dynamic>{
          'streamUrl': entryStreamUrl,
          'title': entry.name,
          if (entry.overview?.isNotEmpty == true) 'subtitle': entry.overview,
        },
      );
    }

    await _native.startGoogleCastSession(
      targetId: target.id,
      streamUrl: streamUrl,
      title: item.name,
      subtitle: item.overview,
      queueItems: queuePayload.length > 1 ? queuePayload : null,
      startPositionTicks: startPositionTicks,
    );
  }

  @override
  Future<void> pause(CastTargetKind kind) async {
    if (kind != CastTargetKind.googleCast) {
      throw UnsupportedError('Unsupported cast kind for GoogleCastProvider.');
    }
    await _native.pauseGoogleCast();
  }

  @override
  Future<void> play(CastTargetKind kind) async {
    if (kind != CastTargetKind.googleCast) {
      throw UnsupportedError('Unsupported cast kind for GoogleCastProvider.');
    }
    await _native.playGoogleCast();
  }

  @override
  Future<void> seek(CastTargetKind kind, {required int positionTicks}) async {
    if (kind != CastTargetKind.googleCast) {
      throw UnsupportedError('Unsupported cast kind for GoogleCastProvider.');
    }
    await _native.seekGoogleCast(positionTicks: positionTicks);
  }

  @override
  Future<void> stop(CastTargetKind kind) async {
    if (kind != CastTargetKind.googleCast) {
      throw UnsupportedError('Unsupported cast kind for GoogleCastProvider.');
    }
    await _native.stopGoogleCastSession();
  }

  @override
  Future<double?> getVolume(CastTargetKind kind) async {
    if (kind != CastTargetKind.googleCast) {
      throw UnsupportedError('Unsupported cast kind for GoogleCastProvider.');
    }
    return _native.getGoogleCastVolume();
  }

  @override
  Future<void> setVolume(CastTargetKind kind, {required double volume}) async {
    if (kind != CastTargetKind.googleCast) {
      throw UnsupportedError('Unsupported cast kind for GoogleCastProvider.');
    }
    await _native.setGoogleCastVolume(volume: volume);
  }
}
