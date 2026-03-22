import 'package:flutter/services.dart';

import 'cast_target.dart';

class NativeCastChannel {
  static const MethodChannel _channel = MethodChannel('com.moonfin/native_cast');
  static const EventChannel _events = EventChannel('com.moonfin/native_cast_events');

  const NativeCastChannel();

  Future<List<CastTarget>> discoverGoogleCastTargets() async {
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'discoverGoogleCastTargets',
    );
    if (raw == null) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .map(
          (entry) => CastTarget(
            id: entry['id'] as String? ?? '',
            kind: CastTargetKind.googleCast,
            title: entry['title'] as String? ?? 'Google Cast',
            subtitle: entry['subtitle'] as String? ?? '',
          ),
        )
        .where((target) => target.id.isNotEmpty)
        .toList();
  }

  Future<void> startGoogleCastSession({
    required String targetId,
    required String streamUrl,
    required String title,
    String? subtitle,
    String? posterUrl,
    int? startPositionTicks,
  }) async {
    await _channel.invokeMethod<void>('startGoogleCastSession', {
      'targetId': targetId,
      'streamUrl': streamUrl,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (posterUrl != null) 'posterUrl': posterUrl,
      if (startPositionTicks != null) 'startPositionTicks': startPositionTicks,
    });
  }

  Future<void> showAirPlayRoutePicker() async {
    await _channel.invokeMethod<void>('showAirPlayRoutePicker');
  }

  Future<void> pauseGoogleCast() async {
    await _channel.invokeMethod<void>('pauseGoogleCast');
  }

  Future<void> playGoogleCast() async {
    await _channel.invokeMethod<void>('playGoogleCast');
  }

  Future<void> seekGoogleCast({required int positionTicks}) async {
    await _channel.invokeMethod<void>('seekGoogleCast', {
      'positionTicks': positionTicks,
    });
  }

  Future<void> stopGoogleCastSession() async {
    await _channel.invokeMethod<void>('stopGoogleCastSession');
  }

  Stream<Map<String, dynamic>> googleCastEventStream() {
    return _events.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return event.cast<String, dynamic>();
      }
      return <String, dynamic>{};
    }).where((event) => event.isNotEmpty);
  }
}
