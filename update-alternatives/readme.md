# update-alternatives

## Description

A Rust implementation of the Debian `update-alternatives` system for managing alternative versions of commands. This tool allows you to maintain multiple versions of a command and switch between them easily.

## Features

- Manage alternative versions of commands system-wide
- Fast Rust implementation with native optimizations
- Compatible with traditional update-alternatives workflows

## Source

- **Upstream**: https://github.com/fthomys/update-alternatives
- **License**: MIT
- **Build from**: Git commit `10fd49bb` (October 2025)

## Build Instructions

```bash
cd update-alternatives
makepkg -si
```

## Usage

After installation, use `update-alternatives` to manage command alternatives on your system.

## Optimizations

This package is built with:
- `-C target-cpu=native` for CPU-specific optimizations
- `-C opt-level=3` for maximum performance
- LLD linker for faster linking

## License

MIT
