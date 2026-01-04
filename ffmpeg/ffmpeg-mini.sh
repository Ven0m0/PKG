#!/bin/bash
set -e

sed -i -e 's|-O2|-Oz|' /etc/makepkg.conf
get-pkgbuild
cd "$BUILD_DIR"
# debloat package, remove x265 support
sed -i \
  -e '/x265/d' \
  "$PKGBUILD"
cat "$PKGBUILD"
# Do not build if version does not match with upstream
if check-upstream-version; then
  makepkg -fs --noconfirm --skippgpcheck
else
  exit 0
fi
ls -la
rm -fv ./*-docs-*.pkg.tar.* ./*-debug-*.pkg.tar.*
mv -v ./"$PACKAGE"-*.pkg.tar."$EXT" ../"$PACKAGE"-mini-"$ARCH".pkg.tar."$EXT"
echo "All done!"
