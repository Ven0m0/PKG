#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'

readonly ARCH_REPO=https://gitlab.archlinux.org/archlinux/packaging/packages
readonly ALARM_REPO=https://github.com/archlinuxarm/PKGBUILDs.git

# ArchlinuxARM has all the PKGBUILDs in a single repository instead
readonly ALARM_DIR="${TMPDIR:-/tmp}"/ALARM-PKGBUILDS

if [[ $ARCH == x86_64 ]]; then
  git clone --depth 1 "$ARCH_REPO/$PACKAGE" "$BUILD_DIR"
elif [[ $ARCH == aarch64 ]]; then
  git clone --depth 1 "$ALARM_REPO" "$ALARM_DIR"
  # if ALARM does not have the package, then use the archlinux package directly
  if compgen -G "$ALARM_DIR/*/$PACKAGE" &>/dev/null; then
    mv -v "$ALARM_DIR"/*/"$PACKAGE" "$BUILD_DIR"
  else
    printf '%s\n' '----------------------------------------' "ArchlinuxARM does not have '$PACKAGE'" 'Using Archlinux PKGBUILD instead...' '----------------------------------------' >&2
    git clone --depth 1 "$ARCH_REPO/$PACKAGE" "$BUILD_DIR"
  fi
  rm -rf "$ALARM_DIR"
fi

# change arch for aarch64 support, even ArchlinuxARM PKGBUILDs need this...
sed -i -e "s|x86_64|$ARCH|" "$PKGBUILD"

# always build without debug info
sed -i -e 's|-g1|-g0|' "$PKGBUILD"
