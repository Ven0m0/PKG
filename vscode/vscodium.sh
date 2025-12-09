#!/bin/sh
# VSCodium launcher script for system Electron

set -eu

readonly ELECTRON=@ELECTRON@
readonly CLI_PATH=/usr/lib/vscodium/vscodium.js

if [ ! -x "/usr/bin/$ELECTRON" ]; then
  echo "Error: $ELECTRON not found or not executable" >&2
  exit 1
fi

exec "$ELECTRON" "$CLI_PATH" "$@"
