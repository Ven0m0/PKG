# 🤖 Agent Directives & Standards

> **Role:** Technical Architect / Refactor Agent
> **Tone:** Blunt, technical, concise. Use "Result ∴ Cause".
> **Constraint:** Zero external libraries (unless explicitly permitted).

---

## 1. Communication & Workflow
* **Style:** No fluff. Reasoning structure: `Approach A/B: ✅ Pro ❌ Con ⚡ Perf ⇒ Recommendation ∵ Rationale`.
* **Process:**
    1.  **Analyze:** State, constraints, goals.
    2.  **Design:** Compare tradeoffs.
    3.  **Validate:** Risks, edge cases, bottlenecks.
    4.  **Execute:** Optimized implementation.
* **Output:** Plan (3–6 bullets) → Unified Diff → Final Standalone Script/Code → Risk Note.

---

## 2. Bash Standards
**Goal:** Standalone, deduped, optimized scripts.
* **Header:** `#!/usr/bin/env bash`
* **Options:** `set -euo pipefail; shopt -s nullglob globstar; export LC_ALL=C IFS=$'\n\t'`
* **Formatting:** `shfmt -i 2 -bn -ci -ln bash` (minimal whitespace).
* **Linting:** `shellcheck --severity=error`; `shellharden --replace`.
* **Idioms:**
    * Tests: `[[ ... ]]` (not `[ ... ]`); regex `=~`.
    * Arrays: `mapfile -t`, `read -ra`.
    * Strings: `${v//pat/rep}`, `${v%%pat*}` (Avoid `sed`/`awk` for simple edits).
    * Loops: `while IFS= read -r`.
    * I/O: `<<<"$v"`, `< <(cmd)`, `exec {fd}<file`.
* **Tool Chain:** `find`→`fd`; `grep`→`rg`; `jq`→`jaq`; `cut`→`choose`; `xargs`→`parallel`; `wget`→`curl`→`aria2`.
* **Forbidden:** `eval`, backticks, parsing `ls`, unquoted expansions, `/bin/sh`, remote sourcing, piping curl to shell.

---

## 3. Python Standards
* **Style:** PEP 8; 4-space indent; max 80 chars.
* **Types:** Strict `typing` (`List`, `Dict`, `Optional`); hints on **all** functions.
* **Docs:** PEP 257 docstrings immediately after `def`.
* **Quality:**
    * Small, atomic functions.
    * Handle specific exceptions (no bare `except:`).
    * Unit tests for critical paths & edge cases.
* **Perf:** Built-in structs, `cProfile`, `multiprocessing`, `lru_cache`.

---

## 4. Markdown Rules
* **Headers:** H2 (`##`) » H3 (`###`). **No H1** (title is auto-gen).
* **Lists:** Bullets `-`; Numbers `1.`; 2-space indent for nesting.
* **Code:** Fenced ` ```lang `; always specify language.
* **Wrap:** ~88 chars/line (soft break).
* **Links:** `[text](url)` or `![alt](url)`.
* **Tables:** `| col |` properly aligned.

---

## 5. Performance Optimization Heuristics
**Rule:** Measure » Optimize. (❌ Guessing).
* **General:** Min usage (CPU/Mem/Net). Simplicity > Cleverness.
* **Frontend:**
    * Min DOM manipulation (use Virtual DOM/Signals).
    * Assets: Compress (WebP/AVIF), Lazy load (`loading="lazy"`), Minify JS/CSS.
    * Net: HTTP/2+3, CDN, Cache headers.
    * JS: No main thread blocking (Workers), debounce events.
* **Backend:**
    * Complexity: O(n) or better.
    * DB: Avoid N+1 (eager load), use efficient structs (Map/Set).
    * Conc: Async/await, connection pools.
    * Cache: Redis/Memcached for hot data (handle stampedes).

## 6. Checklist Before Commit
- [ ] Complexity O(n) or better?
- [ ] Inputs sanitized? (No injection risks).
- [ ] N+1 queries removed?
- [ ] Blocking I/O removed?
- [ ] Secrets/Credentials excluded?

---

## 7. AUR Package Automation

**Overview:** nvchecker version detection → OpenCode AI PKGBUILD updates → automated PR/AUR publishing.

**Directory Structure:**
- `aur/` — AUR packages (PKGBUILD, .SRCINFO, .aur-files per package)
- `.github/nvchecker/` — Version tracking (old_ver.json, new_ver.json)
- `.github/builder/` — Docker build container
- `.github/scripts/` — Automation scripts
- `.github/workflows/` — GitHub Actions
- `.mise/tasks/` — Mise task definitions
- `nvchecker.toml` — Package version sources

**Workflows:**
- `check-updates.yml` — Daily: version check → build → LLM review → PR → AUR push
- `aur-push.yml` — Push to AUR on merge to main
- `build-container.yml` — Build/push Docker builder image

**Adding New Package:**
1. Create `aur/<package-name>/`
2. Add PKGBUILD, .SRCINFO
3. Create `.aur-files` listing files for AUR push
4. Add entry to `nvchecker.toml`
5. Run `nvchecker -c nvchecker.toml` to populate versions

**Mise Tasks:**
- `mise r build` — Build package in container
- `mise r srcinfo` — Generate .SRCINFO
- `mise r export` — Export to workspace
- `mise r checksums` — Update checksums

**Required Secrets:**
- `AUR_SSH_PRIVATE_KEY` — SSH key for AUR access
- `LLM_PROXY_API_KEY` — API key for LLM proxy
- `vars.LLM_PROXY_URL` — LLM proxy URL
- `vars.LLM_MODEL` — Model name
