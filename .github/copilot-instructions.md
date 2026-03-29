# GitHub Copilot Instructions

**Repo:** Optimized Arch Linux PKGBUILDs — performance builds, custom patches, CI/CD automation.
**Tone:** Concise, result-first. Lists ≤7 items. Edit > Create. Subtract > Add.

## Repository Layout

```
<package>/          # one directory per package
  PKGBUILD          # build recipe
  .SRCINFO          # auto-generated; must stay in sync with PKGBUILD
  *.patch           # patches applied in prepare()
  readme.md         # optional package notes
pkg.sh              # unified build/lint/srcinfo tool
lib/helpers.sh      # shared shell library
nvchecker.toml      # upstream version tracking
mise.toml           # task runner (aur-push, export-patches, …)
.github/workflows/  # CI: build.yml, lint.yml, check-updates.yml
```

## Core Rules

1. User instruction > any rule below
2. Edit existing files; never create unless strictly necessary
3. Minimal diff — change only what is needed
4. Follow patterns already in the codebase

## File Discovery

Always use `rg` for content search and `fd` for file/directory discovery.

```bash
# Find PKGBUILDs (fastest in git repo)
git ls-files ':(glob)**/PKGBUILD'

# Search content
rg 'pattern'                       # all files
rg 'pattern' --glob 'PKGBUILD'    # PKGBUILDs only
rg 'pattern' --glob '*.sh'        # shell scripts only
rg -l 'depends='                   # list files containing depends=

# Find files by name
fd -t f -g 'PKGBUILD'             # all PKGBUILDs
fd -t f -e patch                  # all patches
```

**Never use:** `grep`, `find`, `ls | grep`, parsing `ls` output.

## Bash

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- 2-space indent; `[[ ]]` not `[ ]`; quote all vars: `"${var}"`
- Arrays: `mapfile -t arr < <(cmd)` — no string splits
- **Ban:** `eval`, backticks, parsing `ls`, unquoted expansions, `curl | bash`
- CI gates: `shfmt -i 2 -bn -ci -ln bash` + `shellcheck --severity=error` must pass

## Toolchain

| Avoid | Prefer |
|-------|--------|
| `find` | `fd` (or `git ls-files ':(glob)**/PKGBUILD'`) |
| `grep` | `rg` |
| `jq` | `jaq` |
| `xargs` | `parallel` |
| `wget`/`curl` | `aria2` |
| `cut` | `choose` |

## PKGBUILD

- **Always** run `makepkg --printsrcinfo > .SRCINFO` after any PKGBUILD change
- Optimization: replace `-O2` with `-O3`; add `-pipe -fno-plt -fstack-protector-strong`
- Linker: `LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"`
- Rust: `RUSTFLAGS="-C target-cpu=native -C opt-level=3 -C lto=fat -C codegen-units=1"`
- Sources: HTTPS only; `sha256sums`/`sha512sums` on all remote sources; `SKIP` for local files
- Patches: `0001-descriptive-name.patch` naming; apply with `patch -Np1 -i ../0001-name.patch`
- Never commit `pkg/`, `src/`, `*.tar.*`, `*.zip`

## Build & Lint

```bash
./pkg.sh build <pkg>           # build (Docker auto-selected for firefox/obs-studio/etc.)
./pkg.sh lint                  # shellcheck + shfmt + shellharden + .SRCINFO sync check
makepkg -srC                   # clean local build
makepkg --printsrcinfo > .SRCINFO
```

## Automation

- Version tracking: `nvchecker.toml` + `.github/nvchecker/old_ver.json`
- Mise tasks: `mise r setup-workspace` | `aur-push` | `export-patches` | `sync-upstream` | `gather-context`
- CI: `check-updates.yml` (daily), `build.yml` (per PKGBUILD change), `lint.yml` (push/PR)

## Commit Format

```
package-name: Short summary (≤50 chars)

- Detail
- Fixes #N
```

One logical change per commit. Run `./pkg.sh lint` before committing.

## Security

- No `curl | bash`, no remote sourcing, no unverified code execution
- HTTPS sources only; verify checksums; use `validpgpkeys` when available
- No secrets, tokens, or credentials in any committed file

## Quality Gates

- `./pkg.sh lint` clean (shellcheck + shellharden + shfmt)
- `.SRCINFO` in sync with PKGBUILD
- No syntax errors; all scripts executable
- Markdownlint clean for `.md` files
