// lib/src/rar_ffi.dart
//
// FFI implementation for RAR operations.
// Used on Android and Desktop platforms.

import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../rar_platform_interface.dart';

// FFI typedefs
typedef RarExtractC =
    Int32 Function(
      Pointer<Utf8> rarPath,
      Pointer<Utf8> destPath,
      Pointer<Utf8> password,
      Pointer<NativeFunction<RarErrorCallbackC>> errorCb,
    );

typedef RarExtractDart =
    int Function(
      Pointer<Utf8> rarPath,
      Pointer<Utf8> destPath,
      Pointer<Utf8> password,
      Pointer<NativeFunction<RarErrorCallbackC>> errorCb,
    );

typedef RarListC =
    Int32 Function(
      Pointer<Utf8> rarPath,
      Pointer<Utf8> password,
      Pointer<NativeFunction<RarListCallbackC>> listCb,
      Pointer<NativeFunction<RarErrorCallbackC>> errorCb,
    );

typedef RarListDart =
    int Function(
      Pointer<Utf8> rarPath,
      Pointer<Utf8> password,
      Pointer<NativeFunction<RarListCallbackC>> listCb,
      Pointer<NativeFunction<RarErrorCallbackC>> errorCb,
    );

typedef RarGetErrorMessageC = Pointer<Utf8> Function(Int32 errorCode);
typedef RarGetErrorMessageDart = Pointer<Utf8> Function(int errorCode);

typedef RarListCallbackC = Void Function(Pointer<Utf8> filename);
typedef RarErrorCallbackC = Void Function(Pointer<Utf8> error);

// Global library reference
DynamicLibrary? _lib;

DynamicLibrary get _library {
  if (_lib != null) return _lib!;

  if (Platform.isAndroid) {
    _lib = DynamicLibrary.open('librar_native.so');
  } else if (Platform.isLinux) {
    _lib = DynamicLibrary.open('librar_native.so');
  } else if (Platform.isWindows) {
    _lib = DynamicLibrary.open('rar_native.dll');
  } else if (Platform.isMacOS) {
    try {
      _lib = DynamicLibrary.open('librar_native.dylib');
    } catch (e) {
      _lib = DynamicLibrary.process();
    }
  } else {
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }
  return _lib!;
}

// Global list for the current isolate to store files during listing
List<String>? _isolateFileList;

// Static callback function for FFI
void _isolateListCallback(Pointer<Utf8> filename) {
  _isolateFileList?.add(filename.toDartString());
}

class RarFfi extends RarPlatform {
  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    return Isolate.run(() {
      final lib = _library;
      final extractFunc = lib.lookupFunction<RarExtractC, RarExtractDart>(
        'rar_extract',
      );
      final getErrorFunc = lib
          .lookupFunction<RarGetErrorMessageC, RarGetErrorMessageDart>(
            'rar_get_error_message',
          );

      final rarPathPtr = rarFilePath.toNativeUtf8();
      final destPathPtr = destinationPath.toNativeUtf8();
      final passwordPtr = password?.toNativeUtf8() ?? nullptr;

      // We can't easily pass a Dart callback to C when running in Isolate.run
      // without NativeCallable.listener, but here we just need the return code.
      // For detailed errors, we rely on the return code and get_error_message.

      try {
        final result = extractFunc(
          rarPathPtr,
          destPathPtr,
          passwordPtr,
          nullptr,
        );

        if (result == 0) {
          return {
            'success': true,
            'message': 'Extraction completed successfully',
          };
        } else {
          final errorMsgPtr = getErrorFunc(result);
          final errorMsg = errorMsgPtr.toDartString();
          return {'success': false, 'message': errorMsg};
        }
      } finally {
        calloc.free(rarPathPtr);
        calloc.free(destPathPtr);
        if (passwordPtr != nullptr) calloc.free(passwordPtr);
      }
    });
  }

  @override
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) async {
    // We need to use a port to receive callbacks from the isolate
    final receivePort = ReceivePort();

    await Isolate.spawn(_listRarContentsIsolate, [
      receivePort.sendPort,
      rarFilePath,
      password,
    ]);

    final result = await receivePort.first as Map<String, dynamic>;
    return result;
  }

  static void _listRarContentsIsolate(List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final rarFilePath = args[1] as String;
    final password = args[2] as String?;

    try {
      final lib = _library;
      final listFunc = lib.lookupFunction<RarListC, RarListDart>('rar_list');
      final getErrorFunc = lib
          .lookupFunction<RarGetErrorMessageC, RarGetErrorMessageDart>(
            'rar_get_error_message',
          );

      final rarPathPtr = rarFilePath.toNativeUtf8();
      final passwordPtr = password?.toNativeUtf8() ?? nullptr;

      // Initialize the static list for this isolate
      _isolateFileList = <String>[];

      // Use Pointer.fromFunction for synchronous callback
      final listCallback = Pointer.fromFunction<RarListCallbackC>(
        _isolateListCallback,
      );

      try {
        final result = listFunc(rarPathPtr, passwordPtr, listCallback, nullptr);

        if (result == 0) {
          sendPort.send({
            'success': true,
            'message': 'Successfully listed RAR contents',
            'files': _isolateFileList, // Send the populated list
            'rarVersion': _detectRarVersion(rarFilePath),
          });
        } else {
          final errorMsgPtr = getErrorFunc(result);
          final errorMsg = errorMsgPtr.toDartString();
          sendPort.send({
            'success': false,
            'message': errorMsg,
            'files': <String>[],
            'rarVersion': _detectRarVersion(rarFilePath),
          });
        }
      } finally {
        calloc.free(rarPathPtr);
        if (passwordPtr != nullptr) calloc.free(passwordPtr);
        _isolateFileList = null; // Cleanup
      }
    } catch (e) {
      dev.log('Error in isolate: $e');
      sendPort.send({
        'success': false,
        'message': 'Error: $e',
        'files': <String>[],
      });
    }
  }

  static String? _detectRarVersion(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final bytes = file.openSync().readSync(8);

      if (bytes.length >= 7) {
        final sig0 = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00];
        final sig1 = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00];

        bool matches(List<int> sig) {
          if (bytes.length < sig.length) return false;
          for (var i = 0; i < sig.length; i++) {
            if (bytes[i] != sig[i]) return false;
          }
          return true;
        }

        if (matches(sig1)) return 'RAR5';
        if (matches(sig0)) return 'RAR4';
      }
    } catch (e) {
      // Ignore
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
    return {
      'success': false,
      'message': 'RAR creation is not supported on this platform',
    };
  }
}
