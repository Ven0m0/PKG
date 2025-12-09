# CLAUDE.md - AI Assistant Guide for PKG Repository

## Project Overview

This repository contains optimized **PKGBUILDs** (Arch Linux package build scripts) for various software packages. The goal is to provide performance-optimized builds with custom patches and configurations.

**Primary Purpose**: Maintain a collection of PKGBUILDs with performance optimizations, security patches, and custom configurations for Arch Linux packages.

**Key Technologies**:
- Arch Linux packaging system (makepkg, PKGBUILD)
- Bash shell scripting
- Docker for isolated builds
- GitHub Actions CI/CD
- Patch management (git patches)

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
├── .gitconfig              # Git optimization settings
├── README.md               # Main repository documentation
├── TODO.MD                 # Planned features
└── SECURITY.md             # Security policy
```

### Package Directory Structure

Each package directory contains:
- **PKGBUILD** (mandatory): The package build script
- **.SRCINFO** (mandatory): Auto-generated metadata (run `makepkg --printsrcinfo > .SRCINFO`)
- **readme.md** (recommended): Package-specific documentation
- **patches/** or **\*.patch**: Custom patches to apply during build
- **\*.sh**: Custom build/patch helper scripts (optional)

## Key Conventions & Standards

### 1. Shell Script Standards

All shell scripts must follow these standards:

**Shebang and Options**:
```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Safe field separator
```

**Linting Tools** (all must pass):
- **shellcheck**: Static analysis for shell scripts
- **shellharden**: Safety and robustness checks
- **shfmt**: Formatting (indent: 2 spaces, bash dialect)

**Disabled ShellCheck Rules** (see `.shellcheckrc`):
- SC1090, SC1091: Non-constant sources
- SC2034: Unused variables (may be used externally)
- SC2086: Intentional unquoted expansion
- SC2154: Variables from external sources

### 2. PKGBUILD Conventions

**Standard Structure**:
```bash
# Maintainer: Your Name
_pkgname=originalname
pkgname="$_pkgname-custom"  # Use custom suffix if conflicts exist
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
        'patch1.patch'
        'patch2.patch')
sha256sums=('checksum'
            'SKIP'  # Use SKIP for local patches
            'SKIP')

prepare() {
  cd "$_pkgname-$pkgver"
  # Apply patches
  patch -Np1 -i ../patch1.patch
}

build() {
  cd "$_pkgname-$pkgver" || exit
  # Optimized build flags
  export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt"
  export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt"
  # Build commands
  ./configure --prefix=/usr
  make
}

check() {
  cd "$_pkgname-$pkgver" || exit
  make check
}

package() {
  cd "$_pkgname-$pkgver" || exit
  make DESTDIR="$pkgdir" install
}
```

**Optimization Patterns**:
- Replace `-O2` with `-O3` for performance
- Add `-pipe -fno-plt -fstack-protector-strong`
- Use `LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"`
- Set `MAKEFLAGS="-j$(nproc)"` for parallel builds

**After PKGBUILD Changes**:
```bash
makepkg --printsrcinfo > .SRCINFO
```

### 3. EditorConfig Standards

Follow `.editorconfig` settings:
- **Indentation**: 2 spaces (not tabs, except for Makefiles/Go)
- **Line endings**: LF (Unix style)
- **Charset**: UTF-8
- **Max line length**: 128 characters (140 for Markdown)
- **Trim trailing whitespace**: true
- **Insert final newline**: true
- **Shell variant**: bash

### 4. Patch Management

**Naming Convention**:
```
0001-descriptive-name.patch
0002-another-feature.patch
```

**Applying Patches in PKGBUILD**:
```bash
prepare() {
  cd "$_pkgname-$pkgver"
  patch -Np1 -i ../0001-feature.patch
  patch -Np1 -i ../0002-bugfix.patch
}
```

**Custom Patch Scripts** (see `handbrake/patch.sh`):
- Use for complex patch workflows
- Always use `set -euo pipefail`
- Validate directory existence before applying
- Loop through patches in order

### 5. Git Workflow

**Repository Git Configuration**:
The `.gitconfig` file contains optimized settings:
- Compression level: 9
- Protocol: HTTP/2, version 2
- Rebase on pull: true
- Auto-squash rebasing: true
- Aggressive garbage collection
- Incremental maintenance strategy

**Commit Conventions**:
- Use descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused and atomic

**Gitignore Patterns**:
- Build artifacts: `*.tar.*`, `*.zip`, `pkg/`, `src/`
- Compiled binaries: `*.exe`, `*.so`, `*.o`
- IDE files: `.vscode/`, `__pycache__/`
- Temporary files: `*.tmp`, `*.log`, `*.bak`
- Language-specific: `target/` (Rust), `node_modules/` (Node.js)

## Development Workflows

### Building Packages Locally

**Build Single Package**:
```bash
cd <package-name>
makepkg -si  # Build and install
```

**Build with build.sh Script**:
```bash
# Build specific packages
./build.sh aria2 firefox

# Build all packages
./build.sh
```

**Docker Build** (for packages in `DOCKER_REGEX`):
```bash
# Automatically detected for: obs-studio, firefox, egl-wayland2, onlyoffice
./build.sh obs-studio
```

### Linting and Validation

**Run All Linters**:
```bash
./lint.sh
```

This script performs:
1. **ShellCheck**: Static analysis with patch application
2. **Shellharden**: Safety improvements
3. **shfmt**: Code formatting
4. **.SRCINFO validation**: Ensures sync with PKGBUILD

**Fix Common Issues**:
```bash
# Update .SRCINFO after PKGBUILD changes
cd <package>
makepkg --printsrcinfo > .SRCINFO

# Format shell scripts
shfmt -ln bash -bn -s -i 2 -w PKGBUILD

# Check for shell issues
shellcheck -x -a -s bash PKGBUILD
```

### CI/CD Workflows

**GitHub Actions Workflows**:

1. **build.yml** - Package building
   - Triggered: Push/PR to `**/PKGBUILD`, manual dispatch
   - Detects modified packages automatically
   - Builds in matrix (parallel builds)
   - Two build methods: standard (native) and Docker
   - Caching: APT packages, Rust artifacts, Docker layers, sccache
   - Artifacts retention: 30 days
   - Optional GitHub release creation

2. **lint.yml** - Code quality
   - Triggered: Push/PR to PKGBUILDs, shell scripts, Python, JSON, YAML
   - Jobs: PKGBUILD lint, fast-lint (shellcheck/ruff/prettier), MegaLinter
   - Tools: shellcheck, namcap, ruff, black, yamllint, prettier

3. **automerge-dependabot.yml** - Dependency automation
   - Auto-merges Dependabot PRs

**Environment Variables** (CI):
- `DOCKER_BUILD_PACKAGES`: Packages requiring Docker builds
- `CC=clang`, `CXX=clang++`: Use Clang compiler
- `RUSTC_WRAPPER=sccache`: Rust compilation caching
- `SCCACHE_GHA_ENABLED=true`: GitHub Actions cache integration

### Adding a New Package

1. **Create package directory**:
   ```bash
   mkdir new-package
   cd new-package
   ```

2. **Create PKGBUILD**:
   - Follow conventions above
   - Include optimization flags
   - Add patches if needed

3. **Generate .SRCINFO**:
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

4. **Create readme.md** (recommended):
   ```markdown
   # package-name

   ## Description
   Brief description

   ## Source
   - Upstream: https://github.com/...

   ## Build Instructions
   ```bash
   cd package-name
   makepkg -si
   ```

   ## License
   LICENSE-TYPE
   ```

5. **Test build locally**:
   ```bash
   makepkg -sr
   ```

6. **Commit changes**:
   ```bash
   git add .
   git commit -m "Add new-package: Description"
   ```

### Modifying Existing Packages

1. **Edit PKGBUILD**:
   - Bump `pkgrel` for packaging changes
   - Bump `pkgver` for upstream version updates
   - Update checksums if sources change

2. **Update .SRCINFO**:
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

3. **Test build**:
   ```bash
   makepkg -srC  # Clean build
   ```

4. **Run linters**:
   ```bash
   cd /path/to/PKG
   ./lint.sh
   ```

5. **Commit with descriptive message**:
   ```bash
   git commit -am "package-name: Update to version X.Y.Z"
   ```

## Build System Details

### Build Methods

**Standard Build** (native):
- Uses GitHub Actions runner natively
- Caching: APT, Rust, sccache, LLVM
- Faster for smaller packages
- Uses `2m/arch-pkgbuild-builder@v1.25` action

**Docker Build** (containerized):
- Required for: obs-studio, firefox, egl-wayland2, onlyoffice
- Uses `archlinux:latest` base image
- Optimized mirrors (reflector)
- Parallel downloads: 8
- Caching: Docker layers, ccache, sccache
- More disk space (cleanup actions run)

### Compiler and Optimization

**Default Compilers**:
- C: `clang` (LLVM)
- C++: `clang++` (LLVM)
- Rust wrapper: `sccache` (distributed caching)

**Optimization Flags** (common patterns):
```bash
export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
export MAKEFLAGS="-j$(nproc)"
```

### Caching Strategy

**Local Development**:
- Package builds cache in `~/.cache/`
- Source files in `pkg/` and `src/` (gitignored)

**CI/CD Caching**:
- APT packages: `awalsh128/cache-apt-pkgs-action@v1`
- Rust artifacts: `~/.cargo/` directories
- Docker layers: `/tmp/.buildx-cache`
- sccache: GitHub Actions cache backend

## Tools and Requirements

### Required Tools (Development)

**For Local Building**:
- `base-devel` (Arch Linux metapackage)
- `makepkg`, `pacman`
- `git`

**For Linting**:
- `shellcheck` - Shell script linting
- `shellharden` - Shell script safety
- `shfmt` - Shell formatting
- `namcap` - PKGBUILD linting

**Optional but Recommended**:
- `fd` - Fast file finder (alternative to `find`)
- `docker` - For Docker builds
- `sccache` - Compilation caching
- `clang` - Optimized compiler

### Tool Configuration Files

- `.shellcheckrc` - ShellCheck configuration
- `.editorconfig` - Editor settings
- `.eslintrc.js` - JavaScript linting (if applicable)
- `.gitignore` - Git ignore patterns
- `.gitconfig` - Git optimizations
- `.qlty/qlty.toml` - Code quality tool config

## Common Patterns and Idioms

### Safe Shell Scripting

**Always start with**:
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

**Use `readonly` for constants**:
```bash
readonly DOCKER_REGEX="^(obs-studio|firefox)$"
readonly IMAGE="archlinux:latest"
```

**Helper functions** (from build.sh):
```bash
err(){ printf "\e[31m✘ %s\e[0m\n" "$*" >&2; }
log(){ printf "\e[32m➜ %s\e[0m\n" "$*"; }
has(){ command -v "$1" &>/dev/null; }
```

**Safe directory changes**:
```bash
cd "$dir" || exit 1
# or
pushd "$dir" >/dev/null
# ... work ...
popd >/dev/null
```

### Finding PKGBUILDs

**Optimized search** (from build.sh):
```bash
if has fd; then
  fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u
else
  find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u
fi
```

**Caching tool availability** (from lint.sh):
```bash
has_shellcheck=false
command -v shellcheck &>/dev/null && has_shellcheck=true
```

### Docker Build Pattern

**Standard Docker invocation**:
```bash
docker run --rm -it \
  -v "${PWD}:/ws:rw" \
  -w "/ws/$pkg" \
  "$IMAGE" \
  bash -c "
    set -euo pipefail
    pacman -Syu --noconfirm --needed base-devel

    # Extract deps dynamically
    deps=\$(makepkg --printsrcinfo | awk '/^\s*(make)?depends\s*=/ { \$1=\"\"; print \$0 }' | tr '\n' ' ')
    [[ -n \"\$deps\" ]] && pacman -S --noconfirm --needed \$deps

    # Build as non-root
    useradd -m builder
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder
    chmod 440 /etc/sudoers.d/builder
    chown -R builder:builder .
    sudo -u builder makepkg -fs --noconfirm
  "
```

## Security Considerations

### PKGBUILD Security

- **Verify checksums**: Always use proper checksums (sha256sums, sha512sums)
- **HTTPS sources**: Prefer HTTPS URLs for source downloads
- **GPG signatures**: Validate when available (validpgpkeys array)
- **Patch review**: Review all patches before applying
- **No arbitrary code**: Avoid downloading and executing unverified scripts

### Reporting Vulnerabilities

See `SECURITY.md`:
- Do not open public issues for vulnerabilities
- Use private vulnerability reporting
- Email maintainer directly
- Allow time for fixes before disclosure

## Troubleshooting

### Common Build Issues

**Issue**: `.SRCINFO` out of sync
```bash
# Solution
cd <package>
makepkg --printsrcinfo > .SRCINFO
```

**Issue**: Missing dependencies
```bash
# Solution: Install from PKGBUILD
cd <package>
makepkg -s  # Auto-install deps
```

**Issue**: Checksum mismatch
```bash
# Solution: Update checksums
cd <package>
updpkgsums  # or manually update sha256sums
```

**Issue**: Patch fails to apply
```bash
# Debug
cd <package>
source PKGBUILD
cd src/<source-dir>
patch -Np1 --dry-run -i ../../patch.patch
```

### Linting Failures

**ShellCheck errors**:
```bash
# View errors
shellcheck -x -a -s bash PKGBUILD

# Auto-fix (careful!)
shellcheck -x -a -s bash -f diff PKGBUILD | patch -Np1
```

**Formatting issues**:
```bash
# Auto-format
shfmt -ln bash -bn -s -i 2 -w PKGBUILD *.sh
```

### CI/CD Debugging

**Build fails in CI but works locally**:
- Check caching issues (clear cache)
- Verify environment variables match
- Review CI logs for dependency issues
- Test in Docker locally: `./build.sh <package>`

**Lint passes locally but fails in CI**:
- Ensure all tools are same version
- Check `.shellcheckrc` is committed
- Verify `.SRCINFO` is up to date and committed

## AI Assistant Guidelines

### When Working with This Repository

1. **Always read PKGBUILD before modifying** - Understand current state
2. **Run lint.sh after changes** - Ensure quality standards
3. **Update .SRCINFO after PKGBUILD edits** - Keep metadata in sync
4. **Test builds locally** - Don't rely solely on CI
5. **Follow shell script standards** - Use set -euo pipefail, proper quoting
6. **Respect EditorConfig** - 2-space indentation, LF line endings
7. **Keep commits atomic** - One logical change per commit
8. **Update checksums** - When changing sources
9. **Document changes** - Update readme.md if behavior changes
10. **Security first** - Review patches, verify sources, use HTTPS

### DO:
- ✅ Read existing code before suggesting changes
- ✅ Follow established patterns in the codebase
- ✅ Update both PKGBUILD and .SRCINFO together
- ✅ Test changes before committing
- ✅ Use optimization flags consistently
- ✅ Add descriptive commit messages
- ✅ Validate shell scripts with shellcheck
- ✅ Use proper error handling (set -euo pipefail)
- ✅ Cache expensive operations (see lint.sh pattern)
- ✅ Prefer existing tools (fd over find when available)

### DON'T:
- ❌ Modify PKGBUILD without updating .SRCINFO
- ❌ Skip testing builds locally
- ❌ Ignore linting failures
- ❌ Add tabs to shell scripts (use 2 spaces)
- ❌ Use CRLF line endings (use LF)
- ❌ Bypass safety checks (set -euo pipefail)
- ❌ Hardcode paths that could be dynamic
- ❌ Download unverified sources
- ❌ Use HTTP when HTTPS is available
- ❌ Commit build artifacts (pkg/, src/, *.tar.*)

### Suggested Workflow for Changes

1. **Understand the request**
   - Read the relevant PKGBUILD
   - Check existing patches
   - Review package readme.md

2. **Plan the changes**
   - Identify what needs to be modified
   - Consider impact on dependencies
   - Check for similar patterns in other packages

3. **Implement changes**
   - Edit PKGBUILD following conventions
   - Update version/release numbers
   - Add/modify patches if needed

4. **Update metadata**
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

5. **Validate**
   ```bash
   ./lint.sh  # From repo root
   ```

6. **Test build**
   ```bash
   makepkg -srC  # Clean build
   ```

7. **Commit**
   ```bash
   git add .
   git commit -m "package: descriptive message"
   ```

## References and Resources

### External Resources

**Arch Linux**:
- [PKGBUILD Guidelines](https://wiki.archlinux.org/title/PKGBUILD)
- [Arch Package Guidelines](https://wiki.archlinux.org/title/Arch_package_guidelines)
- [makepkg Documentation](https://man.archlinux.org/man/makepkg.8)

**Related Projects** (from README.md):
- [CachyOS-PKGBUILDS](https://github.com/CachyOS/CachyOS-PKGBUILDS)
- [lseman's PKGBUILDs with PGO](https://github.com/lseman/PKGBUILDs)
- [pkgforge-dev/Anylinux-AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages)

**Tools**:
- [shellcheck](https://github.com/koalaman/shellcheck)
- [shfmt](https://github.com/mvdan/sh)
- [shellharden](https://github.com/anordal/shellharden)
- [patchutils](https://github.com/twaugh/patchutils)

### Internal Documentation

- `README.md` - Main repository information
- `TODO.MD` - Planned features
- `SECURITY.md` - Security policy
- `<package>/readme.md` - Package-specific docs

## Project Goals and Philosophy

**Performance First**: Optimize builds with -O3, LTO where applicable, modern compiler flags

**Security Conscious**: Verify sources, use HTTPS, validate checksums, review patches

**Clean Code**: Follow shell best practices, lint everything, maintain consistency

**Automated Quality**: CI/CD catches issues early, automated linting and building

**Documentation**: Clear README files, inline comments where needed, this guide for AI

**Maintainability**: Consistent patterns, modular design, clear separation of concerns

---

**Last Updated**: 2025-12-03
**Repository**: https://github.com/Ven0m0/PKG
**Maintainer**: Ven0m0
