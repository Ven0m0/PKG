# wine-cachyos

**CachyOS-optimized Wine builds with performance patches and modern compiler flags.**

## Variants

### wine-cachyos (Regular)
- **Install location**:  `/usr` (system-wide)
- **Conflicts with**: `wine`, `wine-mono`, `wine-gecko`
- **Full install**:  Binaries + libraries
- **Use case**: Primary Wine installation

### wine-cachyos-opt
- **Install location**: `/opt/wine-cachyos` (isolated)
- **No conflicts**:  Can coexist with system Wine
- **Libraries only**: No binaries (use with launchers like Lutris/Bottles)
- **Use case**: Alternative Wine version for testing or specific applications

## Build Differences from Upstream CachyOS

1. **Optimization level**: Changed `-O2` → `-O3` for maximum performance
2. **Formatting**: Applied 2-space indentation and shellcheck compliance
3. **Simplified logic**: Removed redundant variable assignments
4. **Maintained**:  All CachyOS-specific patches and optimizations

## Features

- **NTsync support** (requires `ntsync-common` + kernel module)
- **Wayland native support**
- **Performance flags**: AVX2, IPA-PTA, cheap vector cost model
- **Bundled**:  wine-gecko, wine-mono, xalia
- **FFmpeg support** (64-bit only for -opt variant)

## Building

```bash
cd wine-cachyos
makepkg -si  # Regular variant

# Or for opt variant
makepkg -si -p PKGBUILD-opt
```

## Usage (wine-cachyos-opt)

Add to your launcher's Wine prefix path:
```
/opt/wine-cachyos/bin/wine
```

Or symlink manually:
```bash
ln -s /opt/wine-cachyos/bin/wine ~/. local/bin/wine-cachyos
```

## Upstream

- **Source**: https://github.com/CachyOS/wine-cachyos
- **PKGBUILD**: https://github.com/CachyOS/CachyOS-PKGBUILDS
