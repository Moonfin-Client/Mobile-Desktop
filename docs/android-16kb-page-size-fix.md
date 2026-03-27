# Android 16 KB Page Size Support Fix Plan

This document captures the concrete steps to make the Android app compatible with 16 KB page-size devices.

## Why this is needed

Android 15+ ecosystem rollout includes devices using 16 KB memory pages. Native libraries in the APK/AAB must be compatible.

In this project, tooling versions are already modern enough, but some bundled native libraries still report 4 KB alignment.

## Current status in this project

Verified toolchain:
- AGP: 8.7.3
- Gradle: 8.10.2
- NDK: 27.0.12077973

Detected 4 KB alignment offenders in the release APK:
- `lib/arm64-v8a/libarchive.so`
- `lib/arm64-v8a/librar_native.so`
- `lib/armeabi-v7a/libarchive.so`
- `lib/armeabi-v7a/libc++_shared.so`
- `lib/armeabi-v7a/libpdfium.so`
- `lib/armeabi-v7a/librar_native.so`
- `lib/armeabi-v7a/libsqlite3.so`

## Step-by-step fix

1. Inventory native libraries in the built artifact

Use this command after each release build:

```bash
APK=build/app/outputs/flutter-apk/app-release.apk
TMP=$(mktemp -d)
unzip -qq "$APK" 'lib/*/*.so' -d "$TMP"
find "$TMP/lib" -name '*.so' | sort | while read -r so; do
  aligns=$(readelf -lW "$so" | awk '/LOAD/{print $NF}' | sort -u)
  min=$(echo "$aligns" | head -n1)
  if [[ "$min" == "0x1000" ]]; then
    echo "${so##$TMP/} :: $(echo "$aligns" | tr '\n' ',' | sed 's/,$//')"
  fi
done
rm -rf "$TMP"
```

2. Update Flutter packages that ship native binaries

Prioritize packages likely producing the offenders:
- `archive_extract` / `archive` / `rar` (for `libarchive.so`, `librar_native.so`)
- `sqlite3_flutter_libs` (for `libsqlite3.so`)
- `pdfrx` (for `libpdfium.so`)

Action:
- Check latest versions and changelogs for 16 KB or Android 15 compatibility.
- Upgrade where possible.
- Rebuild and rerun the check command above.

3. Rebuild in-house native code (if any) with explicit linker flags

For CMake targets:

```cmake
target_link_options(your_target PRIVATE
  -Wl,-z,max-page-size=16384
  -Wl,-z,common-page-size=16384
)
```

For ndk-build:

```make
LOCAL_LDFLAGS += -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384
```

4. Consider ABI policy to reduce risk

Most offenders are in `armeabi-v7a`.

If product requirements allow it, ship only `arm64-v8a` to reduce compatibility work and native dependency surface.

5. Validate the final artifact actually published

Check the final APK/AAB that will be uploaded, not only intermediate local outputs.

## Recommended CI gate

Add a CI check that fails release builds if any `.so` reports min `LOAD` alignment less than `0x4000`.

Example gate script:

```bash
#!/usr/bin/env bash
set -euo pipefail

ARTIFACT="${1:-build/app/outputs/flutter-apk/app-release.apk}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

unzip -qq "$ARTIFACT" 'lib/*/*.so' -d "$TMP"

failed=0
while IFS= read -r so; do
  min_align=$(readelf -lW "$so" | awk '/LOAD/{print $NF}' | sort -u | head -n1)
  if [[ "$min_align" != "0x4000" && "$min_align" != "0x10000" ]]; then
    echo "FAIL: ${so##$TMP/} has min align $min_align"
    failed=1
  fi
done < <(find "$TMP/lib" -name '*.so' | sort)

if [[ "$failed" -ne 0 ]]; then
  echo "16 KB page-size compatibility check failed"
  exit 1
fi

echo "16 KB page-size compatibility check passed"
```

## Definition of done

All native libraries in the release artifact have acceptable `LOAD` alignments (>= `0x4000`), and CI enforces this on every release build.
