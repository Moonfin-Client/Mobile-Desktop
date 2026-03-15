import 'dart:async';

import 'package:flutter/services.dart';

import '../util/platform_detection.dart';

class PipService {
  static const _channel = MethodChannel('org.moonfin.tv/pip');

  bool _isInPiP = false;
  bool get isInPiP => _isInPiP;

  final _pipChangedController = StreamController<bool>.broadcast();
  Stream<bool> get onPiPChanged => _pipChangedController.stream;

  final _actionController = StreamController<String>.broadcast();
  Stream<String> get onPiPAction => _actionController.stream;

  PipService() {
    if (PlatformDetection.isAndroid) {
      _channel.setMethodCallHandler(_handleMethod);
    }
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onPiPChanged':
        _isInPiP = call.arguments as bool;
        _pipChangedController.add(_isInPiP);
      case 'onPiPAction':
        _actionController.add(call.arguments as String);
    }
  }

  Future<void> enableAutoPiP(bool enabled) async {
    if (!PlatformDetection.isAndroid) return;
    try {
      await _channel.invokeMethod('enableAutoPiP', {'enabled': enabled});
    } catch (_) {}
  }

  Future<void> updatePiPActions({required bool isPlaying}) async {
    if (!PlatformDetection.isAndroid || !_isInPiP) return;
    try {
      await _channel
          .invokeMethod('updatePiPActions', {'isPlaying': isPlaying});
    } catch (_) {}
  }

  void dispose() {
    _pipChangedController.close();
    _actionController.close();
  }
}
