#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
src_dir="HandBrake"
help="Usage: patch.sh [src_dir=\"HandBrake\"] [options]
The src_dir is the directory that contains the HandBrake source code (defaults to \"HandBrake\")
-c --clone -> option that clone the repo to src_dir
-h --help  -> print usage message
If no directory is found, the program exits"

if [[ "$#" -gt 2 ]]; then
  echo "$help"; exit 1
fi
for (( i=1; i <= "$#"; i++ )); do
  case ${!i} in
    -h | --help) echo "$help"; exit 0 ;;
    -c | --clone)
      if [[ "$i" -lt "$#" ]]; then
        echo "$help"; exit 1
      fi
      rm -rf HandBrake
      git clone https://github.com/HandBrake/HandBrake.git ;;
    -*) echo "${!i} option doesn't exist!"; echo "$help"; exit 1 ;;
    *) src_dir="$1" ;;
  esac
done
# Resolve src_dir: if relative, make it relative to $PWD (not $BASEDIR)
[[ "$src_dir" = /* ]] || src_dir="$PWD/$src_dir"
if [[ ! -d "$src_dir" ]]; then
  echo "Error: $src_dir directory doesn't exist!"
  echo "$help"; exit 1
fi
if [[ ! -d "$BASEDIR/patches" ]]; then
  echo "Error: patches directory doesn't exist!"; exit 1
fi
cd "$src_dir" || exit 1
for filename in "$BASEDIR"/patches/*.patch; do
  [[ ! -f "$filename" ]] && { echo "Warning: No patch files found in $BASEDIR/patches/"; break; }
  echo "Applying patch: $(basename "$filename")"
  git apply "$filename" || exit 1
done
git add -A
git -c user.name='ven0m0' -c user.email='ven0m0' commit -m "Patch"
