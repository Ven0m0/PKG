---
applyTo: "**/*.sh"
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
- Forbidden: `eval`, backticks, parsing `ls` output, unquoted expansions, `curl | bash`

## Preferred tools

| Avoid | Use instead |
|-------|-------------|
| `grep` | `rg` |
| `find` | `fd` / `git ls-files ':(glob)**'` |
| `jq`  | `jaq` |
| `xargs` | `parallel` |
| `cut` | `choose` |

## Quality gates

All scripts must pass:

```bash
shellcheck --severity=error "$f"
shellharden --check "$f"
shfmt -i 2 -bn -ci -ln bash -d "$f"
```
