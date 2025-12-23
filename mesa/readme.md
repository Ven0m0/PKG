# Mesa (Stable)

## Description

Open-source OpenGL drivers - CachyOS optimized stable build.

This package provides the stable Mesa 3D graphics library with performance optimizations and patches from CachyOS.

## Source

- **Upstream**: <https://www.mesa3d.org/>
- **CachyOS PKGBUILD**: <https://github.com/CachyOS/CachyOS-PKGBUILDS/tree/master/mesa/mesa>
- **Arch Linux Base**: <https://archlinux.org/packages/extra/x86_64/mesa/>

## Features

- **Version**: Mesa 25.3.2 (epoch 1, pkgrel 2)
- **Multiple sub-packages**: Splits Mesa into modular components
  - `mesa` - Core OpenGL drivers
  - `opencl-mesa` - OpenCL support
  - `vulkan-*` - Vulkan drivers for various GPUs (Intel, AMD, Nouveau, etc.)
  - `vulkan-mesa-layers` - Vulkan debugging and utility layers
  - `mesa-docs` - Documentation
- **CachyOS Patches**:
  - Gamescope FPS limiter patch
- **All codecs enabled**: vc1dec, h264dec, h264enc, h265dec, h265enc, av1dec, av1enc, vp9dec
- **Comprehensive driver support**:
  - Gallium drivers: asahi, crocus, d3d12, freedreno, i915, iris, llvmpipe, nouveau, r300, r600, radeonsi, softpipe, svga, virgl, zink
  - Vulkan drivers: amd, freedreno, intel, intel_hasvk, swrast, virtio, microsoft-experimental, nouveau, asahi, gfxstream
- **Rusticl OpenCL**: Enabled for asahi, freedreno, radeonsi
- **Intel RT**: Ray tracing support enabled
- **Sysprof integration**: Performance profiling support

## Build Instructions

```bash
cd mesa
makepkg -si
```

## Sub-packages

| Package | Description |
|---------|-------------|
| `mesa` | Core Mesa OpenGL drivers |
| `opencl-mesa` | OpenCL drivers (Rusticl) |
| `vulkan-asahi` | Vulkan driver for Apple GPUs |
| `vulkan-dzn` | Vulkan driver for D3D12 |
| `vulkan-freedreno` | Vulkan driver for Adreno GPUs |
| `vulkan-gfxstream` | Vulkan driver for Graphics Streaming Kit |
| `vulkan-intel` | Vulkan driver for Intel GPUs |
| `vulkan-nouveau` | Vulkan driver for Nvidia GPUs (open-source) |
| `vulkan-radeon` | Vulkan driver for AMD GPUs |
| `vulkan-swrast` | Vulkan software rasterizer |
| `vulkan-virtio` | Vulkan driver for Virtio-GPU (Venus) |
| `vulkan-mesa-implicit-layers` | Mesa's implicit Vulkan layers |
| `vulkan-mesa-layers` | Mesa's explicit Vulkan layers |
| `mesa-docs` | Mesa documentation |

## Differences from Arch Linux

- Includes CachyOS performance patches
- Gamescope FPS limiter patch applied
- Optimized build flags

## License

MIT AND BSD-3-Clause AND SGI-B-2.0
