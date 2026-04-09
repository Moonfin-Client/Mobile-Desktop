#!/usr/bin/env bash
set -euo pipefail

TEAM_ID="${TEAM_ID:-}"
EXPORT_METHOD="${EXPORT_METHOD:-app-store-connect}"
WORKSPACE="${WORKSPACE:-macos/Runner.xcworkspace}"
SCHEME="${SCHEME:-Runner}"
CONFIGURATION="${CONFIGURATION:-Release}"
ALLOW_PROVISIONING_UPDATES="${ALLOW_PROVISIONING_UPDATES:-1}"
BUILD_APPSTORE_PKG="${BUILD_APPSTORE_PKG:-1}"
BUILD_DMG_GITHUB="${BUILD_DMG_GITHUB:-1}"
CLEAN_FLUTTER="${CLEAN_FLUTTER:-0}"

DEVELOPER_ID="${DEVELOPER_ID:-}"
APP_SIGN_ID="${APP_SIGN_ID:-$DEVELOPER_ID}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-}"

UPLOAD_WITH_TRANSPORTER="${UPLOAD_WITH_TRANSPORTER:-0}"
APPLE_ID="${APPLE_ID:-}"
APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-}"
ASC_PROVIDER="${ASC_PROVIDER:-}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Moonfin"
PKG_OUTPUT=""

if [ "$#" -gt 0 ]; then
  echo "Error: this script no longer accepts positional arguments." >&2
  echo "Run: ./build-macos.sh" >&2
  exit 1
fi

# Optional local overrides for private values.
PRIVATE_ENV_FILE="$REPO_ROOT/build-macos.private.env"
if [ -f "$PRIVATE_ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$PRIVATE_ENV_FILE"
fi

for cmd in flutter xcodebuild; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
done
if [ "$BUILD_DMG_GITHUB" = "1" ] && ! command -v hdiutil >/dev/null 2>&1; then
  echo "Error: required command not found: hdiutil" >&2
  exit 1
fi
if [ "$BUILD_APPSTORE_PKG" != "1" ] && [ "$BUILD_DMG_GITHUB" != "1" ]; then
  echo "Error: both BUILD_APPSTORE_PKG and BUILD_DMG_GITHUB are disabled." >&2
  exit 1
fi
if [ "$BUILD_APPSTORE_PKG" = "1" ] && [ -z "$TEAM_ID" ]; then
  echo "Error: TEAM_ID is required when BUILD_APPSTORE_PKG=1." >&2
  echo "Set TEAM_ID in build-macos.private.env or pass TEAM_ID=... when running." >&2
  exit 1
fi

APP_VERSION=$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | cut -d'+' -f1 | tr -d '[:space:]')
if [ -z "$APP_VERSION" ]; then
  echo "Error: could not read version from pubspec.yaml" >&2
  exit 1
fi

ARCHIVE_PATH="$REPO_ROOT/build/macos/appstore/${APP_NAME}.xcarchive"
EXPORT_DIR="$REPO_ROOT/build/macos/appstore/export"
EXPORT_OPTIONS_PLIST="$REPO_ROOT/build/macos/appstore/ExportOptions.plist"
FINAL_PKG_OUTPUT="$REPO_ROOT/${APP_NAME}_macOS_v${APP_VERSION}.pkg"
APP_FROM_ARCHIVE="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"
DMG_OUTPUT="$REPO_ROOT/${APP_NAME}_macOS_v${APP_VERSION}.dmg"
STAGING_DIR="$REPO_ROOT/build/macos/dmg-staging"

if [ -n "$APP_SIGN_ID" ] && ! command -v codesign >/dev/null 2>&1; then
  echo "Error: codesign is required when APP_SIGN_ID/DEVELOPER_ID is set." >&2
  exit 1
fi

echo "${APP_NAME} version: ${APP_VERSION}"

cd "$REPO_ROOT"

if [ "$CLEAN_FLUTTER" = "1" ]; then
  echo "Cleaning previous Flutter outputs..."
  flutter clean
fi

echo "Resolving packages..."
flutter pub get

echo "Preparing Flutter macOS generated files..."
flutter build macos --release

echo "Cleaning previous App Store outputs..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

echo "Creating archive with xcodebuild archive..."
ARCHIVE_CMD=(
  xcodebuild
  -workspace "$WORKSPACE"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
  CODE_SIGN_STYLE=Automatic
  archive
)
if [ -n "$TEAM_ID" ]; then
  ARCHIVE_CMD+=( DEVELOPMENT_TEAM="$TEAM_ID" )
fi
if [ "$ALLOW_PROVISIONING_UPDATES" = "1" ]; then
  ARCHIVE_CMD+=( -allowProvisioningUpdates )
fi
"${ARCHIVE_CMD[@]}"

if [ "$BUILD_APPSTORE_PKG" = "1" ]; then
  echo "Writing export options plist..."
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    echo '<plist version="1.0">'
    echo '<dict>'
    echo '  <key>method</key>'
    echo "  <string>${EXPORT_METHOD}</string>"
    echo '  <key>destination</key>'
    echo '  <string>export</string>'
    echo '  <key>signingStyle</key>'
    echo '  <string>automatic</string>'
    if [ -n "$TEAM_ID" ]; then
      echo '  <key>teamID</key>'
      echo "  <string>${TEAM_ID}</string>"
    fi
    echo '</dict>'
    echo '</plist>'
  } > "$EXPORT_OPTIONS_PLIST"

  echo "Exporting archive with xcodebuild -exportArchive..."
  EXPORT_CMD=(
    xcodebuild
    -exportArchive
    -archivePath "$ARCHIVE_PATH"
    -exportPath "$EXPORT_DIR"
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
  )
  if [ "$ALLOW_PROVISIONING_UPDATES" = "1" ]; then
    EXPORT_CMD+=( -allowProvisioningUpdates )
  fi
  "${EXPORT_CMD[@]}"

  PKG_OUTPUT="$(find "$EXPORT_DIR" -maxdepth 1 -type f -name '*.pkg' | head -n 1)"
  if [ -z "$PKG_OUTPUT" ]; then
    echo "Error: no exported PKG found in $EXPORT_DIR" >&2
    exit 1
  fi

  cp -f "$PKG_OUTPUT" "$FINAL_PKG_OUTPUT"

  echo "Archive created: $ARCHIVE_PATH"
  echo "Exported PKG: $PKG_OUTPUT"
  echo "Versioned PKG copy: $FINAL_PKG_OUTPUT"

  if [ "$UPLOAD_WITH_TRANSPORTER" = "1" ]; then
    if ! command -v xcrun >/dev/null 2>&1; then
      echo "Error: xcrun is required for Transporter CLI upload." >&2
      exit 1
    fi
    if [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
      echo "Error: APPLE_ID and APP_SPECIFIC_PASSWORD are required when UPLOAD_WITH_TRANSPORTER=1." >&2
      exit 1
    fi

    TRANSPORTER_CMD=(
      xcrun iTMSTransporter
      -m upload
      -assetFile "$FINAL_PKG_OUTPUT"
      -u "$APPLE_ID"
      -p "$APP_SPECIFIC_PASSWORD"
    )
    if [ -n "$ASC_PROVIDER" ]; then
      TRANSPORTER_CMD+=( -itc_provider "$ASC_PROVIDER" )
    fi
    echo "Uploading PKG with iTMSTransporter..."
    "${TRANSPORTER_CMD[@]}"
  else
    echo "Next step: upload this PKG with Transporter app:"
    echo "  $FINAL_PKG_OUTPUT"
  fi
fi

if [ "$BUILD_DMG_GITHUB" = "1" ]; then
  if [ ! -d "$APP_FROM_ARCHIVE" ]; then
    echo "Error: archived app not found at $APP_FROM_ARCHIVE" >&2
    exit 1
  fi

  echo "Building DMG for GitHub distribution..."
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR"
  cp -R "$APP_FROM_ARCHIVE" "$STAGING_DIR/"

  if [ -n "$APP_SIGN_ID" ]; then
    echo "Re-signing app bundle with hardened runtime..."
    find "$STAGING_DIR/${APP_NAME}.app" -type f \( -name '*.dylib' -o -name '*.framework' -o -perm +111 \) -print0 | while IFS= read -r -d '' file; do
      codesign --force --timestamp --options runtime --sign "$APP_SIGN_ID" "$file" 2>/dev/null || true
    done
    codesign --force --deep --timestamp --options runtime --sign "$APP_SIGN_ID" "$STAGING_DIR/${APP_NAME}.app"
  fi

  ln -s /Applications "$STAGING_DIR/Applications"

  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_OUTPUT"

  rm -rf "$STAGING_DIR"

  if [ -n "$APP_SIGN_ID" ]; then
    echo "Signing DMG with $APP_SIGN_ID..."
    codesign --force --timestamp --sign "$APP_SIGN_ID" "$DMG_OUTPUT"
  else
    echo "DMG signing skipped (APP_SIGN_ID/DEVELOPER_ID not set)."
  fi

  if [ -n "$NOTARYTOOL_PROFILE" ]; then
    if ! command -v xcrun >/dev/null 2>&1; then
      echo "Error: xcrun is required for notarization." >&2
      exit 1
    fi
    echo "Submitting DMG for notarization..."
    NOTARIZE_OUTPUT=$(xcrun notarytool submit "$DMG_OUTPUT" \
      --keychain-profile "$NOTARYTOOL_PROFILE" \
      --wait 2>&1) || true
    echo "$NOTARIZE_OUTPUT"

    SUBMISSION_ID=$(echo "$NOTARIZE_OUTPUT" | grep -m1 '  id:' | awk '{print $2}')
    if [ -n "$SUBMISSION_ID" ]; then
      echo "Fetching notarization log for submission $SUBMISSION_ID..."
      xcrun notarytool log "$SUBMISSION_ID" \
        --keychain-profile "$NOTARYTOOL_PROFILE" || true
    fi

    if echo "$NOTARIZE_OUTPUT" | grep -q "status: Invalid"; then
      echo "Error: Notarization failed." >&2
      exit 1
    fi

    echo "Stapling notarization ticket..."
    xcrun stapler staple "$DMG_OUTPUT"
  fi

  echo "DMG created: $DMG_OUTPUT"
fi
