---
name: check-drift
description: Report which packages are behind upstream by running nvchecker and diffing against old_ver.json. Read-only.
disable-model-invocation: true
---

Report version drift without editing anything.

1. `nvchecker -c nvchecker.toml -t 3` (needs a GitHub token in a keyfile via `-k` to avoid rate limits; do not echo it). Install with `uv tool install nvchecker` if missing.
2. `python .github/scripts/nvchecker_drift.py` and read `drift` from its output (set `PACKAGES` to narrow).
3. Confirm each direction with `vercmp` and list package, tracked, latest. Never guess a version.

To apply bumps, use `.github/scripts/bump-pkgbuilds.sh` per `.opencode/skills/update-pkgbuild/SKILL.md`. `new_ver.json` is generated and untracked; do not commit it.
