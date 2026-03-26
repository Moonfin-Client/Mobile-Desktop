#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Moonfin"
APK_SOURCE="$REPO_ROOT/build/app/outputs/flutter-apk/app-release.apk"
APK_OUTPUT="$REPO_ROOT/${APP_NAME}-android.apk"
BUNDLE_SOURCE="$REPO_ROOT/build/app/outputs/bundle/release/app-release.aab"
BUNDLE_OUTPUT="$REPO_ROOT/${APP_NAME}-android.aab"

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

APP_VERSION=$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | cut -d'+' -f1 | tr -d '[:space:]')
if [ -z "$APP_VERSION" ]; then
  echo "Error: could not read version from pubspec.yaml" >&2
  exit 1
fi

echo "${APP_NAME} version: ${APP_VERSION}"

cd "$REPO_ROOT"

echo "Cleaning previous Flutter outputs..."
"$FLUTTER" clean

echo "Resolving packages..."
"$FLUTTER" pub get

echo "Building Android release APK..."
"$FLUTTER" build apk --release --target-platform android-arm64,android-arm

if [ ! -f "$APK_SOURCE" ]; then
  echo "Error: APK not found at $APK_SOURCE" >&2
  exit 1
fi

cp "$APK_SOURCE" "$APK_OUTPUT"

echo "APK created: $APK_SOURCE"
echo "APK copied to root: $APK_OUTPUT"

echo "Building Android App Bundle..."
if ! "$FLUTTER" build appbundle --release; then
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

echo "App Bundle created: $BUNDLE_SOURCE"
echo "App Bundle copied to root: $BUNDLE_OUTPUT"
