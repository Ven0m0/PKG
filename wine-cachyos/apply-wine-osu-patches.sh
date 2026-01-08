#!/usr/bin/env bash
# Apply wine-osu patches in the correct order
# Source: https://github.com/whrvt/wine-osu-patches

set -euo pipefail
IFS=$'\n\t'

# Check if we're in the wine source directory
if [ ! -f "configure.ac" ]; then
  echo "Error: Not in wine source directory" >&2
  exit 1
fi

PATCH_DIR="${1:-../patches/wine-osu}"

if [ ! -d "$PATCH_DIR" ]; then
  echo "Error: Patch directory $PATCH_DIR not found" >&2
  exit 1
fi

echo "==> Applying wine-osu patches from $PATCH_DIR"

# Function to apply all patches in a directory
apply_patches_in_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "Warning: Directory $dir not found, skipping" >&2
    return 0
  fi

  # Find all .patch files and sort them
  local patches
  mapfile -t patches < <(find "$dir" -name "*.patch" -type f | sort)

  if [ ${#patches[@]} -eq 0 ]; then
    echo "No patches found in $dir"
    return 0
  fi

  echo "Found ${#patches[@]} patches in $dir"

  for patch in "${patches[@]}"; do
    local patch_name
    patch_name=$(basename "$patch")
    echo "  -> Applying $patch_name"
    if ! patch -Np1 -i "$patch"; then
      echo "Error: Failed to apply $patch_name" >&2
      exit 1
    fi
  done
}

# Apply patches in order
# Order is important - follow the numbering from wine-osu-patches
PATCH_CATEGORIES=(
  "0003-pending-mrs-and-backports"
  "0004-build-fix-undebug-optimize"
  "0009-windowing-system-integration"
  "0012-audio"
  "0013-server-optimization"
  "0015-bernhard-asan"
  "0016-proton-additions"
  "9000-misc-additions"
)

for category in "${PATCH_CATEGORIES[@]}"; do
  if [ -d "$PATCH_DIR/$category" ]; then
    echo "==> Processing category: $category"
    apply_patches_in_dir "$PATCH_DIR/$category"
  fi
done

echo "==> All wine-osu patches applied successfully"
