#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob globstar
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}; [[ $s != /* ]] && s=$PWD/$s; cd -P -- "${s%/*}"

readonly basedir="$PWD"
printf 'Rebuilding patch files from current fork state...\n'

cleanupPatches(){
  local patch gitver diffs testver
  builtin cd "$1"
  for patch in *.patch; do
    gitver=$(tail -n 2 "$patch" | grep -ve "^$" | tail -n 1)
    diffs=$(git diff --staged "$patch" | grep -E "^(\+|\-)" | grep -Ev "(From [a-z0-9]{32,}|\-\-\- a|\+\+\+ b|.index)")
    testver=$(printf '%s\n' "$diffs" | tail -n 2 | grep -ve "^$" | tail -n 1 | grep -F "$gitver" || true)
    [[ -n $testver ]] && diffs=$(printf '%s\n' "$diffs" | head -n -2)
    [[ -z $diffs ]] && { git reset HEAD "$patch" >/dev/null; git checkout -- "$patch" >/dev/null; }
  done
}

savePatches(){
  local what=$1 target=$2
  builtin cd "$basedir/$target"
  git format-patch --no-stat -N -o "$basedir/patches/" upstream/upstream
  builtin cd "$basedir"
  git add -A "$basedir/patches"
  cleanupPatches "$basedir/patches"
  printf '  Patches saved for %s to patches/\n' "$what"
}

savePatches glfw glfw-wayland
