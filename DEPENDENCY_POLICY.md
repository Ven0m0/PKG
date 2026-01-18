# Dependency Policy for PKG Repository

**Version:** 1.0
**Last Updated:** 2026-01-16
**Status:** Mandatory for all new packages, recommended for existing packages

---

## Purpose

This document establishes clear guidelines for managing package dependencies in the PKG repository to:
- **Minimize bloat** - Only include necessary dependencies
- **Improve security** - Reduce attack surface
- **Enhance user choice** - Let users decide what features they need
- **Maintain clarity** - Make dependencies understandable and well-documented

---

## Dependency Classification Rules

### 1. Runtime Dependencies (`depends`)

**Purpose:** Libraries and programs that **MUST** be installed for the package to function at all.

**Rules:**
- ✅ **ONLY** include essential runtime libraries
- ✅ **MUST** be required for basic functionality
- ❌ **NEVER** include build tools (git, cmake, rust, etc.)
- ❌ **NEVER** include optional features
- ❌ **NEVER** duplicate packages also listed in makedepends

**Examples:**
```bash
# Good - Essential runtime libraries only
depends=(
  'glibc'           # Required: C standard library
  'gcc-libs'        # Required: GCC runtime
  'libx11'          # Required: X11 client library
  'fontconfig'      # Required: Font configuration
)

# Bad - Includes build tools and optional features
depends=(
  'glibc'
  'git'             # ❌ Build tool, not runtime dependency
  'vulkan-icd-loader' # ❌ Optional feature, should be optdepends
  'cmake'           # ❌ Build tool, should be makedepends
)
```

**Test:** Can the package start without this dependency? If yes, it's NOT a runtime dependency.

---

### 2. Build Dependencies (`makedepends`)

**Purpose:** Tools and libraries needed **ONLY** during the build process.

**Rules:**
- ✅ **ONLY** include tools needed for building
- ✅ Automatically removed after installation
- ❌ **NEVER** duplicate packages from depends
- ❌ **NEVER** include dependencies of disabled features

**Examples:**
```bash
# Good - Build-only tools
makedepends=(
  'git'             # ✅ Needed to fetch source
  'cmake'           # ✅ Build system
  'rust'            # ✅ Compiler
  'pkg-config'      # ✅ Build configuration tool
)

# Bad - Runtime libs or duplicates
makedepends=(
  'git'
  'glibc'           # ❌ This is a runtime dep, goes in depends
  'vulkan-icd-loader' # ❌ Optional runtime, goes in optdepends
  'libcups'         # ❌ If built with --without-cups, remove this!
)
```

**Special Case - Disabled Features:**
```bash
# If configure script uses:
#   --without-cups
#   --without-v4l2
#   --without-pcsclite
# Then REMOVE these from makedepends:
#   libcups, lib32-libcups
#   v4l-utils, lib32-v4l-utils
#   pcsclite, lib32-pcsclite
```

**Test:** Is this only needed during `build()` or `prepare()`? If yes, it's a makedepends.

---

### 3. Optional Dependencies (`optdepends`)

**Purpose:** Features that users **MAY** want to enable based on their needs.

**Rules:**
- ✅ **MUST** have clear descriptions
- ✅ Format: `'package: What feature it enables'`
- ✅ Group related packages together
- ✅ Indicate when features are rarely needed
- ❌ **NEVER** use without descriptions

**Format:**
```bash
optdepends=(
  'package: Clear description of what feature this enables'
  'lib32-package: 32-bit version for multilib support'
)
```

**Examples:**
```bash
# Good - Clear descriptions
optdepends=(
  'alsa-lib: ALSA audio support'
  'lib32-alsa-lib: 32-bit ALSA audio support'
  'vulkan-icd-loader: Vulkan graphics API support'
  'libva: Hardware video acceleration (Intel/AMD)'
  'nvidia-utils: Hardware video acceleration (NVIDIA)'
  'pipewire: Modern audio server (only needed outside Steam)'
  'gst-plugins-good: H.264/AAC multimedia codec support'
)

# Bad - No descriptions
optdepends=(
  'alsa-lib'        # ❌ What does this provide?
  'lib32-alsa-lib'  # ❌ Why do I need this?
  'vulkan-icd-loader' # ❌ When would I use this?
)
```

**Categories to Document:**
- **Audio:** ALSA, PulseAudio, JACK, PipeWire
- **Video:** Hardware acceleration (VA-API, VDPAU, NVDEC)
- **Graphics:** Vulkan, OpenCL, CUDA
- **Codecs:** GStreamer plugins, FFmpeg
- **Network:** SMB/CIFS (Samba), CUPS (printing)
- **Desktop:** GTK themes, Qt themes, notifications
- **Gaming:** Steam, gamemode, MangoHud

**Special Annotations:**
```bash
optdepends=(
  'steam: Required for running Proton games (highly recommended)'
  'lib32-vulkan-driver: 32-bit Vulkan (only needed outside Steam)'
  'ntsync-common: NT synchronization for better performance (experimental)'
)
```

---

### 4. Check Dependencies (`checkdepends`)

**Purpose:** Tools needed **ONLY** for running test suites.

**Rules:**
- ✅ Only include if package has `check()` function
- ✅ Testing frameworks only
- ❌ Never installed by default

**Examples:**
```bash
checkdepends=(
  'gtest'           # ✅ Google Test framework
  'pytest'          # ✅ Python testing
  'cppunit'         # ✅ C++ unit tests
)
```

---

## Common Mistakes and How to Fix Them

### Mistake 1: Build Tools in Runtime Dependencies

**Wrong:**
```bash
depends=('glibc' 'git' 'cmake' 'rust')
```

**Correct:**
```bash
depends=('glibc')
makedepends=('git' 'cmake' 'rust')
```

---

### Mistake 2: Optional Features as Required Dependencies

**Wrong:**
```bash
depends=(
  'glibc'
  'vulkan-icd-loader'  # Optional feature
  'libva'              # Optional feature
  'gst-plugins-good'   # Optional feature
)
```

**Correct:**
```bash
depends=('glibc')
optdepends=(
  'vulkan-icd-loader: Vulkan graphics API support'
  'libva: Hardware video acceleration'
  'gst-plugins-good: H.264/AAC codec support'
)
```

---

### Mistake 3: Dependencies for Disabled Features

**Wrong:**
```bash
# In build():
configure --without-cups --without-v4l2

# But in makedepends:
makedepends=(
  'libcups'         # ❌ Feature is disabled!
  'lib32-libcups'   # ❌ Feature is disabled!
  'v4l-utils'       # ❌ Feature is disabled!
)
```

**Correct:**
```bash
# In build():
configure --without-cups --without-v4l2

# In makedepends:
makedepends=(
  # libcups and v4l-utils removed because features are disabled
  'git'
  'cmake'
)
```

---

### Mistake 4: Duplicate Dependencies

**Wrong:**
```bash
depends=('glibc' 'gcc-libs')
makedepends=('git' 'glibc' 'gcc-libs')  # ❌ Duplicates!
```

**Correct:**
```bash
depends=('glibc' 'gcc-libs')
makedepends=('git')  # ✅ No duplicates
```

---

### Mistake 5: Missing Descriptions in optdepends

**Wrong:**
```bash
optdepends=(
  'alsa-lib'
  'vulkan-icd-loader'
  'gst-plugins-good'
)
```

**Correct:**
```bash
optdepends=(
  'alsa-lib: ALSA audio support'
  'vulkan-icd-loader: Vulkan graphics API'
  'gst-plugins-good: H.264/AAC codecs'
)
```

---

### Mistake 6: lib32 Packages Always Required

**Wrong:**
```bash
depends=(
  'glibc' 'lib32-glibc'
  'gcc-libs' 'lib32-gcc-libs'
  # ... 50 more lib32 packages forced for everyone
)
```

**Better:**
```bash
depends=('glibc' 'gcc-libs')

# Conditional multilib support (Wine packages)
if [ "$_NOLIB32" = "false" ]; then
  depends+=(
    'lib32-glibc'
    'lib32-gcc-libs'
  )
fi
```

**Or:**
```bash
optdepends=(
  'lib32-glibc: 32-bit application support'
  'lib32-gcc-libs: 32-bit runtime libraries'
)
```

---

## Package-Specific Guidelines

### Wine Packages

Wine packages have unique requirements because they need libraries available during compilation:

**Template:**
```bash
depends=(
  # Core essentials only
  'attr' 'lib32-attr'
  'fontconfig' 'lib32-fontconfig'
  'freetype2' 'lib32-freetype2'
  'gcc-libs' 'lib32-gcc-libs'
)

makedepends=(
  # Build tools
  'git' 'autoconf' 'bison' 'perl'
  'mingw-w64-gcc'

  # Libraries needed during build
  'alsa-lib' 'lib32-alsa-lib'
  'mesa' 'lib32-mesa'
  'vulkan-headers'
  'gst-plugins-base-libs' 'lib32-gst-plugins-base-libs'
)

optdepends=(
  'alsa-lib: ALSA audio support'
  'lib32-alsa-lib: 32-bit ALSA audio'
  'vulkan-icd-loader: Vulkan graphics API'
  'lib32-vulkan-icd-loader: 32-bit Vulkan'
  'gst-plugins-good: H.264/AAC codecs'
  'lib32-gst-plugins-good: 32-bit codecs'
)

# This is Wine-specific and correct:
makedepends=("${makedepends[@]}" "${depends[@]}")
```

**Note:** Wine's `makedepends=("${makedepends[@]}" "${depends[@]}")` is intentional and correct for Wine. This is an exception, not the rule.

---

### Proton Packages

Proton packages have different needs when running inside vs. outside Steam:

**Template:**
```bash
depends=(
  # Core Proton essentials
  'attr' 'lib32-attr'
  'fontconfig' 'lib32-fontconfig'
  'freetype2' 'lib32-freetype2'
  'gcc-libs' 'lib32-gcc-libs'
  'python' 'python-six'
  'sdl2' 'lib32-sdl2'
  'wayland' 'lib32-wayland'
)

optdepends=(
  'steam: Required for running Proton games (highly recommended)'

  # Features
  'vulkan-icd-loader: Vulkan graphics'
  'lib32-vulkan-icd-loader: 32-bit Vulkan'

  # Steam runtime (only needed outside Steam)
  'atk: Accessibility (only needed outside Steam)'
  'lib32-atk: 32-bit accessibility (only needed outside Steam)'
  'cairo: 2D graphics (only needed outside Steam)'
  'lib32-cairo: 32-bit 2D graphics (only needed outside Steam)'
  # ... more steam runtime packages
)
```

---

### Mesa / Graphics Drivers

**Template:**
```bash
depends=(
  # Core libraries
  'libdrm'
  'libxxf86vm'
  'libxdamage'
  'libxshmfence'
  'libelf'
  'llvm-libs'
  'wayland'
  'zstd'
)

makedepends=(
  'git'
  'python-mako'
  'python-ply'
  'xorgproto'
  'libxml2'
  'meson'
  'ninja'
  'rust'          # For NVK driver
  'rust-bindgen'  # For NVK driver
)

optdepends=(
  'opengl-man-pages: OpenGL API documentation'
  'libva-mesa-driver: VA-API video acceleration (Intel/AMD)'
  'lib32-libva-mesa-driver: 32-bit VA-API'
)
```

---

### Rust Packages

**Template:**
```bash
depends=(
  'gcc-libs'
  'glibc'
  # ... runtime libraries only
)

makedepends=(
  'rust'
  'cargo'
  'clang'         # If needed for bindgen
  'llvm'          # If needed for bindgen
)

# Rust packages rarely need optdepends
optdepends=()
```

---

## Validation Checklist

Before committing changes, verify:

- [ ] No build tools in `depends`
- [ ] No runtime libraries duplicated in `makedepends`
- [ ] All `optdepends` have descriptions
- [ ] Dependencies for `--without-*` features are removed
- [ ] lib32 packages are conditional or clearly justified
- [ ] No packages listed in both `depends` and `makedepends`
- [ ] `makedepends` only contains build-time requirements
- [ ] Optional features are in `optdepends`, not `depends`

---

## Automated Validation

Future: Add to `.github/workflows/lint.yml`:

```yaml
- name: Check dependency bloat
  run: |
    # Check for build tools in depends
    if grep -r "depends=.*git" */PKGBUILD; then
      echo "ERROR: Build tools found in runtime dependencies"
      exit 1
    fi

    # Check for optdepends without descriptions
    if grep -r "optdepends=(.*[^:]" */PKGBUILD; then
      echo "ERROR: optdepends missing descriptions"
      exit 1
    fi
```

---

## Migration Guide

### For Existing Packages

1. **Read the current PKGBUILD**
   - Identify all dependencies
   - Note configure flags (`--with-*`, `--without-*`)

2. **Classify Dependencies**
   - Essential runtime → `depends`
   - Build-only tools → `makedepends`
   - Optional features → `optdepends`

3. **Remove Bloat**
   - Dependencies for disabled features
   - Build tools from `depends`
   - Unnecessary lib32 packages

4. **Add Descriptions**
   - All `optdepends` need clear descriptions
   - Explain what each package provides

5. **Test**
   - Build the package
   - Verify basic functionality without optdepends
   - Test with optdepends installed

6. **Document**
   - Note changes in commit message
   - Update package readme if needed

---

## Examples from Real Packages

### Example 1: localepurge (Minimal)

**Before:**
```bash
depends=()
makedepends=()
```

**After:**
```bash
depends=()  # Bash script, no runtime deps needed
makedepends=()  # No build process
```

**Analysis:** ✅ Perfect - No unnecessary dependencies

---

### Example 2: wine-tkg-git (Before Optimization)

**Before:**
```bash
depends=(
  'attr' 'lib32-attr'
  'gcc-libs' 'lib32-gcc-libs'
  # ... plus lib32-lcms2 listed twice (bug!)
)

optdepends=(
  'vulkan-icd-loader'  # No description
  'libva'              # No description
)
```

**After:**
```bash
depends=(
  'attr' 'lib32-attr'
  'gcc-libs' 'lib32-gcc-libs'
  # ... (duplicate removed)
)

optdepends=(
  'vulkan-icd-loader: Vulkan graphics API support'
  'lib32-vulkan-icd-loader: 32-bit Vulkan support'
  'libva: Hardware video acceleration (Intel/AMD)'
  'lib32-libva: 32-bit hardware video acceleration'
)
```

**Savings:** Removed duplicate, added clarity

---

### Example 3: proton-cachyos (Before Optimization)

**Before:**
```bash
depends=(
  'attr' 'lib32-attr'
  # ... 35+ steam-runtime packages forced
  'atk' 'lib32-atk'
  'cairo' 'lib32-cairo'
  # ... more steam-runtime
)
```

**After:**
```bash
depends=(
  'attr' 'lib32-attr'
  # ... core deps only
)

optdepends=(
  'steam: Required for Proton games (highly recommended)'
  'atk: Accessibility (only needed outside Steam)'
  'lib32-atk: 32-bit accessibility (only needed outside Steam)'
  'cairo: 2D graphics (only needed outside Steam)'
  'lib32-cairo: 32-bit 2D graphics (only needed outside Steam)'
)
```

**Savings:** ~400MB for Steam users (who don't need steam-runtime deps)

---

## FAQs

### Q: Should I list a package in both `depends` and `optdepends`?

**A:** No, never. If it's required, it goes in `depends`. If it's optional, it goes in `optdepends`.

### Q: What about packages needed for building but also optionally at runtime?

**A:**
- If required for building → `makedepends`
- If optional at runtime → `optdepends`
- Both is fine!

Example:
```bash
makedepends=('vulkan-headers')  # Needed to compile
optdepends=('vulkan-icd-loader: Vulkan support')  # Optional at runtime
```

### Q: Can lib32 packages be optional?

**A:** Yes! If your package works without 32-bit support, make them optional:

```bash
optdepends=(
  'lib32-glibc: 32-bit application support'
  'lib32-gcc-libs: 32-bit runtime libraries'
)
```

### Q: What if upstream's documentation says something is "recommended"?

**A:** "Recommended" → `optdepends` with description. Only truly required things go in `depends`.

### Q: Should test frameworks be in `makedepends` or `checkdepends`?

**A:** Always `checkdepends`. They're only needed for `check()` function.

---

## Enforcement

**For New Packages:**
- **Mandatory** - All new packages must follow this policy
- CI/CD will reject non-compliant packages

**For Existing Packages:**
- **Recommended** - Migrate during updates
- High-impact packages (Wine, Proton, Mesa) should be prioritized

---

## References

- [Arch PKGBUILD Guidelines](https://wiki.archlinux.org/title/PKGBUILD)
- [Arch Package Guidelines](https://wiki.archlinux.org/title/Arch_package_guidelines)
- [DEPENDENCY_AUDIT_REPORT.md](./DEPENDENCY_AUDIT_REPORT.md)
- [DEPENDENCY_BLOAT_ANALYSIS.md](./DEPENDENCY_BLOAT_ANALYSIS.md)

---

## Changelog

- **2026-01-16:** Initial policy v1.0 based on dependency audit
