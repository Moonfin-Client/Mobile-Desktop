import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rar/rar.dart';
import 'package:rar_example/platform_stub.dart'
    if (dart.library.io) 'package:rar_example/platform_io.dart'
    if (dart.library.html) 'package:rar_example/platform_web.dart';

class ArchiveResult {
  final bool isSuccess;
  final String? errorMessage;
  final List<String> files;
  final String? rarVersion;
  final String? archiveName;
  final String? extractPath;

  ArchiveResult({
    required this.isSuccess,
    this.errorMessage,
    this.files = const [],
    this.rarVersion,
    this.archiveName,
    this.extractPath,
  });
}

class ArchiveService {
  Future<ArchiveResult?> pickAndOpenArchive({
    String? testExtractPath,
    String? password,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['rar', 'cbr'],
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    String? filePath = file.path;

    // Handle Web
    if (kIsWeb) {
      if (file.bytes == null) {
        return ArchiveResult(
          isSuccess: false,
          errorMessage: 'Could not read file data',
        );
      }
      storeWebFileData(file.name, file.bytes!);
      filePath = file.name;
    }

    if (filePath == null) {
      return ArchiveResult(isSuccess: false, errorMessage: 'Invalid file path');
    }

    // Get extraction path
    String extractPath;
    if (testExtractPath != null) {
      extractPath = testExtractPath;
    } else if (kIsWeb) {
      extractPath = '/extracted';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      extractPath = '${directory.path}/rar_extracted';
      await createDirectory(extractPath);
    }

    // Extract
    final extractResult = await Rar.extractRarFile(
      rarFilePath: filePath,
      destinationPath: extractPath,
      password: password,
    );

    if (extractResult['success'] != true) {
      // Try listing if extraction fails
      final listResult = await Rar.listRarContents(
        rarFilePath: filePath,
        password: password,
      );

      if (listResult['success'] == true) {
        return ArchiveResult(
          isSuccess: true,
          files: List<String>.from(listResult['files'] as List),
          rarVersion: listResult['rarVersion'] as String?,
          archiveName: file.name,
          errorMessage: extractResult['message']?.toString(), // Warning
        );
      }

      return ArchiveResult(
        isSuccess: false,
        errorMessage: extractResult['message'] ?? 'Failed to open archive',
      );
    }

    // List extracted files
    // We use listDirectoryContents from platform utils to get actual files on disk/virtual fs
    final diskFiles = await listDirectoryContents(extractPath);

    // Also get metadata from RAR
    final listResult = await Rar.listRarContents(
      rarFilePath: filePath,
      password: password,
    );

    List<String> files;
    String? rarVersion;

    if (listResult['success'] == true) {
      files = List<String>.from(listResult['files'] as List);
      rarVersion = listResult['rarVersion'] as String?;
    } else {
      files = diskFiles;
    }

    return ArchiveResult(
      isSuccess: true,
      files: files,
      rarVersion: rarVersion,
      archiveName: file.name,
      extractPath: extractPath,
    );
  }

  Future<Uint8List?> loadContent(String path) {
    return loadFileContent(path);
  }

  Future<void> requestPermissions() {
    return requestPlatformPermissions();
  }
}
