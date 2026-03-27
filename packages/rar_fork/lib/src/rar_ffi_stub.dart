// lib/src/rar_ffi_stub.dart
//
// Stub for FFI implementation on platforms where dart:ffi is not available (Web).

import '../rar_platform_interface.dart';

class RarFfi extends RarPlatform {
  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    throw UnimplementedError('FFI not supported on this platform');
  }

  @override
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) async {
    throw UnimplementedError('FFI not supported on this platform');
  }
}
