<h1 align="center">Moonfin</h1>
<h3 align="center">Enhanced Jellyfin & Emby client for mobile, tablet, and desktop</h3>

---

[![License](https://img.shields.io/github/license/Moonfin-Client/Mobile-Desktop.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Moonfin-Client/Mobile-Desktop)](https://github.com/Moonfin-Client/Mobile-Desktop/releases)
[![Downloads](https://img.shields.io/github/downloads/Moonfin-Client/Mobile-Desktop/total?label=Downloads)](https://github.com/Moonfin-Client/Mobile-Desktop/releases)

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

Resume position tracking, offline subtitle support, and full playback controls work identically for downloaded content.

### Ebook & Audiobook Support
**Ebooks** - Read EPUB, MOBI, AZW/AZW3, and PDF directly in-app. Comic archives (CBZ, CBR, CB7, CBT) render with two-page spread on desktop, zoom/pan, and page caching. Reader themes include Light, Dark, and Sepia.

**Audiobooks** - Play M4B and multi-file audiobooks with chapter navigation, position bookmarks, and resume tracking. Download entire audiobooks for offline listening with the same quality presets as video.

Books and audiobooks download in their **original format** - no transcoding.

### Casting and Session Control
- Native Google Cast, DLNA, and AirPlay integration paths
- Playback controls with track selection, delay adjustments, and picture-in-picture support
- Queue/next-up behavior that works across local and remote playback states

### Integrated Admin Surface
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

### Platform Build Commands

#### Android
```bash
./build-android.sh
```

Windows PowerShell:
```powershell
.\build-android.ps1
```

#### iOS (macOS)
```bash
./build-ios.sh
```

#### Linux
```bash
./build-linux.sh all
```

#### macOS
```bash
flutter build macos --release
```

#### Windows
```powershell
.\build-windows.ps1
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

Some Admin analytics UX ideas were inspired by the open-source project [MediaLyze](https://github.com/frederikemmer/MediaLyze) by Frederik Emmer (MIT).

## License

This project is licensed under GPL v2 (inherited from upstream Jellyfin client foundations). See [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Moonfin</strong> is an independent project and is not affiliated with the Jellyfin project.<br>
  <a href="https://github.com/Moonfin-Client">← Back to main Moonfin project</a>
</p>
