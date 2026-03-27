# rar

A Flutter plugin for handling RAR archives on Android, iOS, macOS, and Web.

This plugin allows you to extract RAR files, list their contents, and supports
password-protected archives.

## Features

- Extract RAR files (v4 and v5 formats)
- List contents of RAR files
- Support for password-protected RAR archives
- Cross-platform support:
  - **Android**: Uses libarchive via native FFI (Supports RAR5)
  - **iOS/macOS**: Uses UnrarKit (Objective-C)
  - **Web**: Uses WASM-based archive library via JS interop

## Platform Support

| Platform | Extract | List | Password |
|----------|---------|------|----------|
| Android  | ✅      | ✅   | ✅       |
| iOS      | ✅      | ✅   | ✅       |
| macOS    | ✅      | ✅   | ✅       |
| Web      | ✅      | ✅   | ✅       |

## Getting Started

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  rar: ^latest
```

### Android Setup

The plugin automatically compiles the native RAR library (`libarchive`) using
CMake during the build process. This ensures the correct binary is bundled for
every architecture (ARM, x86, etc.).

**Requirements:** To build the app, the developer must have the following
installed in their Android SDK:
1.  **Android NDK (Side by side)**
2.  **CMake**

**How to install:**
1.  Open **Android Studio**.
2.  Go to **Settings/Preferences** > **Languages & Frameworks** > **Android
    SDK**.
3.  Select the **SDK Tools** tab.
4.  Check **NDK (Side by side)** and **CMake**.
5.  Click **Apply** to install.

No other manual configuration is needed.

### iOS Setup

To allow picking RAR files on iOS, add the following to your
`ios/Runner/Info.plist`:

```xml
<key>UTExportedTypeDeclarations</key>
<array>
  <dict>
    <key>UTTypeConformsTo</key>
    <array>
      <string>public.data</string>
      <string>public.archive</string>
    </array>
    <key>UTTypeDescription</key>
    <string>RAR Archive</string>
    <key>UTTypeIdentifier</key>
    <string>com.rarlab.rar-archive</string>
    <key>UTTypeTagSpecification</key>
    <dict>
      <key>public.filename-extension</key>
      <array>
        <string>rar</string>
        <string>rev</string>
        <string>cbr</string>
      </array>
    </dict>
  </dict>
</array>
```

### Web Dependencies

The plugin bundles the `libarchive.js` WASM runtime and worker scripts. No
manual script tags are required in your `index.html`. The plugin automatically
injects the necessary scripts at runtime.

The bundled assets include:
- `rar_web.js`: The plugin's JavaScript interface
- `libarchive.js`: The WASM loader
- `libarchive.wasm`: The compiled libarchive library
- `worker-bundle.js`: The web worker for background processing

## Usage

### Extracting a RAR file

```dart
import 'package:rar/rar.dart';

Future<void> extractRarFile() async {
  final result = await Rar.extractRarFile(
    rarFilePath: '/path/to/archive.rar',
    destinationPath: '/path/to/destination/folder',
    password: 'optional_password', // Optional
  );

  if (result['success']) {
    print('Extraction successful: ${result['message']}');
  } else {
    print('Extraction failed: ${result['message']}');
  }
}
```

### Listing RAR contents

```dart
import 'package:rar/rar.dart';

Future<void> listRarContents() async {
  final result = await Rar.listRarContents(
    rarFilePath: '/path/to/archive.rar',
    password: 'optional_password', // Optional
  );

  if (result['success']) {
    print('RAR Version: ${result['rarVersion']}'); // e.g., "RAR4" or "RAR5"
    print('Files in archive:');
    for (final file in result['files']) {
      print('- $file');
    }
  } else {
    print('Failed to list contents: ${result['message']}');
  }
}
```

### Web Platform Notes

On the web platform, file system access is limited. The plugin uses a virtual
file system approach:

1. When selecting files via a file picker, use `withData: true` to get file
   bytes
2. Store the file data using `RarWeb.storeFileData(path, bytes)`
3. Extracted files are stored in the virtual file system and can be accessed via
   `RarWeb.getFileData(path)`

```dart
import 'package:rar/rar.dart';

// On web, store file bytes before extraction
if (kIsWeb) {
  RarWeb.storeFileData('archive.rar', fileBytes);
}

final result = await Rar.extractRarFile(
  rarFilePath: 'archive.rar',
  destinationPath: '/extracted',
);

// On web, get extracted file bytes
if (kIsWeb && result['success']) {
  final extractedData = RarWeb.getFileData('/extracted/file.txt');
}
```

## API Reference

### Rar.extractRarFile

```dart
static Future<Map<String, dynamic>> extractRarFile({
  required String rarFilePath,
  required String destinationPath,
  String? password,
})
```

Extracts a RAR file to a destination directory.

**Parameters:**
- `rarFilePath`: Path to the RAR file
- `destinationPath`: Directory where files will be extracted
- `password`: Optional password for encrypted archives

**Returns:** A map containing:
- `success` (bool): Whether the extraction was successful
- `message` (String): Status message or error description

### Rar.listRarContents

```dart
static Future<Map<String, dynamic>> listRarContents({
  required String rarFilePath,
  String? password,
})
```

Lists all files in a RAR archive.

**Parameters:**
- `rarFilePath`: Path to the RAR file
- `password`: Optional password for encrypted archives

**Returns:** A map containing:
- `success` (bool): Whether the listing was successful
- `message` (String): Status message or error description
- `files` (List<String>): List of file names in the archive
- `rarVersion` (String?): Detected RAR version ("RAR4", "RAR5", or "Unknown")

## Note on Creating RAR Archives

Creating RAR archives is **not supported** in this plugin because:

1. RAR is a proprietary format, and creating RAR archives requires proprietary
   tools
2. The RAR compression algorithm is licensed and cannot be freely used for
   compression
3. Only decompression is allowed under the UnRAR license

For creating archives, consider using the ZIP format instead, which has better
native support across all platforms.

## Error Handling

The plugin returns descriptive error messages for common issues:

- **File not found**: The specified RAR file doesn't exist
- **Bad password**: Incorrect password or password required for encrypted
  archive
- **Bad archive**: Corrupt or invalid RAR file
- **Unknown format**: File is not a valid RAR archive
- **Bad data**: CRC check failed (data corruption)

## License

This plugin is released under the MIT License.

## Third-party Libraries

This plugin uses the following libraries:

| Platform | Library | License |
|----------|---------|---------|
| Android | [libarchive](https://libarchive.org/) | BSD |
| iOS | [UnrarKit](https://github.com/abbeycode/UnrarKit) | BSD |
| macOS | [UnrarKit](https://github.com/abbeycode/UnrarKit) | BSD |
| Web | [libarchive.js](https://github.com/nicolo-ribaudo/libarchive.js) | MIT |

## Building Native Libraries

This plugin uses native code for RAR extraction. The build system automatically
compiles the native libraries when you build your Flutter app.

### Android (FFI)

Android now uses `libarchive` compiled via CMake and accessed via Dart FFI.
- **Build System**: CMake (configured in `android/build.gradle`)
- **Native Code**: `src/rar_native.c`
- **Dependencies**: `libarchive` is fetched and built automatically during the
  Gradle build.

### Desktop Platforms (FFI)

The FFI bindings in `lib/src/rar_ffi.dart` are hand-written for better control.
If you need to regenerate bindings from the C header, you can use ffigen:

```bash
dart run ffigen
```

### Mobile/Mac Platforms

- **Android**: Uses `libarchive` via FFI (same as Desktop)
- **iOS/macOS**: Uses UnrarKit library (Objective-C/Swift) via MethodChannel

### Web Platform (JS Interop)

The web platform uses JavaScript interop with a WASM-based archive library. The
WASM library and worker scripts are bundled with the plugin and loaded
dynamically at runtime. No external CDN is used, ensuring the plugin works
offline.

## Plugin Architecture

This plugin follows the federated plugin architecture:

```
lib/
  rar.dart                    # Main entry point
  rar_platform_interface.dart # Abstract platform interface
  src/
    rar_method_channel.dart   # Mobile implementation (iOS/macOS)
    rar_ffi.dart              # FFI implementation (Android)
    rar_web.dart              # Web implementation
```

## Testing

The plugin includes comprehensive tests for all platforms.

### Running Tests

Use the test runner script:

```bash
# Run unit tests only
./test_runner.sh unit

# Run tests for a specific platform
./test_runner.sh macos
./test_runner.sh web

# Run all desktop tests
./test_runner.sh desktop

# Run all mobile tests
./test_runner.sh mobile

# Run all tests
./test_runner.sh all
```

### Test Structure

```
test/
  rar_platform_interface_test.dart  # Platform interface unit tests
  rar_test.dart                     # Main Rar class unit tests
example/
  integration_test/
    rar_integration_test.dart       # Integration tests for all platforms
```

## Example App

The example app (`example/lib/main.dart`) demonstrates all plugin features across platforms. It uses a reusable `FileBrowser` widget (`example/lib/file_browser.dart`) which provides:

- **File picker** for selecting RAR archives
- **Password support** for encrypted archives
- **File browser** with tree view for archive contents
- **Content viewer** supporting:
  - Images (PNG, JPG, GIF, etc.)
  - Text files (TXT, JSON, XML, etc.)
  - Binary files (hex dump view)

Run the example:

```bash
cd example
flutter run -d macos    # or chrome, etc.
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

If you find a bug or want to request a new feature, please open an issue on
[GitHub](https://github.com/lkrjangid1/rar/issues).
