// lib/rar.dart
//
// Main Dart plugin class for the RAR plugin.
// Provides a unified API for handling RAR files across all platforms:
// - Android (via JUnRar)
// - iOS/macOS (via UnrarKit)
// - Web (via WebAssembly with libarchive.js)

import 'rar_platform_interface.dart';

// Export platform interface for advanced users who may want to implement
// custom platform implementations or test mocks.
export 'rar_platform_interface.dart';

// Export web-specific implementation for direct use in web apps.
export 'src/rar_web_stub.dart' if (dart.library.js_interop) 'src/rar_web.dart';

/// A Flutter plugin for handling RAR archive files.
///
/// Supports:
/// - Extracting RAR files (v4 and v5 formats)
/// - Listing RAR archive contents
/// - Password-protected archives
///
/// Example usage:
/// ```dart
/// // Extract a RAR file
/// final result = await Rar.extractRarFile(
///   rarFilePath: '/path/to/archive.rar',
///   destinationPath: '/path/to/extract/to',
///   password: 'optional_password', // optional
/// );
///
/// if (result['success']) {
///   print('Extraction successful: ${result['message']}');
/// } else {
///   print('Extraction failed: ${result['message']}');
/// }
///
/// // List RAR contents
/// final listResult = await Rar.listRarContents(
///   rarFilePath: '/path/to/archive.rar',
/// );
///
/// if (listResult['success']) {
///   final files = listResult['files'] as List<String>;
///   print('Archive contains ${files.length} files');
///   for (final file in files) {
///     print('  - $file');
///   }
/// }
/// ```
class Rar {
  /// Extract a RAR file to a destination directory.
  ///
  /// [rarFilePath] - Path to the RAR file
  /// [destinationPath] - Directory where files will be extracted
  /// [password] - Optional password for encrypted RAR files
  ///
  /// Returns a map with:
  /// - 'success': bool - Whether the extraction was successful
  /// - 'message': String - Status message or error description
  ///
  /// Platform support:
  /// - Android: Full support via JUnRar (RAR v4/v5, passwords)
  /// - iOS/macOS: Full support via UnrarKit (RAR v4/v5, passwords)
  /// - Web: Support via WebAssembly (with some limitations on file system access)
  static Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) {
    return RarPlatform.instance.extractRarFile(
      rarFilePath: rarFilePath,
      destinationPath: destinationPath,
      password: password,
    );
  }

  /// Create a RAR archive from files or directories.
  ///
  /// **Note: RAR creation is NOT supported on any platform** due to RAR's
  /// proprietary compression algorithm licensing. Consider using ZIP format
  /// instead for archive creation.
  ///
  /// [outputPath] - Path where the RAR file will be created
  /// [sourcePaths] - List of file/directory paths to include in the archive
  /// [password] - Optional password to encrypt the RAR file
  /// [compressionLevel] - Optional compression level (0-9)
  ///
  /// Returns a map with:
  /// - 'success': false (always)
  /// - 'message': String - Error message explaining that RAR creation is unsupported
  static Future<Map<String, dynamic>> createRarArchive({
    required String outputPath,
    required List<String> sourcePaths,
    String? password,
    int compressionLevel = 5,
  }) {
    return RarPlatform.instance.createRarArchive(
      outputPath: outputPath,
      sourcePaths: sourcePaths,
      password: password,
      compressionLevel: compressionLevel,
    );
  }

  /// List contents of a RAR file.
  ///
  /// [rarFilePath] - Path to the RAR file
  /// [password] - Optional password for encrypted RAR files
  ///
  /// Returns a map with:
  /// - 'success': bool - Whether the listing was successful
  /// - 'message': String - Status message or error description
  /// - 'files': `List<String>` - List of file names in the archive (empty on failure)
  ///
  /// Platform support:
  /// - Android: Full support via JUnRar
  /// - iOS/macOS: Full support via UnrarKit
  /// - Web: Support via WebAssembly
  static Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) {
    return RarPlatform.instance.listRarContents(
      rarFilePath: rarFilePath,
      password: password,
    );
  }
}
