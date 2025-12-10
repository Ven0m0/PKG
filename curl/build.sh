#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob globstar
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}; [[ $s != /* ]] && s=$PWD/$s; cd -P -- "${s%/*}"

./configure \
  --prefix=/usr \
  --with-openssl \
  --with-openssl-quic \
  --enable-http2 \
  --enable-http3 \
  --with-nghttp2 \
  --with-nghttp3 \
  --with-ngtcp2 \
  --with-quiche \
  --with-brotli \
  --with-zstd \
  --with-libssh2 \
  --enable-hsts \
  --enable-ipv6 \
  --enable-threaded-resolver \
  --enable-websockets \
  --with-gssapi \
  --enable-quic \
  --enable-earlydata \
  --disable-manual \
  --disable-shared \
  --disable-ldap \
  --disable-ldaps \
  --with-rustls \
  --enable-ares \
  --with-ca-bundle='/etc/ssl/certs/ca-certificates.crt'

make -j"$(nproc)"
sudo make install

# % git clone https://github.com/wolfSSL/wolfssl.git
# % cd wolfssl
# % autoreconf -fi
# % ./configure --prefix=<somewhere1> --enable-quic --enable-session-ticket --enable-earlydata --enable-psk --enable-harden --enable-altcertchains
# % make
# % make install
