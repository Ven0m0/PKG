# LLVM Minimal (Optimized)

Comprehensive LLVM toolchain with optimizations including clang, clang-tools-extra, lld, lldb, polly, bolt, and compiler-rt.

## Description

This package builds LLVM and related tools from git sources with performance optimizations:
- Optimized with -O3 and -fno-semantic-interposition
- Includes: clang, clang-tools-extra, lld (linker), lldb (debugger), polly (polyhedral optimizer), bolt (binary optimizer), compiler-rt
- Multilib support
- X86 target architecture
- Uses distribution components to minimize package size

## Features

- **Performance optimizations**: -O3, -fno-semantic-interposition, minimal debug info
- **Comprehensive toolset**: clang, lld, lldb, polly, bolt
- **Multilib support**: Compatible with 32-bit and 64-bit builds
- **Minimal size**: Distribution components used to avoid unnecessary static libraries

## Source

- Upstream: https://github.com/llvm/llvm-project
- Based on: [CachyOS LLVM](https://github.com/CachyOS/CachyOS-PKGBUILDS/tree/master/llvm)

## Build Instructions

```bash
cd llvm
makepkg -si
```

## Packages

This PKGBUILD produces five packages:
- **llvm-minimal**: LLVM tools, clang, lld, lldb, polly, bolt
- **llvm-libs-minimal**: Runtime libraries
- **clang-minimal**: Clang compiler and tools
- **clang-libs-minimal**: Clang runtime libraries
- **clang-opencl-headers-minimal**: OpenCL headers

## License

Apache-2.0 WITH LLVM-exception
