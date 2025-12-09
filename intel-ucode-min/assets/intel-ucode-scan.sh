#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

readonly ucode_dir="/usr/lib/firmware/intel-ucode"
readonly out="/boot/intel-ucode.img"

# Use mktemp in a safe tmpdir
tmp="$(mktemp -t intel-ucode.XXXXXX)"

# Helper: log to stderr
log(){
  printf '%s\n' "$*" >&2
}

# If required tools or firmware are missing, do nothing (safe)
if ! command -v iucode_tool &>/dev/null; then
  log "iucode_tool not found; skipping intel-ucode generation."
  rm -f "$tmp"
  exit 0
fi

if [[ ! -d "$ucode_dir" ]]; then
  log "intel ucode directory missing: $ucode_dir; skipping."
  rm -f "$tmp"
  exit 0
fi

# Generate per-system microcode image
# Write-earlyfw produces an initramfs-friendly cpio
if ! iucode_tool -S --write-earlyfw="$tmp" "$ucode_dir"/* &>/dev/null; then
  log "iucode_tool failed; preserving existing $out (if any)."
  rm -f "$tmp"
  exit 0
fi

# Set conservative permissions and atomically move into place
chmod 0644 "$tmp"
mv -f "$tmp" "$out"

# Rebuild initramfs presets so installed kernels pick up the new microcode
if command -v mkinitcpio &>/dev/null; then
  # Silent rebuild; failures are non-fatal (avoid breaking installs)
  mkinitcpio -P &>/dev/null || log "mkinitcpio -P failed; check /boot and presets."
fi
