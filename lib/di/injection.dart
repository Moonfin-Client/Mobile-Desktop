import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart' as pkg;
import 'package:server_core/server_core.dart';
import 'package:uuid/uuid.dart';

import '../auth/store/authentication_store.dart';
import '../data/database/database_connection.dart';
import '../data/database/offline_database.dart';
import '../data/repositories/offline_repository.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/storage_path_service.dart';
import '../preference/user_preferences.dart';
import '../util/platform_detection.dart';
import 'modules/app_module.dart';
import 'modules/auth_module.dart';
import 'modules/server_module.dart';
import 'modules/playback_module.dart';
import 'modules/preference_module.dart';

final getIt = GetIt.instance;

String _clientName() {
  if (PlatformDetection.isAndroid) return 'Moonfin for Android';
  if (PlatformDetection.isIOS) return 'Moonfin for iOS';
  if (PlatformDetection.isMacOS) return 'Moonfin for macOS';
  if (PlatformDetection.isWindows) return 'Moonfin for Windows';
  if (PlatformDetection.isLinux) return 'Moonfin for Linux';
  return 'Moonfin';
}

String _joinNonEmpty(List<String?> parts, String separator) {
  return parts
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(separator);
}

String _fallbackIfEmpty(String value, String fallback) {
  return value.trim().isEmpty ? fallback : value.trim();
}

String _resolveAndroidDeviceName(AndroidDeviceInfo info) {
  final manufacturer = info.manufacturer.trim();
  final model = info.model.trim();
  final brand = info.brand.trim();

  // Prefer the reported model first. On modern phones this is typically
  // the user-friendly marketing name, e.g. "Pixel 9 Pro XL".
  if (model.isNotEmpty && model.toLowerCase() != 'unknown') {
    final lowerModel = model.toLowerCase();
    final lowerManufacturer = manufacturer.toLowerCase();

    // Avoid repeating manufacturer when model already includes it.
    if (manufacturer.isNotEmpty && !lowerModel.startsWith(lowerManufacturer)) {
      return '$manufacturer $model';
    }

    return model;
  }

  // Fallback path for devices that do not expose a useful model string.
  final combined = _joinNonEmpty([manufacturer, brand, info.device, info.product], ' ');
  return _fallbackIfEmpty(combined, 'Android Device');
}

Future<String> _resolveDeviceName() async {
  final deviceInfo = DeviceInfoPlugin();

  try {
    if (PlatformDetection.isAndroid) {
      final info = await deviceInfo.androidInfo;
      final name = _resolveAndroidDeviceName(info);
      if (!info.isPhysicalDevice) {
        return '$name (emulator)';
      }
      return name;
    }

    if (PlatformDetection.isIOS) {
      final info = await deviceInfo.iosInfo;
      final marketingName = _joinNonEmpty([info.name, info.model], ' ');
      return _fallbackIfEmpty(marketingName, 'iPhone');
    }

    if (PlatformDetection.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      return _fallbackIfEmpty(_joinNonEmpty([info.computerName, info.model], ' '), 'Mac');
    }

    if (PlatformDetection.isWindows) {
      final info = await deviceInfo.windowsInfo;
      return _fallbackIfEmpty(_joinNonEmpty([info.computerName, info.productName], ' '), 'Windows PC');
    }

    if (PlatformDetection.isLinux) {
      final info = await deviceInfo.linuxInfo;
      return _fallbackIfEmpty(_joinNonEmpty([info.name, info.prettyName], ' '), 'Linux Device');
    }
  } catch (_) {
    // Fall through to app-based fallback below.
  }

  return _clientName();
}

Future<String> _resolveAppVersion() async {
  try {
    final info = await pkg.PackageInfo.fromPlatform();
    return info.version.trim().isNotEmpty ? info.version.trim() : '0.1.0';
  } catch (_) {
    return '0.1.0';
  }
}

Future<void> _migrateLegacyBitrateCap(PreferenceStore store) async {
  const migrationKey = 'pref_max_bitrate_migrated_v2';
  if (store.getBool(migrationKey) == true) {
    return;
  }

  final current = store.getString(UserPreferences.maxBitrate.key);
  if (current == '100') {
    await store.setString(
      UserPreferences.maxBitrate.key,
      UserPreferences.maxBitrate.defaultValue,
    );
  }

  await store.setBool(migrationKey, true);
}

Future<void> configureDependencies() async {
  final preferenceStore = PreferenceStore();
  await preferenceStore.init();
  await _migrateLegacyBitrateCap(preferenceStore);

  var deviceId = preferenceStore.getString('device_id');
  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await preferenceStore.setString('device_id', deviceId);
  }

  final clientName = _clientName();
  final deviceName = await _resolveDeviceName();
  final appVersion = await _resolveAppVersion();
  getIt.registerSingleton<DeviceInfo>(DeviceInfo(
    id: deviceId,
    name: deviceName,
    appName: clientName,
    appVersion: appVersion,
  ));

  registerPreferenceModule(preferenceStore);

  final storagePath = StoragePathService();
  getIt.registerSingleton<StoragePathService>(storagePath);
  getIt.registerSingleton<OfflineDatabase>(
    OfflineDatabase(openConnection(() => storagePath.getDatabaseFile())),
  );
  getIt.registerSingleton<OfflineRepository>(
    OfflineRepository(getIt<OfflineDatabase>()),
  );

  final connectivityService = ConnectivityService();
  connectivityService.initialize();
  getIt.registerSingleton<ConnectivityService>(connectivityService);

  registerServerModule();
  registerAuthModule();
  await getIt<AuthenticationStore>().init();
  registerPlaybackModule();
  registerAppModule();
}
