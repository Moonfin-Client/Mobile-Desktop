// lib/src/rar_web_stub.dart
//
// Stub file for non-web platforms.
// The actual implementation is in rar_web.dart and only loaded on web.

import 'dart:typed_data';

/// Stub class for RarWeb on non-web platforms.
/// This provides the same static API so code can reference RarWeb
/// without conditional imports in application code.
class RarWeb {
  /// Store file data in the virtual file system (no-op on non-web).
  static void storeFileData(String path, Uint8List data) {
    // No-op on non-web platforms
  }

  /// Get file data from the virtual file system (returns null on non-web).
  static Uint8List? getFileData(String path) {
    return null;
  }

  /// Clear the virtual file system (no-op on non-web).
  static void clearFileSystem() {
    // No-op on non-web platforms
  }

  /// List all files in the virtual file system (returns empty on non-web).
  static List<String> listVirtualFiles() {
    return [];
  }
}
