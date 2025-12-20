#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail; shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C

# From: https://github.com/PikaOS-Linux/pkg-pika-pbuilder

has(){ command -v -- "$1" &>/dev/null; }
APTCACHEHARDLINK=yes
USENETWORK=yes
export DEBIAN_FRONTEND="noninteractive"
export DEB_BUILD_MAINT_OPTIONS="optimize=+lto -march=x86-64-v3 -O3 -flto -fuse-linker-plugin -falign-functions=32 -w -DQT_NO_VERSION_TAGGING"
export DEB_CFLAGS_MAINT_APPEND="-march=x86-64-v3 -O3 -flto -fuse-linker-plugin -falign-functions=32 -w -DQT_NO_VERSION_TAGGING"
export DEB_CPPFLAGS_MAINT_APPEND="-march=x86-64-v3 -O3 -flto -fuse-linker-plugin -falign-functions=32 -w -DQT_NO_VERSION_TAGGING"
export DEB_CXXFLAGS_MAINT_APPEND="-march=x86-64-v3 -O3 -flto -fuse-linker-plugin -falign-functions=32 -w -DQT_NO_VERSION_TAGGING"
export DEB_LDFLAGS_MAINT_APPEND="-march=x86-64-v3 -O3 -flto -fuse-linker-plugin -falign-functions=32"
export DEB_BUILD_OPTIONS="parallel=8 nocheck notest terse"
export DPKG_GENSYMBOLS_CHECK_LEVEL=0
DEBBUILDOPTS="-j8 -nc --no-sign"
EATMYDATA=yes
# Clone Upstream
mkdir -p ./src-pkg-name
cp -rvf ./debian ./src-pkg-name/
cd ./src-pkg-name/

# Get build deps
LOGNAME=root dh_make --createorig -y -l -p src-pkg-name_"$VERSION" || echo "dh-make: Ignoring Last Error"
apt-get build-dep ./ -y

# Build package
dpkg-buildpackage --no-sign

# Move the debs to output
cd ../
mkdir -p ./output
mv ./*.deb ./output/
