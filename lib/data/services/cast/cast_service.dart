import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/aggregated_item.dart';
import 'cast_provider.dart';
import 'cast_target.dart';
import 'cast_transport_controls.dart';
import 'native_airplay_channel.dart';
import 'native_cast_channel.dart';
import 'native_dlna_channel.dart';

class CastService {
  final List<CastProvider> _providers;
  final List<StreamSubscription<Map<String, dynamic>>> _nativeEventSubscriptions = [];
  final ValueNotifier<CastTargetKind?> activeKindNotifier = ValueNotifier(null);
  final ValueNotifier<CastTarget?> activeTargetNotifier = ValueNotifier(null);
  final ValueNotifier<AggregatedItem?> castItemNotifier = ValueNotifier(null);
  final ValueNotifier<String?> remoteStateNotifier = ValueNotifier(null);
  final ValueNotifier<int> remotePositionNotifier = ValueNotifier(0);
  final ValueNotifier<double?> remoteVolumeNotifier = ValueNotifier(null);

  CastService(
    this._providers, {
    NativeCastChannel? nativeCast,
    NativeDlnaChannel? nativeDlna,
    NativeAirPlayChannel? nativeAirPlay,
  }) {
    if (nativeCast != null) {
      _nativeEventSubscriptions.add(
        nativeCast.googleCastEventStream().listen(
          (e) => _handleNativeEvent(e, 'googleCast', CastTargetKind.googleCast),
          onError: (_) {},
        ),
      );
    }
    if (nativeDlna != null) {
      _nativeEventSubscriptions.add(
        nativeDlna.dlnaEventStream().listen(
          (e) => _handleNativeEvent(e, 'dlna', CastTargetKind.dlna),
          onError: (_) {},
        ),
      );
    }
    if (nativeAirPlay != null) {
      _nativeEventSubscriptions.add(
        nativeAirPlay.airPlayEventStream().listen(
          (e) => _handleNativeEvent(e, 'airPlay', CastTargetKind.airPlay),
          onError: (_) {},
        ),
      );
    }
  }

  void _handleNativeEvent(
    Map<String, dynamic> event,
    String expectedKind,
    CastTargetKind castKind,
  ) {
    final kind = event['kind'] as String?;
    if (kind != expectedKind) return;
    final state = event['state'] as String?;
    switch (state) {
      case 'connected':
        activeKindNotifier.value = castKind;
        remoteStateNotifier.value = null;
        if (castKind == CastTargetKind.googleCast || castKind == CastTargetKind.dlna) {
          _refreshVolume(castKind);
        }
      case 'disconnected':
        if (activeKindNotifier.value == castKind) {
          activeKindNotifier.value = null;
          activeTargetNotifier.value = null;
          castItemNotifier.value = null;
          remoteStateNotifier.value = null;
          remotePositionNotifier.value = 0;
          remoteVolumeNotifier.value = null;
        }
      case 'playing' || 'paused' || 'buffering' || 'idle':
        remoteStateNotifier.value = state;
        remotePositionNotifier.value = (event['positionTicks'] as int?) ?? 0;
    }
  }

  Future<void> _refreshVolume(CastTargetKind kind) async {
    try {
      remoteVolumeNotifier.value = await getVolume(kind);
    } catch (_) {
      remoteVolumeNotifier.value = null;
    }
  }

  CastTargetKind? get activeKind => activeKindNotifier.value;

  void setActiveKind(CastTargetKind? kind) {
    activeKindNotifier.value = kind;
  }

  Stream<CastTarget> discoverTargetsStreamed(AggregatedItem item) {
    final controller = StreamController<CastTarget>();
    int pending = _providers.length;
    if (pending == 0) {
      controller.close();
      return controller.stream;
    }
    for (final provider in _providers) {
      provider.discoverTargets(item).then((targets) {
        for (final t in targets) {
          if (!controller.isClosed) controller.add(t);
        }
      }).catchError((_) {}).whenComplete(() {
        pending--;
        if (pending == 0 && !controller.isClosed) controller.close();
      });
    }
    return controller.stream;
  }

  Future<List<CastTarget>> discoverTargets(AggregatedItem item) async {
    return discoverTargetsStreamed(item).toList();
  }

  Future<void> playToTarget(
    CastTarget target, {
    required AggregatedItem item,
    List<AggregatedItem>? queueItems,
    int? startPositionTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final provider = _providers.firstWhere(
      (p) => p.supportedKinds.contains(target.kind),
      orElse: () => throw StateError('No cast provider found for target'),
    );
    await provider.playToTarget(
      target,
      item: item,
      queueItems: queueItems,
      startPositionTicks: startPositionTicks,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );

    activeTargetNotifier.value = target;
    castItemNotifier.value = item;
    activeKindNotifier.value = target.kind;
    remoteStateNotifier.value = null;
    remotePositionNotifier.value = startPositionTicks ?? 0;
  }

  Future<void> play(CastTargetKind kind) async {
    final provider = _controlProviderForKind(kind);
    await provider.play(kind);
  }

  Future<void> pause(CastTargetKind kind) async {
    final provider = _controlProviderForKind(kind);
    await provider.pause(kind);
  }

  Future<void> seek(CastTargetKind kind, {required int positionTicks}) async {
    final provider = _controlProviderForKind(kind);
    await provider.seek(kind, positionTicks: positionTicks);
  }

  Future<void> stop(CastTargetKind kind) async {
    final provider = _controlProviderForKind(kind);
    await provider.stop(kind);
    if (activeKindNotifier.value == kind) {
      activeKindNotifier.value = null;
      activeTargetNotifier.value = null;
      castItemNotifier.value = null;
      remoteStateNotifier.value = null;
      remotePositionNotifier.value = 0;
      remoteVolumeNotifier.value = null;
    }
  }

  Future<double?> getVolume(CastTargetKind kind) async {
    final provider = _controlProviderForKind(kind);
    return provider.getVolume(kind);
  }

  Future<void> setVolume(CastTargetKind kind, {required double volume}) async {
    final provider = _controlProviderForKind(kind);
    await provider.setVolume(kind, volume: volume);
  }

  CastTransportControls _controlProviderForKind(CastTargetKind kind) {
    final provider = _providers.whereType<CastTransportControls>().firstWhere(
      (p) => p.controllableKinds.contains(kind),
      orElse: () => throw UnsupportedError('No transport controls for cast kind: $kind'),
    );

    return provider;
  }

  Future<void> dispose() async {
    for (final subscription in _nativeEventSubscriptions) {
      await subscription.cancel();
    }
    _nativeEventSubscriptions.clear();
    activeKindNotifier.dispose();
    activeTargetNotifier.dispose();
    castItemNotifier.dispose();
    remoteStateNotifier.dispose();
    remotePositionNotifier.dispose();
    remoteVolumeNotifier.dispose();
  }
}
