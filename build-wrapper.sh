#!/usr/bin/env bash
set -euo pipefail

pkg="${1:?Package name required}"
method="${2:-standard}"
DOCKER_PKGS="obs-studio|firefox|egl-wayland2|onlyoffice"

# Detect method if not provided
if [[ -z "${2:-}" ]] && [[ "$pkg" =~ ^($DOCKER_PKGS)$ ]]; then
  method="docker"
fi
echo "::group::Building $pkg (Method: $method)"
if [[ "$method" == "docker" ]]; then
  # Your complex Docker logic here
  docker run --rm -v "$(pwd):/ws" -w /ws archlinux:latest bash -c "
    pacman -Syu --noconfirm base-devel
    cd '$pkg'
    # ... extraction logic ...
    runuser -u builder makepkg
  "
else
  # Standard build
  cd "$pkg"
  makepkg -s --noconfirm
fi
echo "::endgroup::"
