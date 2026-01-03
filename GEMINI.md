# GEMINI.md - AI Assistant Guide for PKG Repository

## Project Overview

This repository contains optimized **PKGBUILDs** (Arch Linux package build scripts) for various software packages. The goal is to provide performance-optimized builds with custom patches and configurations.

**Primary Purpose**: Maintain a collection of PKGBUILDs with performance optimizations, security patches, and custom configurations for Arch Linux packages.

**Key Technologies**:

- Arch Linux packaging system (makepkg, PKGBUILD)
- Bash shell scripting
- Docker for isolated builds
- GitHub Actions CI/CD
- Patch management (git patches)

## Quick Reference

For comprehensive documentation, see:

- **llms.txt** - Concise project summary for LLMs
- **CLAUDE.md** - Detailed AI assistant guide
- **README.md** - Main repository documentation

## Repository Structure

```
PKG/
├── .github/workflows/       # CI/CD workflows (build, lint, automerge)
├── <package-name>/          # Individual package directories
│   ├── PKGBUILD            # Arch Linux package build script (REQUIRED)
│   ├── .SRCINFO            # Source info metadata (auto-generated)
│   ├── readme.md           # Package-specific documentation
│   ├── patches/            # Custom patches (if applicable)
│   └── *.patch             # Individual patch files
├── build.sh                # Universal build script
├── lint.sh                 # Linting and formatting script
├── .editorconfig           # Editor configuration
├── .shellcheckrc           # ShellCheck linting rules
├── README.md               # Main repository documentation
├── llms.txt                # LLM context file
└── SECURITY.md             # Security policy
```

## Key Conventions

### Shell Script Standards

All shell scripts must follow:

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Safe field separator
```

**Linting Tools** (all must pass):

- **shellcheck**: Static analysis for shell scripts
- **shellharden**: Safety and robustness checks
- **shfmt**: Formatting (indent: 2 spaces, bash dialect)

### PKGBUILD Structure

```bash
# Maintainer: Your Name
_pkgname=originalname
pkgname="$_pkgname-custom"
pkgver=1.0.0
pkgrel=1
pkgdesc='Description'
arch=('x86_64')
url='https://upstream.url'
license=('LICENSE-TYPE')
depends=('dep1' 'dep2')
makedepends=('makedep1')
provides=('originalname')
conflicts=('originalname')
source=('https://url/to/source.tar.gz'
        'patch1.patch')
sha256sums=('checksum'
            'SKIP')

prepare() {
  cd "$_pkgname-$pkgver"
  patch -Np1 -i ../patch1.patch
}

build() {
  cd "$_pkgname-$pkgver" || exit
  export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt"
  export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt"
  ./configure --prefix=/usr
  make
}

package() {
  cd "$_pkgname-$pkgver" || exit
  make DESTDIR="$pkgdir" install
}
```

**After PKGBUILD Changes**:

```bash
makepkg --printsrcinfo > .SRCINFO
```

### EditorConfig Standards

- **Indentation**: 2 spaces (not tabs, except for Makefiles)
- **Line endings**: LF (Unix style)
- **Charset**: UTF-8
- **Trim trailing whitespace**: true
- **Insert final newline**: true

## Common Workflows

### Building Packages

```bash
# Build single package
cd <package-name>
makepkg -si

# Build with script
./pkg.sh build firefox aria2

# Build all packages
./pkg.sh build
```

### Linting and Validation

```bash
# Run all linters
./pkg.sh lint

# Update .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Format shell scripts
shfmt -ln bash -bn -s -i 2 -w PKGBUILD

# Check for shell issues
shellcheck -x -a -s bash PKGBUILD
```

### Adding a New Package

1. Create package directory: `mkdir new-package && cd new-package`
2. Create PKGBUILD following conventions
3. Generate .SRCINFO: `makepkg --printsrcinfo > .SRCINFO`
4. Create readme.md (recommended)
5. Test build: `makepkg -sr`
6. Commit: `git add . && git commit -m "Add new-package: Description"`

### Modifying Existing Packages

1. Edit PKGBUILD (bump `pkgrel` or `pkgver`)
2. Update checksums if sources change
3. Regenerate metadata: `makepkg --printsrcinfo > .SRCINFO`
4. Test: `makepkg -srC`
5. Lint: `./pkg.sh lint`
6. Commit with descriptive message

## Optimization Flags

Standard optimization flags:

```bash
export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
export MAKEFLAGS="-j$(nproc)"
```

## AI Assistant Guidelines

### DO

- Read existing code before suggesting changes
- Follow established patterns in the codebase
- Update both PKGBUILD and .SRCINFO together
- Test changes before committing
- Use optimization flags consistently
- Add descriptive commit messages
- Validate shell scripts with shellcheck
- Use proper error handling (set -euo pipefail)

### DON'T

- Modify PKGBUILD without updating .SRCINFO
- Skip testing builds locally
- Ignore linting failures
- Add tabs to shell scripts (use 2 spaces)
- Use CRLF line endings (use LF)
- Bypass safety checks
- Download unverified sources
- Use HTTP when HTTPS is available
- Commit build artifacts (pkg/, src/, *.tar.*)

### Workflow for Changes

1. **Understand**: Read the relevant PKGBUILD and patches
2. **Plan**: Identify what needs modification
3. **Implement**: Edit following conventions
4. **Update metadata**: `makepkg --printsrcinfo > .SRCINFO`
5. **Validate**: `./pkg.sh lint`
6. **Test**: `makepkg -srC`
7. **Commit**: `git commit -m "package: descriptive message"`

## Troubleshooting

### Common Issues

**.SRCINFO out of sync**:

```bash
makepkg --printsrcinfo > .SRCINFO
```

**Missing dependencies**:

```bash
makepkg -s  # Auto-install deps
```

**Checksum mismatch**:

```bash
updpkgsums  # Update checksums
```

**Patch fails to apply**:

```bash
patch -Np1 --dry-run -i ../../patch.patch  # Test first
```

## Security

- Verify checksums (sha256sums, sha512sums)
- Use HTTPS sources
- Validate GPG signatures when available
- Review all patches before applying

## References

- [PKGBUILD Guidelines](https://wiki.archlinux.org/title/PKGBUILD)
- [makepkg Documentation](https://man.archlinux.org/man/makepkg.8)
- [Arch Package Guidelines](https://wiki.archlinux.org/title/Arch_package_guidelines)

---

**Repository**: <https://github.com/Ven0m0/PKG>
**Maintainer**: Ven0m0
