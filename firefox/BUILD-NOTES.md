# Firefox Custom Build - Optimized PKGBUILD

This is an ultimate optimized Firefox PKGBUILD merged from multiple variants, featuring aggressive optimizations, hardware acceleration, and privacy enhancements.

## Features

### Performance Optimizations
- **Profile-Guided Optimization (PGO)**: Enabled by default with profile reuse for faster rebuilds
- **Aggressive compiler flags**: -O3, march=native, LTO, Polly loop optimization
- **Optional LLVM BOLT**: Post-link binary optimization (requires llvm-bolt)
- **Smart core limiting**: Automatically limits parallel builds based on available RAM
- **sccache support**: Auto-detected for faster compilation
- **Enhanced WASM optimizations**: Memory64, multi-memory, branch hinting, relaxed SIMD
- **Aggressive optimization flags**: Disabled security hardening features (PHC, DMD) for maximum performance
- **Rust optimizations**: Target-cpu=native, LTO, zero debug info, no frame pointers

### Hardware Acceleration
- **VA-API**: Hardware video decoding (force-enabled)
- **WebRender**: GPU-accelerated rendering
- **Hardware H.264**: WebRTC hardware encoding
- **AV1 support**: Hardware AV1 decoding

### System Integration
- **System libraries**: Uses system nspr, nss, vpx, webp, icu, av1, harfbuzz, graphite
- **Wayland native**: Full Wayland support
- **WASM optimizations**: SIMD/AVX/Memory64/Multi-memory/Branch hinting/Relaxed SIMD enabled
- **KDE integration**: Patches included for better KDE desktop integration
- **Image format support**: JXL (JPEG XL), RAW, AV1 image formats enabled

### Privacy & Enhancements
- **Telemetry disabled**: All tracking and telemetry disabled by default
- **JXL support**: JPEG XL image format enabled
- **Privacy preferences**: Privacy-focused vendor.js
- **No startup pages**: Forced homepage removed

## Build Tunables

Control the build behavior using environment variables:

```bash
# CPU architecture (default: native)
NATIVE_ARCH=native

# Profile-Guided Optimization (default: true)
ENABLE_PGO=true

# Reuse previous PGO profiles for faster rebuilds (default: true)
ENABLE_PGO_REUSE=true

# LLVM BOLT optimization - requires llvm-bolt (default: false)
ENABLE_BOLT=false

# Polly loop optimization (default: true)
ENABLE_POLLY=true

# Hardware video acceleration (default: true)
ENABLE_VAAPI=true

# Smart RAM-based core limiting (default: true)
BUILD_LIMIT_CORES=true
```

## Build Instructions

### Standard Build (with PGO)
```bash
makepkg -si
```

This will:
1. Build an instrumented Firefox
2. Run it to generate PGO profiles
3. Rebuild with optimizations using the profiles

**Note**: PGO build takes ~3x longer but results in ~20% better performance.

### Quick Build (without PGO)
```bash
ENABLE_PGO=false makepkg -si
```

### Rebuild with existing PGO profiles
Once you've built with PGO once, subsequent builds will reuse the profiles:
```bash
makepkg -si  # Much faster on subsequent builds!
```

### Maximum optimization (with BOLT)
Requires `llvm-bolt` to be installed:
```bash
ENABLE_BOLT=true makepkg -si
```

### Low memory build
If you have limited RAM:
```bash
BUILD_LIMIT_CORES=true makepkg -si
```

Or manually specify core count:
```bash
BUILD_LIMIT_CORES=2 makepkg -si
```

## Applied Patches

1. **0001-enable-vaapi.patch**: Enables VA-API hardware acceleration
2. **0002-remove-nvidia-blocklist.patch**: Removes NVIDIA blocklist for VA-API
3. **0018-bmo-1516081-Disable-watchdog-during-PGO-builds.patch**: Improves PGO reliability
4. **0024-Add-KDE-integration-to-Firefox.patch**: Better KDE desktop integration

## Hardware Acceleration Setup

### For Intel/AMD GPUs:
```bash
# Install VA-API drivers
sudo pacman -S libva-mesa-driver mesa-vdpau

# Verify VA-API works
vainfo
```

### For NVIDIA GPUs:
```bash
# Install NVIDIA VA-API driver
yay -S libva-nvidia-driver-git

# Verify
vainfo
```

### Enable in Firefox:
Hardware acceleration is enabled by default in this build. Check in Firefox:
1. Go to `about:support`
2. Look for "GPU" section
3. Should show "Hardware WebRender" and "VA-API" enabled

## Build Requirements

### Disk Space
- ~30 GB for full PGO build
- ~20 GB for non-PGO build

### RAM
- Minimum: 8 GB
- Recommended: 16 GB (for parallel builds)
- With PGO: 16+ GB recommended

### Build Time (approximate)
- With PGO, 8 cores: 2-3 hours (first build), 1-1.5 hours (subsequent)
- Without PGO, 8 cores: 45-60 minutes

## Performance Tips

1. **Use ccache/sccache**: Significantly speeds up rebuilds
   ```bash
   yay -S sccache
   ```

2. **Profile reuse**: Keep PGO profiles between builds
   - Profiles stored in `$SRCDEST` or `.pgo-cache`
   - Automatically reused with `ENABLE_PGO_REUSE=true`

3. **RAM-based builds**: Build in tmpfs if you have enough RAM
   ```bash
   # Add to /etc/fstab
   tmpfs /tmp tmpfs defaults,size=32G 0 0
   ```

4. **Parallel builds**: Automatically optimized based on available RAM

## Troubleshooting

### Out of Memory during linking
```bash
# Reduce parallel jobs
BUILD_LIMIT_CORES=2 makepkg -si
```

### PGO profile generation fails
The build will automatically continue without PGO. Check:
- Xvfb is installed: `pacman -S xorg-server-xvfb`
- dbus is running: `pacman -S dbus`

### Compilation errors with -march=native
```bash
# Use a specific architecture
NATIVE_ARCH=x86-64-v3 makepkg -si
```

### Build is too slow
```bash
# Disable PGO
ENABLE_PGO=false makepkg -si

# Or use pre-generated profiles (if you built before)
ENABLE_PGO_REUSE=true makepkg -si
```

## Comparison to Stock Firefox

| Feature | Stock Arch Firefox | This Build |
|---------|-------------------|------------|
| PGO | ✓ | ✓ |
| LTO | ✓ | ✓ (cross,full) |
| march=native | ✗ | ✓ |
| Polly | ✗ | ✓ (optional) |
| BOLT | ✗ | ✓ (optional) |
| VA-API forced | ✗ | ✓ |
| System libs | Partial | Maximum |
| Telemetry | Enabled | Disabled |
| KDE integration | ✗ | ✓ |

## Optimizations from Firefox Vanilla

This build now incorporates advanced optimizations from the [Firefox Vanilla](https://github.com/Ven0m0/firefox-vanilla) project:

- **Enhanced WASM support**: Added memory64, multi-memory, branch hinting, and relaxed SIMD features
- **Aggressive module disabling**: Disabled PHC (Probabilistic Heap Checker), DMD (Dark Matter Detector), and Valgrind integration
- **Property minification**: JavaScript property minification for smaller binaries
- **RAW image support**: Native support for RAW image formats
- **Optimized Rust compilation**: Enhanced RUSTFLAGS with debuginfo=0 and no frame pointers

These optimizations are based on Firefox Vanilla's ESR 140 branch, which showed benchmark improvements of:
- Octane 2.0: +0.38%
- Speedometer 2.1: +2.00%
- Speedometer 3.0: +2.17%
- JetStream 3.0: +3.81%
- MotionMark 1.3.1: +15.50%

## Credits

This PKGBUILD is merged from:
- Arch Linux official Firefox PKGBUILD
- firefox-vaapi (VA-API patches)
- firefox-kde-opensuse (KDE integration, system libs)
- Floorp PKGBUILD (PGO reuse, smart core limiting)
- Flowfox and Waterfox PKGBUILDs
- [Firefox Vanilla](https://github.com/Ven0m0/firefox-vanilla) (Advanced optimizations, WASM enhancements)

## License

Mozilla Public License 2.0 (MPL-2.0)
