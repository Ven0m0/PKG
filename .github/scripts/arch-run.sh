#!/usr/bin/env bash
# Run makepkg tooling on an Ubuntu runner: arch-run <package-dir> '<command>'
# from the repo root. The command runs as an unprivileged user with the
# runner's UID inside archlinux:base-devel, so files it writes need no chown.
# SRCDEST lives inside the --rm container, so tarballs and git+ clones vanish
# with it instead of filling the runner disk (run 38054504314).
set -euo pipefail
dir=${1:?usage: arch-run <package-dir> <command>}
shift
exec docker run --rm -e HOST_UID="$(id -u)" -e CMD="$*" \
  -v "${GITHUB_WORKSPACE:-$PWD}:/ws" -w "/ws/${dir}" archlinux:base-devel \
  bash -c '
    set -euo pipefail
    pacman -Sy --noconfirm --needed git pacman-contrib >/dev/null
    useradd -m -u "$HOST_UID" builder
    install -d -o builder /tmp/src
    exec su builder -c "SRCDEST=/tmp/src $CMD"
  '
