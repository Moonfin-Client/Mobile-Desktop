import 'package:get_it/get_it.dart';
import 'package:playback_core/playback_core.dart';
import 'package:playback_emby/playback_emby.dart';
import 'package:playback_jellyfin/playback_jellyfin.dart';
import 'package:server_core/server_core.dart';

import '../../../util/platform_detection.dart';
import '../../../playback/device_profile_builder.dart';
import '../../models/aggregated_item.dart';
import '../media_server_client_factory.dart';
import 'cast_provider.dart';
import 'cast_target.dart';
import 'cast_transport_controls.dart';
import 'native_dlna_channel.dart';

class DlnaProvider implements CastProvider, CastTransportControls {
  final NativeDlnaChannel _native;
  final MediaServerClientFactory _clientFactory;

  const DlnaProvider(this._native, this._clientFactory);

  MediaStreamResolver _resolverForClient(MediaServerClient client) {
    return switch (client.serverType) {
      ServerType.jellyfin => JellyfinPlugin(client).createStreamResolver(),
      ServerType.emby => EmbyPlugin(client).createStreamResolver(),
    };
  }

  @override
  Set<CastTargetKind> get supportedKinds => {CastTargetKind.dlna};

  @override
  Set<CastTargetKind> get controllableKinds => {CastTargetKind.dlna};

  @override
  Future<List<CastTarget>> discoverTargets(AggregatedItem item) async {
    if (!PlatformDetection.isAndroid && !PlatformDetection.isIOS) {
      return const [];
    }

    try {
      return await _native.discoverDlnaTargets();
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
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final client =
        _clientFactory.getClientIfExists(item.serverId) ?? GetIt.instance<MediaServerClient>();
    final hasExplicitIndices = audioStreamIndex != null || subtitleStreamIndex != null;
    final resolution = await _resolverForClient(client).resolve(
      item,
      deviceProfile: DeviceProfileBuilder.build(trueHdEnabled: false),
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      enableDirectPlay: !hasExplicitIndices,
      enableDirectStream: !hasExplicitIndices,
    );
    final streamUrl = resolution.streamUrl;

    await _native.playToDlnaDevice(
      targetId: target.id,
      streamUrl: streamUrl,
      title: item.name,
      startPositionTicks: startPositionTicks,
    );
  }

  @override
  Future<void> pause(CastTargetKind kind) async {
    if (kind != CastTargetKind.dlna) {
      throw UnsupportedError('Unsupported cast kind for DlnaProvider.');
    }
    await _native.pauseDlna();
  }

  @override
  Future<void> play(CastTargetKind kind) async {
    if (kind != CastTargetKind.dlna) {
      throw UnsupportedError('Unsupported cast kind for DlnaProvider.');
    }
    await _native.playDlna();
  }

  @override
  Future<void> seek(CastTargetKind kind, {required int positionTicks}) async {
    if (kind != CastTargetKind.dlna) {
      throw UnsupportedError('Unsupported cast kind for DlnaProvider.');
    }
    await _native.seekDlna(positionTicks: positionTicks);
  }

  @override
  Future<void> stop(CastTargetKind kind) async {
    if (kind != CastTargetKind.dlna) {
      throw UnsupportedError('Unsupported cast kind for DlnaProvider.');
    }
    await _native.stopDlna();
  }

  @override
  Future<double?> getVolume(CastTargetKind kind) async {
    if (kind != CastTargetKind.dlna) {
      throw UnsupportedError('Unsupported cast kind for DlnaProvider.');
    }
    return _native.getDlnaVolume();
  }

  @override
  Future<void> setVolume(CastTargetKind kind, {required double volume}) async {
    if (kind != CastTargetKind.dlna) {
      throw UnsupportedError('Unsupported cast kind for DlnaProvider.');
    }
    await _native.setDlnaVolume(volume: volume);
  }
}
