import 'package:flutter/foundation.dart';

class PlatformDetection {
  const PlatformDetection._();

    static bool get _isWebMobileTarget {
        if (!kIsWeb) return false;
        return defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS;
    }

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
  static bool get isWeb => kIsWeb;

    static String get linuxSessionType => '';

  static bool get isLinuxWayland => linuxSessionType == 'wayland';
  static bool get isLinuxX11 => linuxSessionType == 'x11';

  static bool get isMobile => (isAndroid || isIOS) && !_isTv;
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  static bool get isTV => _isTv;
  static bool _isTv = false;
  static void setTvMode(bool value) => _isTv = value;

  /// Whether to use a 10-foot (lean-back) UI optimized for remote control.
  static bool get useLeanbackUi => isTV;
    static bool get useDesktopUi =>
            (isDesktop || (isWeb && !_isWebMobileTarget)) && !isTV;
    static bool get useMobileUi =>
            (isMobile || (isWeb && _isWebMobileTarget)) && !isTV;
}
