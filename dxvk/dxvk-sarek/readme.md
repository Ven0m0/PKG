# dxvk-sarek

## Description

DXVK Sarek is a specialized fork of DXVK designed for older GPUs that don't meet the Vulkan 1.3 requirement of modern DXVK. It backports quality-of-life improvements to the 1.10.x branch while maintaining compatibility with legacy hardware.

Perfect for users with:

- Older NVIDIA GPUs (GTX 600/700 series)
- Older AMD GPUs (GCN 1.0-3.0)
- Intel GPUs without Vulkan 1.3 support
- Any Vulkan-capable GPU that doesn't support Vulkan 1.3

## Features

- Full D3D8, D3D9, D3D10, and D3D11 support
- Based on DXVK 1.11.0 branch
- Configurable shader compilation using `DXVK_ALL_CORES`
- State caching for reduced stuttering
- Performance HUD with detailed metrics
- No Vulkan 1.3 requirement

## Source

- Upstream: <https://github.com/pythonlover02/DXVK-Sarek>
- Based on: <https://github.com/doitsujin/dxvk>

## Build Instructions

```bash
cd dxvk/dxvk-sarek
makepkg -si
```

## Usage

### Installation

After installing the package, run the setup script:

```bash
# Install to default Wine prefix
setup_dxvk_sarek install

# Install to specific Wine prefix
WINEPREFIX=/path/to/prefix setup_dxvk_sarek install

# Install without DXGI
setup_dxvk_sarek install --without-dxgi
```

### Configuration

Sarek uses half CPU cores for shader compilation by default. To use all cores:

```bash
export DXVK_ALL_CORES=1
```

Additional configuration in `~/.wine/drive_c/users/$USER/dxvk.conf`:

```conf
# Enable state cache
dxvk.enableStateCache = True

# HUD settings
dxvk.hud = fps

# Maximum frame rate
dxvk.maxFrameRate = 60
```

### Environment Variables

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

1. **First Run**: Expect stuttering during initial shader compilation
2. **State Cache**: Located in `~/.cache/wine/dxvk_state_cache/`
3. **Multi-Core**: Use `DXVK_ALL_CORES=1` for faster shader compilation
4. **Frame Limiting**: Use `DXVK_FRAME_RATE` to cap framerate and reduce power consumption

## Compatibility

- **Minimum**: Wine 7.1+, Vulkan 1.1+
- **Recommended**: Wine 9.0+, Vulkan 1.2+
- **GPU**: Any Vulkan-capable GPU (no Vulkan 1.3 required!)

## Differences from Standard DXVK

- No Vulkan 1.3 requirement (backward compatible)
- Based on 1.11.0 branch instead of 2.x
- Configurable CPU core usage for compilation
- Optimized for older hardware

## Notes

- Conflicts with other DXVK packages
- Use this if your GPU doesn't support Vulkan 1.3
- For modern GPUs, use dxvk-gplasync-lowlatency instead

## License

Zlib License
