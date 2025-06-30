https://github.com/curl/curl/blob/master/GIT-INFO.md
https://curl.se/docs/install.html

https://gitlab.archlinux.org/archlinux/packaging/packages/curl-rustls/-/blob/main/PKGBUILD

https://github.com/stunnel/static-curl

https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=curl-http3
https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=curl-c-ares


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
  --disable-manual \
  --enable-ipv6 \
  --enable-threaded-resolver \
  --enable-websockets \
  --with-gssapi \
  --with-openssl \
  --with-openssl-quic \
  --disable-ldap \
  --disable-ldaps \

make -j"$(nproc)"
sudo make install
