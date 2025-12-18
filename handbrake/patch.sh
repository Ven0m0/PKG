#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail; shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C
s=${BASH_SOURCE[0]}
[[ $s != /* ]] && s=$PWD/$s
cd -P -- "${s%/*}"

readonly BASEDIR="$PWD"
src_dir="HandBrake"
readonly help='Usage: patch.sh [src_dir="HandBrake"] [options]
The src_dir is the directory that contains the HandBrake source code (defaults to "HandBrake")
-c --clone -> option that clone the repo to src_dir
-h --help  -> print usage message
If no directory is found, the program exits'

[[ $# -gt 2 ]] && { printf '%s\n' "$help"; exit 1; }

for arg in "$@"; do
  case $arg in
  -h | --help)
    printf '%s\n' "$help"
    exit 0
    ;;
  -c | --clone)
    rm -rf HandBrake
    git clone https://github.com/HandBrake/HandBrake.git
    ;;
  -*)
    printf '%s option does not exist!\n%s\n' "$arg" "$help" >&2
    exit 1
    ;;
  *) src_dir=$arg ;;
  esac
done

[[ $src_dir == /* ]] || src_dir=$PWD/$src_dir

[[ ! -d $src_dir ]] && {
  printf 'Error: %s directory does not exist!\n%s\n' "$src_dir" "$help" >&2
  exit 1
}
[[ ! -d $BASEDIR/patches ]] && {
  printf 'Error: patches directory does not exist!\n' >&2
  exit 1
}

builtin cd "$src_dir" || exit 1

for filename in "$BASEDIR"/patches/*.patch; do
  [[ ! -f $filename ]] && {
    printf 'Warning: No patch files found in %s/patches/\n' "$BASEDIR" >&2
    break
  }
  printf 'Applying patch: %s\n' "$(basename "$filename")"
  git apply "$filename" || exit 1
done

git add -A
git -c user.name='ven0m0' -c user.email='ven0m0' commit -m "Patch"
