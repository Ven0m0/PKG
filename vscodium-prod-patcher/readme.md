# vscodium-prod-patcher

## Description

Universal patcher for VSCodium's `product.json`. Replaces the per-variant
`vscodium-marketplace` / `vscodium-features` patch packages with one
configurable tool.

## Features

- Extension gallery replacement (Open VSX or the Microsoft marketplace)
- VSCodium feature toggles (API proposals, telemetry config, auth, settings sync)
- Data directory relocation, so VSCodium can be XDG-compliant-ish
- Re-patches automatically after a VSCodium upgrade via a generated pacman hook

## Source

- **Upstream**: <https://github.com/Ven0m0/vscodium-prod-patcher>
- **License**: GPL-3.0-only
- **Build from**: branch HEAD — upstream publishes no git tags, so the package
  is a `-git` package and `pkgver()` derives `r<count>.<short-sha>`.

## Build instructions

```bash
cd vscodium-prod-patcher
makepkg -srC
```

`.SRCINFO` is intentionally absent: `pkgver()` is resolved from a git clone at
build time, so `makepkg --printsrcinfo` has to run against a real checkout
rather than being committed from a stale value. This matches the other
untagged git packages in this repo (`update-alternatives`, `ghostty`,
`rclone-filen`).

## Usage

```bash
vscodium-prod-patcher config packages   # pick which VSCodium package to patch
vscodium-prod-patcher patch             # apply the configured patches
```

Installing the package drops `97-vscodium-prod-patcher-self.hook`, which runs
`vscodium-prod-patcher hook install` after the patcher is installed or upgraded.
That regenerates `/etc/pacman.d/hooks/98-vscodium-prod-patcher-action.hook`,
which in turn re-applies the patches after every VSCodium upgrade.

## Pacman hooks

| Hook | Owner | Purpose |
| --- | --- | --- |
| `97-vscodium-prod-patcher-self.hook` | this package | regenerate the action hook |
| `98-vscodium-prod-patcher-action.hook` | generated at runtime | re-patch VSCodium after an upgrade |

## Notes

- `python-inquirer` is an optional dependency; without it the `config`
  subcommand still works, just without the interactive TUI.
- The upstream repository ships its own AUR-oriented `PKGBUILD` that builds a
  second `vscodium_prod_patcher_alpm_ini` wheel and sources a
  `vscodium-prod-patcher.hook.in` file. Neither exists on `main` any more
  (`alpm_ini` moved into `vscodium_prod_patcher.pacman`), so this PKGBUILD
  builds the single wheel and writes the hook inline instead.

## License

GPL-3.0-only
