#!/bin/bash

sudo -v

git clone https://gitlab.com/gnuwget/wget2.git && cd wget2
sleep 1
./bootstrap

echo "🔄 Configuring wget2..."

export CC=clang && export CXX=clang++ && export LD=lld && export CC_LD=lld && export CXX_LD=lld && export AR=llvm-ar

export CFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt -fno-semantic-interposition -fdata-sections -ffunction-sections -fmerge-all-constants"

export LDFLAGS="-fuse-ld=lld -Wl,-O3 -Wl,--sort-common -Wl,--as-needed -Wl,-gc-sections -Wl,--strip-all -Wl,--compress-debug-sections=zstd"

./configure --with-lzma --with-linux-crypto --with-ssl=openssl --with-bzip2 --with-openssl=yes --enable-threads=posix --enable-year2038 --disable-doc --enable-manylibs

make -j$(nproc)
sleep 1

echo "🚀 Build success, now installing..."

sudo make install

read -s -r -p "✅ Wget2 compiled and got installed, press Enter to exit"
