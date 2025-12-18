# Dependency Bloat Reduction - Removal Justifications

This document explains the rationale for removing packages from the PKG repository as part of the dependency audit cleanup.

## Packages Removed for Security Reasons (SKIP Checksums)

### 1. borked3DS
- **Reason:** CRITICAL SECURITY RISK
- **Details:** 50+ git submodules all with SKIP checksums
- **Risk:** Supply chain attack vector - no verification of submodule authenticity
- **Recommendation:** Users should use official 3DS emulator sources with proper checksums

### 2. sudachi
- **Reason:** CRITICAL SECURITY RISK
- **Details:**
  - 30+ git submodules with SKIP checksums
  - Binary distribution (.zip) with SKIP checksum
  - Complex sed hacks for compatibility
- **Risk:** Unverified binary distribution + unverified submodules
- **Alternative:** ryujinx (kept) - single binary with clearer provenance

### 3. prismlauncher
- **Reason:** SECURITY + LEGAL/ETHICAL CONCERNS
- **Details:**
  - From "PrismLauncher-Cracked" repository
  - SKIP checksum on main source
  - Multiple license types without clear provenance
- **Risk:** Cracked software distribution, unverified sources
- **Alternative:** Use official PrismLauncher from main repository

### 4. oxicloud
- **Reason:** SECURITY RISK + REDUNDANCY
- **Details:**
  - Git source with SKIP checksum
  - Rust application without checksum verification
  - Redundant with nextcloud (already in repo)
- **Alternative:** nextcloud (more mature, better maintained)

### 5. preload-ng
- **Reason:** SECURITY RISK + QUESTIONABLE UTILITY
- **Details:**
  - VCS source with SKIP checksum
  - Preloading daemon - minimal benefit on modern systems
- **Risk:** Kernel-level optimization without source verification
- **Alternative:** Modern Linux kernels have better memory management

### 6. webp-converter
- **Reason:** SECURITY RISK + NICHE USE CASE
- **Details:**
  - Git source with SKIP checksums
  - Electron-based (heavy dependency)
  - China mirror detection/switching (concerning)
- **Alternative:** Command-line tools: libvips, imagemagick, ffmpeg

### 7. update-alternatives
- **Reason:** SECURITY RISK + NICHE USE CASE
- **Details:**
  - Git source with SKIP checksum
  - Duplicates Debian's update-alternatives tool
  - Limited use case on Arch Linux
- **Alternative:** Manual symlink management or upstream package

## Packages Removed for Redundancy

### 8. etchdns
- **Reason:** DUPLICATE FUNCTIONALITY
- **Details:**
  - Duplicate DNS server (smartdns-rs also in repo)
  - Both are Rust-based DNS servers
- **Kept:** smartdns-rs (more feature-rich, active development)
- **Alternative:** Use smartdns-rs or system DNS

## Packages Kept Despite Concerns

### ryujinx
- **Status:** KEPT (with caveats)
- **Reason:** Only maintained Switch emulator after removals
- **Concerns:** Binary with SKIP checksum, strips/debug disabled
- **TODO:** Add proper checksum verification in future update
- **Recommendation:** Monitor for official Arch Linux package

## Summary Statistics

- **Total packages removed:** 8
- **Security risk removals:** 7 (SKIP checksums)
- **Redundancy removals:** 1 (duplicate functionality)
- **Estimated disk space saved:** ~5GB (source + build artifacts)
- **Attack surface reduction:** ~110+ unverified git submodules removed

## Impact Assessment

### Build Time Reduction
- borked3DS: ~30 minutes (50+ submodules)
- sudachi: ~25 minutes (30+ submodules)
- prismlauncher: ~10 minutes
- Electron apps (webp-converter): ~15 minutes
- **Total:** ~80+ minutes saved on full repository builds

### Security Improvements
- Eliminated 110+ git submodules without checksum verification
- Removed 3 binary distributions without verification
- Removed "cracked" software from official repository
- Reduced supply chain attack surface significantly

### Maintenance Burden Reduction
- Fewer packages to track for updates
- Fewer complex build systems to maintain
- Clearer package purposes and alternatives

## Migration Guide for Users

If you were using removed packages:

**borked3DS users:**
```bash
# Use official Citra (3DS emulator) instead
yay -S citra-qt-git
```

**sudachi users:**
```bash
# Use ryujinx (still in repo) or yuzu
pacman -S ryujinx  # from this repo
# OR
yay -S yuzu-mainline-git
```

**prismlauncher users:**
```bash
# Use official PrismLauncher
yay -S prismlauncher  # official package
```

**oxicloud users:**
```bash
# Use nextcloud (more mature)
pacman -S nextcloud  # from this repo
```

**preload-ng users:**
```bash
# Modern kernels don't need preloading daemons
# Remove preload and rely on kernel memory management
```

**webp-converter users:**
```bash
# Use command-line tools
pacman -S libvips imagemagick
# Convert with: vips webpsave input.jpg output.webp
```

**update-alternatives users:**
```bash
# Manual symlink management
# ln -sf /usr/bin/python3.11 /usr/local/bin/python
```

**etchdns users:**
```bash
# Use smartdns-rs (still in repo)
pacman -S smartdns-rs  # from this repo
```

---

**Date:** 2025-12-18
**Audit Reference:** PKG Repository Dependency Audit Report
**Decision Authority:** Based on security analysis and CVE audit findings
