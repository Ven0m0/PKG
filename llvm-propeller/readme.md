# LLVM Propeller

Profile-guided, relinking optimizer for warehouse-scale applications built on LLVM.

## Description

LLVM Propeller is a compiler optimization tool developed by Google that uses profile-guided optimizations (PGO) and binary relinking to improve the performance of large-scale applications.

## Source

- Upstream: https://github.com/google/llvm-propeller
- CachyOS PKGBUILD: https://github.com/CachyOS/CachyOS-PKGBUILDS/tree/master/llvm-propeller

## Build Instructions

```bash
cd llvm-propeller
makepkg -si
```

## Features

- Profile-guided optimization using LLVM
- Binary relinking for improved performance
- Designed for warehouse-scale applications
- Built with Clang compiler (required by upstream)

## License

Apache-2.0
