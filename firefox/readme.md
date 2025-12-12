# Firefox Custom - Ultimate Optimized Build

The most optimized Firefox PKGBUILD available, merged from multiple variants with the best features from each.

## Quick Start

```bash
# Standard optimized build with PGO
makepkg -si

# Quick build without PGO
ENABLE_PGO=false makepkg -si

# Maximum optimization with BOLT
ENABLE_BOLT=true makepkg -si
```

## Key Features

✅ **Profile-Guided Optimization** (PGO) with smart profile reuse
✅ **Optional 3-Stage Context-Sensitive PGO** (+1-3% performance)
✅ **VA-API hardware acceleration** (force-enabled for Intel/AMD/NVIDIA)
✅ **Aggressive compiler optimizations** (-O3, native arch, full LTO)
✅ **Polly loop optimization** for better vectorization
✅ **Smart RAM-based core limiting** (prevents OOM)
✅ **System library integration** (reduces size, improves compatibility)
✅ **Privacy-focused** (all telemetry disabled, Ghostery patches)
✅ **KDE integration patches** included
✅ **WASM SIMD/AVX/Memory64** optimizations enabled
✅ **sccache support** (auto-detected)
✅ **Firefox Vanilla optimizations** (Enhanced WASM, aggressive module disabling)
✅ **RAW image format support** enabled
✅ **Enhanced binary stripping** (aggressive size reduction)

## Build Options

Control build behavior with environment variables:

- `ENABLE_PGO=true` - Profile-Guided Optimization (~20% faster)
- `ENABLE_PGO_REUSE=true` - Reuse previous profiles (saves time)
- `ENABLE_PGO_3STAGE=false` - 3-stage context-sensitive PGO (+1-3% performance, 50% longer build)
- `ENABLE_BOLT=false` - LLVM BOLT optimization (requires llvm-bolt)
- `ENABLE_POLLY=true` - Polly loop optimization
- `ENABLE_VAAPI=true` - Hardware video acceleration
- `BUILD_LIMIT_CORES=true` - Auto-limit cores by RAM
- `NATIVE_ARCH=native` - CPU architecture target

## Performance

Compared to stock Firefox:

- ~20% faster (with PGO)
- ~15% better memory usage (march=native optimizations)
- Hardware video decoding enabled
- Better desktop integration

## Requirements

- **Disk**: 30GB for PGO build, 20GB without
- **RAM**: 16GB recommended, 8GB minimum
- **Time**: 2-3 hours first PGO build, 1 hour subsequent builds

## Documentation

See **BUILD-NOTES.md** for:

- Detailed feature list
- Build tunable options
- Hardware acceleration setup
- Troubleshooting guide
- Performance tips

## Applied Patches

1. **0001-enable-vaapi.patch** - VA-API hardware acceleration
1. **0002-remove-nvidia-blocklist.patch** - NVIDIA VA-API support
1. **0018-bmo-1516081-Disable-watchdog-during-PGO-builds.patch** - PGO reliability
1. **0024-Add-KDE-integration-to-Firefox.patch** - KDE desktop integration
1. **ghostery/0039-Remove-Firefox-View.patch** - Remove Firefox View (size reduction)
1. **ghostery/0040-Disable-experiments-reporting.patch** - Disable Nimbus experiments (size reduction)

## Credits

This ultimate PKGBUILD is merged from multiple optimized Firefox builds:

### Primary Sources

- **Arch Linux Official** - Base structure and dependencies
- **firefox-vaapi** - VA-API patches and hardware acceleration
- **firefox-kde-opensuse** - KDE integration, system libraries (harfbuzz, graphite, icu)
- **Floorp PKGBUILD** - PGO profile reuse, smart core limiting
- **Flowfox** - Clean build patterns
- **Waterfox** - Additional optimization techniques
- **[Firefox Vanilla](https://github.com/Ven0m0/firefox-vanilla)** - Enhanced WASM optimizations, aggressive performance tuning

### Additional Credits

- <https://build.opensuse.org/package/show/mozilla:Factory/MozillaFirefox>
- <https://gitlab.com/garuda-linux/firedragon>
- [Firefox-opt](https://github.com/Ven0m0/Firefox-opt)
- [firefox-vaapi-opt](https://github.com/lseman/PKGBUILDs/tree/main/firefox-vaapi-opt)
- <https://github.com/CachyOS/firefox-wayland-cachy-hg>
- <https://github.com/Betterbird/thunderbird-patches>
- <https://github.com/openSUSE/firefox-maintenance>
- <https://github.com/ghostery/user-agent-desktop>
- <https://github.com/CachyOS/CachyOS-Browser-Common>
- <https://github.com/CYFARE/HellFire>
- <https://github.com/VolRencs/PKGBUILDS>
- <https://github.com/zen-browser/desktop>

### Patches Sources

- openSUSE Firefox maintenance repository
- Arch Linux Firefox patches
- Custom VA-API enablement patches
- KDE integration patches

## Optimization Flags Used

```bash
# C/C++ flags
CFLAGS="-O3 -march=native -mtune=native -fomit-frame-pointer -ffunction-sections -fdata-sections -pipe -fno-plt -fno-semantic-interposition -fjump-tables"

# Linker flags
LDFLAGS="-Wl,-O3 -Wl,--gc-sections -Wl,--sort-common -Wl,--as-needed -Wl,-z,pack-relative-relocs -Wl,-z,relro -Wl,-z,now -flto -fuse-linker-plugin"

# Rust flags
RUSTFLAGS="-Ctarget-cpu=native -Copt-level=3 -Clto=fat -Ccodegen-units=1 -Cpanic=abort -Clink-arg=-fuse-ld=lld -Cllvm-args=-enable-dfa-jump-thread -Cdebuginfo=0 -Cforce-frame-pointers=no -Cembed-bitcode=yes -Cllvm-args=--inline-threshold=2000 -Cllvm-args=--vectorize-slp-max-reg-size=64"

# Polly (optional)
-mllvm -polly -mllvm -polly-vectorizer=stripmine
```

---

**Note**: First PGO build takes longer but subsequent builds reuse profiles for faster compilation.

**License**: Mozilla Public License 2.0 (MPL-2.0)
