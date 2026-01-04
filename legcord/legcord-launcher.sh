#!/bin/bash

if command -v electron39 &>/dev/null; then
  electron="$(command -v electron39 2>/dev/null)"
elif command -v electron38 &>/dev/null; then
  electron="$(command -v electron38 2>/dev/null)"
else
  electron="/usr/bin/electron"
fi
FLAGS="${XDG_CONFIG_HOME:-${HOME}/.config}/legcord-flags.conf"
# Allow users to override command-line options
[[ -f "$FLAGS" ]] && USER_FLAGS="$(<"$FLAGS")"
# shellcheck disable=SC2086 # USER_FLAGS has to be unquoted
"$electron" /usr/share/legcord/app.asar $USER_FLAGS "$@"
