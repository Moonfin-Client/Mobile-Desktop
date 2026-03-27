// lib/src/rar_method_channel.dart
//
// MethodChannel implementation for the RAR plugin.
// Used on Android and iOS where native implementations communicate via platform channels.

import 'dart:io';

import 'package:flutter/services.dart';

import '../rar_platform_interface.dart';

/// Method channel implementation of [RarPlatform].
///
/// This implementation uses platform channels to communicate with the native
/// Android (JUnRar) and iOS (UnrarKit) implementations.
class RarMethodChannel extends RarPlatform {
  /// The method channel used to interact with the native platform.
  static const MethodChannel _channel = MethodChannel('com.lkrjangid.rar');

  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('extractRarFile', {
            'rarFilePath': rarFilePath,
            'destinationPath': destinationPath,
            'password': password,
          });

      return {
        'success': result?['success'] ?? false,
        'message': result?['message'] ?? 'Unknown error',
      };
    } on PlatformException catch (e) {
      return {'success': false, 'message': 'Platform error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) async {
    String? rarVersion;
    try {
      final file = File(rarFilePath);
      if (await file.exists()) {
        // Read enough bytes for the longest signature (8 bytes for RAR5)
        final handle = await file.open();
        final bytes = await handle.read(8);
        await handle.close();
        rarVersion = _detectRarVersion(bytes);
      }
    } catch (e) {
      // Ignore errors during version detection, it's an optional field
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'listRarContents',
        {'rarFilePath': rarFilePath, 'password': password},
      );

      return {
        'success': result?['success'] ?? false,
        'message': result?['message'] ?? 'Unknown error',
        'files': result?['files'] ?? <String>[],
        'rarVersion': rarVersion,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': 'Platform error: ${e.message}',
        'files': <String>[],
        'rarVersion': rarVersion,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'files': <String>[],
        'rarVersion': rarVersion,
      };
    }
  }

  String? _detectRarVersion(Uint8List data) {
    if (data.length >= 7) {
      final sig0 = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00];
      final sig1 = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00];
      bool matches(List<int> sig) {
        if (data.length < sig.length) return false;
        for (var i = 0; i < sig.length; i++) {
          if (data[i] != sig[i]) return false;
        }
        return true;
      }

      if (matches(sig1)) return 'RAR5';
      if (matches(sig0)) return 'RAR4';
    }
    return 'Unknown';
  }

  @override
  Future<Map<String, dynamic>> createRarArchive({
    required String outputPath,
    required List<String> sourcePaths,
    String? password,
    int compressionLevel = 5,
  }) async {
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('createRarArchive', {
            'outputPath': outputPath,
            'sourcePaths': sourcePaths,
            'password': password,
            'compressionLevel': compressionLevel,
          });

      return {
        'success': result?['success'] ?? false,
        'message': result?['message'] ?? 'Unknown error',
      };
    } on PlatformException catch (e) {
      return {'success': false, 'message': 'Platform error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
