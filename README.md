# PKG - Optimized Arch Linux Package Builds

[![Build Status](https://github.com/Ven0m0/PKG/workflows/build/badge.svg)](https://github.com/Ven0m0/PKG/actions)
[![License](https://img.shields.io/badge/license-Various-blue.svg)](LICENSE)

A curated collection of **performance-optimized PKGBUILDs** for Arch Linux packages with custom patches, aggressive compiler optimizations, and enhanced configurations.

## Utilities

- [ISA Level Detection](ISA-DETECTION.md) - Check x86-64 microarchitecture level support (based on [CachyOS/cachyos-repo-add-script](https://github.com/CachyOS/cachyos-repo-add-script))

## Cloudflare

This repository provides optimized package builds for Arch Linux with a focus on:

- **Performance**: Aggressive compiler optimizations (-O3, LTO, PGO, native architecture targeting)
- **Security**: Enhanced security flags, verified checksums, HTTPS sources
- **Customization**: Custom patches, debloating, and performance tuning
- **Quality**: Automated CI/CD testing, comprehensive linting, and validation

## Features

### Build System

- ✅ **Automated builds** with GitHub Actions CI/CD
- ✅ **Docker support** for complex packages (Firefox, OBS Studio, etc.)
- ✅ **Parallel compilation** with intelligent core limiting
- ✅ **Caching support** (sccache, ccache, apt packages)
- ✅ **Multiple compiler support** (Clang/LLVM preferred)

### Code Quality

- ✅ **Comprehensive linting** (shellcheck, shellharden, shfmt, namcap)
- ✅ **Automated formatting** with consistent style enforcement
- ✅ **EditorConfig integration** for consistent coding standards
- ✅ **Git hooks with lefthook** for automated quality checks

### Optimization Techniques

- ✅ **Profile-Guided Optimization** (PGO) for critical packages
- ✅ **Link-Time Optimization** (LTO) enabled by default
- ✅ **Native architecture targeting** (march=native, mtune=native)
- ✅ **Aggressive inlining** and vectorization
- ✅ **Memory layout optimizations** (-fno-plt, section garbage collection)

## Quick Start

### Prerequisites

```bash
# Install base development tools (Arch Linux)
sudo pacman -S base-devel git

# Optional but recommended
sudo pacman -S shellcheck shfmt docker sccache clang
```

### Build a Package

```bash
# Clone the repository
git clone https://github.com/Ven0m0/PKG.git
cd PKG

# Build a specific package
cd firefox
makepkg -si

# Or use the build script
cd ..
./pkg.sh build firefox aria2 obs-studio
```

### Docker Build (for complex packages)

```bash
# Automatically handled for Firefox, OBS Studio, etc.
./pkg.sh build firefox
```

## Repository Structure

```
PKG/
├── .github/
│   ├── workflows/          # CI/CD pipelines (build, lint, automerge)
│   ├── scripts/            # CI-only helper scripts
│   ├── instructions/       # GitHub-specific guidelines
│   └── agents/             # AI agent configurations
├── <package-name>/         # Individual package directories
│   ├── PKGBUILD           # Package build script (required)
│   ├── .SRCINFO           # Metadata (auto-generated)
│   ├── README.md          # Package documentation
│   ├── patches/           # Custom patches
│   └── *.patch            # Individual patch files
├── lib/helpers.sh         # Shared shell helper functions
├── pkg.sh                 # Unified build/lint/srcinfo tool
├── vp                     # Package helper CLI
├── CLAUDE.md              # AI assistant documentation
├── CONTRIBUTING.md        # Contribution guidelines
├── SECURITY.md            # Security policy
└── README.md              # This file
```

## Available Packages

### Featured Packages

| Package | Description | Optimizations |
|---------|-------------|---------------|
| **firefox** | Web browser | PGO, BOLT, VA-API, aggressive optimizations |
| **chromium** | Web browser | Custom flags, performance patches |
| **obs-studio** | Video recording/streaming | Optimized build configuration |
| **ffmpeg** | Multimedia framework | Hardware acceleration, codec optimizations |
| **mesa-git** | Graphics drivers | Latest features, performance patches |
| **wine-tkg-git** | Windows compatibility | Custom patches, optimizations |
| **llvm** | Compiler infrastructure | Optimized build |

### System Tools

- **aria2** - Download utility with speed optimizations
- **curl** - HTTP client with custom patches
- **7zip** - Compression utility
- **smartdns-rs** - DNS resolver
- **preload-ng** - Application preloader

### Gaming

- **dolphin-emu** - GameCube/Wii emulator
- **prismlauncher** - Minecraft launcher
- **heroic-games-launcher** - Epic Games launcher
- **dxvk** variants - DirectX to Vulkan translation

### Development

- **gitoxide** - Rust-based Git tools
- **vscode** - Code editor with patches
- **legcord/discord** - Communication tools

See individual package directories for detailed documentation.

## Building Packages

### Standard Build

```bash
cd <package-name>
makepkg -si
```

### Build Options

```bash
# Clean build (removes previous build artifacts)
makepkg -srC

# Skip dependency checks (for experienced users)
makepkg -si --nodeps

# Package only (no install)
makepkg -s
```

### Using the Build Script

```bash
# Build specific packages
./pkg.sh build firefox chromium obs-studio

# Build all packages (not recommended)
./pkg.sh build

# Force clean builds
./pkg.sh build --force firefox
```

## Development

### Git Hooks Setup

This repository uses [lefthook](https://github.com/evilmartians/lefthook) for automated code quality checks.

```bash
# Install lefthook
# Linux/macOS via script
curl -1sLf 'https://dl.cloudsmith.io/public/evilmartians/lefthook/setup.deb.sh' | sudo -E bash
sudo apt-get install lefthook

# Or via Go
go install github.com/evilmartians/lefthook@latest

# Or via Homebrew (macOS)
brew install lefthook

# Or via uv (recommended for Python tools)
uv tool install lefthook

# Install hooks in repository
lefthook install

# Run hooks manually
lefthook run pre-commit

# Skip hooks temporarily
LEFTHOOK=0 git commit -m "message"
```

### Linting

```bash
# Run all linters
./pkg.sh lint

# Lint specific package
cd <package>
shellcheck -x -a -s bash PKGBUILD
namcap PKGBUILD
shfmt -ln bash -bn -s -i 2 -w PKGBUILD
```

### Adding a New Package

1. Create package directory: `mkdir new-package && cd new-package`
2. Create `PKGBUILD` following [PKGBUILD Guidelines](CLAUDE.md#pkgbuild-conventions)
3. Generate metadata: `makepkg --printsrcinfo > .SRCINFO`
4. Add documentation: Create `readme.md` using the [template](CONTRIBUTING.md#package-documentation-template)
5. Test build: `makepkg -sr`
6. Commit: `git add . && git commit -m "Add new-package: description"`

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Modifying Packages

1. Edit `PKGBUILD` (update `pkgver` or `pkgrel`)
2. Update checksums: `updpkgsums`
3. Regenerate metadata: `makepkg --printsrcinfo > .SRCINFO`
4. Test: `makepkg -srC`
5. Lint: `cd .. && ./pkg.sh lint`
6. Commit with descriptive message

## CI/CD Integration

### GitHub Actions Workflows

- **build.yml** - Automated package building with matrix strategy
- **lint.yml** - Code quality checks (shellcheck, namcap, prettier, MegaLinter)
- **automerge-dependabot.yml** - Automated dependency updates

### Build Caching

- APT packages cached for faster CI runs
- Docker layer caching enabled
- sccache for Rust compilation
- ccache for C/C++ compilation

### Matrix Builds

Packages are detected automatically and built in parallel across multiple jobs.

## Optimization Flags

Standard optimization flags used across packages:

```bash
# C/C++ compiler flags
export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"

# Linker flags
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

# Parallel compilation
export MAKEFLAGS="-j$(nproc)"
```

Package-specific optimizations may include PGO, BOLT, Polly, and architecture-specific tuning.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Code of conduct
- Development workflow
- Coding standards
- Pull request process
- Package submission guidelines

## Security

Security is a priority. See [SECURITY.md](SECURITY.md) for:

- Reporting vulnerabilities
- Security best practices
- Supported versions

## Related Projects

### Inspired By

- [CachyOS-PKGBUILDS](https://github.com/CachyOS/CachyOS-PKGBUILDS) - High-performance Arch repository
- [CachyOS Packages](https://packages.cachyos.org) - Binary repository
- [lseman's PKGBUILDs](https://github.com/lseman/PKGBUILDs) - PGO-optimized packages
- [KISS-repo](https://github.com/XDream8/kiss-repo) - Keep it simple packages
- [Pika OS](https://pika-os.com) - Gaming-focused distribution
- [loathingKernel PKGBUILDS](https://github.com/loathingKernel/PKGBUILDs)

### Upstream Resources

- [Cloudflare quiche-mallard](https://github.com/cloudflare/quiche-mallard) - QUIC protocol
- [Cloudflare jpegtran](https://github.com/cloudflare/jpegtran) - JPEG optimization
- [Cloudflare BoringSSL](https://github.com/cloudflare/boringssl-pq) - Post-quantum TLS
- [Cloudflare reqwest](https://github.com/cloudflare/cf-reqwest) - HTTP client

### Tools Used

- [patchutils](https://github.com/twaugh/patchutils) - Patch manipulation
- [mpatch](https://crates.io/crates/mpatch) - Rust patch utility
- [shellcheck](https://github.com/koalaman/shellcheck) - Shell script linting
- [shfmt](https://github.com/mvdan/sh) - Shell formatter
- [namcap](https://wiki.archlinux.org/title/Namcap) - PKGBUILD linter

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive AI assistant guide and project conventions
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines and workflow
- **[SECURITY.md](SECURITY.md)** - Security policy and vulnerability reporting
- **[TODO.md](TODO.md)** - Planned features and improvements
- **Package READMEs** - Individual package documentation in `<package>/readme.md`

## License

This repository contains PKGBUILDs and scripts under various licenses:

- **Build scripts**: MIT License (unless otherwise specified)
- **PKGBUILDs**: Follow upstream package licenses
- **Patches**: Typically inherit upstream license

See individual package directories for specific license information.

## Support

- **Issues**: [GitHub Issues](https://github.com/Ven0m0/PKG/issues)
- **Discussions**: Use GitHub Discussions for questions
- **Pull Requests**: Contributions welcome via PRs

---

**Maintained by**: Ven0m0
**Repository**: <https://github.com/Ven0m0/PKG>
**Last Updated**: 2025-12-24
