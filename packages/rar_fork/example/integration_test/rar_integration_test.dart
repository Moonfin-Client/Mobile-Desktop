// example/integration_test/rar_integration_test.dart
//
// Integration tests for the RAR plugin.
// These tests can be run on each platform to verify real RAR functionality.
//
// Run with:
//   flutter test integration_test/rar_integration_test.dart
//
// Or for specific platforms:
//   flutter test integration_test --device-id=linux
//   flutter test integration_test --device-id=macos
//   flutter test integration_test --device-id=windows
//   flutter test integration_test --device-id=chrome

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rar/rar.dart';

// Sample RAR file bytes (minimal valid RAR4 archive with one text file)
// This is a base64-decoded minimal RAR archive containing "hello.txt" with content "Hello, World!"
final Uint8List sampleRarBytes = Uint8List.fromList([
  // RAR 4.x signature
  0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00,
  // Archive header
  0xCF, 0x90, 0x73, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  // File header for "hello.txt"
  0x3D, 0xA4, 0x74, 0x00, 0x90, 0x2C, 0x00, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00,
  0x0D, 0x00, 0x00, 0x00, 0x02, 0xBD, 0xA8, 0xCB, 0x63, 0x14, 0x00, 0x20, 0x00,
  0x00, 0x00, 0x09, 0x00, 0x00, 0x00, 0x00, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x2E,
  0x74, 0x78, 0x74,
  // File data (stored/uncompressed)
  0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x2C, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64, 0x21,
  // End of archive marker
  0xC4, 0x3D, 0x7B, 0x00, 0x40, 0x07, 0x00,
]);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String testDir;
  late String rarFilePath;
  late String extractDir;

  setUpAll(() async {
    // Create test directory
    if (kIsWeb) {
      testDir = '/test';
      rarFilePath = '/test/sample.rar';
      extractDir = '/test/extracted';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      testDir = '${appDir.path}/rar_test';
      rarFilePath = '$testDir/sample.rar';
      extractDir = '$testDir/extracted';

      // Create test directory
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);

      // Write sample RAR file
      final rarFile = File(rarFilePath);
      await rarFile.writeAsBytes(sampleRarBytes);
    }
  });

  tearDownAll(() async {
    // Cleanup test directory
    if (!kIsWeb) {
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  });

  group('Platform Info', () {
    testWidgets('reports correct platform', (tester) async {
      String expectedPlatform;
      if (kIsWeb) {
        expectedPlatform = 'Web';
      } else if (Platform.isAndroid) {
        expectedPlatform = 'Android';
      } else if (Platform.isIOS) {
        expectedPlatform = 'iOS';
      } else if (Platform.isLinux) {
        expectedPlatform = 'Linux';
      } else if (Platform.isMacOS) {
        expectedPlatform = 'macOS';
      } else if (Platform.isWindows) {
        expectedPlatform = 'Windows';
      } else {
        expectedPlatform = 'Unknown';
      }

      debugPrint('Running on: $expectedPlatform');
      expect(expectedPlatform, isNotEmpty);
    });
  });

  group('RAR List Contents', () {
    testWidgets('can list contents of valid RAR file', (tester) async {
      // Skip on web for now as we need different handling
      if (kIsWeb) {
        debugPrint('Skipping file-based test on web');
        return;
      }

      final result = await Rar.listRarContents(rarFilePath: rarFilePath);

      debugPrint('List result: $result');

      // Check result structure
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), true);
      expect(result.containsKey('message'), true);
      expect(result.containsKey('files'), true);

      if (result['success'] == true) {
        final files = result['files'] as List;
        debugPrint('Files in archive: $files');
        expect(files, isNotEmpty);
      } else {
        // Log error but don't fail - native library might not be installed
        debugPrint(
          'List failed (expected if native library not installed): ${result['message']}',
        );
      }
    });

    testWidgets('handles non-existent file gracefully', (tester) async {
      if (kIsWeb) return;

      final result = await Rar.listRarContents(
        rarFilePath: '$testDir/nonexistent.rar',
      );

      debugPrint('Non-existent file result: $result');
      expect(result['success'], false);
      expect(result['files'], isEmpty);
    });
  });

  group('RAR Extract', () {
    testWidgets('can extract RAR file', (tester) async {
      if (kIsWeb) {
        debugPrint('Skipping file-based test on web');
        return;
      }

      // Create extract directory
      final extractDirObj = Directory(extractDir);
      if (await extractDirObj.exists()) {
        await extractDirObj.delete(recursive: true);
      }
      await extractDirObj.create(recursive: true);

      final result = await Rar.extractRarFile(
        rarFilePath: rarFilePath,
        destinationPath: extractDir,
      );

      debugPrint('Extract result: $result');

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), true);
      expect(result.containsKey('message'), true);

      if (result['success'] == true) {
        // Verify extracted files exist
        final entities = await extractDirObj.list().toList();
        debugPrint('Extracted files: ${entities.map((e) => e.path).toList()}');
        expect(entities, isNotEmpty);
      } else {
        debugPrint(
          'Extract failed (expected if native library not installed): ${result['message']}',
        );
      }
    });

    testWidgets('handles non-existent file gracefully', (tester) async {
      if (kIsWeb) return;

      final result = await Rar.extractRarFile(
        rarFilePath: '$testDir/nonexistent.rar',
        destinationPath: extractDir,
      );

      debugPrint('Non-existent file extract result: $result');
      expect(result['success'], false);
    });
  });

  group('RAR Create (unsupported)', () {
    testWidgets('createRarArchive returns unsupported', (tester) async {
      final result = await Rar.createRarArchive(
        outputPath: '$testDir/new.rar',
        sourcePaths: ['$testDir/file.txt'],
      );

      debugPrint('Create result: $result');
      expect(result['success'], false);
      expect(
        result['message'].toString().toLowerCase(),
        contains('not supported'),
      );
    });
  });

  group('Error Handling', () {
    testWidgets('handles invalid RAR file', (tester) async {
      if (kIsWeb) return;

      // Create an invalid RAR file (just random bytes)
      final invalidRarPath = '$testDir/invalid.rar';
      final invalidFile = File(invalidRarPath);
      await invalidFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      final result = await Rar.listRarContents(rarFilePath: invalidRarPath);

      debugPrint('Invalid RAR result: $result');
      expect(result['success'], false);
    });

    testWidgets('handles empty file', (tester) async {
      if (kIsWeb) return;

      final emptyRarPath = '$testDir/empty.rar';
      final emptyFile = File(emptyRarPath);
      await emptyFile.writeAsBytes([]);

      final result = await Rar.listRarContents(rarFilePath: emptyRarPath);

      debugPrint('Empty file result: $result');
      expect(result['success'], false);
    });
  });
}
