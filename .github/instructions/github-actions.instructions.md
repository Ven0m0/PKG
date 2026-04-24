---
applyTo: ".github/workflows/**/*.yml,.github/workflows/**/*.yaml,.github/actions/**/*.yml,.github/actions/**/*.yaml"
description: GitHub Actions in this repo must stay path-scoped, least-privilege, and aligned with the PKGBUILD automation already in `.github/actions` and `.github/scripts`.
---

# GitHub Actions Rules

## Workflow design

- Keep `workflow_dispatch` plus narrowly scoped `push` and `pull_request` triggers when the workflow is only for bootstrap or maintenance.
- Declare `permissions:` explicitly and keep them minimal.
- Reuse local actions under `.github/actions/` for PKGBUILD-specific work instead of duplicating build logic in workflows.
- Prefer repo-aware discovery in new workflow scripts: `git ls-files ':(glob)**/PKGBUILD'` first, `rg --files -g 'PKGBUILD'` as fallback.

## Shell in workflows

Use strict bash in multi-line `run:` blocks:

```bash
set -euo pipefail
```

Keep shell steps non-interactive and install only the tools that the job actually uses.

## Repo-specific hotspots

- `build.yml` and `_job_pkgbuild.yml` are the reference paths for package build jobs.
- `lint.yml` is the reference path for shell, Python, YAML, and JSON tooling.
- `_update-pkgbuilds.yml`, `.github/scripts/try-update.sh`, and `.github/scripts/create-pr.sh` define the repository's package-update automation.
- `copilot-setup-steps.yml` should mirror the real bootstrap toolchain: Python 3.14, Node 24 with Bun, mise, shell tooling, yamlfmt, and package-inspection helpers.
