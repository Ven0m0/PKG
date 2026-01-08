# Wine OSU Patches Integration

The wine-osu patches are integrated via a **git submodule** located at `wine-tkg-git/wine-osu-patches/`. This submodule references the [wine-osu-patches](https://github.com/whrvt/wine-osu-patches) repository, which provides optimizations and customizations specifically for running osu! (and other games) on Linux via Wine.

## Updating the Patches

To update to the latest wine-osu patches:

```bash
cd wine-tkg-git/wine-osu-patches
git pull origin master
cd ../..
git add wine-tkg-git/wine-osu-patches
git commit -m "wine-tkg-git: Update wine-osu-patches submodule"
```

## What's Included

The wine-osu patches are organized into functional categories:

- **0003-pending-mrs-and-backports**: Upstream Wine merge requests and backported fixes
- **0004-build-fix-undebug-optimize**: Build system and compiler optimizations
- **0009-windowing-system-integration**: Display server and input handling improvements
- **0012-audio**: Audio subsystem enhancements (PulseAudio, ALSA)
- **0013-server-optimization**: Performance and synchronization improvements
- **0015-bernhard-asan**: AddressSanitizer compatibility fixes
- **0016-proton-additions**: Proton-specific enhancements
- **9000-misc-additions**: Game-specific and miscellaneous patches

## How It Works

Wine-TKG automatically applies patches from the `wine-tkg-userpatches/` directory during the build process. The patches in the `wine-osu/` subdirectory will be discovered and applied automatically.

## Environment Variables

The wine-osu patches introduce numerous tunable environment variables for runtime configuration:

### Audio
- `ALSA_EXTRA_PAD`: Extra audio padding (units: usecs*10; default: 40000)
- `STAGING_AUDIO_PERIOD`: Custom audio period (units: usecs*10)
- `STAGING_AUDIO_DURATION`: Custom audio duration (units: usecs*10)
- `WINE_PULSE_MEMLOCK`: Enable/disable audio buffer memlocking (default: enabled)

### Graphics/Performance
- `WINE_CUSTOM_FPS`: Custom frame rate limiter
- `WINE_CUSTOM_FPS_BUSYTHRESH`: FPS limiter busy threshold
- `WINE_STATIC_CPUFREQ`: Static CPU frequency reporting
- `vblank_mode`: Override VSync behavior (!=0 to force enable)

### Input/Display
- `WINE_DISABLE_RAWINPUT`: Force disable RawInput support
- `WINE_ENABLE_ABS_TABLET_HACK`: Enable tablet cursor clip hack
- `WINE_WAYLAND_DISPLAY_INDEX`: Select Wayland display index
- `WINE_ENABLE_OSU_FOCUS_FIX`: Enable osu! focus fix for certain WMs

### System
- `WINE_DISABLE_IME`: Disable Input Method Editor
- `WINE_DISABLE_KDE_HACKS`: Disable KDE-specific workarounds
- `WINE_DISABLE_TSC`: Disable RDTSCP for older kernels
- `WINE_LARGE_ADDRESS_AWARE`: Override IMAGE_FILE_LARGE_ADDRESS_AWARE flag
- `WINE_INSTALL_ROOT_DEVICES`: Enable/disable root device installation
- `WINE_HOST_XDG_CACHE_HOME`: Override XDG cache directory
- `WINEDMO`: Enable/disable winedmo

### osu!-Specific
- `WINE_ENABLE_OSU_FOCUS_FIX`: Fix focus issues on certain window managers
- `WINE_SHELL32_HACKS`: Enable shell32 hacks for osu! (screenshot folder, .osu files)

## Base Versions

These patches are based on:
- **Wine commit**: a82d717c
- **Staging commit**: 52bc59da
- **Staging exclude flags**: `-W winedevice-Default_Drivers -W dsound-EAX -W mountmgr-DosDevices`

## Disabling Patches

If you want to disable specific wine-osu patches, you can:

1. Move or rename patches you don't want to apply
2. Add them to your wine-tkg configuration exclusion list
3. Remove the entire `wine-osu/` directory to disable all patches

## More Information

For detailed information about each patch and environment variable, see the [README.md](wine-osu/README.md) in the wine-osu directory.

## Source

Repository: https://github.com/whrvt/wine-osu-patches
Integrated: 2026-01-08
Total patches: ~288
