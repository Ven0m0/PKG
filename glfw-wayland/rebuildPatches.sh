#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

readonly basedir="$PWD"
echo "Rebuilding patch files from current fork state..."

cleanupPatches(){
  local patch gitver diffs testver
  cd "$1"
  for patch in *.patch; do
    gitver=$(tail -n 2 "$patch" | grep -ve "^$" | tail -n 1)
    diffs=$(git diff --staged "$patch" | grep -E "^(\+|\-)" | grep -Ev "(From [a-z0-9]{32,}|\-\-\- a|\+\+\+ b|.index)")

    # Check if gitver appears in the last non-empty lines and strip if so
    testver=$(echo "$diffs" | tail -n 2 | grep -ve "^$" | tail -n 1 | grep -F "$gitver" || true)
    if [[ -n "$testver" ]]; then
      diffs=$(echo "$diffs" | head -n -2)
    fi

    if [[ -z "$diffs" ]]; then
      git reset HEAD "$patch" >/dev/null
      git checkout -- "$patch" >/dev/null
    fi
  done
}

savePatches(){
  local what="$1"
  local target="$2"

  cd "$basedir/$target"
  git format-patch --no-stat -N -o "$basedir/patches/" upstream/upstream
  cd "$basedir"
  git add -A "$basedir/patches"
  cleanupPatches "$basedir/patches"
  echo "  Patches saved for $what to patches/"
}

savePatches glfw glfw-wayland
