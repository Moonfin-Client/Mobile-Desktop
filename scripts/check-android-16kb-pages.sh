#!/usr/bin/env bash
set -euo pipefail

# Verifies native .so PT_LOAD alignment in an APK or AAB.
# Fails if any library has a minimum LOAD alignment below 0x4000 (16 KB).

ARTIFACT_PATH="${1:-build/app/outputs/flutter-apk/app-release.apk}"
MIN_ALIGN_HEX="0x4000"

if [[ ! -f "$ARTIFACT_PATH" ]]; then
  echo "Error: artifact not found: $ARTIFACT_PATH" >&2
  exit 2
fi

if ! command -v readelf >/dev/null 2>&1; then
  echo "Error: readelf is required but not found in PATH" >&2
  exit 2
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "Error: unzip is required but not found in PATH" >&2
  exit 2
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Works for both APK and AAB archives.
unzip -qq "$ARTIFACT_PATH" '*.so' -d "$tmp_dir"

mapfile -t libs < <(find "$tmp_dir" -name '*.so' | sort)
if [[ "${#libs[@]}" -eq 0 ]]; then
  echo "Error: no native libraries found in artifact: $ARTIFACT_PATH" >&2
  exit 2
fi

min_align_dec=$((MIN_ALIGN_HEX))
failed=0

for so in "${libs[@]}"; do
  # Collect alignments from PT_LOAD headers.
  mapfile -t aligns < <(readelf -lW "$so" | awk '/LOAD/{print $NF}' | sort -u)

  if [[ "${#aligns[@]}" -eq 0 ]]; then
    echo "FAIL: ${so##$tmp_dir/} has no LOAD alignment data" >&2
    failed=1
    continue
  fi

  # Use the smallest LOAD alignment for compatibility checks.
  min_so_align="${aligns[0]}"
  min_so_align_dec=$((min_so_align))

  if (( min_so_align_dec < min_align_dec )); then
    echo "FAIL: ${so##$tmp_dir/} min LOAD align $min_so_align (< $MIN_ALIGN_HEX)" >&2
    failed=1
  fi
done

if (( failed != 0 )); then
  echo "16 KB page-size check failed for: $ARTIFACT_PATH" >&2
  exit 1
fi

echo "16 KB page-size check passed: $ARTIFACT_PATH"
