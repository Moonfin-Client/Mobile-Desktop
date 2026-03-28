#!/usr/bin/env bash
set -euo pipefail

# Set APP_SIGN_ID to your app signing certificate common name.
# Example: APP_SIGN_ID="Apple Distribution: Your Name (TEAMID)"
# DEVELOPER_ID is still honored as a fallback for backward compatibility.
DEVELOPER_ID="${DEVELOPER_ID:-}"
APP_SIGN_ID="${APP_SIGN_ID:-$DEVELOPER_ID}"

# Set NOTARYTOOL_PROFILE to your stored notarytool keychain profile name.
# Create one (once) with:
#   xcrun notarytool store-credentials "moonfin-notary" \
#     --apple-id "you@example.com" --team-id "TEAMID" --password "<app-specific-password>"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-}"
INSTALLER_ID="${INSTALLER_ID:-}"

ENTITLEMENTS="macos/Runner/Release.entitlements"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Moonfin"
APP_PATH="$REPO_ROOT/build/macos/Build/Products/Release/${APP_NAME}.app"
STAGING_DIR="$REPO_ROOT/build/macos/dmg-staging"
DMG_OUTPUT=""
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

for cmd in flutter lipo hdiutil pkgbuild; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
done

APP_VERSION=$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | cut -d'+' -f1 | tr -d '[:space:]')
if [ -z "$APP_VERSION" ]; then
  echo "Error: could not read version from pubspec.yaml" >&2
  exit 1
fi

DMG_OUTPUT="$REPO_ROOT/${APP_NAME}_macOS_v${APP_VERSION}.dmg"
PKG_OUTPUT="$REPO_ROOT/${APP_NAME}_macOS_v${APP_VERSION}.pkg"

echo "${APP_NAME} version: ${APP_VERSION}"

cd "$REPO_ROOT"

echo "Cleaning previous Flutter outputs..."
flutter clean

echo "Resolving packages..."
flutter pub get

echo "Building macOS release..."
flutter build macos --release

if [ ! -d "$APP_PATH" ]; then
  echo "Error: .app not found at $APP_PATH" >&2
  exit 1
fi

BINARY_PATH="$APP_PATH/Contents/MacOS/$APP_NAME"
ARCHS=$(lipo -archs "$BINARY_PATH" 2>/dev/null || echo "unknown")
echo "Binary architectures: $ARCHS"
if [[ "$ARCHS" != *"arm64"* ]] || [[ "$ARCHS" != *"x86_64"* ]]; then
  echo "Warning: binary is not universal (arm64 + x86_64). Got: $ARCHS" >&2
  echo "         It will only run on the current machine's architecture." >&2
fi

if [ -z "$APP_SIGN_ID" ]; then
  echo "Error: APP_SIGN_ID (or DEVELOPER_ID fallback) is required." >&2
  echo "This script is configured to always produce App Store ready artifacts." >&2
  exit 1
fi
if [ -z "$INSTALLER_ID" ]; then
  echo "Error: INSTALLER_ID is required for signed PKG output." >&2
  echo "This script is configured to always produce App Store ready artifacts." >&2
  exit 1
fi

if [ ! -f "$REPO_ROOT/$ENTITLEMENTS" ]; then
  echo "Error: entitlements file not found: $REPO_ROOT/$ENTITLEMENTS" >&2
  exit 1
fi
if ! command -v codesign >/dev/null 2>&1; then
  echo "Error: required command not found: codesign" >&2
  exit 1
fi
echo "Signing .app with app signing identity..."
find "$APP_PATH/Contents/Frameworks" -type f \( -name "*.dylib" -o -name "*.so" \) | while IFS= read -r lib; do
  codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$lib"
done
find "$APP_PATH/Contents/Frameworks" -name "*.framework" -type d | sort -r | while IFS= read -r fw; do
  codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$fw"
done
find "$APP_PATH/Contents/MacOS" -type f ! -name "$APP_NAME" | while IFS= read -r bin; do
  codesign --force --options runtime --timestamp --sign "$APP_SIGN_ID" "$bin"
done
codesign \
  --force \
  --options runtime \
  --timestamp \
  --entitlements "$REPO_ROOT/$ENTITLEMENTS" \
  --sign "$APP_SIGN_ID" \
  "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
echo "Code signing complete."

rm -f "$PKG_OUTPUT"
echo "Building signed PKG with installer identity..."
pkgbuild \
  --component "$APP_PATH" \
  --install-location /Applications \
  --sign "$INSTALLER_ID" \
  "$PKG_OUTPUT"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_OUTPUT"

rm -rf "$STAGING_DIR"

codesign --force --timestamp --sign "$APP_SIGN_ID" "$DMG_OUTPUT"

if [ -n "$NOTARYTOOL_PROFILE" ]; then
  if ! command -v xcrun >/dev/null 2>&1; then
    echo "Error: required command not found: xcrun" >&2
    exit 1
  fi
  echo "Submitting DMG for notarization (this may take a few minutes)..."
  xcrun notarytool submit "$DMG_OUTPUT" \
    --keychain-profile "$NOTARYTOOL_PROFILE" \
    --wait
  echo "Stapling notarization ticket..."
  xcrun stapler staple "$DMG_OUTPUT"
  echo "Notarization complete."
else
  echo "Skipping notarization (NOTARYTOOL_PROFILE not set)."
  echo "  Users may need to right-click and choose Open to bypass Gatekeeper."
fi

echo "DMG created: $DMG_OUTPUT"
echo "PKG created: $PKG_OUTPUT"
echo "App Store upload: drag PKG into Transporter/App Store Connect."
