// test/rar_test.dart
//
// Unit tests for the main Rar class.
// These tests use mock implementations to verify the public API behavior.

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rar/rar.dart';
import 'package:rar/src/rar_method_channel.dart';

class MockRarPlatform extends RarPlatform with MockPlatformInterfaceMixin {
  bool extractCalled = false;
  bool listCalled = false;
  bool createCalled = false;

  String? lastRarFilePath;
  String? lastDestinationPath;
  String? lastPassword;

  bool shouldSucceed = true;
  List<String> mockFiles = ['file1.txt', 'file2.txt'];
  String errorMessage = 'Test error';

  void reset() {
    extractCalled = false;
    listCalled = false;
    createCalled = false;
    lastRarFilePath = null;
    lastDestinationPath = null;
    lastPassword = null;
    shouldSucceed = true;
    mockFiles = ['file1.txt', 'file2.txt'];
    errorMessage = 'Test error';
  }

  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    extractCalled = true;
    lastRarFilePath = rarFilePath;
    lastDestinationPath = destinationPath;
    lastPassword = password;

    if (shouldSucceed) {
      return {
        'success': true,
        'message': 'Extraction completed successfully',
      };
    } else {
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) async {
    listCalled = true;
    lastRarFilePath = rarFilePath;
    lastPassword = password;

    if (shouldSucceed) {
      return {
        'success': true,
        'message': 'Successfully listed RAR contents',
        'files': mockFiles,
      };
    } else {
      return {
        'success': false,
        'message': errorMessage,
        'files': <String>[],
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
    createCalled = true;
    return {
      'success': false,
      'message': 'RAR creation is not supported',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRarPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockRarPlatform();
    RarPlatform.instance = mockPlatform;
  });

  tearDown(() {
    RarPlatform.instance = RarMethodChannel();
  });

  group('Rar.extractRarFile', () {
    test('calls platform extractRarFile with correct parameters', () async {
      await Rar.extractRarFile(
        rarFilePath: '/path/to/archive.rar',
        destinationPath: '/path/to/destination',
        password: 'mypassword',
      );

      expect(mockPlatform.extractCalled, true);
      expect(mockPlatform.lastRarFilePath, '/path/to/archive.rar');
      expect(mockPlatform.lastDestinationPath, '/path/to/destination');
      expect(mockPlatform.lastPassword, 'mypassword');
    });

    test('returns success result on successful extraction', () async {
      final result = await Rar.extractRarFile(
        rarFilePath: '/path/to/archive.rar',
        destinationPath: '/path/to/destination',
      );

      expect(result['success'], true);
      expect(result['message'], 'Extraction completed successfully');
    });

    test('returns failure result on failed extraction', () async {
      mockPlatform.shouldSucceed = false;
      mockPlatform.errorMessage = 'File not found';

      final result = await Rar.extractRarFile(
        rarFilePath: '/nonexistent.rar',
        destinationPath: '/path/to/destination',
      );

      expect(result['success'], false);
      expect(result['message'], 'File not found');
    });

    test('handles null password', () async {
      await Rar.extractRarFile(
        rarFilePath: '/path/to/archive.rar',
        destinationPath: '/path/to/destination',
      );

      expect(mockPlatform.lastPassword, null);
    });
  });

  group('Rar.listRarContents', () {
    test('calls platform listRarContents with correct parameters', () async {
      await Rar.listRarContents(
        rarFilePath: '/path/to/archive.rar',
        password: 'secret',
      );

      expect(mockPlatform.listCalled, true);
      expect(mockPlatform.lastRarFilePath, '/path/to/archive.rar');
      expect(mockPlatform.lastPassword, 'secret');
    });

    test('returns file list on success', () async {
      mockPlatform.mockFiles = ['doc.pdf', 'image.png', 'folder/file.txt'];

      final result = await Rar.listRarContents(
        rarFilePath: '/path/to/archive.rar',
      );

      expect(result['success'], true);
      expect(result['files'], isA<List>());
      expect((result['files'] as List).length, 3);
      expect(result['files'], contains('doc.pdf'));
    });

    test('returns empty list on failure', () async {
      mockPlatform.shouldSucceed = false;
      mockPlatform.errorMessage = 'Invalid archive';

      final result = await Rar.listRarContents(
        rarFilePath: '/path/to/invalid.rar',
      );

      expect(result['success'], false);
      expect(result['files'], isEmpty);
      expect(result['message'], 'Invalid archive');
    });
  });

  group('Rar.createRarArchive', () {
    test('always returns unsupported', () async {
      final result = await Rar.createRarArchive(
        outputPath: '/path/to/output.rar',
        sourcePaths: ['/file1.txt', '/file2.txt'],
      );

      expect(result['success'], false);
      expect(result['message'], contains('not supported'));
    });
  });

  group('Error scenarios', () {
    test('handles password-protected archive without password', () async {
      mockPlatform.shouldSucceed = false;
      mockPlatform.errorMessage = 'Incorrect password or password required';

      final result = await Rar.extractRarFile(
        rarFilePath: '/path/to/encrypted.rar',
        destinationPath: '/path/to/destination',
      );

      expect(result['success'], false);
      expect(result['message'], contains('password'));
    });

    test('handles corrupt archive', () async {
      mockPlatform.shouldSucceed = false;
      mockPlatform.errorMessage = 'Corrupt or invalid RAR archive';

      final result = await Rar.listRarContents(
        rarFilePath: '/path/to/corrupt.rar',
      );

      expect(result['success'], false);
      expect(result['message'], contains('Corrupt'));
    });
  });
}
