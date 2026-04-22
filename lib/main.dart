import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit/media_kit.dart';
import 'package:playback_core/playback_core.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'data/services/cast/airplay_command_bridge.dart';
import 'data/services/download_notification_service.dart';
import 'data/services/media_server_client_factory.dart';
import 'di/injection.dart';
import 'playback/audio_handler.dart';
import 'playback/playback_lifecycle_handler.dart';
import 'preference/user_preferences.dart';
import 'util/platform_detection.dart';

void _configureImageCache() {
  final imageCache = PaintingBinding.instance.imageCache;
  if (PlatformDetection.isWeb) {
    imageCache.maximumSize = 60;
    imageCache.maximumSizeBytes = 48 << 20;
    return;
  }
  if (PlatformDetection.isMobile) {
    imageCache.maximumSize = 100;
    imageCache.maximumSizeBytes = 120 << 20;
    return;
  }

  imageCache.maximumSize = 200;
  imageCache.maximumSizeBytes = 256 << 20;
}

Future<void> _restoreWindowGeometry() async {
  final prefs = GetIt.instance<UserPreferences>();
  final w = prefs.get(UserPreferences.windowWidth);
  final h = prefs.get(UserPreferences.windowHeight);
  final x = prefs.get(UserPreferences.windowX);
  final y = prefs.get(UserPreferences.windowY);

  const minW = 800.0;
  const minH = 500.0;
  final hasSavedGeometry = w >= minW && h >= minH;

  final options = WindowOptions(
    size: hasSavedGeometry ? Size(w, h) : const Size(1280, 720),
    minimumSize: const Size(minW, minH),
    center: !hasSavedGeometry,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    if (hasSavedGeometry) {
      await windowManager.setPosition(Offset(x, y));
    }
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> _detectAndSetTvMode() async {
  if (!PlatformDetection.isAndroid) return;
  try {
    const channel = MethodChannel('org.moonfin.androidtv/platform');
    final isTV = await channel.invokeMethod<bool>('isTvDevice') ?? false;
    PlatformDetection.setTvMode(isTV);
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformDetection.isDesktop) {
    await windowManager.ensureInitialized();
  }

  _configureImageCache();
  MediaKit.ensureInitialized();

  await _detectAndSetTvMode();

  // On Linux the GTK font pipeline loads fonts asynchronously. The first frame
  // can render before MaterialIcons and other fonts are ready, causing icons to
  // appear blank. Pumping a warm-up frame gives the font loader time to finish.
  // The issue is intermittent and goes away on re-run once the OS font cache
  // is warm, which confirms the timing root cause.
  if (PlatformDetection.isLinux) {
    WidgetsBinding.instance.scheduleWarmUpFrame();
  }

  if (PlatformDetection.isMobile) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  await configureDependencies();

  if (PlatformDetection.isDesktop) {
    await _restoreWindowGeometry();
  }

  final notificationService = GetIt.instance<DownloadNotificationService>();
  try {
    await notificationService.initialize();
  } catch (_) {}

  if (PlatformDetection.isMobile) {
    try {
      await initAudioService(
        manager: GetIt.instance<PlaybackManager>(),
        clientFactory: GetIt.instance<MediaServerClientFactory>(),
      );
    } catch (_) {}
  }

  try {
    final session = await AudioSession.instance;
    final iosCategoryOptions =
        AVAudioSessionCategoryOptions.allowAirPlay |
        AVAudioSessionCategoryOptions.allowBluetooth |
        AVAudioSessionCategoryOptions.allowBluetoothA2dp;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: iosCategoryOptions,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
    ));
    await session.setActive(true);
  } catch (_) {}

  if (!GetIt.instance.isRegistered<PlaybackLifecycleHandler>()) {
    GetIt.instance.registerSingleton<PlaybackLifecycleHandler>(
      PlaybackLifecycleHandler(GetIt.instance<PlaybackManager>()),
    );
  }

  try {
    GetIt.instance<AirPlayCommandBridge>().start();
  } catch (_) {}

  runApp(const MoonfinApp());
}
