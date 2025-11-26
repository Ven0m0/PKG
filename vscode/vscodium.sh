#!/bin/sh
# VSCodium launcher script for system Electron

ELECTRON=@ELECTRON@
CLI_PATH=/usr/lib/vscodium/vscodium.js
NAME=vscodium

if [ ! -x "/usr/bin/$ELECTRON" ]; then
  echo "Error: $ELECTRON not found or not executable" >&2
  exit 1
fi

exec "$ELECTRON" "$CLI_PATH" "$@"
