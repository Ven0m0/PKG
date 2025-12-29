---
post_title: "DXVK Unified Package: dxvk-gplasync-lowlatency / dxvk-sarek"
author1: "REPLACE_WITH_AUTHOR_NAME"
post_slug: "dxvk-gplasync-lowlatency-dxvk-sarek"
microsoft_alias: "REPLACE_WITH_ALIAS"
featured_image: "REPLACE_WITH_IMAGE_URL"
categories:
  - gaming
tags:
  - dxvk
  - vulkan
  - wine
  - performance
ai_note: "AI-assisted content"
summary: "Unified DXVK package providing dxvk-gplasync-lowlatency and dxvk-sarek variants for modern and legacy Vulkan-capable GPUs."
post_date: "2025-01-01"
---

## dxvk-gplasync-lowlatency / dxvk-sarek
## Description

Unified DXVK package supporting two variants:

1. **GPL Async + Low Latency** (default) - For modern GPUs with Vulkan 1.3+ support
2. **Sarek** - For older GPUs without Vulkan 1.3 support

This package combines the best of both worlds, allowing you to choose the appropriate DXVK variant for your hardware during build time.

## Variants

### GPL Async + Low Latency (default)

- **Version**: 2.7.1
- **Source**: <https://github.com/Digger1955/dxvk-gplasync-lowlatency>
- **Requirements**: Vulkan 1.3+ capable GPU
- **Features**:
  - Graphics Pipeline Library async shader compilation
  - Low latency frame pacing for reduced input lag
  - Based on DXVK 2.7.1
  - Optimized state cache handling
  - Full D3D8, D3D9, D3D10, and D3D11 support

**Ideal for**:
- Modern NVIDIA GPUs (GTX 900 series and newer)
- Modern AMD GPUs (GCN 4.0+, RDNA, RDNA2, RDNA3)
- Modern Intel GPUs (Arc series)

### Sarek

- **Version**: 1.11.0
- **Source**: <https://github.com/pythonlover02/DXVK-Sarek>
- **Requirements**: Vulkan 1.1+ capable GPU
- **Features**:
  - No Vulkan 1.3 requirement
  - Based on DXVK 1.11.0 branch
  - Configurable shader compilation using `DXVK_ALL_CORES`
  - State caching for reduced stuttering
  - Full D3D8, D3D9, D3D10, and D3D11 support

**Ideal for**:
- Older NVIDIA GPUs (GTX 600/700/800 series)
- Older AMD GPUs (GCN 1.0-3.0)
- Intel GPUs without Vulkan 1.3 support
- Any Vulkan-capable GPU without Vulkan 1.3

## Build Instructions

### Building GPL Async + Low Latency (default)

```bash
cd dxvk/dxvk-gplasync
makepkg -si
```

### Building Sarek variant

```bash
cd dxvk/dxvk-gplasync
_variant=sarek makepkg -si
```

## Usage

### Installation

After installing the package, run the setup script to install DXVK to a Wine prefix:

#### GPL Async + Low Latency

```bash
# Install to default Wine prefix
setup_dxvk install

# Install to specific Wine prefix
WINEPREFIX=/path/to/prefix setup_dxvk install

# Install without DXGI
setup_dxvk install --without-dxgi
```

#### Sarek

```bash
# Install to default Wine prefix
setup_dxvk_sarek install

# Install to specific Wine prefix
WINEPREFIX=/path/to/prefix setup_dxvk_sarek install

# Install without DXGI
setup_dxvk_sarek install --without-dxgi
```

## Configuration

### GPL Async + Low Latency Configuration

The package automatically sets `DXVK_ASYNC=1` via `/etc/environment.d/dxvk-async.conf`.

Additional options in `~/.wine/drive_c/users/$USER/dxvk.conf`:

```conf
# Enable async shader compilation
dxvk.enableAsync = True

# Enable graphics pipeline library
dxvk.enableGraphicsPipelineLibrary = True

# Low latency frame pacing
dxvk.lowLatencyAllowCpuFramesOverlap = False

# State cache
dxvk.enableStateCache = True
```

Environment variables:

```bash
# Enable async shader compilation (enabled by default)
DXVK_ASYNC=1

# Enable HUD for monitoring
DXVK_HUD=fps,frametimes,gpuload

# Full HUD
DXVK_HUD=full

# Frame rate limit
DXVK_FRAME_RATE=60
```

### Sarek Configuration

Sarek uses half CPU cores for shader compilation by default. To use all cores:

```bash
export DXVK_ALL_CORES=1
```

Additional options in `~/.wine/drive_c/users/$USER/dxvk.conf`:

```conf
# Enable state cache
dxvk.enableStateCache = True

# HUD settings
dxvk.hud = fps

# Maximum frame rate
dxvk.maxFrameRate = 60
```

Environment variables:

```bash
# Use all CPU cores for shader compilation
DXVK_ALL_CORES=1

# Enable HUD
DXVK_HUD=fps,frametimes,gpuload

# Frame rate limit
DXVK_FRAME_RATE=60

# Log level
DXVK_LOG_LEVEL=info
```

## Performance Tips

### GPL Async + Low Latency

1. **First Run**: Expect some stuttering during first gameplay as shaders compile
2. **State Cache**: Shaders are cached in `~/.cache/wine/dxvk_state_cache/`
3. **Low Latency**: Set `dxvk.lowLatencyAllowCpuFramesOverlap = False` for better input response
4. **Optimization**: `DXVK_ASYNC=1` is enabled by default for async compilation

### Sarek

1. **First Run**: Expect stuttering during initial shader compilation
2. **State Cache**: Located in `~/.cache/wine/dxvk_state_cache/`
3. **Multi-Core**: Use `DXVK_ALL_CORES=1` for faster shader compilation
4. **Frame Limiting**: Use `DXVK_FRAME_RATE` to cap framerate and reduce power consumption

## Compatibility

### GPL Async + Low Latency

- **Minimum**: Wine 7.0+, Vulkan 1.3+
- **Recommended**: Wine 9.0+, Vulkan 1.3+
- **GPU**: Vulkan 1.3 capable hardware

### Sarek

- **Minimum**: Wine 7.1+, Vulkan 1.1+
- **Recommended**: Wine 9.0+, Vulkan 1.2+
- **GPU**: Any Vulkan-capable GPU (no Vulkan 1.3 required)

## Which Variant Should I Use?

### Use GPL Async + Low Latency if:
- You have a modern GPU (2016 or newer)
- Your GPU supports Vulkan 1.3
- You want the latest features and best performance
- You play competitive games and need low latency

### Use Sarek if:
- You have an older GPU (pre-2016)
- Your GPU doesn't support Vulkan 1.3
- You need backward compatibility
- Standard DXVK doesn't work on your hardware

## Notes

- This package conflicts with other DXVK packages
- Both variants provide standard DXVK DLL overrides
- Setup scripts can install/uninstall from Wine prefixes
- Only one variant can be installed at a time

## Checking Your Vulkan Version

To check if your GPU supports Vulkan 1.3:

```bash
vulkaninfo | grep "apiVersion"
```

If the version is 1.3.x or higher, use the default GPL Async + Low Latency variant.
If it's 1.1.x or 1.2.x, use the Sarek variant.

## License

Zlib License

## Credits

- **GPL Async + Low Latency**: <https://github.com/Digger1955/dxvk-gplasync-lowlatency>
- **Sarek**: <https://github.com/pythonlover02/DXVK-Sarek>
- **Original DXVK**: <https://github.com/doitsujin/dxvk>
