---
applyTo: "**/{PKGBUILD,.SRCINFO}"
description: PKGBUILD edits must keep version tracking, checksums, and .SRCINFO in sync with this repository's update automation.
---

# PKGBUILD Rules

## Invariants

- Always run `makepkg --printsrcinfo > .SRCINFO` after any PKGBUILD change.
- Commit the PKGBUILD, `.SRCINFO`, and related source files only; leave generated build trees and package archives out of the diff.
- HTTPS sources only; use `sha256sums` or `sha512sums` for remote sources and `SKIP` only for local files.
- Read `nvchecker.toml` and `.github/nvchecker/old_ver.json` before changing tracked package versions.

## Standard update flow

```bash
updpkgsums
makepkg --printsrcinfo > .SRCINFO
tools/pkg.sh lint
makepkg -srC
```

Reset `pkgrel=1` when updating `pkgver` unless the change is only a packaging revision.

## Special cases

- `proton-cachyos-slr` and `wine-cachyos`: update `_srctag`; keep the derived `pkgver` expression unchanged.
- `llvm`: treat the tracked nvchecker value as the upstream release version; if `pkgver()` derives the final value, refresh it with makepkg tooling instead of hand-editing the generated version.
- `chromium`: parse the tracked release as `{pkgver}-{commit}`; update `pkgver`, `_commit`, and keep `_pkgver=${pkgver}` present before recalculating checksums and `.SRCINFO`.

## Patches

- Naming: `0001-descriptive-name.patch`, `0002-next-change.patch`
- Apply patch files from `prepare()` with `patch -Np1 -i` against the package-local patch file you just edited
- If an update touches patched sources, verify every patch still applies cleanly.
