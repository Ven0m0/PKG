# Mesa-git

## Description

Open-source OpenGL drivers - CachyOS/Tk-Glitch customizable git build.

This package provides bleeding-edge Mesa 3D graphics library built from the latest git sources with extensive customization options.

## Source

- **Upstream**: <https://www.mesa3d.org/>
- **Git Repository**: <https://gitlab.freedesktop.org/mesa/mesa>
- **Base PKGBUILD**: Tk-Glitch <https://github.com/Frogging-Family/mesa-git>
- **CachyOS Version**: <https://github.com/CachyOS/CachyOS-PKGBUILDS/tree/master/mesa/mesa-git>

## Features

- **Git version**: Builds from the latest Mesa git main branch
- **Highly customizable**: Extensive configuration via `customization.cfg`
- **Compiler choice**: GCC or Clang (Clang enabled by default)
- **LTO support**: Link-time optimization (enabled by default)
- **Custom optimization flags**: `-march=native -O3` for maximum performance
- **lib32 support**: Optional 32-bit library builds
- **Rusticl OpenCL**: Modern Rust-based OpenCL implementation
- **User patches**: Support for custom patches via `.mymesapatch` files
- **Community patches**: Integration with Frogging-Family community patches
- **Flexible driver selection**: Choose which Gallium and Vulkan drivers to build

## Configuration

Edit `customization.cfg` to customize your build:

### Key Options

```bash
# Compiler selection (gcc or clang)
_compiler="clang"

# Enable lib32 (32-bit libraries for Wine, etc.)
_lib32=true

# Gallium drivers to build
_gallium_drivers="r300,r600,radeonsi,nouveau,svga,llvmpipe,softpipe,virgl,iris,zink,crocus,i915"

# Vulkan drivers to build (current: nouveau, swrast)
_vulkan_drivers="swrast,nouveau"

# Enable Rusticl OpenCL
_rusticl="true"

# Custom optimization flags
_custom_opt_flags="-march=native -O3"

# Enable LTO
_lto="true"

# Mesa branch (main or amber for legacy drivers)
_mesa_branch="main"
```

### LLVM Selection

The PKGBUILD supports multiple LLVM versions:
1. llvm-minimal-git (AUR)
2. llvm-git (AUR)
3. llvm-git from LordHeavy unofficial repo
4. llvm (stable from extra) - **Default**

Set `MESA_WHICH_LLVM` environment variable or configure in `customization.cfg`.

## Build Instructions

### Basic Build

```bash
cd mesa-git
makepkg -si
```

### Custom Build

1. Edit `customization.cfg` to your preferences
2. (Optional) Add custom patches as `*.mymesapatch` in the directory
3. Build:
   ```bash
   makepkg -si
   ```

### PGO Build (Profile-Guided Optimization)

1. First build with PGO generation:
   ```bash
   # In customization.cfg, set:
   _additional_meson_flags="--strip --buildtype release -Db_pgo=generate"
   _lto="false"
   makepkg -si
   ```

2. Run your games/applications to generate profiles

3. Rebuild with PGO optimization:
   ```bash
   # In customization.cfg, set:
   _additional_meson_flags="--strip --buildtype release -Db_pgo=use"
   makepkg -si
   ```

## User Patches

### Adding Custom Patches

1. Place patch files in the `mesa-git/` directory or `mesa-git/mesa-userpatches/`
2. Name them with `.mymesapatch` extension
3. Enable in `customization.cfg`:
   ```bash
   _user_patches="true"
   ```

### Reverting Patches

1. Place revert patches with `.mymesarevert` extension
2. They will be applied in reverse

### Community Patches

Use patches from Frogging-Family community-patches repository:

```bash
_community_patches="patch1.mymesapatch patch2.mymesapatch"
```

## Current Customizations

This build is configured with:
- **Compiler**: Clang (for better optimization)
- **Optimization**: `-march=native -O3` + LTO
- **lib32**: Enabled (for Wine/Proton compatibility)
- **Vulkan drivers**: swrast, nouveau (minimal set)
- **Gallium drivers**: Full set including radeonsi, iris, zink, etc.
- **Rusticl**: Enabled for modern OpenCL support
- **Codecs**: All video codecs enabled (H.264, H.265, AV1, VP9, VC1)

## Performance Considerations

- **LTO**: Enabled for better performance, uses Clang to avoid GCC stability issues
- **march=native**: Optimizes for your specific CPU architecture
- **Clang compiler**: Generally produces faster Mesa code than GCC

## Differences from Arch Linux mesa

- Bleeding-edge git version vs stable releases
- Highly customizable build options
- Performance optimizations enabled by default
- User patch system for experimental features

## Differences from CachyOS Default

- Optimized for performance with Clang + LTO + march=native
- Reduced Vulkan driver set (swrast, nouveau only)
- User patches enabled

## Notes

- `.SRCINFO` must be regenerated after changing `customization.cfg`:
  ```bash
  makepkg --printsrcinfo > .SRCINFO
  ```
- Git builds can be unstable; use stable `mesa` package for production systems
- Build time can be long (30-60+ minutes) depending on enabled drivers and CPU

## Troubleshooting

### Build Failures

- Try disabling LTO: `_lto="false"`
- Reduce driver count in `customization.cfg`
- Switch to GCC: `_compiler="gcc"`

### Runtime Issues

- Check `~/.config/frogminer/mesa-git.cfg` for external configuration overrides
- Review `last_build_config.log` to see what was built

## License

Custom (MIT-based)
