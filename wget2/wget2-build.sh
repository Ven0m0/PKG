#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

sudo -v

wget https://gnuwget.gitlab.io/wget2/wget2-latest.tar.gz
tar xf wget2-latest.tar.gz
cd wget2-* || exit 1

echo "🔄 Configuring wget2..."

export CC=clang
export CXX=clang++
export LD=lld
export CC_LD=lld
export CXX_LD=lld
export AR=llvm-ar

export CFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt -fno-semantic-interposition \
  -fdata-sections -ffunction-sections -fmerge-all-constants"
export LDFLAGS="-fuse-ld=lld -Wl,-O3 -Wl,--sort-common -Wl,--as-needed -Wl,-gc-sections \
  -Wl,--strip-all -Wl,--compress-debug-sections=zstd"

./configure --with-linux-crypto --enable-threads=posix --disable-doc
make -j"$(nproc)"
make check

echo "🚀 Build success, now installing..."

sudo make install

echo "✅ Wget2 compiled and installed successfully!"
