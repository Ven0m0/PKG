---
name: update-pkgbuild
description: "Update a tracked package version in this repo: read nvchecker state, apply the right PKGBUILD special case, refresh checksums and .SRCINFO, and validate with the existing package tooling. Use when asked to update a package, bump a version, handle a new release, or perform a pkgver bump."
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
---

# Update PKGBUILD

Update a tracked package with a clean, verifiable diff that matches this repository's automation.

## Steps

1. **Read tracking state first** — inspect `nvchecker.toml` and `.github/nvchecker/old_ver.json` before deciding what to change.
2. **Choose the correct path**:
   - Prefer `.github/scripts/try-update.sh` for straightforward mechanical bumps.
   - Fall back to manual PKGBUILD edits when patches, generated versions, or package-specific logic require it.
3. **Apply the version update**:
   - Normal packages: update `pkgver`, reset `pkgrel=1`.
   - `proton-cachyos-slr` and `wine-cachyos`: update `_srctag`; leave the derived `pkgver` expression unchanged.
   - `llvm`: treat the tracked nvchecker value as the upstream release version and refresh any generated `pkgver()` result with non-interactive makepkg tooling.
   - `chromium`: parse the tracked release as `{pkgver}-{commit}`, update both `pkgver` and `_commit`, and ensure `_pkgver=${pkgver}` is present.
4. **Refresh generated metadata**:
   ```bash
   updpkgsums
   makepkg --printsrcinfo > .SRCINFO
   ```
5. **Check patches** — verify that any `prepare()` patches still apply after the version bump.
6. **Update tracked version state** — keep `.github/nvchecker/old_ver.json` in sync for every package you changed.
7. **Validate**:
   ```bash
   pkg.sh lint
   makepkg -srC
   ```

## Invariants

- Commit `.SRCINFO` with every PKGBUILD change.
- Commit the PKGBUILD, `.SRCINFO`, and related source files only; leave generated build trees and package archives out of the diff.
- If automation fails, record why and stop rather than inventing a silent workaround.
