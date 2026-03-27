// lib/rar_platform_interface.dart
//
// Platform interface for the RAR plugin.
// This defines the contract that all platform implementations must follow.
// Uses the plugin_platform_interface package for proper platform registration.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/rar_ffi.dart' if (dart.library.js_interop) 'src/rar_ffi_stub.dart';
import 'src/rar_method_channel.dart';

/// The interface that implementations of rar must implement.
///
/// Platform implementations should extend this class rather than implement it
/// as `rar` does not consider newly added methods to be breaking changes.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
/// this interface will be broken by newly added [RarPlatform] methods.
abstract class RarPlatform extends PlatformInterface {
  /// Constructs a RarPlatform.
  RarPlatform() : super(token: _token);

  static final Object _token = Object();

  static RarPlatform _instance = _createDefaultInstance();

  static RarPlatform _createDefaultInstance() {
    if (!kIsWeb && Platform.isAndroid) {
      return RarFfi();
    }
    return RarMethodChannel();
  }

  /// The default instance of [RarPlatform] to use.
  ///
  /// Defaults to [RarMethodChannel] for iOS/macOS and [RarFfi] for Android.
  static RarPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RarPlatform] when they register
  /// themselves.
  static set instance(RarPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Extract a RAR file to a destination directory.
  ///
  /// [rarFilePath] - Path to the RAR file
  /// [destinationPath] - Directory where files will be extracted
  /// [password] - Optional password for encrypted RAR files
  ///
  /// Returns a map with:
  /// - 'success': bool - Whether the extraction was successful
  /// - 'message': String - Status message or error description
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) {
    throw UnimplementedError('extractRarFile() has not been implemented.');
  }

  /// List contents of a RAR file.
  ///
  /// [rarFilePath] - Path to the RAR file
  /// [password] - Optional password for encrypted RAR files
  ///
  /// Returns a map with:
  /// - 'success': bool - Whether the listing was successful
  /// - 'message': String - Status message or error description
  /// - 'files': `List<String>` - List of file names in the archive
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) {
    throw UnimplementedError('listRarContents() has not been implemented.');
  }

  /// Create a RAR archive from files or directories.
  ///
  /// Note: RAR creation is not supported on most platforms due to licensing
  /// restrictions. This method exists for API completeness but will typically
  /// return an error indicating the feature is unsupported.
  ///
  /// [outputPath] - Path where the RAR file will be created
  /// [sourcePaths] - List of file/directory paths to include in the archive
  /// [password] - Optional password to encrypt the RAR file
  /// [compressionLevel] - Optional compression level (0-9)
  ///
  /// Returns a map with:
  /// - 'success': bool - Whether the creation was successful
  /// - 'message': String - Status message or error description
  Future<Map<String, dynamic>> createRarArchive({
    required String outputPath,
    required List<String> sourcePaths,
    String? password,
    int compressionLevel = 5,
  }) {
    throw UnimplementedError('createRarArchive() has not been implemented.');
  }
}
