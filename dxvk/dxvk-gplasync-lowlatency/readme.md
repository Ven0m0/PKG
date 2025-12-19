# dxvk-gplasync-lowlatency

## Description

DXVK fork with GPL Async shader compilation and Low Latency features for improved gaming performance on Linux. This variant combines:

- **GPL Async**: Graphics Pipeline Library async shader compilation for reduced stuttering
- **Low Latency**: Frame pacing improvements for reduced input lag
- Based on DXVK 2.7.1 with backported features from DXVK 2.6.2 and GPLAsync variants

## Features

- Asynchronous shader compilation (reduces stuttering)
- Low latency frame pacing options
- Optimized state cache handling
- Support for D3D8, D3D9, D3D10, and D3D11
- Vulkan 1.3 based implementation

## Source

- Upstream: <https://github.com/Digger1955/dxvk-gplasync-lowlatency>
- Based on: <https://github.com/doitsujin/dxvk>

## Build Instructions

```bash
cd dxvk/dxvk-gplasync-lowlatency
makepkg -si
```

## Usage

### Installation

After installing the package, run the setup script to install DXVK to a Wine prefix:

```bash
# Install to default Wine prefix
setup_dxvk install

# Install to specific Wine prefix
WINEPREFIX=/path/to/prefix setup_dxvk install

# Install without DXGI (useful for some games)
setup_dxvk install --without-dxgi
```

### Configuration

The package automatically sets `DXVK_ASYNC=1` via `/etc/environment.d/dxvk-async.conf`.

Additional configuration options in `~/.wine/drive_c/users/$USER/dxvk.conf`:

```conf
# Enable async shader compilation
dxvk.enableAsync = True

# Enable graphics pipeline library
dxvk.enableGraphicsPipelineLibrary = True

# Low latency frame pacing
dxvk.lowLatencyAllowCpuFramesOverlap = False

# State cache location
dxvk.enableStateCache = True
```

### Environment Variables

```bash
# Enable async shader compilation
DXVK_ASYNC=1

# Enable HUD for monitoring
DXVK_HUD=fps,frametimes,gpuload

# Full HUD
DXVK_HUD=full

# Frame rate limit
DXVK_FRAME_RATE=60
```

## Performance Tips

1. **First Run**: Expect some stuttering during first gameplay as shaders compile
2. **State Cache**: Shaders are cached in `~/.cache/wine/dxvk_state_cache/`
3. **Low Latency**: Set `dxvk.lowLatencyAllowCpuFramesOverlap = False` for better input response
4. **Optimization**: Use `DXVK_ASYNC=1` for async compilation (enabled by default)

## Compatibility

- Requires: Wine 7.0+ or Proton
- GPU: Vulkan 1.3 capable hardware
- Not compatible with very old GPUs (for older GPUs, see dxvk-sarek)

## Notes

- Conflicts with other DXVK packages
- Provides standard DXVK DLL overrides
- Setup script can install/uninstall from Wine prefixes

## License

Zlib License
