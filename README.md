<h1 align="center">Moonfin</h1>
<h3 align="center">Enhanced Jellyfin & Emby client for mobile, tablet, and desktop</h3>

---
<p align="center">
  <img width="1920" height="1080" alt="moonfin_1920x1080" src="https://github.com/user-attachments/assets/b1d9c7d8-f113-457d-ab5c-1600bbd0600a" />
</p>


[![License](https://img.shields.io/github/license/Moonfin-Client/Mobile-Desktop.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Moonfin-Client/Mobile-Desktop)](https://github.com/Moonfin-Client/Mobile-Desktop/releases)
[![Downloads](https://img.shields.io/github/downloads/Moonfin-Client/Mobile-Desktop/total?label=Downloads)](https://github.com/Moonfin-Client/Mobile-Desktop/releases)

<a href="https://www.buymeacoffee.com/moonfin" target="_blank"><img src="https://github.com/user-attachments/assets/fe26eaec-147f-496f-8e95-4ebe19f57131" alt="Buy Me A Coffee" ></a>

> **[← Back to main Moonfin project](https://github.com/Moonfin-Client)**

Moonfin is a cross-platform media client built with Flutter, designed for Jellyfin and Emby users who want a modern, customizable experience across mobile, tablet, and desktop platforms.

## Supported Servers

| Server | Minimum Version | Status |
|--------|------------------|--------|
| Jellyfin | 10.8.0+ | Full support |
| Emby | 4.8.0.0+ | Full support |

## Platform Support

| Platform | Minimum Version | Status |
|----------|------------------|--------|
| **Android** | 6.0 (API 23) | Full support |
| **iOS** | 13.0 | Full support |
| **macOS** | 10.15 (Catalina) | Full support |
| **Windows** | 10 | Full support |
| **Linux** | GTK 3 + CMake 3.13+ | Full support |

## Features & Enhancements

### Mobile + Desktop Experience
- Optimized for phones, tablets, and desktop environments from one Flutter codebase
- Responsive navigation patterns tuned for touch on mobile and larger layouts on desktop
- Platform-specific build/release scripts for Android, iOS, Linux, macOS, and Windows

### Playback Engine - libmpv via media_kit
All video and audio playback is powered by [media_kit](https://github.com/media-kit/media-kit) (libmpv) across every platform. This gives Moonfin broad codec coverage without relying on platform-specific media frameworks:

| Category | Supported Formats |
|----------|-------------------|
| **Video** | H.264, HEVC (H.265), VP8, VP9, AV1, MPEG-2, MPEG-4, VC-1 |
| **Audio** | AAC, MP3, FLAC, Opus, Vorbis, AC3 (Dolby Digital), EAC3 (Dolby Digital Plus), DTS, TrueHD, PCM (16-/24-bit), ALAC |
| **Containers** | MP4, MKV, WebM, AVI, MOV, TS / M2TS, WMV / ASF |
| **Subtitles** | SRT, ASS / SSA, VTT / WebVTT, TTML, SUB; bitmap (PGS, DVB, VobSub) on desktop |
| **HDR** | Dolby Vision, HDR10+, HDR10, HLG - automatic detection and signaling |
| **HW Accel** | VA-API, QSV, NVENC, VideoToolbox, V4L2, RKMPP |

### Downloads - Original or Transcoded
Media can be downloaded in its **original format** (bit-for-bit copy) or **server-transcoded** to a smaller file before saving. Transcoded downloads use **HEVC (H.265) video + AAC audio in an MP4 container**, which delivers roughly 50% smaller files compared to H.264 at equivalent perceived quality.

| Preset | Resolution | Video Bitrate | Audio Bitrate | Est. Size/hr |
|--------|-----------|---------------|---------------|--------------|
| Original | Source | Source | Source | Varies |
| High | 1080p | 4 Mbps | 192 kbps | ~1.8 GB |
| Medium | 720p | 2 Mbps | 128 kbps | ~950 MB |
| Low | 480p | 1 Mbps | 96 kbps | ~490 MB |
| Mobile | 360p | 500 kbps | 64 kbps | ~250 MB |

Downloaded files are organized automatically:
```
Movies/{Title (Year)}/
TV/{Series}/Season NN/
Music/{Artist}/{Album}/
Audiobooks/{Author}/{Collection}/
Books/{BookName}/
```
Android  downloads are saved under the app's external storage directory `(Android/data/com.moonfin.app/files/Moonfin/)`. This uses getExternalStorageDirectory(), which provides more space than internal app storage and avoids counting against the device's internal storage quota. If external storage is unavailable, it falls back to the app's internal documents directory.

iOS downloads are saved under the app's Documents directory `(Documents/Moonfin/)`. This is the standard sandboxed location iOS provides for user-generated content. Files here are included in iCloud/iTunes backups by default and persist across app updates.

Desktop downloads are saved under the application support directory by default, but users can configure a custom download path in settings.

Resume position tracking, offline subtitle support, and full playback controls work identically for downloaded content.

### Ebook & Audiobook Support
**Ebooks** - Read EPUB, MOBI, AZW/AZW3, and PDF directly in-app. Comic archives (CBZ, CBR, CB7, CBT) render with two-page spread on desktop, zoom/pan, and page caching. Reader themes include Light, Dark, and Sepia.

**Audiobooks** - Play M4B and multi-file audiobooks with chapter navigation, position bookmarks, and resume tracking. Download entire audiobooks for offline listening with the same quality presets as video.

Books and audiobooks download in their **original format** - no transcoding.

### Casting and Session Control
- Native Google Cast, DLNA, and AirPlay integration paths
- Playback controls with track selection, delay adjustments, and picture-in-picture support
- Queue/next-up behavior that works across local and remote playback states

### Integrated Admin Panel
- Built-in admin dashboard screens directly in the client
- Server operations views for settings, users, libraries, logs, devices, and analytics
- Reduced context switching when managing a server from a mobile or desktop client

### Multi-Server Unified Library
- Connect to multiple Jellyfin and/or Emby servers simultaneously under one UI
- Unified library view merges content from all servers - browse, search, and play without switching
- Libraries display as "Library Name (Server Name)" when multiple servers are active
- Aggregated Continue Watching, Next Up, and Latest rows pull from every connected server
- Toggle unified mode on or off per preference; works independently per server type

### Featured Media Bar
- Rotating featured hero content on the home screen with rich backdrop presentation
- Includes quick-glance metadata like ratings, genres, runtime, and overview
- Designed to highlight trending and library content without leaving the home flow

### SyncPlay
- Group watch support with synchronized playback across participants
- SyncPlay entry points are available in app navigation and settings-driven controls
- Built for shared viewing sessions while preserving local playback controls

### Ratings Integration (MDBList + TMDB)
- Optional MDBList ratings support with multiple rating sources shown in item details
- TMDB episode ratings support for episodic content where available
- Rating display can be customized through settings

### Trickplay and Media Segment Controls
- Trickplay preview support for improved scrubbing and seek navigation
- Media segment handling for intros, credits, and other detected segments
- Playback controls remain consistent across streaming and offline scenarios

### Live TV & DVR
- Built-in Live TV browsing and playback screens
- Electronic Program Guide (EPG) style scheduling views
- DVR recordings and schedule management interfaces integrated in-app

### In-App Trailer Previews
- Trailer playback support directly in-app from item detail contexts
- Uses resilient trailer source resolution for better playback reliability
- Lets users preview content without leaving the Moonfin experience

### Advanced Playback Controls
- Fine-grained subtitle and audio delay adjustment during playback
- Pre-playback track selection and ongoing track control support
- Includes features like still-watching flow support and next-up handling

### Home Row Customization
- Reorder and toggle home sections (for example, Continue Watching, Next Up, Latest)
- Home row preferences are compatible with plugin-backed sync workflows
- Lets users tailor discovery layout to their personal viewing habits

### Parental Controls & PIN
- PIN code configuration support for sensitive settings/actions
- Parental controls include configurable content/rating restrictions
- Works alongside account and preference-level customization paths

### Automatic Update Checks
- Built-in app update checks with configurable cadence behavior
- Surfaces update availability in-app to reduce manual version tracking
- Designed to keep clients current across supported platforms

---

# User Guide

## Keyboard Shortcuts (Desktop)

### App-Wide Shortcuts
- **Escape** — Navigate back to the previous screen, or return to home if no history remains
- **Enter/Return** — Activate the currently focused item
- **F11** — Toggle fullscreen mode
- **Ctrl+Q** — Quit the application

### Player Shortcuts
- **Space** — Play or pause playback
- **Left Arrow** — Seek backward (default 10 seconds)
- **Right Arrow** — Seek forward (default 30 seconds)
- **Up Arrow** — Increase volume
- **Down Arrow** — Decrease volume
- **I** — Display stream information overlay (codec, bitrate, resolution, etc.)
- **Escape** — Exit fullscreen (if in fullscreen); otherwise exit playback
- **Enter/Space** — Show player controls if hidden; play/pause if controls are visible

## Custom mpv.conf Configuration (Desktop + Android)

Moonfin allows power users to fine-tune playback behavior using a custom `mpv.conf` file. This enables advanced options like custom shaders, video scaling algorithms, tone mapping, and more.

### Setup

1. **Enable Custom mpv.conf** — Go to **Settings → Playback → Advanced mpv** and toggle **Enable Custom mpv.conf** to on.

2. **Specify File Location** — Provide a path to your `mpv.conf` file:
   - Click **Custom mpv.conf Path** to browse or enter the path manually.
   - On **Android**, the easiest flow is to create/store `mpv.conf` in a user-accessible folder (for example `Downloads`) and select it with the picker.
   - Moonfin will automatically check for `mpv.conf` in standard locations if not specified:
     - Application support directory (recommended)
     - Current working directory

3. **Example File Locations**
   - **Linux**: `~/.config/Moonfin/mpv.conf` or `/home/user/.local/share/Moonfin/mpv.conf`
   - **macOS**: `~/Library/Application Support/Moonfin/mpv.conf`
   - **Windows**: `C:\Users\YourName\AppData\Local\Moonfin\mpv.conf`
   - **Android**: Keep `mpv.conf` in a normal user folder (for example `Downloads`) and select it via **Custom mpv.conf Path**

### File Size Limit

Configuration files must not exceed **256 KB**. Larger files are rejected.

### Allowed and Blocked Options

**Protected Options** — These affect core playback and are not configurable:
- `aid`, `sid`, `vid` (audio/subtitle/video selection)
- `sub-visibility`, `sub-ass`, `sub-ass-override` (subtitle rendering)
- `sub-delay`, `audio-delay` (sync controls)
- `network-timeout`, `sub-fonts-dir`, `sub-font` (core behavior)

**Blocked Options** — These are blocked for security:
- `script`, `scripts`, `script-opts`, `load-scripts` (script execution)
- `include`, `profile`, `input-conf` (config file manipulation)

**Allowed Options** (Basic & Advanced scaling, rendering):
- Scaling: `scale`, `cscale`, `dscale`, `scale-*` options
- Rendering: `sigmoid-upscaling`, `deband`, `deband-*`, `interpolation`, `tscale`, `video-sync`
- Color & tone: `tone-mapping`, `tone-mapping-param`, `target-trc`, `brightness`, `contrast`, `saturation`, `gamma`, `sharpen`
- Audio: `audio-channels`, `audio-normalize-downmix`
- Effects: `deinterlace`, `keep-open`
- GLSL shaders: `glsl-shader*` (loading custom shaders)

### Unsafe Advanced Mode

Enable **Unsafe Advanced mpv Options** to unlock lower-level settings:
- `vo` (video output driver)
- `gpu-context` (GPU backend selection)
- `hwdec` (hardware decoding mode)
- `vf`, `af` (custom video/audio filters)
- `input-ipc-server` (IPC socket endpoint)
- `vd-lavc-*` (decoder options)
- `demuxer-*` and `cache-*` (stream behavior)

**Warning**: These options can break playback or cause instability if misconfigured.

### Example Configuration

```ini
# Scaling and rendering
scale=lanczos
deband=yes
tone-mapping=hdr

# Video sync and interpolation
video-sync=display-resample
interpolation=yes

# Shaders (if using unsafe advanced)
# glsl-shader=/path/to/shader.glsl

# Color adjustments
gamma=1.1
saturation=1.05
```

### SVP (Smooth Video Project) on Windows

Moonfin ships a minimal `libmpv-2.dll` for a smaller download size. If you use [SVP](https://www.svp-team.com/) for frame interpolation, you need to replace it with a full build that includes vapoursynth support:

1. Download the latest `libmpv-2.dll` from [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake/releases) (the ~115 MB `x86_64-v3` build).
2. Replace `libmpv-2.dll` in your Moonfin installation folder (default: `C:\Program Files\Moonfin\`).
3. Launch SVP Manager before starting playback in Moonfin.

Normal playback works fine with the included DLL, this swap is only needed for SVP.

## Subtitle Downloads

Download subtitles directly from the item details screen.

1. Open any **Movie** or **Episode** details screen.
2. In the details area, locate the **Subtitles** section.
3. Tap or click the **download icon** next to available subtitles.
4. Subtitles are saved in your downloads folder organized by media type and library structure.
5. Downloaded subtitles are automatically available for offline playback.

Synchronized subtitle timing is preserved during download. Use your preferred subtitle format (SRT, ASS, VTT, etc.) from your server's available sources.

## Remote Device Control

Control other Jellyfin devices on your network directly from Moonfin.

### How to Use

1. Tap or click the **user avatar** in the top toolbar.
2. A dialog menu will appear with account and device options.
3. Select **Remote Control** from the menu.
4. A list of available Jellyfin devices on your server will appear, showing:
   - Device name
   - Current playback status (if applicable)
   - Device type icon

5. Select a device to send playback commands:
   - **Play on Device** — Start playback on the remote device
   - **Pause** — Pause playback on the remote device
   - **Stop** — Stop playback on the remote device
   - **Volume Control** — Adjust device volume if supported
   - **Seek** — Control playback position

### Supported Device Types

- Desktop clients
- Mobile apps
- Web players
- Smart TV apps
- Media players (via Jellyfin server compatibility)

### Requirements

- Device must be registered with your Jellyfin server
- Device must be actively online and connected to the network
- You must have playback permission for the content
- Both devices must be connected to the same Jellyfin server instance

---

# Screenshots

## Tablet and Desktop
<img width="48%" height="1200" alt="1" src="https://github.com/user-attachments/assets/3ff05968-655f-42c7-a9ff-55b08529356c" />
<img width="48%" height="1200" alt="2" src="https://github.com/user-attachments/assets/70263c7b-24de-410d-a24f-d8bd1b08f1c6" />
<img width="48%" height="1200" alt="4" src="https://github.com/user-attachments/assets/23d4a73e-51b4-40b7-8e14-0366b479ea9d" />
<img width="48%" height="1200" alt="11" src="https://github.com/user-attachments/assets/1ab26def-da41-4f35-8a5b-62b13f3689b8" />
<img width="48%" height="1200" alt="25" src="https://github.com/user-attachments/assets/0eb12879-6699-4948-88ef-47b716b309e2" />
<img width="48%" height="1200" alt="3" src="https://github.com/user-attachments/assets/3feb1106-0d3d-4012-8779-cc9586e82ea5" />
<img width="48%" height="1200" alt="6" src="https://github.com/user-attachments/assets/6e1b588d-e5fd-4f4c-9046-7ccbe7651dab" />
<img width="48%" height="1200" alt="10" src="https://github.com/user-attachments/assets/6cb04d80-3d5d-4ea1-b58f-6a43cc74662f" />
<img width="48%" height="1200" alt="5" src="https://github.com/user-attachments/assets/8c7c48f9-1781-43fe-ac64-f601b9b8b806" />
<img width="48%" height="1200" alt="9" src="https://github.com/user-attachments/assets/74a72550-abed-4fa1-9c13-8cb5a4590bf3" />
<img width="48%" height="1200" alt="8" src="https://github.com/user-attachments/assets/069ad7e5-35ee-479f-be3b-a41cbf1ccf5e" />
<img width="48%" height="1200" alt="7" src="https://github.com/user-attachments/assets/23c5ad1b-008b-4199-94fb-476ce5b8234a" />

## Phones
<img width="23%" height="2244" alt="12" src="https://github.com/user-attachments/assets/8bcc0483-a650-43e3-91fb-b9d3b4c57440" />
<img width="23%" height="2244" alt="13" src="https://github.com/user-attachments/assets/4455fc3e-997d-4e89-b915-09987158466f" />
<img width="23%" height="2244" alt="15" src="https://github.com/user-attachments/assets/65ed881e-1738-478d-8df9-0a36b35574a4" />
<img width="23%" height="2244" alt="14" src="https://github.com/user-attachments/assets/1813ac6b-546e-4796-b4a8-15fe006d4c9e" />
<img width="23%" height="2244" alt="16" src="https://github.com/user-attachments/assets/7601662d-08cb-45da-a4db-4f0d139248dc" />
<img width="23%" height="2244" alt="19" src="https://github.com/user-attachments/assets/83ff8582-1380-404a-9ee2-9721a6f3209f" />
<img width="23%" height="2244" alt="18" src="https://github.com/user-attachments/assets/ecd7ff2d-13d1-4fcc-9de4-5d5c937dbe53" />
<img width="23%" height="2244" alt="21" src="https://github.com/user-attachments/assets/e5d4abab-35bf-436f-a8ab-ed8da1681a34" />
<img width="23%" height="2244" alt="24" src="https://github.com/user-attachments/assets/994ab127-afce-480f-8875-955e8188c814" />
<img width="23%" height="2244" alt="23" src="https://github.com/user-attachments/assets/c342d953-135a-4913-945d-1444403cd336" />
<img width="23%" height="2244" alt="22" src="https://github.com/user-attachments/assets/1732a561-ff1c-4efc-abf5-fa5b938cd098" />
<img width="23%" height="2244" alt="20" src="https://github.com/user-attachments/assets/75abe3f8-1cc3-4fef-b99b-920e8a3748e7" />

## Installation

### Pre-built Releases
Download platform artifacts from the [Releases page](https://github.com/Moonfin-Client/Mobile-Desktop/releases).

### Android
- Primary output: APK (`Moonfin_Android_v<version>.apk`)
- Optional output: App Bundle (`Moonfin_Android_v<version>.aab`)
- Recommended for Android phones and tablets

### iOS
- Signed IPA output: `Moonfin_iOS_v<version>.ipa`
- Unsigned IPA output (default workflow): `Moonfin_iOS_v<version>_unsigned.ipa`

### Desktop
- Windows installer output: `Moonfin_Windows_v<version>.exe`
- macOS DMG output: `Moonfin_macOS_v<version>.dmg`
- Linux packaging via tarball/AppImage/deb/rpm/snap/flatpak (depending on tools)
- Linux package outputs: `Moonfin_Linux_v<version>.<ext>`
- macOS app bundle build support

## Building from Source

### Required Toolchain Versions
- Flutter SDK: stable channel, 3.41+
- Dart SDK: 3.11+ (see `environment.sdk` in `pubspec.yaml`)

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/)

### Quick Start

```bash
git clone https://github.com/Moonfin-Client/Mobile-Desktop.git
cd Mobile-Desktop
flutter pub get
```

### Local Testing Build Commands

Use these commands for contributor/local testing builds.

#### Android
```bash
flutter build apk --release
```

#### iOS (macOS)
```bash
flutter build ios --debug
```

#### Linux
```bash
flutter build linux --release
```

#### macOS
```bash
flutter build macos --release
```

#### Windows
```powershell
flutter build windows --release
```

## Development

### Developer Notes
- Use Flutter stable and keep dependencies up to date
- Validate changes with `flutter analyze` before PRs
- Test playback and navigation flows on at least one target platform
- Prefer small, focused commits for easier review

## Contributing

We welcome contributions to Moonfin.

### Guidelines
1. Check existing issues before opening new ones.
2. Discuss major feature changes before implementation.
3. Follow existing code style and project conventions.
4. Test your changes on relevant platforms.
5. Keep PR scope focused and clearly documented.

### Pull Request Process
1. Fork the repository.
2. Create a branch (`git checkout -b feature/your-change`).
3. Implement and test your changes.
4. Run static checks (`flutter analyze`).
5. Open a PR with context, screenshots/logs when useful, and test notes.

## Support & Community

- **Issues**: [GitHub Issues](https://github.com/Moonfin-Client/Mobile-Desktop/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Moonfin-Client/Mobile-Desktop/discussions)
- **Upstream Jellyfin**: [jellyfin.org](https://jellyfin.org)

## Credits

Moonfin is built on the work of:
- **[Jellyfin Project](https://jellyfin.org)**
- **Jellyfin client contributors**
- **Moonfin contributors**
- **[MakD](https://github.com/MakD)** - Original Jellyfin-Media-Bar concept that inspired our featured media bar
- **[MediaLyze](https://github.com/frederikemmer/MediaLyze)** The Admin analytics UI was inspired by this open-source project 

## License

This project is licensed under GPL v2. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Moonfin</strong> is an independent project and is not affiliated with the Jellyfin project.<br>
  <a href="https://github.com/Moonfin-Client">← Back to main Moonfin project</a>
</p>
