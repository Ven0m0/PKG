#!/usr/bin/env bash

files="$(LC_ALL=C find . -name "PKGBUILD")"
for f in "$files"; do
  d=$(dirname $f); cd $d
  updpkgsums
  makepkg --printsrcinfo >.SRCINFO
  #rm -rf *.patch
  cd ..
done
