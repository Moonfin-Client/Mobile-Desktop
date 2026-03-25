#!/usr/bin/env bash
set -euo pipefail

# Builds an unsigned iOS IPA by default for user-side signing.
# Optional local overrides can be placed in build-ios.private.env.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Moonfin"
ARCHIVE_DIR="$REPO_ROOT/build/ios/archive"
IPA_DIR="$REPO_ROOT/build/ios/ipa"
ROOT_IPA_OUTPUT="$REPO_ROOT/${APP_NAME}-ios.ipa"
ROOT_UNSIGNED_IPA_OUTPUT="$REPO_ROOT/${APP_NAME}-ios-unsigned.ipa"

# Optional local overrides for private values.
PRIVATE_ENV_FILE="$REPO_ROOT/build-ios.private.env"
if [ -f "$PRIVATE_ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$PRIVATE_ENV_FILE"
fi

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
IOS_EXPORT_METHOD="${IOS_EXPORT_METHOD:-development}"
IOS_EXPORT_OPTIONS_PLIST="${IOS_EXPORT_OPTIONS_PLIST:-}"
IOS_CODESIGN="${IOS_CODESIGN:-0}"

if [ -n "$IOS_EXPORT_OPTIONS_PLIST" ] && [[ "$IOS_EXPORT_OPTIONS_PLIST" != /* ]]; then
  IOS_EXPORT_OPTIONS_PLIST="$REPO_ROOT/$IOS_EXPORT_OPTIONS_PLIST"
fi

for cmd in xcodebuild zip; do
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

echo "${APP_NAME} version: ${APP_VERSION}"

cd "$REPO_ROOT"

echo "Cleaning previous Flutter outputs..."
"$FLUTTER" clean

echo "Resolving packages..."
"$FLUTTER" pub get

rm -f "$ROOT_IPA_OUTPUT"
rm -f "$ROOT_UNSIGNED_IPA_OUTPUT"

build_args=(build ipa --release)

if [ "$IOS_CODESIGN" = "0" ]; then
  echo "Building unsigned iOS archive..."
  build_args+=(--no-codesign)
else
  if [ -n "$IOS_EXPORT_OPTIONS_PLIST" ]; then
    if [ ! -f "$IOS_EXPORT_OPTIONS_PLIST" ]; then
      echo "Error: export options plist not found: $IOS_EXPORT_OPTIONS_PLIST" >&2
      exit 1
    fi
    echo "Building signed iOS IPA with export options plist..."
    build_args+=(--export-options-plist="$IOS_EXPORT_OPTIONS_PLIST")
  else
    echo "Building signed iOS IPA with export method: $IOS_EXPORT_METHOD"
    build_args+=(--export-method="$IOS_EXPORT_METHOD")
  fi
fi

"$FLUTTER" "${build_args[@]}"

if [ "$IOS_CODESIGN" = "0" ]; then
  if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "Error: expected archive directory not found: $ARCHIVE_DIR" >&2
    exit 1
  fi

  APP_IN_ARCHIVE="$(find "$ARCHIVE_DIR" -type d -path '*/Products/Applications/*.app' | head -n 1)"
  if [ -z "$APP_IN_ARCHIVE" ]; then
    echo "Error: .app not found in archive at $ARCHIVE_DIR" >&2
    exit 1
  fi

  mkdir -p "$IPA_DIR"
  UNSIGNED_IPA_SOURCE="$IPA_DIR/${APP_NAME}-unsigned.ipa"
  rm -f "$UNSIGNED_IPA_SOURCE"

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  mkdir -p "$TMP_DIR/Payload"
  cp -R "$APP_IN_ARCHIVE" "$TMP_DIR/Payload/"
  (
    cd "$TMP_DIR"
    zip -qry "$UNSIGNED_IPA_SOURCE" Payload
  )
  cp "$UNSIGNED_IPA_SOURCE" "$ROOT_UNSIGNED_IPA_OUTPUT"

  echo "Unsigned iOS archive created in: $ARCHIVE_DIR"
  echo "Unsigned IPA created: $UNSIGNED_IPA_SOURCE"
  echo "Unsigned IPA copied to root: $ROOT_UNSIGNED_IPA_OUTPUT"
  echo "This IPA must be signed by the end user before installation."
  exit 0
fi

IPA_SOURCE="$(find "$IPA_DIR" -maxdepth 1 -type f -name '*.ipa' | head -n 1)"
if [ -z "$IPA_SOURCE" ]; then
  echo "Error: IPA not found in $IPA_DIR" >&2
  exit 1
fi

cp "$IPA_SOURCE" "$ROOT_IPA_OUTPUT"

echo "IPA created: $IPA_SOURCE"
echo "IPA copied to root: $ROOT_IPA_OUTPUT"
echo "Export method: $IOS_EXPORT_METHOD"