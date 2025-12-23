#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'

export ARCH="$(uname -m)"
export CC=gcc
export CXX=g++

SCRIPT="$1"
PACKAGE="${SCRIPT##*/}"
PACKAGE="${PACKAGE%-mini.sh}"
PACKAGE="${PACKAGE%-nano.sh}"
export PACKAGE
export BUILD_DIR="$PWD"/tmpbuild
export PKGBUILD="$BUILD_DIR"/PKGBUILD

_cleanup(){ rm -rf "$BUILD_DIR"; }
trap _cleanup INT TERM EXIT

case $ARCH in
x86_64) export EXT=zst ;;
aarch64) export EXT=xz ;;
*)
  printf 'Unsupported Arch: %s\n' "$ARCH" >&2
  exit 1
  ;;
esac

if [[ $PACKAGE != qt6-base ]]; then
  export CMAKE_C_COMPILER_LAUNCHER=ccache
  export CMAKE_CXX_COMPILER_LAUNCHER=ccache
else
  export CMAKE_C_COMPILER_LAUNCHER=sccache
  export CMAKE_CXX_COMPILER_LAUNCHER=sccache
fi

export PATH="$PWD:$PWD/bin:$PATH:/usr/bin/core_perl"
chmod +x "$PWD"/bin/* "$PWD"/*.sh 2>/dev/null || true

if [[ ${FORCE_BUILD:-} == 1 ]]; then
  printf 'Forcing build!\n'
  printf 'Packages will be built and released regardless of version mismatch\n'
fi

if [[ -n ${ONE_PACKAGE:-} && ${ONE_PACKAGE:-} != "$PACKAGE" ]]; then
  printf 'ONE_PACKAGE is set to %s\n' "$ONE_PACKAGE" >&2
  printf 'Does not match %s, aborting...\n' "$PACKAGE" >&2
  : >~/OPERATION_ABORTED
  exit 0
fi

COUNT=0
while :; do
  if "$SCRIPT"; then
    [[ -f ~/OPERATION_ABORTED ]] && exit 0
    printf '%s\n' '----------------------------------------' 'Package built successfully!' '----------------------------------------'
    break
  else
    rm -rf "$BUILD_DIR"
    printf '%s\n' '----------------------------------------' 'Failed to build package, trying again...' '----------------------------------------' >&2
    ((COUNT++))
  fi
  if ((COUNT >= 3)); then
    printf '%s\n' '----------------------------------------' 'Failed to build package 3 times' '----------------------------------------' >&2
    exit 1
  fi
done

if [[ $PACKAGE != qt6-base ]]; then
  ccache -s -v
else
  sccache --show-stats
fi

mkdir ./dist
sha256sum ./*.pkg.tar.*
mv ./*.pkg.tar.* ./dist
