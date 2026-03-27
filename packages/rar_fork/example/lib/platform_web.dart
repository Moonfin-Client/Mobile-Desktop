// example/lib/platform_web.dart
//
// Platform utilities for web platform.

import 'dart:typed_data';

import 'package:rar/rar.dart';

/// Get the platform name.
String getPlatformName() => 'Web (WASM)';

/// Request platform-specific permissions.
Future<void> requestPlatformPermissions() async {
  // Web platform doesn't need runtime permissions
}

/// Store file data in the web virtual file system.
void storeWebFileData(String name, Uint8List data) {
  RarWeb.storeFileData(name, data);
}

/// Create a directory at the given path (no-op on web).
Future<void> createDirectory(String path) async {
  // No-op on web - we use a virtual file system
}

/// List contents of the virtual file system.
Future<List<String>> listDirectoryContents(String path) async {
  // Return files that start with the given path prefix
  final allFiles = RarWeb.listVirtualFiles();
  final prefix = path.endsWith('/') ? path : '$path/';

  return allFiles
      .where((f) => f.startsWith(prefix))
      .map((f) => f.substring(prefix.length))
      .where((f) => f.isNotEmpty && !f.contains('/'))
      .toList()
    ..sort();
}

/// Load file content as bytes from virtual file system.
Future<Uint8List?> loadFileContent(String path) async {
  return RarWeb.getFileData(path);
}
