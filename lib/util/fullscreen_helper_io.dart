import 'package:window_manager/window_manager.dart';

import 'platform_detection.dart';

Future<bool> isFullscreen() async {
  if (!PlatformDetection.isDesktop) return false;
  try {
    return await windowManager.isFullScreen();
  } catch (_) {
    return false;
  }
}

Future<void> setFullscreen(bool value) async {
  if (!PlatformDetection.isDesktop) return;
  try {
    await windowManager.setFullScreen(value);
  } catch (_) {}
}
