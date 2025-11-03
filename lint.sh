#!/usr/bin/env bash
set -e; shopt -s globstar nullglob
LC_ALL=C LANG=C
pkgs=($(find -O2 . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||'))
errs=()
for pkg in "${pkgs[@]}"; do
  [[ -d $pkg ]] || continue
  cd "$pkg"
  echo "==> $pkg"
  if [[ ! -f PKGBUILD ]]; then
    errs+=("$pkg: no PKGBUILD")
    cd - &>/dev/null
    continue
  fi
  if command -v shellcheck &>/dev/null; then
    shellcheck -x -a -s bash -f diff PKGBUILD | patch -Np1 || errs+=("$pkg: shellcheck failed")
  fi
  if command -v shellharden &>/dev/null; then
    shellharden --replace PKGBUILD || errs+=("$pkg: shellharden failed")
  fi
  if command -v shfmt &>/dev/null; then
    shfmt -ln bash -bn -s -i 2 -w PKGBUILD || || errs+=("$pkg: shfmt failed")
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
  cd - &>/dev/null
done
if ((${#errs[@]})); then
  printf '%s\n' "${errs[@]}" >&2
  exit 1
fi
echo "All checks passed"
