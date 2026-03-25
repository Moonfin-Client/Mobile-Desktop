# Moonfin

Jellyfin & Emby media client for mobile, TV, and desktop.

## Required Toolchain Versions

- Flutter SDK: stable channel, 3.41+
- Dart SDK: 3.11+ (see `environment.sdk` in `pubspec.yaml`)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/)

## Getting Started

```bash
# Clone the repo
git clone <repo-url>
cd Mobile-Desktop

# Install dependencies
flutter pub get
```

## Building for Windows

### Requirements

1. **Windows 10 or Windows 11**

2. **PowerShell 5.1+**
   - Included with modern Windows installations

3. **Git**
   - Install from [git-scm.com](https://git-scm.com/)

4. **Flutter SDK**
   - Stable channel, 3.41+
   - Either add `flutter` to `PATH` or install it at `C:\flutter\bin\flutter.bat`
   - Verify with:
     ```powershell
     flutter doctor -v
     ```

5. **Visual Studio 2022** (Community edition or higher)

6. The following Visual Studio workloads/components (install via Visual Studio Installer → Modify):
   - **Desktop development with C++** workload
   - **MSVC v142+ C++ x64/x86 build tools** (included in the workload)
   - **C++ CMake tools for Windows** (included in the workload)
   - **Windows 10 SDK** (10.0.19041.0 or later)
   - **C++ ATL for latest build tools** (required by `flutter_secure_storage`)

   You can also install these from an **elevated (Admin) PowerShell**:
   ```powershell
   & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe' modify `
     --installPath 'C:\Program Files\Microsoft Visual Studio\2022\Community' `
     --add Microsoft.VisualStudio.Workload.NativeDesktop `
     --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
     --add Microsoft.VisualStudio.Component.VC.CMake.Project `
     --add Microsoft.VisualStudio.Component.Windows10SDK.19041 `
     --add Microsoft.VisualStudio.Component.VC.ATL `
     --passive --norestart
   ```

7. **Inno Setup 6**
   - Install from [innosetup.com](https://jrsoftware.org/isinfo.php)
   - The build script auto-detects `ISCC.exe` from common install paths and registry entries

### One-time setup checklist

Run these checks before the first Windows build:

```powershell
flutter doctor -v
where flutter
```

Confirm these work:
- `flutter doctor -v` shows Windows desktop toolchain ready
- Visual Studio C++ desktop components are installed
- Inno Setup 6 is installed

### One-command full rebuild installer

From the repo root, run:

```powershell
.\build-windows.ps1
```

What this does:
- runs `flutter clean`
- runs `flutter pub get`
- builds Windows release
- builds the Inno Setup installer
  - reads the installer version automatically from `pubspec.yaml`
- copies the final installer to the repo root

Final outputs:
- Root copy: `Moonfin-Setup-x64.exe`
- Build copy: `build\windows\installer\Moonfin-Setup-x64.exe`

Generated during the build:
- `build\windows\installer\moonfin.generated.iss`

### Example release flow

```powershell
git pull
.\build-windows.ps1
```

After the script finishes, share or test:
- `Moonfin-Setup-x64.exe`

### Portable EXE only

```bash
flutter build windows --release
```

The output is a self-contained folder at:
```
build\windows\x64\runner\Release\
```
Copy the entire `Release` folder to distribute. Run `moonfin.exe` to launch.

### MSIX Installer (Optional)

```bash
flutter pub run msix:create
```

The `.msix` installer will be generated at:
```
build\windows\x64\runner\Release\moonfin.msix
```

## Building for Android

### Requirements

- **Supported host OS:** Linux, macOS, or Windows
- [Android Studio](https://developer.android.com/studio) with Android SDK
- Android SDK Build-Tools, Platform-Tools, and an Android platform
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, 3.41+)
  - Either add `flutter` to `PATH`, set `FLUTTER_BIN`, or install it in one of these common locations used by the build script:
    - `~/flutter/bin/flutter`
    - `~/Documents/flutter/bin/flutter`
    - `~/snap/flutter/common/flutter/bin/flutter`

### One-time setup checklist

Run these checks before the first Android build:

```bash
flutter doctor -v
flutter doctor --android-licenses
```

Confirm these work:
- `flutter doctor -v` shows the Android toolchain ready
- Android SDK and platform tools are installed
- At least one Android platform is installed in Android Studio SDK Manager

### One-command Android APK build

On Linux or macOS, from the repo root, run:

```bash
./build-android.sh
```

On Windows PowerShell, from the repo root, run:

```powershell
.\build-android.ps1
```

What this does:
- runs `flutter clean`
- runs `flutter pub get`
- builds a release APK for `arm64-v8a` and `armeabi-v7a`
- excludes `x86_64` plugin JNI libraries during packaging
- copies the final APK to the repo root

Note:
- This release flow targets ARM devices only. `x86_64` Android emulators are not supported by these release artifacts.

Final outputs:
- Root copy: `Moonfin-android.apk`
- Build copy: `build/app/outputs/flutter-apk/app-release.apk`

### Example release flow

```bash
git pull
./build-android.sh
```

Windows PowerShell equivalent:

```powershell
git pull
.\build-android.ps1
```

After the script finishes, share or test:
- `Moonfin-android.apk`

### Manual Android builds

Build a release APK:

```bash
flutter build apk --release --target-platform android-arm64,android-arm
```

Build a Google Play bundle:

```bash
flutter build appbundle --release
```

Outputs:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Windows note

Android builds do not require Linux specifically. They can be built on Windows too.
Use `build-android.ps1` on Windows PowerShell.

## Building for iOS

### Requirements

- macOS with [Xcode](https://developer.apple.com/xcode/) installed
- Valid Apple Developer account (for device/distribution builds)
- CocoaPods: `sudo gem install cocoapods`

### One-command iOS build

From the repo root, run:

```bash
./build-ios.sh
```

What this does:
- runs `flutter clean`
- runs `flutter pub get`
- builds an unsigned iOS archive
- packages an unsigned IPA for user-side signing
- copies the unsigned IPA to the repo root

Default behavior:
- unsigned IPA output for open-source release distribution
- intended for end users to sign locally (AltStore, Sideloadly, Xcode, etc.)

Private local config:
- create `build-ios.private.env` next to the script
- a template is provided in `build-ios.private.env.example`

Environment overrides:
- `IOS_CODESIGN=1` to enable signed IPA export
- `IOS_EXPORT_METHOD=development|ad-hoc|app-store|enterprise`
- `IOS_EXPORT_OPTIONS_PLIST=/absolute/path/ExportOptions.plist`
- `IOS_CODESIGN=0` keeps unsigned IPA mode (default)
- `FLUTTER_BIN=/absolute/path/to/flutter`

Final outputs:
- Unsigned IPA root copy: `Moonfin-ios-unsigned.ipa` (default)
- Unsigned IPA build copy: `build/ios/ipa/Moonfin-unsigned.ipa` (default)
- Signed IPA root copy: `Moonfin-ios.ipa` when `IOS_CODESIGN=1`
- Signed IPA build copy: `build/ios/ipa/*.ipa` when `IOS_CODESIGN=1`

Examples:

```bash
./build-ios.sh
IOS_CODESIGN=1 IOS_EXPORT_METHOD=development ./build-ios.sh
IOS_CODESIGN=1 IOS_EXPORT_METHOD=ad-hoc ./build-ios.sh
```

```bash
cd ios && pod install && cd ..
flutter build ios --release
```

For an IPA (distribution):
```bash
flutter build ipa --release
```

Output: `build/ios/ipa/moonfin.ipa`

Notes:
- A sideloadable IPA still needs signing. In practice that usually means a `development` or `ad-hoc` export.
- `app-store` export is for App Store Connect submission, not direct sideloading.
- By default the script packages an unsigned IPA intended for end users to sign locally (AltStore, Sideloadly, Xcode, etc.).

## Building for macOS

### Requirements

- macOS with [Xcode](https://developer.apple.com/xcode/) installed
- CocoaPods: `sudo gem install cocoapods`

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/moonfin.app`

## Building for Linux

> **Windows users:** Linux packages require Linux tools. Use WSL2 or WSL1 to build Linux packages on Windows:
> ```bash
> wsl ./build-linux.sh all
> ```

### Requirements

- **Build tools:** GCC, CMake, Ninja, pkg-config, GTK 3.0 development headers
  - On Ubuntu/Debian:
    ```bash
    sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev
    ```
- **Flutter SDK:** (stable channel, 3.41+)
  - Either add `flutter` to `PATH`, set `FLUTTER_BIN`, or install in common locations (checked by build script)

### One-command build with multi-format packaging

Build Flutter binary and create multiple distribution packages at once.

**On Linux or macOS**, from the repo root, run:

```bash
./build-linux.sh [FORMAT]
```

**On Windows**, use WSL to run the same bash script:

```bash
wsl ./build-linux.sh [FORMAT]
```

This creates a release binary and packages it in your chosen format(s).

#### Available package formats

Run `./build-linux.sh all` to attempt building all available formats.

**Format names are lowercase without file extensions** (e.g., `tarball` not `tar.gz`):

| Format Name | Output File | Tools Required | Best For |
|-------------|-------------|-----------------|----------|
| `tarball` | `*.tar.gz` | None (built-in) | Universal distribution |
| `appimage` | `*.AppImage` | `appimaketool` | Any Linux distro, single file |
| `deb` | `*.deb` | `dpkg-tools` | Ubuntu, Debian, Mint |
| `rpm` | `*.rpm` | `rpmbuild` | Fedora, RHEL, openSUSE |
| `snap` | `*.snap` | `snapcraft` | Ubuntu snapcraft ecosystem |
| `flatpak` | `*.flatpak` | `flatpak-builder` | Cross-distro, sandboxed |

#### Examples

Build all formats (skipped if tools missing):

```bash
./build-linux.sh all
```

Build specific formats (use lowercase names):

```bash
./build-linux.sh tarball     # Tarball only
./build-linux.sh appimage    # AppImage only
./build-linux.sh deb         # Debian package only
./build-linux.sh rpm         # RPM package only
./build-linux.sh snap        # Snap package only
./build-linux.sh flatpak     # Flatpak package only
```

Output artifacts are copied to the project root (alongside `build-linux.sh`):

```
Moonfin-linux-x86_64.tar.gz
Moonfin-linux-x86_64.AppImage
moonfin_0.1.0_amd64.deb
moonfin-0.1.0-1.x86_64.rpm
```

#### Tool installation examples

**AppImage tools** (on Ubuntu/Debian):

```bash
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
```

**.deb tools** (already installed with `build-essential`):

```bash
sudo apt install dpkg-dev
```

**.rpm tools** (Fedora/openSUSE):

```bash
sudo dnf install rpm-build  # Fedora
sudo zypper install rpm-build-devel  # openSUSE
```

**Snap tools** (Ubuntu):

```bash
sudo snap install snapcraft --classic
```

**Flatpak tools**:

```bash
sudo apt install flatpak flatpak-builder
```

### Manual Linux build (without packaging)

Build a release binary only:

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

To run:

```bash
./build/linux/x64/release/bundle/moonfin
```

The bundle contains the binary, libraries, and all dependencies needed.

## Troubleshooting

- Run `flutter doctor -v` to diagnose missing dependencies for any platform.
- If you see a `RepeatMode` ambiguity error, ensure the Flutter material import hides it:
  ```dart
  import 'package:flutter/material.dart' hide RepeatMode;
  ```
- On Windows, if `atlstr.h` is missing, install the **C++ ATL** component via Visual Studio Installer.
