#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail; shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C
has(){ command -v -- "$1" &>/dev/null; }
msg(){ printf '%s\n' "$@"; }
die(){ printf '%s\n' "$1" >&2; exit "${2:-1}"; }

REPO="https://ven0m0.github.io/PKG"
RAW="https://raw.githubusercontent.com/Ven0m0/PKG/main"

msg "======================================" "   vp - Ven0m0's Package Helper      " "======================================" ""

if has vp; then
  msg "✓ vp is already installed at $(command -v vp)" ""
  read -rp "Reinstall/update? (y/N) " -n 1 r
  msg ""
  [[ $r =~ ^[Yy]$ ]] || exit 0
fi

msg "Installing vp..." "→ Downloading vp..."
for url in "$REPO/vp" "$RAW/vp"; do
  curl -fsL "$url" -o /tmp/vp 2>/dev/null && break
done
[[ -f /tmp/vp ]] || die "Error: Failed to download vp\nThe repository might not be deployed yet.\nTry: curl -fsL $RAW/vp | sudo tee /usr/local/bin/vp >/dev/null && sudo chmod +x /usr/local/bin/vp" 1

chmod +x /tmp/vp
msg "→ Installing to /usr/local/bin/vp (requires sudo)..."
sudo mv /tmp/vp /usr/local/bin/vp

has vp || die "Error: Installation failed" 1
msg "" "✓ Installation successful!" "" "Usage:" "  vp list                   # List available packages" "  vp search <query>         # Search packages" "  vp install <package>      # Install a package" "  vp info <package>         # Show package info" "  vp update                 # Update vp itself" "" "Try: vp install firefox"
