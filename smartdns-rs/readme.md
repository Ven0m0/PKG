# smartdns-rs

A cross-platform local DNS server written in Rust that returns the fastest IP address.

## Description

SmartDNS-rs is a high-performance DNS server implementation that automatically selects the fastest responding IP address for domain queries. It's written in Rust for optimal performance and memory safety.

## Source

- Upstream: https://github.com/mokeyish/smartdns-rs

## Build Instructions

```bash
cd smartdns-rs
makepkg -si
```

## Features

- Cross-platform support (x86_64, aarch64)
- Optimized build with target-native CPU flags
- Link-time optimization with LLD linker
- Comprehensive test suite included

## License

GPL-3.0-or-later
