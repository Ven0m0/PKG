#!/bin/bash

sudo -v

git clone https://gitlab.com/gnuwget/wget2.git && cd wget2
sleep 1
./bootstrap

echo "🔄 Configuring wget2..."

export CC=clang && export CXX=clang++ && export LD=lld && export CC_LD=lld && export CXX_LD=lld && export AR=llvm-ar

export CFLAGS="-march=native -mtune=native -O3 -flto -pipe -fno-plt -fno-semantic-interposition -fdata-sections -ffunction-sections \
-fomit-frame-pointer -fvisibility=hidden -fmerge-all-constants -finline-functions -fjump-tables -pthread -ffast-math -fcf-protection=none \
-fveclib=SVML -fcomplex-arithmetic=improved -fopenmp -falign-functions=32 -falign-loops=32 -ffp-contract=fast -freciprocal-math \
-mprefer-vector-width=256 -fvectorize -fslp-vectorize -fno-trapping-math -fshort-enums -fshort-wchar"

export LDFLAGS="-fuse-ld=lld -Wl,-O3 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now \
-Wl,-z,pack-relative-relocs -Wl,-gc-sections -Wl,--icf=all \
-Wl,--lto-whole-program-visibility -Wl,--lto-O3 -Wl,--lto-partitions=1 \
-Wl,--optimize-bb-jumps -Wl,--compress-debug-sections=zstd \
-Wl,--discard-locals -Wl,--strip-all"

./configure --with-lzma --with-linux-crypto --with-ssl=openssl --with-bzip2 --with-openssl=yes --enable-threads=posix --enable-year2038 --enable-cross-guesses=risky --disable-doc --enable-manylibs --disable-libtool-lock

make -j$(nproc)
sleep 1

echo "🚀 Build success, now installing..."

sudo make install

read -s -r -p "✅ Wget2 compiled and got installed, press Enter to exit"
