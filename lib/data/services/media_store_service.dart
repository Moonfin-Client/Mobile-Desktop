import 'package:flutter/services.dart';

class MediaStoreService {
  static const _channel = MethodChannel('com.moonfin/media_store');

  /// Returns the base path for MediaStore downloads: `/storage/emulated/0/Download/Moonfin`
  static Future<String> getMediaStorePath() async {
    final path = await _channel.invokeMethod<String>('getMediaStorePath');
    return path!;
  }

  /// Creates a MediaStore entry and returns the absolute file path to write to.
  static Future<String> getDownloadPath({
    required String fileName,
    String relativePath = '',
  }) async {
    final path = await _channel.invokeMethod<String>('getDownloadPath', {
      'fileName': fileName,
      'relativePath': relativePath,
    });
    return path!;
  }
}
