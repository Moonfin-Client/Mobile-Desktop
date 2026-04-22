import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PlatformDetection {
  const PlatformDetection._();

  static const double _mobileFormFactorBreakpoint = 600;

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

  static String get pathSeparator => isWindows ? '\\' : '/';

  static bool get isLinuxWayland => linuxSessionType == 'wayland';
  static bool get isLinuxX11 => linuxSessionType == 'x11';

  static bool get isMobile => (isAndroid || isIOS) && !_isTv;
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  static bool get isTV => _isTv;
  static bool _isTv = false;
  static void setTvMode(bool value) => _isTv = value;

  static Size? get _screenLogicalSize {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return null;
    final pixelRatio = view.devicePixelRatio == 0 ? 1.0 : view.devicePixelRatio;
    return view.physicalSize / pixelRatio;
  }

  static bool get _isMobilePlatformSignal {
    if (isAndroid || isIOS) return true;
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
    }
    return false;
  }

  static bool get _hasMobileFormFactor {
    final size = _screenLogicalSize;
    if (size == null) return _isMobilePlatformSignal;
    if (size.shortestSide <= 0) return _isMobilePlatformSignal;
    return size.shortestSide < _mobileFormFactorBreakpoint;
  }

  /// Whether to use a 10-foot (lean-back) UI optimized for remote control.
  static bool get useLeanbackUi => isTV;
  static bool get useDesktopUi => !_hasMobileFormFactor && !isTV;
  static bool get useMobileUi => _hasMobileFormFactor && !isTV;
}
