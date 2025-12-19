# dxvk-nvapi-vkreflex-layer

## Description

Alternative NVAPI implementation on top of DXVK with Vulkan Reflex layer. Enables NVIDIA-specific features for games running through DXVK and VKD3D-Proton:

- **NVIDIA DLSS** (Deep Learning Super Sampling)
- **NVIDIA Reflex** (Low Latency)
- **NVIDIA PhysX**
- **NVAPI Support** for games requiring NVIDIA features

## Features

- Full NVAPI implementation for DXVK
- Vulkan Reflex layer for low-latency rendering
- DLSS support for AI-powered upscaling
- PhysX support
- Compatible with both Wine and Proton

## Source

- Upstream: <https://github.com/jp7677/dxvk-nvapi>
- PKGBUILD Base: <https://aur.archlinux.org/packages/dxvk-nvapi-vkreflex-layer>

## Build Instructions

```bash
cd dxvk/dxvk-nvapi
makepkg -si
```

## Usage

### For Wine Prefixes

```bash
# Install to default Wine prefix
setup_dxvk_nvapi install

# Install to specific Wine prefix
WINEPREFIX=/path/to/prefix setup_dxvk_nvapi install
```

### For Proton

```bash
# Install to Proton prefix
/usr/share/dxvk-nvapi-vkreflex-layer/setup_dxvk_proton.sh install
```

### Configuration

The package automatically configures DXVK environment variables via `/etc/environment.d/dxvk-nvapi.conf`.

Additional configuration can be done via `dxvk.conf` in your Wine prefix:

```conf
# Enable NVAPI logging
dxvk.enableNvapi = True
dxvk.nvapiLogging = True

# DLSS settings
dxvk.nvapiDlss = True

# Reflex settings
dxvk.nvapiReflex = True
```

### Environment Variables

```bash
# Enable NVAPI debug logging
DXVK_NVAPI_LOG_LEVEL=info

# Enable Vulkan Reflex
VKD3D_CONFIG=dxr

# DXVK HUD to verify NVAPI is working
DXVK_HUD=api,fps
```

## Compatibility

- **GPU**: NVIDIA GPUs with Vulkan support
- **Features**:
  - DLSS: RTX 20/30/40 series
  - Reflex: GTX 900+ series
  - PhysX: Most NVIDIA GPUs
- **Software**: Wine 7.0+, Proton 5.0+

## Requirements

- NVIDIA GPU with proprietary drivers
- Vulkan-capable drivers (495.44+)
- DXVK or VKD3D-Proton

## Features Supported

| Feature         | Support       | Requirements               |
| --------------- | ------------- | -------------------------- |
| DLSS 2.x        | ✅ Full        | RTX 20/30/40 series        |
| DLSS 3.x        | ✅ Full        | RTX 40 series              |
| Reflex          | ✅ Full        | GTX 900+ series            |
| PhysX           | ✅ Full        | Most NVIDIA GPUs           |
| NVAPI Calls     | ✅ Full        | All supported GPUs         |
| Ray Tracing API | ⚠️ Partial    | RTX series                 |

## Notes

- Only works with NVIDIA GPUs
- Requires proprietary NVIDIA drivers
- Some games may require specific tweaks
- Check game compatibility at <https://www.pcgamingwiki.com/>

## Troubleshooting

### DLSS Not Working

1. Ensure you have RTX 20+ series GPU
2. Check driver version (495.44+)
3. Enable in game settings
4. Verify with `DXVK_HUD=api,fps`

### Reflex Not Working

1. Ensure GPU supports Reflex (GTX 900+)
2. Enable in game settings
3. Check `DXVK_NVAPI_LOG_LEVEL=info` for errors

## License

MIT License
