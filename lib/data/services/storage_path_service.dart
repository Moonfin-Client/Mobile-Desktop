import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import '../../preference/user_preferences.dart';
import '../../util/platform_detection.dart';

class StoragePathService {
  Directory? _cachedRoot;

  void clearCache() => _cachedRoot = null;

  Future<Directory> getOfflineRoot() async {
    if (_cachedRoot != null) return _cachedRoot!;

    if (PlatformDetection.isDesktop || Platform.isAndroid) {
      final prefs = GetIt.instance<UserPreferences>();
      final customPath = prefs.get(UserPreferences.customDownloadPath);
      if (customPath.isNotEmpty) {
        final dir = Directory(customPath);
        if (await dir.exists() || await _tryCreate(dir)) {
          _cachedRoot = dir;
          return dir;
        }
      }
    }

    Directory dir;
    if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      final base = extDir ?? await getApplicationDocumentsDirectory();
      dir = Directory('${base.path}/Moonfin');
    } else if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/Moonfin');
    } else {
      final support = await getApplicationSupportDirectory();
      dir = Directory('${support.path}/Downloads');
    }

    if (!await dir.exists()) await dir.create(recursive: true);
    _cachedRoot = dir;
    return dir;
  }

  Future<bool> _tryCreate(Directory dir) async {
    try {
      await dir.create(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<File> getDatabaseFile() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${docs.path}/Moonfin/DB');
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return File('${dbDir.path}/offline.db');
  }

  Future<Directory> getImageCacheDir() async {
    final root = await getOfflineRoot();
    final dir = Directory('${root.path}/images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
