## 0.3.0

- Added support for macOS and the web

## 0.2.1

### Testing
* Added unit tests for platform interface (`test/rar_platform_interface_test.dart`)
* Added unit tests for Rar class (`test/rar_test.dart`)
* Added integration tests for all platforms (`example/integration_test/`)
* Added test runner script for cross-platform testing (`test_runner.sh`)

### Example App
* Added file browser with tree view for archive contents
* Added file content viewer supporting images, text, and binary (hex dump)
* Added platform-specific file loading helpers

### Development
* Added `ffigen.yaml` for optional FFI binding regeneration
* Updated documentation with FFI best practices
* Updated README with plugin architecture documentation

## 0.2.0

Major release adding full desktop and web support:

### New Features
* **Desktop Support (Linux, macOS, Windows)**: Full RAR extraction and listing via native FFI with libarchive
* **Web Support**: RAR extraction and listing via WebAssembly (WASM) with JS interop
* **Platform Interface Pattern**: Refactored to use federated plugin architecture for better maintainability

### Platform-Specific Implementations
* **Linux**: Native library using libarchive, compiled via CMake
* **macOS**: Native library using libarchive, built with CocoaPods
* **Windows**: Native library using libarchive, compiled via CMake/Visual Studio
* **Web**: JavaScript/WASM implementation with libarchive.js fallback

### Technical Changes
* Added `plugin_platform_interface` dependency for federated plugin pattern
* Added `ffi` package dependency for desktop FFI bindings
* Created `RarPlatform` abstract interface for platform implementations
* Implemented `RarMethodChannel` for mobile platforms (Android/iOS)
* Implemented `RarLinux`, `RarMacOS`, `RarWindows` for desktop via FFI
* Implemented `RarWeb` for web via JS interop
* Added native C wrapper (`rar_native.c`) using libarchive for desktop platforms
* Added JavaScript glue code (`rar_web.js`) for web platform

### Example App Improvements
* Updated to work across all six platforms
* Added platform-specific file handling
* Added password input dialog for encrypted archives
* Improved UI with Material Design 3

### Documentation
* Updated README with platform support matrix
* Added installation instructions for desktop dependencies
* Added web platform usage guide
* Documented API reference

## 0.1.0

Initial release with:

* Extract RAR files on Android (JUnRar) and iOS (UnrarKit)
* List RAR file contents
* Support for password-protected archives
