#!/usr/bin/env bash
set -euo pipefail

# Clear symlinks
cd /usr/lib/ccache/bin || exit 1
for file in {*-,}{c++,cc,clang,clang++,g++,gcc}{,-[0-9]*}; do
  if [[ -L "$file" ]]; then
    rm -- "$file"
  fi
done

# Recreate symlinks
cd /usr/bin || exit 1
for file in {*-,}{c++,cc,clang,clang++,g++,gcc}{,-[0-9]*}; do
  if [[ -x $file ]]; then
    ret=$(pacman -Qqo "/usr/bin/$file" 2>/dev/null | grep -e gcc -e clang || true)
    if [[ $ret ]]; then
      ln -s /usr/bin/ccache "/usr/lib/ccache/bin/$file"
    fi
  fi
done

# Update nvcc
{
  [[ -f /usr/lib/ccache/bin/nvcc-ccache ]] && rm "/usr/lib/ccache/bin/nvcc-ccache"
  if [[ -f /opt/cuda/bin/nvcc ]]; then
    printf '%s\n' '#!/bin/sh -' '/usr/bin/ccache /opt/cuda/bin/nvcc "$@"' > /usr/lib/ccache/bin/nvcc-ccache
    chmod 755 /usr/lib/ccache/bin/nvcc-ccache
  fi
}
