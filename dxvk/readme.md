# dxvk

## Description

Comprehensive collection of DXVK variants optimized for different use cases and hardware. DXVK is a Vulkan-based translation layer for Direct3D 9/10/11, allowing Windows games to run on Linux with improved performance.

## Variants

This repository includes three DXVK variants:

### 1. dxvk-gplasync-lowlatency

**Best for: Modern GPUs with Vulkan 1.3 support**

- Based on DXVK 2.7.1 with GPLAsync and Low Latency features
- GPL Async shader compilation for reduced stuttering
- Low latency frame pacing for reduced input lag
- Optimized state cache handling
- Supports D3D8, D3D9, D3D10, D3D11

[Read more →](dxvk-gplasync-lowlatency/readme.md)

### 2. dxvk-sarek

**Best for: Older GPUs without Vulkan 1.3 support**

- Based on DXVK 1.11.0 for older hardware compatibility
- No Vulkan 1.3 requirement (supports Vulkan 1.1+)
- Configurable CPU core usage for shader compilation
- Perfect for GTX 600/700 series, older AMD GCN GPUs
- Backported QoL improvements from newer DXVK

[Read more →](dxvk-sarek/readme.md)

### 3. dxvk-nvapi-vkreflex-layer

**Best for: NVIDIA GPUs requiring DLSS/Reflex support**

- NVAPI implementation for NVIDIA-specific features
- DLSS (Deep Learning Super Sampling) support
- NVIDIA Reflex for ultra-low latency
- PhysX support
- Works with both Wine and Proton

[Read more →](dxvk-nvapi/readme.md)

## Quick Start

### Choose Your Variant

```bash
# For modern GPUs (Vulkan 1.3+)
cd dxvk/dxvk-gplasync-lowlatency
makepkg -si

# For older GPUs (Vulkan 1.1+)
cd dxvk/dxvk-sarek
makepkg -si

# For NVIDIA-specific features
cd dxvk/dxvk-nvapi
makepkg -si
```

### Install to Wine Prefix

```bash
# dxvk-gplasync-lowlatency
setup_dxvk install

# dxvk-sarek
setup_dxvk_sarek install

# dxvk-nvapi
setup_dxvk_nvapi install
```

## Comparison Table

| Feature                 | gplasync-lowlatency | sarek    | nvapi         |
| ----------------------- | ------------------- | -------- | ------------- |
| **DXVK Version**        | 2.7.1               | 1.11.0   | Layer only    |
| **Vulkan Requirement**  | 1.3                 | 1.1+     | 1.1+          |
| **GPL Async**           | ✅                   | ❌        | N/A           |
| **Low Latency Mode**    | ✅                   | ❌        | ✅ (Reflex)    |
| **Old GPU Support**     | ❌                   | ✅        | ⚠️ (NVIDIA)   |
| **DLSS Support**        | ❌                   | ❌        | ✅             |
| **NVIDIA Reflex**       | ❌                   | ❌        | ✅             |
| **State Cache**         | ✅ Advanced          | ✅ Basic  | N/A           |
| **D3D8 Support**        | ✅                   | ✅        | N/A           |
| **Best For**            | Gaming performance  | Old GPUs | NVIDIA users  |

## Use Cases

### Gaming on Modern Hardware

→ Use **dxvk-gplasync-lowlatency**

- Latest features and optimizations
- Best performance on new GPUs
- Async shader compilation reduces stutter

### Gaming on Older Hardware

→ Use **dxvk-sarek**

- Supports older Vulkan versions
- Compatible with GTX 600/700, AMD GCN 1-3
- Resource-efficient shader compilation

### NVIDIA-Specific Features

→ Use **dxvk-nvapi-vkreflex-layer** (in addition to DXVK)

- Enable DLSS for AI upscaling
- Use Reflex for competitive gaming
- Access PhysX and NVAPI features

## Configuration

### Environment Variables

All variants support these common DXVK environment variables:

```bash
# Enable HUD
DXVK_HUD=fps,frametimes,gpuload

# Frame rate limit
DXVK_FRAME_RATE=60

# Log level
DXVK_LOG_LEVEL=info

# State cache location (automatic by default)
DXVK_STATE_CACHE_PATH=~/.cache/wine/dxvk_state_cache
```

### Variant-Specific Variables

**dxvk-gplasync-lowlatency:**

```bash
DXVK_ASYNC=1  # Enable async compilation (default)
DXVK_LOW_LATENCY_ALLOW_CPU_FRAMES_OVERLAP=0  # Reduce input lag
```

**dxvk-sarek:**

```bash
DXVK_ALL_CORES=1  # Use all CPU cores for compilation
```

**dxvk-nvapi:**

```bash
DXVK_NVAPI_LOG_LEVEL=info  # NVAPI debug logging
VKD3D_CONFIG=dxr  # Enable ray tracing
```

## Sources

- **dxvk-gplasync-lowlatency**: <https://github.com/Digger1955/dxvk-gplasync-lowlatency>
- **dxvk-sarek**: <https://github.com/pythonlover02/DXVK-Sarek>
- **dxvk-nvapi**: <https://github.com/jp7677/dxvk-nvapi>
- **Upstream DXVK**: <https://github.com/doitsujin/dxvk>

## Building

Each variant can be built independently:

```bash
cd dxvk/<variant>
makepkg -si
```

Or build all variants:

```bash
./pkg.sh build dxvk-gplasync-lowlatency dxvk-sarek dxvk-nvapi
```

## License

- **dxvk-gplasync-lowlatency**: Zlib License
- **dxvk-sarek**: Zlib License
- **dxvk-nvapi**: MIT License

## Additional Resources

- [DXVK Documentation](https://github.com/doitsujin/dxvk/wiki)
- [Wine Documentation](https://wiki.winehq.org/)
- [ProtonDB](https://www.protondb.com/) - Game compatibility database
- [PCGamingWiki](https://www.pcgamingwiki.com/wiki/DXVK) - DXVK configuration guide
