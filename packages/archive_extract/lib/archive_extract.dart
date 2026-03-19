import 'package:flutter/services.dart';

class ArchiveExtract {
  static const MethodChannel _channel =
      MethodChannel('com.moonfin.archive_extract');

  static Future<List<String>> extract7z({
    required String archivePath,
    required String destinationPath,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('extract7z', {
      'archivePath': archivePath,
      'destinationPath': destinationPath,
    });
    return result?.cast<String>() ?? [];
  }

  static Future<bool> get isSupported async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
