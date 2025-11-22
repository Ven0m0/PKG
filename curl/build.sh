# https://github.com/curl/curl/blob/master/GIT-INFO.md
# https://curl.se/docs/install.html
#
# https://gitlab.archlinux.org/archlinux/packaging/packages/curl-rustls/-/blob/main/PKGBUILD
#
# https://github.com/stunnel/static-curl
#
# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=curl-http3
# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=curl-c-ares


./configure \
  --with-ssl       \
  --enable-http2   \
  --enable-http3   \
  --with-nghttp2   \
  --with-nghttp3   \
  --with-ngtcp2    \
  --with-quiche    \
  --with-brotli    \
  --with-zstd      \
  --with-libssh2   \
  --enable-hsts    \
  --enable-ipv6 \
  --enable-threaded-resolver \
  --enable-websockets \
  --with-gssapi \
  --with-openssl \
  --with-openssl-quic \
  --enable-quic \
  --enable-earlydata \
  --disable-manual \
  --disable-shared \
  --disable-ldap \
  --disable-ldaps \
  --with-gssapi \
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

 
