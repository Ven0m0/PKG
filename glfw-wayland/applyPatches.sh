#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob globstar
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}
[[ $s != /* ]] && s=$PWD/$s
cd -P -- "${s%/*}"

readonly basedir="$PWD"
printf 'Rebuilding Forked projects...\n'

applyPatch() {
  local what=$1 target=$2 branch=$3
  builtin cd "$basedir/$what"
  git fetch
  git reset --hard "$branch"
  git branch -f upstream >/dev/null
  builtin cd "$basedir"
  [[ -d $basedir/$target ]] || git clone "$what" "$target" -b upstream
  builtin cd "$basedir/$target"
  printf 'Resetting %s to %s...\n' "$target" "$what"
  git remote rm upstream &>/dev/null || true
  git remote add upstream ../"$what" &>/dev/null
  git checkout master &>/dev/null
  git fetch upstream &>/dev/null
  git reset --hard upstream/upstream
  if [[ -z $(find "$basedir/patches/" -maxdepth 1 -name '*.patch' -print -quit) ]]; then
    printf '  No patches found for %s\n' "$target"
  else
    printf '  Applying patches to %s...\n' "$target"
    git am --abort || true
    if git am --3way "$basedir/patches/"*.patch; then
      printf '  Patches applied cleanly to %s\n' "$target"
    else
      printf '  Something did not apply cleanly to %s.\n' "$target"
      printf '  Please review above details and finish the apply then\n'
      printf '  save the changes with rebuildPatches.sh\n'
      return 1
    fi
  fi
}

applyPatch glfw glfw-wayland master
