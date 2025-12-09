#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

readonly basedir="$PWD"
echo "Rebuilding Forked projects..."

applyPatch(){
  local what="$1"
  local target="$2"
  local branch="$3"

  cd "$basedir/$what"
  git fetch
  git reset --hard "$branch"
  git branch -f upstream >/dev/null

  cd "$basedir"
  if [[ ! -d "$basedir/$target" ]]; then
    git clone "$what" "$target" -b upstream
  fi

  cd "$basedir/$target"
  echo "Resetting $target to $what..."
  git remote rm upstream &>/dev/null || true
  git remote add upstream ../"$what" &>/dev/null
  git checkout master &>/dev/null
  git fetch upstream &>/dev/null
  git reset --hard upstream/upstream

  if [[ -z "$(find "$basedir/patches/" -maxdepth 1 -name '*.patch' -print -quit)" ]]; then
    echo "  No patches found for $target"
  else
    echo "  Applying patches to $target..."
    git am --abort || true
    if git am --3way "$basedir/patches/"*.patch; then
      echo "  Patches applied cleanly to $target"
    else
      echo "  Something did not apply cleanly to $target."
      echo "  Please review above details and finish the apply then"
      echo "  save the changes with rebuildPatches.sh"
      return 1
    fi
  fi
}

applyPatch glfw glfw-wayland master
