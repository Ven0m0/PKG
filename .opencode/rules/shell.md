---
applyTo: "**/*.sh"
description: Bash scripts in this repo must stay strict-mode, use 2-space indent, and prefer repo-aware discovery helpers in new code.
---

# Shell Script Rules

## Required header

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

## Style

- 2-space indent; `[[ ]]` not `[ ]`; quote every variable: `"${var}"`
- Arrays: `mapfile -t arr < <(cmd)` — never split strings into arrays
- Prefer shared helpers such as `tools/lib/helpers.sh` and `find_pkgbuilds` when they already cover the job
- In new code prefer `git ls-files ':(glob)**/PKGBUILD'`, `rg`, `fd`, `jaq`, and `parallel`
- Existing scripts still contain some older `find`/`grep`/`xargs`/`wget` usage; do not copy that style into new code unless the task requires matching an existing pattern
- Forbidden: `eval`, backticks, parsing `ls` output, unquoted expansions, `curl | bash`

## Quality gates

All changed scripts should pass:

```bash
bash -n "$f"
shellcheck --severity=error "$f"
shellharden --check "$f"
shfmt -i 2 -bn -ci -ln bash -d "$f"
```

Use `tools/pkg.sh lint` for repo-level validation when shell changes touch package automation.
