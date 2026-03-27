#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Moonfin"
APK_SOURCE="$REPO_ROOT/build/app/outputs/flutter-apk/app-release.apk"
BUNDLE_SOURCE="$REPO_ROOT/build/app/outputs/bundle/release/app-release.aab"
PAGE_SIZE_CHECKER="$REPO_ROOT/scripts/check-android-16kb-pages.sh"

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

FLUTTER="$(resolve_flutter)"

VERSION_LINE=$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | tr -d '[:space:]')
APP_VERSION=$(printf '%s' "$VERSION_LINE" | cut -d'+' -f1)
APP_BUILD_NUMBER=$(printf '%s' "$VERSION_LINE" | cut -d'+' -f2)
if [ -z "$APP_VERSION" ] || [ -z "$APP_BUILD_NUMBER" ]; then
  echo "Error: could not read semantic version and build number from pubspec.yaml (expected x.y.z+build)" >&2
  exit 1
fi

APK_OUTPUT="$REPO_ROOT/${APP_NAME}_Android_v${APP_VERSION}.apk"
BUNDLE_OUTPUT="$REPO_ROOT/${APP_NAME}_Android_v${APP_VERSION}.aab"

echo "${APP_NAME} version: ${APP_VERSION} (${APP_BUILD_NUMBER})"

cd "$REPO_ROOT"

echo "Cleaning previous Flutter outputs..."
"$FLUTTER" clean

echo "Resolving packages..."
"$FLUTTER" pub get

echo "Building Android release APK (arm64-v8a only)..."
"$FLUTTER" build apk --release \
  --build-name "$APP_VERSION" \
  --build-number "$APP_BUILD_NUMBER" \
  --target-platform android-arm64

if [ ! -f "$APK_SOURCE" ]; then
  echo "Error: APK not found at $APK_SOURCE" >&2
  exit 1
fi

cp "$APK_SOURCE" "$APK_OUTPUT"

if [ -x "$PAGE_SIZE_CHECKER" ]; then
  echo "Running 16 KB page-size compatibility check on APK..."
  "$PAGE_SIZE_CHECKER" "$APK_SOURCE"
else
  echo "Warning: 16 KB checker not executable or missing at $PAGE_SIZE_CHECKER" >&2
fi

echo "APK created: $APK_SOURCE"
echo "APK copied to root: $APK_OUTPUT"

echo "Building Android App Bundle..."
if ! "$FLUTTER" build appbundle --release \
  --build-name "$APP_VERSION" \
  --build-number "$APP_BUILD_NUMBER"; then
  echo "Flutter appbundle build failed. Retrying with Gradle bundleRelease fallback..."
  (
    cd "$REPO_ROOT/android"
    ./gradlew bundleRelease
  )
fi

if [ ! -f "$BUNDLE_SOURCE" ]; then
  echo "Error: App Bundle not found at $BUNDLE_SOURCE" >&2
  exit 1
fi

cp "$BUNDLE_SOURCE" "$BUNDLE_OUTPUT"

if [ -x "$PAGE_SIZE_CHECKER" ]; then
  echo "Running 16 KB page-size compatibility check on App Bundle..."
  "$PAGE_SIZE_CHECKER" "$BUNDLE_SOURCE"
fi

echo "App Bundle created: $BUNDLE_SOURCE"
echo "App Bundle copied to root: $BUNDLE_OUTPUT"
