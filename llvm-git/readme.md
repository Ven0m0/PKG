# LLVM Git

LLVM development version built from git sources. Includes clang, lldb, lld, and many other tools.

## Description

This package builds LLVM and related tools (clang, lldb, lld, polly, compiler-rt) from the latest git sources. It's intended for users who want to test bleeding-edge features or contribute to LLVM development.

## Source

- Upstream: https://github.com/llvm/llvm-project
- CachyOS PKGBUILD: https://github.com/CachyOS/CachyOS-PKGBUILDS/tree/master/llvm-git/llvm-git

## Build Instructions

```bash
cd llvm-git
makepkg -si
```

## Packages

This PKGBUILD produces two packages:

- **llvm-git**: LLVM development tools, clang, lldb, lld, and other utilities
- **llvm-libs-git**: Runtime libraries for LLVM

## Features

- Built from latest git sources
- Includes clang, lldb, lld, polly, compiler-rt, and bolt
- Provides multilib support
- Includes Python bindings for clang

## Note

**.SRCINFO should be generated locally** using:
```bash
makepkg --printsrcinfo > .SRCINFO
```

## License

Apache-2.0 with LLVM Exception
