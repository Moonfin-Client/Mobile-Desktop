// test/rar_platform_interface_test.dart
//
// Unit tests for the RAR platform interface.
// These tests verify that the platform interface contract is properly defined
// and that the default implementation is correctly set up.

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rar/rar_platform_interface.dart';
import 'package:rar/src/rar_method_channel.dart';

class MockRarPlatform extends RarPlatform with MockPlatformInterfaceMixin {
  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    return {'success': true, 'message': 'Mock extraction completed'};
  }

  @override
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) async {
    return {
      'success': true,
      'message': 'Mock listing completed',
      'files': ['file1.txt', 'file2.txt', 'folder/file3.txt'],
    };
  }

  @override
  Future<Map<String, dynamic>> createRarArchive({
    required String outputPath,
    required List<String> sourcePaths,
    String? password,
    int compressionLevel = 5,
  }) async {
    return {'success': false, 'message': 'RAR creation is not supported'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RarPlatform', () {
    test('default instance is RarMethodChannel', () {
      expect(RarPlatform.instance, isA<RarMethodChannel>());
    });

    test('can set custom instance', () {
      final mock = MockRarPlatform();
      RarPlatform.instance = mock;
      expect(RarPlatform.instance, mock);

      // Reset to default
      RarPlatform.instance = RarMethodChannel();
    });
  });

  group('MockRarPlatform', () {
    late MockRarPlatform platform;

    setUp(() {
      platform = MockRarPlatform();
      RarPlatform.instance = platform;
    });

    tearDown(() {
      RarPlatform.instance = RarMethodChannel();
    });

    test('extractRarFile returns success', () async {
      final result = await platform.extractRarFile(
        rarFilePath: '/test/archive.rar',
        destinationPath: '/test/output',
      );

      expect(result['success'], true);
      expect(result['message'], 'Mock extraction completed');
    });

    test('extractRarFile with password', () async {
      final result = await platform.extractRarFile(
        rarFilePath: '/test/archive.rar',
        destinationPath: '/test/output',
        password: 'secret',
      );

      expect(result['success'], true);
    });

    test('listRarContents returns file list', () async {
      final result = await platform.listRarContents(
        rarFilePath: '/test/archive.rar',
      );

      expect(result['success'], true);
      expect(result['files'], isA<List>());
      expect((result['files'] as List).length, 3);
    });

    test('listRarContents with password', () async {
      final result = await platform.listRarContents(
        rarFilePath: '/test/archive.rar',
        password: 'secret',
      );

      expect(result['success'], true);
      expect(result['files'], contains('file1.txt'));
    });

    test('createRarArchive returns unsupported', () async {
      final result = await platform.createRarArchive(
        outputPath: '/test/output.rar',
        sourcePaths: ['/test/file1.txt'],
      );

      expect(result['success'], false);
      expect(result['message'], contains('not supported'));
    });
  });
}
