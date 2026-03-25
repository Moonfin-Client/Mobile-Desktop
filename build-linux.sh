#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Moonfin"
APP_ID="org.moonfin.linux"
APP_ICON="$REPO_ROOT/assets/icons/logo.png"
BUILD_DIR="$REPO_ROOT/build/linux/release/bundle"
TEMP_DIR="$REPO_ROOT/build/linux/temp"

resolve_flutter() {
  if [ -n "${FLUTTER_BIN:-}" ] && [ -x "$FLUTTER_BIN" ]; then
    printf '%s\n' "$FLUTTER_BIN"
    return 0
  fi

  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return 0
  fi

  local candidates=(
    "$HOME/flutter/bin/flutter"
    "$HOME/Documents/flutter/bin/flutter"
    "$HOME/snap/flutter/common/flutter/bin/flutter"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "Error: Flutter not found. Add flutter to PATH or set FLUTTER_BIN to the full flutter executable path." >&2
  exit 1
}

get_app_version() {
  grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | cut -d'+' -f1 | tr -d '[:space:]'
}

create_desktop_file() {
  local dest="$1"
  cat > "$dest/${APP_ID}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Moonfin
Exec=moonfin
Icon=${APP_ID}
Categories=AudioVideo;Video;
Comment=Jellyfin & Emby media client
Terminal=false
EOF
}

copy_icon() {
  local dest="$1"
  if [ -f "$APP_ICON" ]; then
    cp "$APP_ICON" "$dest/${APP_ID}.png"
  fi
}

build_flutter_binary() {
  echo "Building Flutter release binary for Linux..."
  local flutter_bin
  flutter_bin="$(resolve_flutter)"
  cd "$REPO_ROOT"
  "$flutter_bin" build linux --release
}

build_appimage() {
  echo "=== Building AppImage ==="
  if ! command -v appimagetool >/dev/null 2>&1; then
    echo "Skipping AppImage: appimagetool not found"
    echo "  Install: https://github.com/AppImage/AppImageKit/releases"
    return 1
  fi

  local appimage_dir="$TEMP_DIR/appimage"
  local appimage_name="${APP_NAME}-linux-x86_64.AppImage"

  rm -rf "$appimage_dir"
  mkdir -p "$appimage_dir"

  cp -r "$BUILD_DIR"/* "$appimage_dir/"

  cat > "$appimage_dir/AppRun" << 'EOF'
#!/bin/bash
APPDIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$APPDIR/lib:$LD_LIBRARY_PATH"
exec "$APPDIR/moonfin" "$@"
EOF
  chmod +x "$appimage_dir/AppRun"

  create_desktop_file "$appimage_dir"
  mkdir -p "$appimage_dir/usr/share/pixmaps"
  copy_icon "$appimage_dir/usr/share/pixmaps"

  cd "$TEMP_DIR"
  appimagetool "$appimage_dir" "$appimage_name" || true
  
  if [ -f "$appimage_name" ]; then
    mv "$appimage_name" "$REPO_ROOT/"
    echo "✓ Created: $REPO_ROOT/$appimage_name"
  fi
}

build_tarball() {
  echo "=== Building Tarball ==="

  local tarball_name="${APP_NAME}-linux-x86_64.tar.gz"
  local version="$(get_app_version)"
  local tar_dir="$TEMP_DIR/tarball/moonfin-${version}"

  rm -rf "$TEMP_DIR/tarball"
  mkdir -p "$tar_dir"
  cp -r "$BUILD_DIR"/* "$tar_dir/"

  cat > "$tar_dir/README.txt" << EOF
Moonfin ${version}
Jellyfin & Emby media client for Linux

Installation:
  1. Extract this archive
  2. Run ./moonfin

Dependencies:
  - GTK 3.0+
  - GLib 2.0+
  - libflutter_linux_gtk (bundled)

Requirements:
  - X11 or Wayland display server
  - Network access to Jellyfin/Emby server
EOF

  cd "$TEMP_DIR/tarball"
  tar -czf "$tarball_name" "moonfin-${version}"
  mv "$tarball_name" "$REPO_ROOT/"
  echo "✓ Created: $REPO_ROOT/$tarball_name"
}

build_deb() {
  echo "=== Building Debian Package (.deb) ==="
  if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "Skipping .deb: dpkg-deb not found"
    return 1
  fi

  local version="$(get_app_version)"
  local pkg_root="$TEMP_DIR/deb/moonfin-${version}"

  rm -rf "$TEMP_DIR/deb"
  mkdir -p "$pkg_root"/{usr/bin,usr/lib/moonfin,usr/share/applications,usr/share/pixmaps,usr/share/doc/moonfin,DEBIAN}

  cp "$BUILD_DIR/moonfin" "$pkg_root/usr/bin/"
  chmod +x "$pkg_root/usr/bin/moonfin"

  if [ -d "$BUILD_DIR/lib" ]; then
    cp -r "$BUILD_DIR/lib"/* "$pkg_root/usr/lib/moonfin/"
  fi

  create_desktop_file "$pkg_root/usr/share/applications"
  copy_icon "$pkg_root/usr/share/pixmaps"

  cat > "$pkg_root/DEBIAN/control" << EOF
Package: moonfin
Version: ${version}
Architecture: amd64
Maintainer: Moonfin Team <support@moonfin.dev>
Installed-Size: $(du -sk "$pkg_root/usr" | cut -f1)
Depends: libgtk-3-0, libglib2.0-0
Description: Jellyfin & Emby media client
 Moonfin is a media client for Jellyfin and Emby servers,
 available on mobile, TV, and desktop platforms.
 .
 Features:
  - Browse and stream media
  - Offline downloads
  - Casting support
  - DLNA playback
Homepage: https://moonfin.app/
License: GPL-3.0
EOF

  cat > "$pkg_root/usr/share/doc/moonfin/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Moonfin
Upstream-Contact: https://github.com/jmshrv/Moonfin
Source: https://github.com/jmshrv/Moonfin

Files: *
Copyright: 2024-2025 Moonfin Team
License: GPL-3.0
EOF

  cd "$TEMP_DIR/deb"
  dpkg-deb --build "moonfin-${version}" "moonfin_${version}_amd64.deb" 2>/dev/null || true

  if [ -f "moonfin_${version}_amd64.deb" ]; then
    mv "moonfin_${version}_amd64.deb" "$REPO_ROOT/"
    echo "✓ Created: $REPO_ROOT/moonfin_${version}_amd64.deb"
  fi
}

build_rpm() {
  echo "=== Building RPM Package (.rpm) ==="
  if ! command -v rpmbuild >/dev/null 2>&1; then
    echo "Skipping .rpm: rpmbuild not found"
    return 1
  fi

  local version="$(get_app_version)"
  local rpm_dir="$TEMP_DIR/rpm"
  local spec_file="$rpm_dir/moonfin.spec"

  rm -rf "$rpm_dir"
  mkdir -p "$rpm_dir"/{SPECS,SOURCES,BUILD,RPMS,SRPMS}

  cat > "$spec_file" << EOF
Name:           moonfin
Version:        ${version}
Release:        1
Summary:        Jellyfin & Emby media client
License:        GPL-3.0

%description
Moonfin is a media client for Jellyfin and Emby servers,
available on mobile, TV, and desktop platforms.

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/lib/moonfin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/pixmaps

cp -r ${BUILD_DIR}/* %{buildroot}/usr/lib/moonfin/
ln -s /usr/lib/moonfin/moonfin %{buildroot}/usr/bin/moonfin

cat > %{buildroot}/usr/share/applications/${APP_ID}.desktop << 'EOFDESKTOP'
[Desktop Entry]
Type=Application
Name=Moonfin
Exec=moonfin
Icon=${APP_ID}
Categories=AudioVideo;Video;
Comment=Jellyfin & Emby media client
EOFDESKTOP

if [ -f "$APP_ICON" ]; then
  cp "$APP_ICON" %{buildroot}/usr/share/pixmaps/${APP_ID}.png
fi

%files
/usr/bin/moonfin
/usr/lib/moonfin/
/usr/share/applications/${APP_ID}.desktop
/usr/share/pixmaps/${APP_ID}.png

%changelog
* Mon Mar 25 2026 Moonfin Team
- Release ${version}
EOF

  cd "$rpm_dir"
  rpmbuild --define "_topdir $rpm_dir" -bb "$spec_file" 2>/dev/null || true

  local rpm_file=$(find "$rpm_dir/RPMS" -name "*.rpm" 2>/dev/null | head -1)
  if [ -n "$rpm_file" ]; then
    cp "$rpm_file" "$REPO_ROOT/"
    echo "✓ Created: $REPO_ROOT/$(basename "$rpm_file")"
  fi
}

build_snap() {
  echo "=== Building Snap Package ==="
  if ! command -v snapcraft >/dev/null 2>&1; then
    echo "Skipping Snap: snapcraft not found"
    echo "  Install: sudo snap install snapcraft --classic"
    return 1
  fi

  local snap_dir="$TEMP_DIR/snap"
  local version="$(get_app_version)"

  rm -rf "$snap_dir"
  mkdir -p "$snap_dir"

  cat > "$snap_dir/snapcraft.yaml" << EOF
name: moonfin
version: '${version}'
summary: Jellyfin & Emby media client
description: |
  Moonfin is a media client for Jellyfin and Emby servers.
  Stream movies, TV shows, music, and photos from your server.

grade: stable
confinement: strict
base: core22

apps:
  moonfin:
    command: moonfin
    plugs:
      - home
      - network
      - network-bind
      - opengl
      - pulseaudio
    environment:
      LD_LIBRARY_PATH: \$SNAP/lib/x86_64-linux-gnu

parts:
  moonfin:
    plugin: dump
    source: .
    override-build: |
      mkdir -p \$SNAPCRAFT_PART_INSTALL/bin
      mkdir -p \$SNAPCRAFT_PART_INSTALL/lib
      cp -r ${BUILD_DIR}/* \$SNAPCRAFT_PART_INSTALL/
    stage-packages:
      - libgtk-3-0
      - libglib2.0-0
      - libx11-6
EOF

  echo "Skipping Snap build (requires snapcraft setup)"
  echo "  To build snap: cd $snap_dir && snapcraft"
}

build_flatpak() {
  echo "=== Building Flatpak Package ==="
  if ! command -v flatpak-builder >/dev/null 2>&1; then
    echo "Skipping Flatpak: flatpak-builder not found"
    echo "  Install: sudo apt install flatpak-builder"
    return 1
  fi

  local flatpak_dir="$TEMP_DIR/flatpak"
  local version="$(get_app_version)"

  rm -rf "$flatpak_dir"
  mkdir -p "$flatpak_dir"

  cat > "$flatpak_dir/${APP_ID}.yml" << EOF
app-id: ${APP_ID}
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk

command: moonfin

modules:
  - name: moonfin
    buildsystem: simple
    build-commands:
      - mkdir -p /app/bin /app/lib
      - cp -r ${BUILD_DIR}/moonfin /app/bin/
      - cp -r ${BUILD_DIR}/lib/* /app/lib/ || true
    sources:
      - type: dir
        path: .
EOF

  echo "Skipping Flatpak build (requires host Flatpak setup)"
  echo "  To build flatpak: flatpak-builder --force-clean $flatpak_dir ${APP_ID}.yml"
}

main() {
  local formats="${1:-all}"
  formats="$(printf '%s\n' "$formats" | tr '[:upper:]' '[:lower:]')"
  local version="$(get_app_version)"

  echo "======================================"
  echo "Moonfin Linux Package Builder"
  echo "Version: ${version}"
  echo "======================================"
  echo ""

  build_flutter_binary
  rm -rf "$TEMP_DIR"

  case "$formats" in
    all)
      build_tarball || true
      build_appimage || true
      build_deb || true
      build_rpm || true
      build_snap || true
      build_flatpak || true
      ;;
    tarball)
      build_tarball
      ;;
    appimage)
      build_appimage
      ;;
    deb)
      build_deb
      ;;
    rpm)
      build_rpm
      ;;
    snap)
      build_snap
      ;;
    flatpak)
      build_flatpak
      ;;
    *)
      cat << USAGE
Usage: $0 [FORMAT]

Available formats:
  all          Build all package formats (default)
  tarball      Create tarball (.tar.gz)
  appimage     Create AppImage (requires appimagetool)
  deb          Create Debian package (requires dpkg-deb)
  rpm          Create RPM package (requires rpmbuild)
  snap         Create Snap package (requires snapcraft)
  flatpak      Create Flatpak package (requires flatpak-builder)

Examples:
  $0                 # Build all formats
  $0 tarball         # Build only tarball
  $0 appimage        # Build only AppImage
USAGE
      exit 1
      ;;
  esac

  rm -rf "$TEMP_DIR"

  echo ""
  echo "======================================"
  echo "Build complete!"
  echo "Artifacts: $REPO_ROOT"
  ls -lh "$REPO_ROOT"/Moonfin-* "$REPO_ROOT"/moonfin-* 2>/dev/null || echo "(no artifacts built)"
  echo "======================================"
}

main "$@"

# Create AppImage
build_appimage() {
  echo "=== Building AppImage ==="
  if ! require_tool appimagetool; then
    echo "Skipping AppImage: appimagetool not found"
    echo "  Install: https://github.com/AppImage/AppImageKit/releases"
    return 1
  fi

  local bundle_dir="$REPO_ROOT/build/linux/release/bundle"
  local appimage_dir="$OUTPUT_DIR/appimage-build"
  local appimage_name="${APP_NAME}-linux-x86_64.AppImage"

  mkdir -p "$appimage_dir"

  # Copy bundle files
  cp -r "$bundle_dir"/* "$appimage_dir/"

  # Create AppRun script
  cat > "$appimage_dir/AppRun" << 'EOF'
#!/bin/bash
APPDIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$APPDIR/lib:$LD_LIBRARY_PATH"
exec "$APPDIR/moonfin" "$@"
EOF
  chmod +x "$appimage_dir/AppRun"

  # Create .desktop file
  cat > "$appimage_dir/${APP_ID}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Moonfin
Exec=moonfin
Icon=${APP_ID}
Categories=AudioVideo;Video;
Comment=Jellyfin & Emby media client
EOF

  # Copy icon if available
  if [ -f "$APP_ICON" ]; then
    mkdir -p "$appimage_dir/usr/share/pixmaps"
    cp "$APP_ICON" "$appimage_dir/usr/share/pixmaps/${APP_ID}.png"
    cp "$APP_ICON" "$appimage_dir/.icon"
  fi

  # Create AppImage
  cd "$appimage_dir/.."
  appimagetool "$appimage_dir" "$appimage_name" || true
  
  if [ -f "$appimage_name" ]; then
    mv "$appimage_name" "$REPO_ROOT/$appimage_name"
    echo "✓ Created: $REPO_ROOT/$appimage_name"
  fi

  cd "$REPO_ROOT"
}

# Create tarball
build_tarball() {
  echo "=== Building Tarball ==="

  local bundle_dir="$REPO_ROOT/build/linux/release/bundle"
  local tarball_name="${APP_NAME}-linux-x86_64.tar.gz"
  local version="$(get_app_version)"

  mkdir -p "$OUTPUT_DIR/tarball"

  # Create directory structure
  local tar_dir="$OUTPUT_DIR/tarball/moonfin-${version}"
  mkdir -p "$tar_dir"

  # Copy binary and lib
  cp -r "$bundle_dir"/* "$tar_dir/"

  # Create README
  cat > "$tar_dir/README.txt" << EOF
Moonfin ${version}
Jellyfin & Emby media client for Linux

Installation:
  1. Extract this archive
  2. Run ./moonfin

Dependencies:
  - GTK 3.0+
  - GLib 2.0+
  - libflutter_linux_gtk (bundled)

Requirements:
  - X11 or Wayland display server
  - Network access to Jellyfin/Emby server
EOF

  # Create tarball
  cd "$OUTPUT_DIR/tarball"
  tar -czf "$tarball_name" "moonfin-${version}"
  mv "$tarball_name" "$REPO_ROOT/"
  echo "✓ Created: $REPO_ROOT/$tarball_name"
  rm -rf "moonfin-${version}"

  cd "$REPO_ROOT"
}

# Create .deb package
build_deb() {
  echo "=== Building Debian Package (.deb) ==="
  if ! require_tool dpkg-deb; then
    echo "Skipping .deb: dpkg tools not found"
    return 1
  fi

  local bundle_dir="$REPO_ROOT/build/linux/release/bundle"
  local version="$(get_app_version)"
  local deb_dir="$OUTPUT_DIR/deb-build"
  local pkg_root="$deb_dir/moonfin-${version}"

  mkdir -p "$pkg_root"

  # Create directory structure
  mkdir -p "$pkg_root/usr/bin"
  mkdir -p "$pkg_root/usr/lib/moonfin"
  mkdir -p "$pkg_root/usr/share/applications"
  mkdir -p "$pkg_root/usr/share/pixmaps"
  mkdir -p "$pkg_root/usr/share/doc/moonfin"
  mkdir -p "$pkg_root/DEBIAN"

  # Copy binary
  cp "$bundle_dir/moonfin" "$pkg_root/usr/bin/"
  chmod +x "$pkg_root/usr/bin/moonfin"

  # Copy libraries
  if [ -d "$bundle_dir/lib" ]; then
    cp -r "$bundle_dir/lib"/* "$pkg_root/usr/lib/moonfin/"
  fi

  # Create .desktop file
  cat > "$pkg_root/usr/share/applications/${APP_ID}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Moonfin
Exec=moonfin
Icon=${APP_ID}
Categories=AudioVideo;Video;
Comment=Jellyfin & Emby media client
Terminal=false
EOF

  # Copy icon
  if [ -f "$APP_ICON" ]; then
    cp "$APP_ICON" "$pkg_root/usr/share/pixmaps/${APP_ID}.png"
  fi

  # Create control file
  cat > "$pkg_root/DEBIAN/control" << EOF
Package: moonfin
Version: ${version}
Architecture: amd64
Maintainer: Moonfin Team <support@moonfin.dev>
Installed-Size: $(du -sk "$pkg_root/usr" | cut -f1)
Depends: libgtk-3-0, libglib2.0-0
Description: Jellyfin & Emby media client
 Moonfin is a media client for Jellyfin and Emby servers,
 available on mobile, TV, and desktop platforms.
 .
 Features:
  - Browse and stream media
  - Offline downloads
  - Casting support
  - DLNA playback
Homepage: https://moonfin.app/
License: GPL-3.0
EOF

  # Create changelog
  cat > "$pkg_root/usr/share/doc/moonfin/changelog.Debian.gz" << EOF
moonfin (${version}) unstable; urgency=low

  * See https://github.com/jmshrv/Moonfin/releases for details

EOF

  gzip "$pkg_root/usr/share/doc/moonfin/changelog.Debian" 2>/dev/null || true

  # Create copyright
  cat > "$pkg_root/usr/share/doc/moonfin/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Moonfin
Upstream-Contact: https://github.com/jmshrv/Moonfin
Source: https://github.com/jmshrv/Moonfin

Files: *
Copyright: 2024-2025 Moonfin Team
License: GPL-3.0
EOF

  # Build .deb
  cd "$deb_dir"
  dpkg-deb --build "moonfin-${version}" "moonfin_${version}_amd64.deb" || true

  if [ -f "moonfin_${version}_amd64.deb" ]; then
    mv "moonfin_${version}_amd64.deb" "$REPO_ROOT/"
    echo "✓ Created: $REPO_ROOT/moonfin_${version}_amd64.deb"
  fi

  cd "$REPO_ROOT"
}

# Create RPM package
build_rpm() {
  echo "=== Building RPM Package (.rpm) ==="
  if ! require_tool rpmbuild; then
    echo "Skipping .rpm: rpmbuild not found"
    return 1
  fi

  local bundle_dir="$REPO_ROOT/build/linux/release/bundle"
  local version="$(get_app_version)"
  local rpm_dir="$OUTPUT_DIR/rpm-build"
  local spec_file="$rpm_dir/moonfin.spec"

  mkdir -p "$rpm_dir"/{SPECS,SOURCES,BUILD,RPMS,SRPMS}

  # Create spec file
  cat > "$spec_file" << EOF
Name:           moonfin
Version:        ${version}
Release:        1
Summary:        Jellyfin & Emby media client
License:        GPL-3.0

%description
Moonfin is a media client for Jellyfin and Emby servers,
available on mobile, TV, and desktop platforms.

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/lib/moonfin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/pixmaps

cp -r ${bundle_dir}/* %{buildroot}/usr/lib/moonfin/
ln -s /usr/lib/moonfin/moonfin %{buildroot}/usr/bin/moonfin

cat > %{buildroot}/usr/share/applications/${APP_ID}.desktop << 'EOFDESKTOP'
[Desktop Entry]
Type=Application
Name=Moonfin
Exec=moonfin
Icon=${APP_ID}
Categories=AudioVideo;Video;
Comment=Jellyfin & Emby media client
EOFDESKTOP

if [ -f "$APP_ICON" ]; then
  cp "$APP_ICON" %{buildroot}/usr/share/pixmaps/${APP_ID}.png
fi

%files
/usr/bin/moonfin
/usr/lib/moonfin/
/usr/share/applications/${APP_ID}.desktop
/usr/share/pixmaps/${APP_ID}.png

%changelog
* Mon Mar 24 2026 Moonfin Team
- Release ${version}
EOF

  # Build RPM
  cd "$rpm_dir"
  rpmbuild --define "_topdir $rpm_dir" -bb "$spec_file" 2>/dev/null || true

  # Find and move RPM
  local rpm_file=$(find "$rpm_dir/RPMS" -name "*.rpm" 2>/dev/null | head -1)
  if [ -n "$rpm_file" ]; then
    cp "$rpm_file" "$REPO_ROOT/"
    echo "✓ Created: $REPO_ROOT/$(basename "$rpm_file")"
  fi

  cd "$REPO_ROOT"
}

# Create Snap package
build_snap() {
  echo "=== Building Snap Package ==="
  if ! require_tool snapcraft; then
    echo "Skipping Snap: snapcraft not found"
    echo "  Install: sudo snap install snapcraft --classic"
    return 1
  fi

  local bundle_dir="$REPO_ROOT/build/linux/release/bundle"
  local snap_dir="$OUTPUT_DIR/snap-build"
  local version="$(get_app_version)"

  mkdir -p "$snap_dir"

  # Create snapcraft.yaml
  cat > "$snap_dir/snapcraft.yaml" << EOF
name: moonfin
version: '${version}'
summary: Jellyfin & Emby media client
description: |
  Moonfin is a media client for Jellyfin and Emby servers.
  Stream movies, TV shows, music, and photos from your server.

grade: stable
confinement: strict
base: core22

apps:
  moonfin:
    command: moonfin
    plugs:
      - home
      - network
      - network-bind
      - opengl
      - pulseaudio
    environment:
      LD_LIBRARY_PATH: \$SNAP/lib/x86_64-linux-gnu

parts:
  moonfin:
    plugin: dump
    source: .
    override-build: |
      mkdir -p \$SNAPCRAFT_PART_INSTALL/bin
      mkdir -p \$SNAPCRAFT_PART_INSTALL/lib
      cp -r ${bundle_dir}/* \$SNAPCRAFT_PART_INSTALL/
    stage-packages:
      - libgtk-3-0
      - libglib2.0-0
      - libx11-6
EOF

  echo "Skipping Snap build (requires snapcraft setup)"
  echo "  To build snap: cd $snap_dir && snapcraft"
}

# Create Flatpak package
build_flatpak() {
  echo "=== Building Flatpak Package ==="
  if ! require_tool flatpak-builder; then
    echo "Skipping Flatpak: flatpak-builder not found"
    echo "  Install: sudo apt install flatpak-builder"
    return 1
  fi

  local bundle_dir="$REPO_ROOT/build/linux/release/bundle"
  local flatpak_dir="$OUTPUT_DIR/flatpak-build"
  local version="$(get_app_version)"

  mkdir -p "$flatpak_dir"

  # Create Flatpak manifest
  cat > "$flatpak_dir/${APP_ID}.yml" << EOF
app-id: ${APP_ID}
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk

command: moonfin

modules:
  - name: moonfin
    buildsystem: simple
    build-commands:
      - mkdir -p /app/bin /app/lib
      - cp -r ${bundle_dir}/moonfin /app/bin/
      - cp -r ${bundle_dir}/lib/* /app/lib/ || true
    sources:
      - type: dir
        path: .
EOF

  echo "Skipping Flatpak build (requires host Flatpak setup)"
  echo "  To build flatpak: flatpak-builder --force-clean $flatpak_dir ${APP_ID}.yml"
}

# Main logic
main() {
  local formats="${1:-all}"
  # Convert to lowercase for case-insensitive comparison
  formats="$(printf '%s\n' "$formats" | tr '[:upper:]' '[:lower:]')"
  local version="$(get_app_version)"

  echo "======================================"
  echo "Moonfin Linux Package Builder"
  echo "Version: ${version}"
  echo "======================================"
  echo ""

  FLUTTER_BIN="$(resolve_flutter)"

  # Always build Flutter binary first
  build_flutter_binary

  # Create output directory
  mkdir -p "$OUTPUT_DIR"

  # Build requested formats
  case "$formats" in
    all)
      build_tarball || true
      build_appimage || true
      build_deb || true
      build_rpm || true
      build_snap || true
      build_flatpak || true
      ;;
    tarball)
      build_tarball
      ;;
    appimage)
      build_appimage
      ;;
    deb)
      build_deb
      ;;
    rpm)
      build_rpm
      ;;
    snap)
      build_snap
      ;;
    flatpak)
      build_flatpak
      ;;
    *)
      cat << USAGE
Usage: $0 [FORMAT]

Available formats:
  all          Build all package formats (default)
  tarball      Create tarball (.tar.gz)
  appimage     Create AppImage (requires appimagetool)
  deb          Create Debian package (requires dpkg-deb)
  rpm          Create RPM package (requires rpmbuild)
  snap         Create Snap package (requires snapcraft)
  flatpak      Create Flatpak package (requires flatpak-builder)

Examples:
  $0                 # Build all formats
  $0 tarball         # Build only tarball
  $0 appimage        # Build only AppImage
USAGE
      exit 1
      ;;
  esac

  echo ""
  echo "======================================"
  echo "Build complete!"
  echo "Artifacts: $REPO_ROOT"
  ls -lh "$REPO_ROOT"/Moonfin-* "$REPO_ROOT"/moonfin-* 2>/dev/null || echo "(no artifacts built)"
  echo "======================================"
}

main "$@"
