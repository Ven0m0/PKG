# OpenCode bootstrap — PKG

Canonical repo-wide guidance is the repo-root `AGENTS.md`; `opencode.json` loads
it alongside this file and every `.github/instructions/*.instructions.md`. Apply
`AGENTS.md` first, then the path-specific instruction files, then this file.
Keep `CLAUDE.md` symlinked to `AGENTS.md`, never to this file.

## What this repo is

Arch Linux PKGBUILDs plus the automation around them. A change here is almost
always package metadata, repo tooling, or agent guidance — not application code.
There is no application to run and no test suite that covers the packages.

## Before you edit

Read the tracked state before changing any version:

```bash
cat nvchecker.toml .github/nvchecker/old_ver.json
git ls-files ':(glob)**/PKGBUILD'
```

Use `git ls-files ':(glob)**/PKGBUILD'` for discovery, `rg` for content, `fd`
for files. Do not shell out to `find`/`grep` in new code.

## Non-negotiables

- Regenerate `.SRCINFO` with `makepkg --printsrcinfo > .SRCINFO` after any
  PKGBUILD change. The exception is packages whose `pkgver()` resolves from a
  git clone at build time — those intentionally ship without `.SRCINFO`.
- Reset `pkgrel=1` whenever `pkgver` changes; bump `pkgrel` for packaging-only
  changes.
- Stage tracked sources only. `makepkg` and `updpkgsums` leave tarballs, `.pkg.tar.zst`
  archives, `src/`, `pkg/`, and `git+` clones in the package directory — delete
  them before `git add`, and check `git status --porcelain` before committing.
- No secrets, no remote sourcing, no `curl | bash`.
- Never rename or hardcode the externally managed workflow secrets.

## Editing PKGBUILDs

Do not let a formatter rewrite a PKGBUILD. They are bash, but they rely on
makepkg's parsing and array quoting; `opencode.json` disables autoformat for
them for that reason. Match the surrounding style by hand: 2-space indent,
`[[ ]]`, quoted expansions.

Packages with special update rules are listed in
`.github/instructions/pkgbuild.instructions.md`. Read it before touching
`proton-cachyos-slr`, `wine-cachyos`, `llvm`, or `chromium`.

## Validation

```bash
tools/pkg.sh lint          # PKGBUILD lint + format
tools/pkg.sh srcinfo       # regenerate every .SRCINFO
tools/pkg.sh build <pkg>   # makepkg or Docker build
make lint                  # shell + package lint
bash -n <file>             # syntax-only, works without the Arch toolchain
```

`makepkg`, `updpkgsums`, and `namcap` are Arch-only. On a non-Arch machine run
them inside `archlinux:base-devel` rather than reporting the package as
unverifiable.

## Scope discipline

Smallest useful diff. Edit an existing file before creating a new one. Prefer
the existing workflows in `tools/` and `.github/scripts/` over writing a
one-off script; if you do write one, it does not belong in the commit.
