# PKG Agent Guide

> Canonical repo-wide guidance for AI agents working in this repository.
> `CLAUDE.md` must remain a symlink to this file.

## Priorities

1. User instruction wins.
2. Make the smallest useful diff; edit existing files before creating new ones.
3. Keep repo-wide guidance here; keep `.github/copilot-instructions.md` bootstrap-only.
4. Prefer existing repo workflows over one-off scripts.
5. For new discovery code, prefer `git ls-files ':(glob)**/PKGBUILD'`, `rg`, and `fd`.

## Repository map

- Package directories live both at the repo root and in grouped folders such as `dxvk/`, `java/`, `uutils/`, and `zlib-ng/`.
- `pkg.sh` is the canonical entry point for `build`, `lint`, and `srcinfo`.
- `lib/helpers.sh` contains shared helpers, including `find_pkgbuilds`.
- `nvchecker.toml` and `.github/nvchecker/old_ver.json` track upstream versions.
- `.github/scripts/try-update.sh`, `create-pr.sh`, and `fetch-changelog.sh` drive automated package updates.
- `.github/actions/pkgbuild/` is the reusable PKGBUILD validation action.
- `.github/workflows/` contains CI for build, lint, package updates, AUR publishing, and agent tasks.

## Discovery commands

```bash
git ls-files ':(glob)**/PKGBUILD'   # preferred package discovery
rg 'pattern'                        # content search
rg --files -g 'PKGBUILD'            # fallback file discovery
fd -t f -g 'PKGBUILD'               # fallback when fd is available
```

## Standard commands

```bash
pkg.sh lint
pkg.sh build <package>
pkg.sh srcinfo
mise r list
mise r setup-all
mise r sync-all
```

Use `makepkg -srC` inside an individual package directory for a clean local build.

## Package update workflow

1. Read `nvchecker.toml` and `.github/nvchecker/old_ver.json` first.
2. For normal PKGBUILDs: update `pkgver`, reset `pkgrel=1`, run `updpkgsums`, then regenerate `.SRCINFO`.
3. For `proton-cachyos-slr` and `wine-cachyos`: update `_srctag` and leave the derived `pkgver` expression alone.
4. For `llvm`: treat the nvchecker value as the tracked upstream release; if `pkgver()` derives the final value, refresh it with non-interactive makepkg tooling instead of hand-editing the generated result.
5. For `chromium`: parse the tracked release as `{pkgver}-{commit}`, update `pkgver` and `_commit`, and keep `_pkgver=${pkgver}` present before refreshing sums and `.SRCINFO`.
6. When the mechanical path fits, prefer `.github/scripts/try-update.sh` and `.github/scripts/create-pr.sh` over ad-hoc scripts.

## File-specific guidance

- Shell scripts: `.github/instructions/shell.instructions.md`
- `PKGBUILD` / `.SRCINFO`: `.github/instructions/pkgbuild.instructions.md`
- GitHub Actions and composite actions: `.github/instructions/github-actions.instructions.md`
- Reusable update workflow: `.github/skills/update-pkgbuild/SKILL.md`

## CI and workflow rules

- Keep `push` and `pull_request` triggers path-scoped where possible.
- Declare least-privilege `permissions:` explicitly.
- Reuse local actions under `.github/actions/` for PKGBUILD-specific jobs.
- In new bash `run:` blocks, start with `set -euo pipefail`.
- Install only the tools a job actually uses; if guidance requires a tool, setup must provide it.
- Workflow secrets such as `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENCODE_API_KEY`, `OPENROUTER_API_KEY`, `KILO_API_KEY`, `KILO_ORG_ID`, and `AUR_SSH_PRIVATE_KEY` are externally managed GitHub secrets; never hardcode or rename them in repo changes.

## Safety and validation

- No secrets, remote sourcing, or `curl | bash`.
- Commit only tracked source files and metadata; leave generated build trees, package archives, and other build outputs out of the diff.
- After PKGBUILD changes, run `makepkg --printsrcinfo > .SRCINFO`.
- After shell or workflow changes, run the repository's existing validation plus any requested guidance tooling.
