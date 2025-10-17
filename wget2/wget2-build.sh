#!/bin/bash

sudo -v

wget https://gnuwget.gitlab.io/wget2/wget2-latest.tar.gz && tar xf wget2-latest.tar.gz
cd wget2-*
#git clone https://gitlab.com/gnuwget/wget2.git && cd wget2
sleep 1
#./bootstrap

echo "🔄 Configuring wget2..."

export CC=clang && export CXX=clang++ && export LD=lld && export CC_LD=lld && export CXX_LD=lld && export AR=llvm-ar

export CFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt -fno-semantic-interposition -fdata-sections -ffunction-sections -fmerge-all-constants"

export LDFLAGS="-fuse-ld=lld -Wl,-O3 -Wl,--sort-common -Wl,--as-needed -Wl,-gc-sections -Wl,--strip-all -Wl,--compress-debug-sections=zstd"

# export LDFLAGS="-fuse-ld=lld -L/usr/lib -Wl,-O3 -Wl,--sort-common -Wl,--as-needed -Wl,-gc-sections -Wl,--strip-all -Wl,--compress-debug-sections=zstd"
#export LIBS="-lwolfssl"
#export LIBS="-lssl -lcrypto"

#./configure --with-lzma --with-linux-crypto --with-ssl=openssl --with-bzip2 --with-openssl=yes --enable-threads=posix --enable-year2038 --disable-doc --enable-manylibs
#./configure --with-linux-crypto --with-ssl=openssl --with-openssl=yes --enable-threads=posix --disable-doc
#./configure --with-linux-crypto --with-ssl=wolfssl --enable-threads=posix --disable-doc
# make -j$(nproc)
./configure --with-linux-crypto --enable-threads=posix --disable-doc
make -j$(nproc)
make check

echo "🚀 Build success, now installing..."

sudo make install

read -s -r -p "✅ Wget2 compiled and got installed, press Enter to exit"

make clean && ./configure --with-linux-crypto --enable-threads=posix --disable-doc && make -j$(nproc) && make check
