---
description: Bump one or more tracked packages to their latest upstream version
agent: pkg-updater
subtask: true
---

Update these packages to their latest upstream versions: $ARGUMENTS

If no package is named, check every key in `nvchecker.toml` and update only the
ones that are actually behind.

Tracked state, for reference:

!`cat nvchecker.toml`

!`cat .github/nvchecker/old_ver.json`

Follow `.opencode/skills/update-pkgbuild/SKILL.md`. Do not stage build output.
Report old -> new per package, plus anything skipped and why.
