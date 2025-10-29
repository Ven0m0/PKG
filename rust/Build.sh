#!/usr/bin/env bash
set -euo pipefail

git clone --depth=1 git@github.com:rust-lang/rust.git && cd rust
./configure --enable-llvm-link-shared --release-channel=nightly --enable-llvm-assertions --enable-offload --enable-enzyme --enable-clang --enable-lld \
--enable-option-checking --enable-ninja --disable-docs --set llvm.libzstd=true --set rust.jemalloc --set rust.use-lld=true --set rust.lto=fat \
--set rust.codegen-units=1 --disable-compiler-docs

llvm-plugins
llvm-enzyme
llvm-assertions
optimize-llvm
new-symbol-mangling
use-libcxx
clang
llvm-bitcode-linker
lld
optimize-tests
use_bolt
