import 'package:get_it/get_it.dart';
import 'package:playback_core/playback_core.dart';
import 'package:playback_emby/playback_emby.dart';
import 'package:playback_jellyfin/playback_jellyfin.dart';
import 'package:server_core/server_core.dart';

import '../../../playback/device_profile_builder.dart';
import '../../../util/platform_detection.dart';
import '../../models/aggregated_item.dart';
import '../media_server_client_factory.dart';
import 'cast_provider.dart';
import 'cast_target.dart';
import 'cast_transport_controls.dart';
import 'native_airplay_channel.dart';
import 'native_cast_channel.dart';

class AirPlayProvider implements CastProvider, CastTransportControls {
  final NativeCastChannel _native;
  final NativeAirPlayChannel _nativeAirPlay;
  final MediaServerClientFactory _clientFactory;

  const AirPlayProvider(this._native, this._nativeAirPlay, this._clientFactory);

  MediaStreamResolver _resolverForClient(MediaServerClient client) {
    return switch (client.serverType) {
      ServerType.jellyfin => JellyfinPlugin(client).createStreamResolver(),
      ServerType.emby => EmbyPlugin(client).createStreamResolver(),
    };
  }

  @override
  Set<CastTargetKind> get supportedKinds => {CastTargetKind.airPlay};

  @override
  Set<CastTargetKind> get controllableKinds => {CastTargetKind.airPlay};

  @override
  Future<List<CastTarget>> discoverTargets(AggregatedItem item) async {
    if (!PlatformDetection.isIOS) {
      return const [];
    }

    final isAvailable = await _native.isAirPlayRoutePickerAvailable();
    if (!isAvailable) {
      return const [];
    }

    return const [
      CastTarget(
        id: 'airplay-system-picker',
        kind: CastTargetKind.airPlay,
        title: 'AirPlay',
        subtitle: 'Open iOS route picker',
      ),
    ];
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
    final isAvailable = await _native.isAirPlayRoutePickerAvailable();
    if (!isAvailable) {
      throw StateError('AirPlay route picker is unavailable on this device.');
    }

    final client =
        _clientFactory.getClientIfExists(item.serverId) ?? GetIt.instance<MediaServerClient>();
    final resolution = await _resolverForClient(client).resolve(
      item,
      deviceProfile: DeviceProfileBuilder.build(
        ac3Enabled: false,
        trueHdEnabled: false,
        useProgressiveTranscode: false,
        maxBitrateMbps: 15,
        subtitlesInManifest: false,
      ),
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      startTimeTicks: null,
      mediaSourceId: mediaSourceId,
      enableDirectPlay: false,
      enableDirectStream: false,
    );

    var streamUrl = resolution.streamUrl;
    final token = client.accessToken;
    if (token != null &&
        token.isNotEmpty &&
        !streamUrl.toLowerCase().contains('api_key=') &&
        !streamUrl.toLowerCase().contains('apikey=')) {
      final separator = streamUrl.contains('?') ? '&' : '?';
      streamUrl = '$streamUrl${separator}api_key=${Uri.encodeComponent(token)}';
    }

    streamUrl = streamUrl.replaceFirst('?&', '?');

    await _nativeAirPlay.loadAirPlay(
      url: streamUrl,
      title: item.name,
      positionTicks: 0,
    );

    await _native.showAirPlayRoutePicker();
  }

  @override
  Future<void> play(CastTargetKind kind) async {
    if (kind != CastTargetKind.airPlay) {
      throw UnsupportedError('Unsupported cast kind for AirPlayProvider.');
    }
    await _nativeAirPlay.playAirPlay();
  }

  @override
  Future<void> pause(CastTargetKind kind) async {
    if (kind != CastTargetKind.airPlay) {
      throw UnsupportedError('Unsupported cast kind for AirPlayProvider.');
    }
    await _nativeAirPlay.pauseAirPlay();
  }

  @override
  Future<void> seek(CastTargetKind kind, {required int positionTicks}) async {
    if (kind != CastTargetKind.airPlay) {
      throw UnsupportedError('Unsupported cast kind for AirPlayProvider.');
    }
    await _nativeAirPlay.seekAirPlay(positionTicks: positionTicks);
  }

  @override
  Future<void> stop(CastTargetKind kind) async {
    if (kind != CastTargetKind.airPlay) {
      throw UnsupportedError('Unsupported cast kind for AirPlayProvider.');
    }
    await _nativeAirPlay.stopAirPlay();
  }

  @override
  Future<double?> getVolume(CastTargetKind kind) async {
    if (kind != CastTargetKind.airPlay) {
      throw UnsupportedError('Unsupported cast kind for AirPlayProvider.');
    }
    return null;
  }

  @override
  Future<void> setVolume(CastTargetKind kind, {required double volume}) async {
    if (kind != CastTargetKind.airPlay) {
      throw UnsupportedError('Unsupported cast kind for AirPlayProvider.');
    }
  }
}
