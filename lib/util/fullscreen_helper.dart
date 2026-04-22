import 'fullscreen_helper_io.dart'
    if (dart.library.js_interop) 'fullscreen_helper_web.dart' as impl;

abstract class FullscreenHelper {
  static Future<bool> isFullscreen() => impl.isFullscreen();
  static Future<void> setFullscreen(bool value) => impl.setFullscreen(value);
  static Future<void> toggle() async {
    final current = await isFullscreen();
    await setFullscreen(!current);
  }
}
