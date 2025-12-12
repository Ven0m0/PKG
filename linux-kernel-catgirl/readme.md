# linux-catgirl-edition

## Description

A performance-optimized Linux kernel based on the [Linux-Kernel-Patches](https://github.com/Ven0m0/Linux-Kernel-Patches) repository. This kernel combines patches from multiple sources to provide enhanced performance, responsiveness, and hardware support.

## Features

### Performance Optimizations

- **Multiple CPU Schedulers**: Choose from BORE (desktop-optimized), BMQ (lightweight), EEVDF (stock), or RT variants
- **O3 Compiler Optimization**: Aggressive optimization flags for improved performance
- **LLVM LTO Support**: Thin or Full Link-Time Optimization for better code generation
- **TCP BBR3**: Google's congestion control algorithm for improved network performance
- **Configurable Tick Rate**: Support for 100Hz to 1000Hz tick rates

### Patch Sets

- **CachyOS Patches**: Performance and responsiveness improvements
- **Clear Linux Patches**: Intel optimizations and power management improvements
- **XanMod Patches**: Additional performance and desktop-focused tweaks

### Key Options

The PKGBUILD supports several configuration options that can be set before building:

```bash
# CPU Scheduler (bore, bmq, eevdf, rt, rt-bore)
_cpusched=bore

# Enable O3 optimization
_cflags_O3=yes

# LLVM LTO mode (none, thin, full)
_use_llvm_lto=thin

# Tickrate in Hz
_HZ_ticks=1000

# Preemption type (full, lazy, voluntary, none)
_preempt=lazy

# Processor optimization (native, x86-64, x86-64-v3, znver4, etc.)
_processor_opt=native

# Enable TCP BBR3
_tcp_bbr3=yes
```

## Build Instructions

### Standard Build

```bash
cd linux-kernel-catgirl
makepkg -si
```

### Custom Configuration

Set environment variables before building:

```bash
# Use specific kernel version
_major=6.17 _minor=.8 makepkg -si

# Build with different scheduler
_cpusched=eevdf makepkg -si

# Optimize for specific CPU
_processor_opt=znver4 makepkg -si

# Interactive configuration
_makenconfig=yes makepkg -si
```

### Using modprobed-db

To reduce compile time by only building modules you use:

```bash
# Install modprobed-db
yay -S modprobed-db

# Run modprobed-db for a while to collect module data
sudo modprobed-db recall

# Build kernel with local module configuration
_localmodcfg=yes makepkg -si
```

## Scheduler Recommendations

- **bore**: Best for desktop users who want responsive systems under load
- **bmq**: Good for systems with limited CPU cache (older/slower machines)
- **eevdf**: Stock Linux scheduler, best for servers requiring fairness
- **rt**: Real-time systems requiring predictable latency
- **rt-bore**: Real-time desktop systems (e.g., professional audio workstations)

## Performance Tuning

### Processor Optimization

The `_processor_opt` variable allows you to optimize for your specific CPU:

- `native`: Optimizes for your current CPU (not portable to other systems)
- `x86-64`: Baseline, works on all x86-64 CPUs
- `x86-64-v2`, `x86-64-v3`, `x86-64-v4`: Increasingly newer instruction sets
- CPU-specific: `znver4` (Ryzen 7000), `skylake`, `alderlake`, etc.

### LTO (Link-Time Optimization)

- `thin`: Fast multi-threaded LTO, good balance of speed and optimization
- `full`: Slower but theoretically better optimization
- `none`: No LTO, uses GCC instead of Clang

## Installation Notes

### Package Contents

The build creates two packages:

1. `linux-catgirl-edition`: The kernel itself
2. `linux-catgirl-edition-headers`: Headers for building external modules (DKMS)

### Post-Installation

After installation, update your bootloader configuration:

```bash
# For GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# For systemd-boot
# The kernel should be auto-detected on next boot
```

### Removing Old Kernels

```bash
# List installed kernels
pacman -Q | grep linux

# Remove old kernel
sudo pacman -R linux-catgirl-edition linux-catgirl-edition-headers
```

## System Requirements

### Build Requirements

- **Disk Space**: ~20-30GB for build
- **RAM**: 8GB minimum, 16GB recommended
- **Time**: 30-120 minutes depending on CPU and configuration

### Runtime Requirements

- x86_64 architecture
- UEFI or BIOS boot support
- Bootloader (GRUB, systemd-boot, rEFInd, etc.)

## Source

- **Upstream**: <https://github.com/Ven0m0/Linux-Kernel-Patches>
- **Based on**: Linux Catgirl Edition by a-catgirl-dev
- **Kernel Source**: <https://kernel.org>
- **Patches From**:
  - CachyOS: <https://github.com/CachyOS/kernel-patches>
  - Clear Linux: <https://github.com/clearlinux-pkgs>
  - XanMod: <https://gitlab.com/xanmod/linux-patches>

## Troubleshooting

### Build Fails with "checksum mismatch"

This PKGBUILD uses dynamic sources and `SKIP` for checksums during development. For production, update checksums:

```bash
updpkgsums
```

### Build Fails During Compilation

Check you have sufficient disk space and RAM. For systems with limited resources:

```bash
# Reduce parallel compilation
MAKEFLAGS="-j4" makepkg -si

# Use less aggressive optimization
_cflags_O3=no makepkg -si

# Disable LTO
_use_llvm_lto=none makepkg -si
```

### Kernel Doesn't Boot

1. Boot into previous kernel from bootloader menu
2. Check kernel command line parameters in bootloader config
3. Try disabling advanced features:

   ```bash
   _cflags_O3=no _use_llvm_lto=none makepkg -si
   ```

### Module Issues

If external modules (NVIDIA, VirtualBox, etc.) don't load:

```bash
# Ensure headers package is installed
sudo pacman -S linux-catgirl-edition-headers

# Rebuild DKMS modules
sudo dkms autoinstall
```

## License

GPL-2.0-only (same as Linux kernel)

## Credits

- **Linux Kernel**: Linus Torvalds and contributors
- **CachyOS Team**: For performance patches and optimizations
- **Clear Linux Team**: For Intel optimizations
- **XanMod**: For desktop-focused patches
- **a-catgirl-dev**: For the original Catgirl Edition PKGBUILD
- **Ven0m0**: For maintaining the Linux-Kernel-Patches repository

## Contributing

Issues and improvements should be reported at:

- PKG Repository: <https://github.com/Ven0m0/PKG>
- Linux-Kernel-Patches: <https://github.com/Ven0m0/Linux-Kernel-Patches>
