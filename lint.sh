#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
shopt -s globstar nullglob
export LC_ALL=C LANG=C
mapfile -t pkgs < <(find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||')
errs=()
original_dir="$PWD"

# Cache tool availability checks once (avoid repeated command lookups in loop)
has_shellcheck=false; command -v shellcheck &>/dev/null && has_shellcheck=true
has_shellharden=false; command -v shellharden &>/dev/null && has_shellharden=true

for pkg in "${pkgs[@]}"; do
  [[ -d $pkg ]] || continue
  cd "$original_dir/$pkg" || { errs+=("$pkg: cd failed"); continue; }
  echo "==> $pkg"
  if [[ ! -f PKGBUILD ]]; then
    errs+=("$pkg: no PKGBUILD")
    continue
  fi
  if $has_shellcheck; then
    shellcheck -x -a -s bash -f diff PKGBUILD | patch -Np1 || errs+=("$pkg: shellcheck failed")
  fi
  if $has_shellharden; then
    shellharden --replace PKGBUILD || errs+=("$pkg: shellharden failed")
  fi
  if [[ -f .SRCINFO ]]; then
    makepkg --printsrcinfo 2>/dev/null | diff --ignore-blank-lines .SRCINFO - &>/dev/null || {
      errs+=("$pkg: .SRCINFO out of sync")
      echo "Run: cd $pkg && makepkg --printsrcinfo > .SRCINFO"
    }
  else
    errs+=("$pkg: missing .SRCINFO")
    echo "Run: cd $pkg && makepkg --printsrcinfo > .SRCINFO"
  fi
done
cd "$original_dir"
if ((${#errs[@]})); then
  printf '%s\n' "${errs[@]}" >&2; exit 1
fi
echo "All checks passed"
