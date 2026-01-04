#!/bin/bash

electron="/usr/bin/electron39"
FLAGS="${XDG_CONFIG_HOME:-~/.config}/legcord-flags.conf"
# Allow users to override command-line options
if [[ -f "$FLAGS" ]]; then
  USER_FLAGS="$(cat "$FLAGS")"
fi
# shellcheck disable=SC2086 # USER_FLAGS has to be unquoted
"$electron" /usr/share/legcord/app.asar $USER_FLAGS "$@"
