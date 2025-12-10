#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail; shopt -s nullglob globstar
LC_ALL=C IFS=$'\n\t'
has(){ command -v -- "$1" &>/dev/null; }
log(){ printf '%s\n' "$*" >&2; }

readonly ucode_dir="/usr/lib/firmware/intel-ucode" out="/boot/intel-ucode.img"
tmp=$(mktemp -t intel-ucode.XXXXXX)
has iucode_tool || { log "iucode_tool not found; skipping intel-ucode generation."; rm -f "$tmp"; exit 0; }
[[ -d $ucode_dir ]] || { log "intel ucode directory missing: $ucode_dir; skipping."; rm -f "$tmp"; exit 0; }
iucode_tool -S --write-earlyfw="$tmp" "$ucode_dir"/* &>/dev/null || { log "iucode_tool failed; preserving existing $out (if any)."; rm -f "$tmp"; exit 0; }
chmod 0644 "$tmp"
mv -f "$tmp" "$out"
has mkinitcpio && { mkinitcpio -P &>/dev/null || log "mkinitcpio -P failed; check /boot and presets."; }

# vim:set sw=2 sts=2 et:
