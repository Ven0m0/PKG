#!/usr/bin/env bash
set -euo pipefail

# Clone Rust repository
if [[ ! -d rust ]]; then
  git clone --depth=1 https://github.com/rust-lang/rust.git
fi

cd rust

# Configure Rust build with optimizations
./configure \
  --enable-llvm-link-shared \
  --release-channel=nightly \
  --enable-llvm-assertions \
  --enable-offload \
  --enable-enzyme \
  --enable-clang \
  --enable-lld \
  --enable-option-checking \
  --enable-ninja \
  --disable-docs \
  --disable-compiler-docs \
  --set llvm.libzstd=true \
  --set llvm.plugins=true \
  --set llvm.enzyme=true \
  --set llvm.assertions=true \
  --set llvm.optimize=true \
  --set llvm.use-libcxx=true \
  --set llvm.clang=true \
  --set llvm.bitcode-linker=true \
  --set llvm.lld=true \
  --set llvm.polly=true \
  --set rust.jemalloc=true \
  --set rust.use-lld=true \
  --set rust.lto=fat \
  --set rust.codegen-units=1 \
  --set rust.new-symbol-mangling=true \
  --set rust.optimize-tests=true

# Build Rust
./x.py build --stage 2

# Install (optional)
# sudo ./x.py install
