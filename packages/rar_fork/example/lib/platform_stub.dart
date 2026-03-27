// example/lib/platform_stub.dart
//
// Stub implementation for platform utilities.
// This file is used when the actual platform cannot be determined.

import 'dart:typed_data';

/// Get the platform name.
String getPlatformName() => 'Unknown';

/// Request platform-specific permissions.
Future<void> requestPlatformPermissions() async {}

/// Store file data for web platform (no-op on other platforms).
void storeWebFileData(String name, Uint8List data) {}

/// Create a directory at the given path.
Future<void> createDirectory(String path) async {}

/// List contents of a directory.
Future<List<String>> listDirectoryContents(String path) async => [];

/// Load file content as bytes.
Future<Uint8List?> loadFileContent(String path) async => null;
