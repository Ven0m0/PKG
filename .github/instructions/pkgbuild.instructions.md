---
applyTo: "**/PKGBUILD,**/.SRCINFO"
---

# PKGBUILD Rules

## Invariants

- **Always** run `makepkg --printsrcinfo > .SRCINFO` after any PKGBUILD change.
- Never commit `pkg/`, `src/`, `*.tar.*`, `*.zip`.
- HTTPS sources only; `sha256sums`/`sha512sums` on all remote sources; `SKIP` only for local files.

## Optimization flags

```bash
export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
export MAKEFLAGS="-j$(nproc)"
# Rust:
export RUSTFLAGS="-C target-cpu=native -C opt-level=3 -C lto=fat -C codegen-units=1"
```

## Patches

- Naming: `0001-descriptive-name.patch`, `0002-next.patch`
- Apply in `prepare()`: `patch -Np1 -i ../0001-descriptive-name.patch`

## Validation

```bash
./pkg.sh lint          # shellcheck + shfmt + .SRCINFO sync check
makepkg -srC           # clean local build
```
