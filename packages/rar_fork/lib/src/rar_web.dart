// lib/src/rar_web.dart
//
// Web implementation of the RAR plugin using JS interop.
// Communicates with JavaScript/WASM-based RAR extraction library.
//
// WASM Library: libarchive.js (BSD License)
// This library provides archive handling capabilities including RAR support
// compiled from libarchive to WebAssembly.
//
// Web Platform Limitations:
// - File paths refer to in-memory data or virtual file system paths
// - Extraction returns file data that must be handled by the application
// - No direct file system access (browser security restrictions)

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../rar_platform_interface.dart';

/// JavaScript interop types for the RAR WASM library.
///
/// These types map to the JavaScript API exposed by rar_web.js

/// Result of a RAR operation from JavaScript.
extension type RarResult._(JSObject _) implements JSObject {
  external bool get success;
  external String get message;
  external JSArray<JSString>? get files;
  external JSArray<RarFileEntry>? get entries;
}

/// A file entry returned from extraction.
extension type RarFileEntry._(JSObject _) implements JSObject {
  external String get name;
  external JSUint8Array get data;
  external int get size;
}

/// JavaScript API exposed by rar_web.js
@JS('RarWeb')
extension type RarWebJS._(JSObject _) implements JSObject {
  /// Initialize the WASM library. Must be called before other operations.
  external static JSPromise<JSBoolean> init();

  /// List contents of a RAR archive from bytes.
  external static JSPromise<RarResult> listFromBytes(
    JSUint8Array data,
    JSString? password,
  );

  /// Extract a RAR archive from bytes.
  /// Returns file entries with name and data for each extracted file.
  external static JSPromise<RarResult> extractFromBytes(
    JSUint8Array data,
    JSString? password,
  );

  /// Check if the library is initialized.
  external static bool get isInitialized;
}

/// Web implementation of [RarPlatform] using JavaScript interop.
///
/// This implementation uses a WASM-based RAR library loaded via JavaScript.
/// Due to browser security restrictions, this implementation works with
/// in-memory data rather than file system paths.
///
/// Usage on Web:
/// - For listing: Pass a path that the app can resolve to bytes, or use
///   the web-specific API to pass bytes directly.
/// - For extraction: Extracted files are returned as in-memory data that
///   the application must handle (e.g., trigger downloads, store in IndexedDB).
class RarWeb extends RarPlatform {
  static bool _initialized = false;

  /// Registers this class as the default instance of [RarPlatform] for web.
  static void registerWith([Object? registrar]) {
    RarPlatform.instance = RarWeb();
  }

  /// Ensure the WASM library is initialized.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // Check if RarWeb is already loaded
    if (!_isRarWebLoaded) {
      await _injectRarWebScript();
    }

    try {
      final result = await RarWebJS.init().toDart;
      _initialized = result.toDart;
      if (!_initialized) {
        throw Exception('Failed to initialize RAR WASM library');
      }
    } catch (e) {
      throw Exception('Error initializing RAR WASM library: $e');
    }
  }

  bool get _isRarWebLoaded {
    return web.window.has('RarWeb');
  }

  Future<void> _injectRarWebScript() async {
    final completer = Completer<void>();
    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    // Try to load from the package assets
    // Note: In debug builds, this might need adjustment depending on how assets are served
    script.src = 'assets/packages/rar/web/rar_web.js';
    script.type = 'text/javascript';

    script.onload = (web.Event e) {
      completer.complete();
    }.toJS;

    script.onerror = (web.Event e) {
      completer.completeError(Exception('Failed to load rar_web.js'));
    }.toJS;

    web.document.head?.appendChild(script);
    await completer.future;
  }

  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    try {
      await _ensureInitialized();

      // On web, we need to load the file data first
      // The rarFilePath on web is expected to be handled by the JS layer
      // which may load it from various sources (fetch, File API, etc.)
      final data = await _loadFileData(rarFilePath);
      if (data == null) {
        return {
          'success': false,
          'message': 'Failed to load RAR file: $rarFilePath',
        };
      }

      final jsData = data.toJS;
      final jsPassword = password?.toJS;

      final result = await RarWebJS.extractFromBytes(jsData, jsPassword).toDart;

      if (result.success) {
        // On web, we store extracted files in a virtual location
        // or trigger downloads depending on the implementation
        final entries = result.entries;
        if (entries != null) {
          final entriesList = entries.toDart;
          final fileCount = entriesList.length;
          // Store in web storage or make available for download
          await _storeExtractedFiles(destinationPath, entries);
          return {
            'success': true,
            'message': 'Extraction completed successfully ($fileCount files)',
          };
        }
        return {'success': true, 'message': result.message};
      } else {
        return {'success': false, 'message': result.message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Web extraction error: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) async {
    try {
      await _ensureInitialized();

      // Load file data
      final data = await _loadFileData(rarFilePath);
      if (data == null) {
        return {
          'success': false,
          'message': 'Failed to load RAR file: $rarFilePath',
          'files': <String>[],
        };
      }

      final rarVersion = _detectRarVersion(data);

      final jsData = data.toJS;
      final jsPassword = password?.toJS;

      final result = await RarWebJS.listFromBytes(jsData, jsPassword).toDart;

      if (result.success) {
        final jsFiles = result.files;
        final files = jsFiles != null
            ? jsFiles.toDart.map((f) => f.toDart).toList()
            : <String>[];
        return {
          'success': true,
          'message': result.message,
          'files': files,
          'rarVersion': rarVersion,
        };
      } else {
        return {
          'success': false,
          'message': result.message,
          'files': <String>[],
          'rarVersion': rarVersion,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Web listing error: $e',
        'files': <String>[],
        'rarVersion': null,
      };
    }
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
      'message':
          'RAR creation is not supported on web. Consider using ZIP format instead.',
    };
  }

  /// Load file data from a path or URL.
  /// On web, this may fetch from a URL or read from the virtual file system.
  Future<Uint8List?> _loadFileData(String path) async {
    try {
      // Check if we have file data stored in the virtual file system
      final cachedData = _virtualFileSystem[path];
      if (cachedData != null) {
        return cachedData;
      }

      // Try to fetch from URL if it looks like a URL
      if (path.startsWith('http://') ||
          path.startsWith('https://') ||
          path.startsWith('blob:')) {
        return await _fetchFromUrl(path);
      }

      // If we have a registered file loader, use it
      if (_fileLoader != null) {
        return await _fileLoader!(path);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch file data from a URL using the Fetch API.
  Future<Uint8List?> _fetchFromUrl(String url) async {
    try {
      final response = await _jsFetch(url.toJS).toDart;
      if (!response.ok) {
        return null;
      }
      final arrayBuffer = await response.arrayBuffer().toDart;
      return Uint8List.view(arrayBuffer.toDart);
    } catch (e) {
      return null;
    }
  }

  /// Store extracted files in web storage or virtual file system.
  Future<void> _storeExtractedFiles(
    String basePath,
    JSArray<RarFileEntry> entries,
  ) async {
    final entriesList = entries.toDart;
    for (var i = 0; i < entriesList.length; i++) {
      final entry = entriesList[i];
      final fullPath = '$basePath/${entry.name}';
      _virtualFileSystem[fullPath] = entry.data.toDart;
    }
  }

  // Virtual file system for web platform
  static final Map<String, Uint8List> _virtualFileSystem = {};

  // Optional custom file loader
  static Future<Uint8List?> Function(String path)? _fileLoader;

  /// Register a custom file loader for web platform.
  /// This allows the application to provide file data from various sources
  /// (File picker, drag-and-drop, etc.).
  static void registerFileLoader(
    Future<Uint8List?> Function(String path) loader,
  ) {
    _fileLoader = loader;
  }

  /// Store file data in the virtual file system.
  /// Use this to make file data available for RAR operations.
  static void storeFileData(String path, Uint8List data) {
    _virtualFileSystem[path] = data;
  }

  /// Get file data from the virtual file system.
  /// Returns null if the file is not found.
  static Uint8List? getFileData(String path) {
    return _virtualFileSystem[path];
  }

  /// Clear the virtual file system.
  static void clearFileSystem() {
    _virtualFileSystem.clear();
  }

  /// List all files in the virtual file system.
  static List<String> listVirtualFiles() {
    return _virtualFileSystem.keys.toList();
  }

  String? _detectRarVersion(Uint8List data) {
    if (data.length >= 8) {
      final sig0 = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00];
      final sig1 = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00];
      bool matches(List<int> sig) {
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
}

/// JavaScript Fetch API interop
@JS('fetch')
external JSPromise<_FetchResponse> _jsFetch(JSString url);

extension type _FetchResponse._(JSObject _) implements JSObject {
  external bool get ok;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}
