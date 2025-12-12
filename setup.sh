#!/usr/bin/env bash
set -e

ARCH="$(uname -m)"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export DEPLOY_PIPEWIRE=1
export DEPLOY_QT=1
export URUNTIME_PRELOAD=1
export OPTIMIZE_LAUNCH=1
export PYTHON_LEAVE_PIP=1

poststrip() {
  strip -s -R .comment --strip-unneeded ./*.so*
}
