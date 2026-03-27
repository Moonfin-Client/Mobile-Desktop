import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rar/rar.dart';
import 'package:rar_example/services/archive_service.dart';

// Mock RarPlatform
class MockRarPlatform extends RarPlatform with MockPlatformInterfaceMixin {
  bool extractCalled = false;
  bool listCalled = false;
  bool shouldSucceed = true;
  String errorMessage = 'Test error';
  List<String> mockFiles = ['file1.txt', 'file2.txt'];

  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    extractCalled = true;
    if (shouldSucceed) {
      return {'success': true, 'message': 'Extraction successful'};
    } else {
      return {'success': false, 'message': errorMessage};
    }
  }

  @override
  Future<Map<String, dynamic>> listRarContents({
    required String rarFilePath,
    String? password,
  }) async {
    listCalled = true;
    if (shouldSucceed) {
      return {
        'success': true,
        'message': 'List successful',
        'files': mockFiles,
        'rarVersion': 'v5',
      };
    } else {
      return {'success': false, 'message': errorMessage, 'files': <String>[]};
    }
  }
}

// Mock FilePicker
class MockFilePicker extends FilePicker {
  PlatformFile? fileToPick;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool? allowCompression,
    bool allowMultiple = false,
    bool? withData,
    bool? withReadStream,
    bool? lockParentWindow,
    bool? readSequential,
    int compressionQuality = 30,
  }) async {
    if (fileToPick != null) {
      return FilePickerResult([fileToPick!]);
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ArchiveService archiveService;
  late MockRarPlatform mockRarPlatform;
  late MockFilePicker mockFilePicker;

  setUp(() {
    mockRarPlatform = MockRarPlatform();
    RarPlatform.instance = mockRarPlatform;

    mockFilePicker = MockFilePicker();
    FilePicker.platform = mockFilePicker;

    archiveService = ArchiveService();
  });

  test('pickAndOpenArchive returns null when no file picked', () async {
    mockFilePicker.fileToPick = null;

    final result = await archiveService.pickAndOpenArchive();

    expect(result, isNull);
    expect(mockRarPlatform.extractCalled, false);
  });

  test('pickAndOpenArchive extracts and lists files on success', () async {
    mockFilePicker.fileToPick = PlatformFile(
      name: 'test.rar',
      size: 1024,
      path: '/path/to/test.rar',
    );

    // We need to mock getApplicationDocumentsDirectory, but ArchiveService
    // might abstract that away or we can mock PathProvider.
    // For now, let's assume ArchiveService handles path internally or we can inject it.
    // To keep it simple and testable, we might want to inject a path provider or just mock the platform channel for path_provider.
    // But mocking path_provider platform channel is verbose.
    // Let's assume ArchiveService has a method to get extract path that we can override or it uses a helper.

    // Actually, for this test, since we are running in a unit test environment,
    // path_provider might fail if not mocked.
    // Let's see if we can avoid path_provider dependency in the service or mock it.

    // Simplest way: Mock PathProviderPlatform.
    // But let's write the service to accept an optional extractPath for testing?
    // Or just mock the platform channel.

    // Let's try to run it and see if it fails on path_provider.
    // If it does, we'll add the mock.

    final result = await archiveService.pickAndOpenArchive(
      testExtractPath: '/tmp/extract', // Dependency injection for testing
    );

    expect(result, isNotNull);
    expect(result!.isSuccess, true);
    expect(result.files, contains('file1.txt'));
    expect(mockRarPlatform.extractCalled, true);
    expect(mockRarPlatform.listCalled, true);
  });

  test('pickAndOpenArchive returns error on extraction failure', () async {
    mockFilePicker.fileToPick = PlatformFile(
      name: 'test.rar',
      size: 1024,
      path: '/path/to/test.rar',
    );
    mockRarPlatform.shouldSucceed = false;
    mockRarPlatform.errorMessage = 'Extraction failed';

    final result = await archiveService.pickAndOpenArchive(
      testExtractPath: '/tmp/extract',
    );

    expect(result, isNotNull);
    expect(result!.isSuccess, false);
    expect(result.errorMessage, 'Extraction failed');
  });
}
