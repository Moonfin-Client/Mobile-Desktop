// example/lib/platform_io.dart
//
// Platform utilities for non-web platforms (mobile and desktop).

import 'dart:io';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';

/// Get the platform name.
String getPlatformName() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isLinux) return 'Linux (Desktop FFI)';
  if (Platform.isMacOS) return 'macOS (Desktop FFI)';
  if (Platform.isWindows) return 'Windows (Desktop FFI)';
  return Platform.operatingSystem;
}

/// Request platform-specific permissions.
Future<void> requestPlatformPermissions() async {
  if (Platform.isAndroid) {
    // Request storage permissions on Android
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // For Android 11+, also request manage external storage if needed
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }
  // iOS, desktop platforms don't typically need runtime permissions
  // for file access in documents directory
}

/// Store file data for web platform (no-op on native platforms).
void storeWebFileData(String name, Uint8List data) {
  // No-op on native platforms - files are accessed directly from filesystem
}

/// Create a directory at the given path.
Future<void> createDirectory(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

/// List contents of a directory.
Future<List<String>> listDirectoryContents(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    return [];
  }

  final entities = await dir.list(recursive: false).toList();
  return entities.map((e) {
    final name = e.path.split(Platform.pathSeparator).last;
    return e is Directory ? '$name/' : name;
  }).toList()..sort();
}

/// Load file content as bytes.
Future<Uint8List?> loadFileContent(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    return null;
  }
  try {
    return await file.readAsBytes();
  } catch (e) {
    return null;
  }
}
