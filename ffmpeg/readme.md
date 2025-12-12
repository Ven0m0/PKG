# FFmpeg with SVT-AV1 Optimizations

This is an optimized build of FFmpeg 7.1 with enhanced SVT-AV1 support and various performance improvements.

## Key Features

### Integrated Optimizations from FFmpeg-Builds

This build integrates optimizations and build configurations from [Ven0m0/FFmpeg-Builds](https://github.com/Ven0m0/FFmpeg-Builds), including:

1. **Enhanced SVT-AV1 Support**
   - AVX512 instruction set enabled (when CPU supports it via `-march=native`)
   - Optimized build configuration: `-DENABLE_AVX512=ON`
   - SVT-AV1 commit: `f0057e34d1656fd2c1e1f349d8281459272cc5cb`

1. **Compiler Optimizations**
   - O3 optimization level for maximum performance
   - Link-Time Optimization (LTO) with auto-parallelization
   - Native architecture tuning (`-march=native -mtune=native`)
   - Symbol visibility optimization (`-fvisibility=hidden`)
   - Semantic interposition disabled for aggressive optimizations

1. **Security Hardening**
   - Stack protection (`-fstack-protector-strong`)
   - Stack clash protection (`-fstack-clash-protection`)
   - Control-flow protection Intel CET (`-fcf-protection`)
   - FORTIFY_SOURCE=2 for runtime buffer overflow detection
   - Position Independent Code (PIC) for ASLR
   - RELRO and NOW linking for enhanced security

1. **AV1 Codec Suite**
   - **SVT-AV1**: Fast AV1 encoder with AVX512 support
   - **libaom**: Reference AV1 codec with VMAF tuning
   - **dav1d**: Fast AV1 decoder
   - **rav1e**: Rust-based AV1 encoder

1. **Multi-Codec Support**
   - x264 (H.264/AVC encoder)
   - x265 (HEVC/H.265 encoder with multi-bit depth support)
   - VP8/VP9 (libvpx)
   - JPEG XL (libjxl)
   - All major audio codecs (Opus, Vorbis, MP3, AAC)

1. **Hardware Acceleration**
   - NVIDIA NVENC/NVDEC
   - Intel QuickSync (VA-API, oneVPL)
   - OpenCL acceleration
   - Vulkan rendering
   - VDPAU

1. **Advanced Filters and Features**
   - libplacebo (advanced GPU video processing)
   - VMAF (video quality metrics)
   - vid.stab (video stabilization)
   - Rubberband (audio time-stretching)
   - VapourSynth scripting

## Build Information

### Build Flags

All configure flags are enabled for maximum codec and feature support:

- `--enable-gpl --enable-version3 --enable-nonfree`
- `--enable-lto` for link-time optimization
- All major codecs enabled via `--enable-lib*` flags

### Compiler Configuration

```bash
CFLAGS="-O3 -march=native -mtune=native -pipe -fno-plt -flto=auto \
  -fexceptions -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
  -fstack-clash-protection -fstack-protector-strong -fcf-protection \
  -fvisibility=hidden -fno-semantic-interposition"
```

## Installation

```bash
cd ffmpeg/
makepkg -si
```

## Performance Notes

- **march=native**: Optimizes for your specific CPU. Binary won't be portable to older CPUs.
- **AVX512**: Automatically enabled if your CPU supports it (Skylake-X, Ice Lake, Zen 4+)
- **LTO**: Increases build time but produces faster binaries

## References and Credits

- [FFmpeg Official](https://ffmpeg.org)
- [Arch Linux FFmpeg Package](https://archlinux.org/packages/extra/x86_64/ffmpeg/)
- [Jellyfin FFmpeg](https://github.com/jellyfin/jellyfin-ffmpeg)
- [Ven0m0/FFmpeg-Builds](https://github.com/Ven0m0/FFmpeg-Builds)
- [SVT-AV1-Essential](https://github.com/nekotrix/FFmpeg-Builds-SVT-AV1-Essential)
- [SVT-VP9](https://github.com/OpenVisualCloud/SVT-VP9)
- [SVT-HEVC](https://github.com/OpenVisualCloud/SVT-HEVC)
- [emby-ffmpeg](https://gitlab.archlinux.org/archlinux/packaging/packages/emby-ffmpeg)
