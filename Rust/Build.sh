#!/usr/bin/env bash
set -euo pipefail

git clone --depth=1 git@github.com:rust-lang/rust.git && cd rust
./configure --enable-llvm-link-shared --release-channel=nightly --enable-llvm-assertions --enable-offload --enable-enzyme --enable-clang --enable-lld --enable-option-checking --enable-ninja --disable-docs
