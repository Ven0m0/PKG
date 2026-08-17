# PKG Agent Guide

> Canonical repo-wide guidance for AI agents. `CLAUDE.md` must remain a symlink to `AGENTS.md`.
> Keep this file short enough to stay in context; path-specific detail belongs in `.opencode/rules/`.

## Priorities

1. User instruction wins.
2. Make the smallest useful diff; edit existing files before creating new ones.
3. Prefer existing repo workflows in `tools/` and `.github/scripts/` over one-off scripts.
4. Keep repo-wide guidance here and `.github/copilot-instructions.md` bootstrap-only.

## What this repo is

PKG maintains Arch Linux PKGBUILDs, patches, and the automation around version tracking, validation, and CI publishing. Nearly every change is package metadata, repo tooling, or agent guidance. There is no application runtime here, and no test suite covering the packages — `tests/` covers `tools/` only.

## Repository map

- Packages live at the repo root and in grouped folders (`dxvk/`, `java/`, `uutils/`, `zlib-ng/`). `git ls-files ':(glob)**/PKGBUILD'` is the source of truth for which exist.
- `tools/pkg.sh` is the entry point for `build`, `lint`, and `srcinfo`; `tools/lib/helpers.sh` holds shared helpers including `find_pkgbuilds`.
- Other tooling: `tools/vp-dev.py` (regenerates `packages.json` from the PKGBUILDs), `tools/find_updates.py`, `tools/check-isa-level.sh`, `tools/generate-schedule.py`, `tools/generate-workflow.py`.
- Version tracking: `nvchecker.toml` plus `.github/nvchecker/old_ver.json`. `new_ver.json` is generated on every run and is not tracked.
- Update automation: `.github/scripts/try-update.sh`, `create-pr.sh`, `fetch-changelog.sh`. `_update-pkgbuilds.yml` detects drift itself, then dispatches an agent through `_run-agent.yml`.
- `.github/actions/pkgbuild/` is the reusable PKGBUILD validation action.
- `.github/` is CI only. Rules, skills, agents, and commands live in `.opencode/`.

## Environment

`mise install` provisions the toolchain: Python 3.14, Node 24, bun, uv, ruff, ripgrep, fd, shellcheck, shfmt, actionlint.

`makepkg`, `updpkgsums`, and `namcap` are Arch-only. On another distro run them inside `archlinux:base-devel` rather than reporting a package as unverifiable. `bash -n` works anywhere and is not a substitute for the rest.

## Commands

```bash
git ls-files ':(glob)**/PKGBUILD'   # package discovery; rg for content, fd for files
tools/pkg.sh lint                   # lint and format PKGBUILDs
tools/pkg.sh srcinfo                # regenerate every .SRCINFO
tools/pkg.sh build <package>        # makepkg or Docker build
make lint                           # shell and package lint
mise r list | mise r setup-all | mise r sync-all
makepkg -srC                        # clean build inside one package directory
```

## Package updates

Read `nvchecker.toml` and `.github/nvchecker/old_ver.json` first. Derive every version from nvchecker or upstream — never guess one — and confirm the direction with `vercmp` before editing. Never downgrade. Full procedure: `.opencode/skills/update-pkgbuild/SKILL.md`.

Default path: set `pkgver`, reset `pkgrel=1`, run `updpkgsums`, then `makepkg --printsrcinfo > .SRCINFO`. Exceptions:

- **Any PKGBUILD defining `pkgver()`** resolves its real version from a clone at build time. Do not hand-edit the generated value; record the new tracked value in `old_ver.json` and let makepkg regenerate it. List them with
  `rg -l '^\s*pkgver\s*\(\)' --glob PKGBUILD`.
- **`proton-cachyos-slr`, `wine-cachyos`** — update `_srctag`; leave the derived `pkgver` expression alone.
- **`chromium`** — the tracked value is `{pkgver}-{commit}`; update `pkgver` and `_commit`, and keep `_pkgver=${pkgver}` present.
- **`llvm`** — the tracked value is the upstream release; refresh a `pkgver()`-derived result with non-interactive makepkg tooling instead of hand-editing it.

Some untagged git packages (`ghostty`, `rclone-filen`, `update-alternatives`, `vscodium-prod-patcher`, several `uutils/*`) intentionally ship without `.SRCINFO`, because generating one needs a real clone. Do not add one from a stale value; the absence is deliberate, not an omission.

When the mechanical path fits, prefer `.github/scripts/try-update.sh` and `create-pr.sh` over ad-hoc scripts.

## File-specific guidance

- Shell scripts: `.opencode/rules/shell.md`
- `PKGBUILD` / `.SRCINFO`: `.opencode/rules/pkgbuild.md`
- GitHub Actions and composite actions: `.opencode/rules/github-actions.md`
- Reusable task workflows: `.opencode/skills/*/SKILL.md`

## Agent tooling layout

- `.opencode/` is the single home for agent configuration: `opencode.json` loads `AGENTS.md` plus every file in `rules/`; `agents/`, `commands/`, and `skills/` hold the rest.
- There is exactly one copy of each rule and skill. Edit it in place; never fork a second copy into another tool's directory.
- Tools that cannot discover `.opencode/` on their own are pointed at it from their own bootstrap file.

## CI and workflow rules

- Path-scope `push` and `pull_request` triggers where possible; declare least-privilege `permissions:` explicitly.
- Start every multi-line bash `run:` block with `set -euo pipefail`. Pass untrusted values (PR titles, branch names, issue bodies) through `env:`, never by interpolating `${{ }}` into the script body.
- Reuse `.github/actions/pkgbuild/` for PKGBUILD jobs instead of reimplementing makepkg logic. Install only the tools a job uses — and everything its guidance requires.
- Give long or dispatchable workflows a `timeout-minutes` and a `concurrency` group so superseded runs get cancelled.
- `ANTHROPIC_API_KEY`, `OPENCODE_API_KEY`, `OPENROUTER_API_KEY`, `AUR_SSH_PRIVATE_KEY`, and `PAT` are externally managed GitHub secrets. Never hardcode, rename, or echo them.

## Safety and validation

- No secrets in the diff, no remote sourcing, no `curl | bash`.
- Commit tracked sources only. `makepkg` and `updpkgsums` leave `src/`, `pkg/`, tarballs, and `git+` clones behind — delete them and check `git status --porcelain` before staging.
- Regenerate `.SRCINFO` after any PKGBUILD change, except the packages noted above.
- After shell or workflow changes, run the repository's existing validation. Fix the cause; never silence the check.
