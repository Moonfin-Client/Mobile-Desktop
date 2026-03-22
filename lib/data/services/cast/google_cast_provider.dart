import 'package:get_it/get_it.dart';
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
    int? startPositionTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final client =
        _clientFactory.getClientIfExists(item.serverId) ?? GetIt.instance<MediaServerClient>();
    final streamUrl = client.playbackApi.getStreamUrl(item.id);

    await _native.startGoogleCastSession(
      targetId: target.id,
      streamUrl: streamUrl,
      title: item.name,
      subtitle: item.overview,
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
}
