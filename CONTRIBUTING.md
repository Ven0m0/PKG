# Contributing to PKG

Thank you for your interest in contributing to PKG! This document provides guidelines and workflows for contributing to this repository.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [PKGBUILD Guidelines](#pkgbuild-guidelines)
- [Submitting Changes](#submitting-changes)
- [Package Documentation Template](#package-documentation-template)
- [Testing](#testing)
- [Review Process](#review-process)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Focus on constructive feedback
- Accept criticism gracefully
- Prioritize the community's best interest
- Show empathy towards other contributors

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or inflammatory comments
- Personal or political attacks
- Publishing others' private information
- Other conduct deemed inappropriate

## Getting Started

### Prerequisites

1. **Arch Linux** (or Arch-based distribution)
2. **base-devel** package group
3. **Git** for version control
4. **Code quality tools**:
   ```bash
   sudo pacman -S shellcheck shfmt namcap
   ```

### Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/PKG.git
cd PKG

# Add upstream remote
git remote add upstream https://github.com/Ven0m0/PKG.git

# Create a feature branch
git checkout -b feature/your-feature-name
```

## Development Workflow

### 1. Before Making Changes

```bash
# Update your fork
git fetch upstream
git checkout main
git merge upstream/main
git push origin main

# Create feature branch
git checkout -b feature/package-name
```

### 2. Making Changes

#### Adding a New Package

```bash
# Create package directory
mkdir package-name
cd package-name

# Create PKGBUILD (see guidelines below)
vim PKGBUILD

# Generate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Create package documentation
vim README.md
```

#### Modifying Existing Package

```bash
cd package-name

# Edit PKGBUILD
vim PKGBUILD

# Update version/release
# pkgver for upstream updates
# pkgrel for packaging changes

# Update checksums if sources changed
updpkgsums

# Regenerate .SRCINFO
makepkg --printsrcinfo > .SRCINFO
```

### 3. Testing Your Changes

```bash
# Clean build test
makepkg -srC

# Install and test
makepkg -si

# Run linters (from repository root)
cd ..
./pkg.sh lint
```

### 4. Committing Changes

```bash
# Stage changes
git add package-name/

# Commit with descriptive message
git commit -m "package-name: Brief description

- Detailed change 1
- Detailed change 2
- Fixes #issue_number (if applicable)"

# Push to your fork
git push origin feature/package-name
```

### 5. Opening a Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your feature branch
4. Fill out the PR template:
   - **Title**: `package-name: Brief description`
   - **Description**: Detailed explanation of changes
   - **Testing**: How you tested the changes
   - **Related Issues**: Link any related issues

## Coding Standards

### Shell Scripts

All shell scripts must follow these standards:

#### Required Header

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

#### Style Guidelines

- **Indentation**: 2 spaces (no tabs)
- **Line endings**: LF (Unix style)
- **Encoding**: UTF-8
- **Max line length**: 128 characters
- **Quotes**: Double quotes for variables: `"$var"`
- **Functions**: Use lowercase with underscores: `my_function()`

#### Linting Requirements

All scripts must pass:

```bash
# Static analysis
shellcheck -x -a -s bash script.sh

# Safety checks
shellharden --replace script.sh

# Formatting
shfmt -ln bash -bn -s -i 2 -d script.sh
```

### EditorConfig

Follow `.editorconfig` settings:

```ini
[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{sh,bash}]
indent_style = space
indent_size = 2
max_line_length = 128
shell_variant = bash
```

## PKGBUILD Guidelines

### Standard Structure

```bash
# Maintainer: Your Name <email@example.com>
# Contributor: Other Name <email@example.com>

_pkgname=originalname
pkgname="${_pkgname}-custom"  # Use suffix if conflicts exist
pkgver=1.0.0
pkgrel=1
pkgdesc='Clear, concise description'
arch=('x86_64')
url='https://upstream.url'
license=('LICENSE-TYPE')
depends=('dep1' 'dep2')
makedepends=('makedep1' 'makedep2')
optdepends=('optional-dep: for feature X')
provides=("${_pkgname}")
conflicts=("${_pkgname}")
source=("https://url/to/${_pkgname}-${pkgver}.tar.gz"
        'local-patch.patch')
sha256sums=('CHECKSUM_HERE'
            'SKIP')  # Use SKIP for local files

prepare() {
  cd "${_pkgname}-${pkgver}" || exit
  # Apply patches
  patch -Np1 -i ../local-patch.patch
}

build() {
  cd "${_pkgname}-${pkgver}" || exit

  # Optimization flags
  export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
  export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
  export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

  # Configure and build
  ./configure --prefix=/usr
  make
}

check() {
  cd "${_pkgname}-${pkgver}" || exit
  make check
}

package() {
  cd "${_pkgname}-${pkgver}" || exit
  make DESTDIR="$pkgdir" install
}
```

### Optimization Standards

#### Compiler Flags

```bash
# Performance optimizations
export CFLAGS="${CFLAGS/-O2/-O3} -march=native -mtune=native -pipe -fno-plt"
export CXXFLAGS="${CXXFLAGS/-O2/-O3} -march=native -mtune=native -pipe -fno-plt"

# Security flags
export CFLAGS="$CFLAGS -fstack-protector-strong -fstack-clash-protection"
export CXXFLAGS="$CXXFLAGS -fstack-protector-strong -fstack-clash-protection"

# Linker optimizations
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
export LDFLAGS="$LDFLAGS -Wl,--gc-sections"  # Remove unused sections

# Parallel builds
export MAKEFLAGS="-j$(nproc)"
```

#### Rust Optimizations

```bash
export RUSTFLAGS="-Ctarget-cpu=native -Copt-level=3 -Clto=fat"
export RUSTFLAGS="$RUSTFLAGS -Ccodegen-units=1 -Cpanic=abort"
```

### Security Requirements

1. **Use HTTPS for sources**: `https://` not `http://`
2. **Verify checksums**: Use `sha256sums` or `sha512sums`
3. **GPG signatures** (when available):
   ```bash
   validpgpkeys=('KEY_FINGERPRINT')
   source+=("${url}.sig")
   ```
4. **Review patches**: Understand what every patch does
5. **No arbitrary code execution**: Avoid `curl | bash` patterns

### Common Patterns

#### Conditional Dependencies

```bash
# CPU-specific optimizations
if [[ $(uname -m) == "x86_64" ]]; then
  makedepends+=('nasm')
fi
```

#### Multiple Sources

```bash
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/user/repo/archive/v${pkgver}.tar.gz"
        "${pkgname}.desktop"
        "0001-fix-something.patch")
```

#### Git Sources

```bash
source=("git+https://github.com/user/repo.git#tag=v${pkgver}")
sha256sums=('SKIP')

pkgver() {
  cd repo
  git describe --long --tags | sed 's/^v//;s/-/.r/;s/-/./'
}
```

## Package Documentation Template

Every package should have a `readme.md` following this template:

```markdown
# package-name

## Description

Brief description of the package and what it does.

## Features

- Feature 1
- Feature 2
- Optimization highlights (if applicable)

## Source

- **Upstream**: https://github.com/upstream/repo
- **PKGBUILD Maintainer**: Your Name

## Build Instructions

### Standard Build

\```bash
cd package-name
makepkg -si
\```

### Build Options

List any environment variables or build options:

\```bash
# Example build option
ENABLE_FEATURE=true makepkg -si
\```

## Optimizations Applied

Document specific optimizations:

- Compiler flags: -O3, LTO, etc.
- Architecture-specific tuning
- Custom patches (if applicable)

## Dependencies

### Runtime
- dependency1
- dependency2

### Build-time
- makedep1
- makedep2

## Configuration

Post-installation configuration steps (if needed).

## Known Issues

- Issue 1 and workaround
- Issue 2 and status

## Credits

- Original PKGBUILD: Source
- Patches from: Source
- Inspired by: Related projects

## License

LICENSE-TYPE (e.g., GPL-2.0, MIT, MPL-2.0)
```

## Submitting Changes

### Commit Message Format

```
package-name: Brief summary (50 chars or less)

More detailed explanatory text, if necessary. Wrap it to 72
characters. Explain the problem this commit is solving and why
this particular solution was chosen.

- Bullet points are okay
- Use present tense: "Add feature" not "Added feature"
- Reference issues: "Fixes #123" or "Closes #456"
```

### Commit Message Examples

**Good**:
```
firefox: Update to version 122.0

- Bump pkgver to 122.0
- Update checksums
- Refresh VA-API patches for new version
- Add new dependency on libwebp

Fixes #234
```

**Bad**:
```
updated stuff
```

### Pull Request Guidelines

1. **One feature per PR**: Don't mix unrelated changes
2. **Test thoroughly**: Build, install, and test the package
3. **Update documentation**: Keep README.md and package readme in sync
4. **Pass CI checks**: All linters and builds must pass
5. **Respond to feedback**: Address review comments promptly

### PR Checklist

Before submitting:

- [ ] PKGBUILD follows coding standards
- [ ] .SRCINFO is up to date (`makepkg --printsrcinfo > .SRCINFO`)
- [ ] Package builds successfully (`makepkg -srC`)
- [ ] All linters pass (`./pkg.sh lint`)
- [ ] Documentation is updated
- [ ] Commit messages are descriptive
- [ ] No merge conflicts with main branch

## Testing

### Local Testing

```bash
# Clean build
makepkg -srC

# Install and test functionality
makepkg -si

# Test package contents
makepkg -s
namcap *.pkg.tar.zst

# Check PKGBUILD
namcap PKGBUILD
```

### CI Testing

The CI pipeline will automatically:

1. **Lint all files** (shellcheck, namcap, prettier)
2. **Build packages** (native and Docker)
3. **Check formatting** (shfmt, MegaLinter)
4. **Validate .SRCINFO** matches PKGBUILD

Ensure all checks pass before requesting review.

## Review Process

### What Reviewers Look For

1. **Code quality**: Follows standards, well-structured
2. **Security**: No vulnerabilities, verified sources
3. **Performance**: Proper optimizations applied
4. **Documentation**: Clear and complete
5. **Testing**: Evidence of thorough testing
6. **Compliance**: Follows licensing requirements

### Review Timeline

- Initial review: Within 1-3 days
- Follow-up reviews: Within 1-2 days
- Merging: After approval and CI passes

### Getting Help

- **Questions**: Open a discussion on GitHub
- **Issues**: Create an issue for bugs or feature requests
- **Real-time help**: Check project discussions

## Additional Guidelines

### Package Naming

- Use lowercase with hyphens: `package-name`
- Add suffix if conflicts: `package-custom`, `package-git`
- Follow Arch conventions: `-git`, `-bin`, `-lts`

### Versioning

- `pkgver`: Upstream version (e.g., `1.2.3`)
- `pkgrel`: Increment for packaging changes (reset to 1 on pkgver bump)
- VCS packages: Use `pkgver()` function

### Patch Management

```bash
# Patch naming convention
patches/
├── 0001-descriptive-name.patch
├── 0002-another-feature.patch
└── 0003-security-fix.patch

# In PKGBUILD
prepare() {
  cd "${srcdir}/${_pkgname}-${pkgver}"
  for patch in "${srcdir}"/patches/*.patch; do
    patch -Np1 -i "$patch"
  done
}
```

### Dependencies

- **depends**: Required at runtime
- **makedepends**: Required only for building
- **optdepends**: Optional features with description
- **checkdepends**: Required only for tests

### Common Mistakes to Avoid

1. ❌ Forgetting to update .SRCINFO
2. ❌ Not testing clean builds
3. ❌ Hardcoding paths that should be variables
4. ❌ Using HTTP instead of HTTPS
5. ❌ Not validating checksums
6. ❌ Ignoring linter warnings
7. ❌ Mixing tabs and spaces
8. ❌ Missing error handling in prepare/build functions

## Resources

### Documentation

- [Arch PKGBUILD Documentation](https://wiki.archlinux.org/title/PKGBUILD)
- [Arch Package Guidelines](https://wiki.archlinux.org/title/Arch_package_guidelines)
- [makepkg Manual](https://man.archlinux.org/man/makepkg.8)
- [Project CLAUDE.md](CLAUDE.md) - Detailed AI assistant guide

### Tools

- [shellcheck](https://github.com/koalaman/shellcheck) - Shell linting
- [shfmt](https://github.com/mvdan/sh) - Shell formatting
- [namcap](https://wiki.archlinux.org/title/Namcap) - PKGBUILD linting

### Related Projects

- [CachyOS PKGBUILDs](https://github.com/CachyOS/CachyOS-PKGBUILDS)
- [lseman's PKGBUILDs](https://github.com/lseman/PKGBUILDs)

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project (see individual package licenses).

---

**Questions?** Open an issue or discussion on GitHub.
**Thank you for contributing!**
