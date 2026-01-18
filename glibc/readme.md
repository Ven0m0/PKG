# glibc-eac-roco

## ⚠️ SECURITY WARNING - GAMING-SPECIFIC FORK ⚠️

**THIS IS A SPECIALIZED GAMING BUILD WITH SECURITY/MODERNIZATION TRADE-OFFS**

This package contains custom patches that **revert upstream glibc improvements** to maintain compatibility with:
- **Epic Games Easy Anti-Cheat (EAC)**
- **Rogue Company** game
- Other games using older glibc assumptions

### **⚠️ DO NOT USE FOR GENERAL-PURPOSE SYSTEMS**

This build is **NOT recommended** for:
- Production servers
- General desktop use
- Security-sensitive environments
- Systems that don't need gaming compatibility

**For general use, install the official `glibc` package instead.**

---

## What This Package Does

### Patch 1: `reenable_DT_HASH.patch`

**Purpose:** Re-enables old `DT_HASH` symbol table format alongside modern `DT_GNU_HASH`

**Impact:**
- Forces `--hash-style=both` for Epic Games EAC compatibility
- Slightly larger binary sizes
- Slightly slower symbol lookups (DT_HASH is less efficient)
- **Risk Level: LOW** - Functional change for compatibility, minimal security impact

**Why It's Needed:** Epic Games' Easy Anti-Cheat expects both hash styles to be present.

---

### Patch 2: `rogue_company_reverts.patch`

**Purpose:** Reverts **5 upstream glibc commits** to make Rogue Company work

**Commits Reverted:**

#### 1. Commit `7a5db2e82fbb` - Cleanup of GLIBC_PRIVATE exports
- **Impact:** Re-exposes internal symbols (`_dl_addr`, `_dl_sym`, `__libc_dlopen_mode`)
- **Risk:** Internal APIs exposed; potential ABI compatibility issues

#### 2. Commit `8208be389bce` - Modern shared object installation
- **Impact:** Uses old library naming scheme
- **Risk:** May break modern tooling expectations

#### 3. Commit `6bf789d69e6b` - DSO name recognition generalization
- **Impact:** Hardcodes "lib" and "ld-" prefix checks in ldconfig
- **Risk:** Less flexible library detection

#### 4. Commit `b89d5de25082` - Removal of lib-version/subdir-version
- **Impact:** Re-adds old version handling code
- **Risk:** More code paths = more potential for bugs

#### 5. Commit `86f0179bc003` - libthread_db installation modernization
- **Impact:** Old naming scheme for thread debugging library
- **Risk:** Tool compatibility issues

---

## Security Implications

### What You're Giving Up

1. **Modern glibc improvements** - Missing optimizations and fixes from reverted commits
2. **Code quality** - Re-introducing code that upstream removed for good reasons
3. **Future compatibility** - Diverging from standard glibc development path
4. **Potential vulnerabilities** - Older code may have undiscovered issues

### What You're Gaining

- **Gaming compatibility** with EAC and Rogue Company
- **Ability to play** games that don't work with standard glibc

---

## Trade-Off Summary

| Aspect | Official glibc | glibc-eac-roco |
| :------ | :------------- | :------------- |
| **Security** | ✅ Latest patches | ⚠️ Reverted improvements |
| **Performance** | ✅ Optimized | ⚠️ Older code paths |
| **Compatibility** | ✅ Standard | ⚠️ Divergent |
| **Gaming (EAC/Rogue Co)** | ❌ May not work | ✅ Works |
| **General Use** | ✅ Recommended | ❌ Not recommended |
| **Security Updates** | ✅ Upstream | ⚠️ Manual tracking needed |

---

## Recommendations

### ✅ Use This Package If:
- You **need** to play games with Easy Anti-Cheat
- You **need** to play Rogue Company
- You understand and accept the security trade-offs
- This is a **dedicated gaming system**

### ❌ DO NOT Use This Package If:
- You don't play EAC-protected games
- You run a multi-user system
- You handle sensitive data
- You need maximum security
- You run production services
- **You're not sure** - use official `glibc` instead!

---

## Maintenance

### Security Patch Tracking

**IMPORTANT:** You must **manually track** upstream glibc security patches because this package diverges from upstream.

Monitor:
- [glibc security mailing list](https://sourceware.org/mailman/listinfo/libc-security)
- [glibc bugzilla](https://sourceware.org/bugzilla/)
- Arch Linux `glibc` package updates

### Updating This Package

When updating:
1. Check if upstream fixes conflict with reverted commits
2. Test gaming functionality after updates
3. Verify EAC and Rogue Company still work
4. Consider if newer glibc versions have made patches unnecessary

---

## Source

- **Upstream:** https://www.gnu.org/software/libc/
- **Arch glibc:** https://archlinux.org/packages/core/x86_64/glibc/
- **Patches:** Custom patches for gaming compatibility

---

## Alternatives

### Option 1: Official glibc (Recommended for most users)
```bash
sudo pacman -S glibc
```

### Option 2: Dual-boot Gaming/Production
- Use glibc-eac-roco for gaming partition
- Use official glibc for work partition

### Option 3: Gaming Container
- Run games in container with glibc-eac-roco
- Use official glibc on host system
- Best of both worlds, but complex to set up

---

## Building

```bash
cd glibc
makepkg -si
```

**Note:** Build time is significant (30+ minutes on most systems).

---

## License

- glibc is licensed under LGPL-2.1-or-later
- Patches are modifications for compatibility

---

## Support

**Issues with:**
- **Gaming/EAC compatibility:** Report in this repository
- **General glibc bugs:** Report to [upstream glibc](https://sourceware.org/bugzilla/)
- **Security vulnerabilities:** Report via your distribution's standard security response process.

---

## Changelog

- Initial release with EAC and Rogue Company patches
- Based on glibc 2.42+r33

---

## Disclaimer

This package modifies core system libraries. Use at your own risk. The maintainers are not responsible for any issues caused by using this package.

**When in doubt, use the official `glibc` package.**
