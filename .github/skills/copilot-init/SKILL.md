---
name: copilot-init
description: Bootstrap Copilot guidance for this repository by keeping `AGENTS.md` canonical, `CLAUDE.md` symlinked, startup guidance short, and bootstrap workflow/instructions aligned with the real PKGBUILD toolchain. Use when asked to initialize Copilot guidance, refresh repo instructions, or update `copilot-setup-steps`.
allowed-tools: "Read, Write, Edit, Glob, Grep, Bash"
---

# Copilot init

Refresh the repository's Copilot bootstrap assets without duplicating the long-form guidance.

## Canonical split for this repo

- Long-form repo guide: `AGENTS.md`
- Mirror file: `CLAUDE.md` symlinked to `AGENTS.md`
- Startup bootstrap only: `.github/copilot-instructions.md`
- Path-specific rules: `.github/instructions/*.instructions.md`
- Reusable task workflows: `.github/skills/*/SKILL.md`
- Bootstrap environment: `.github/workflows/copilot-setup-steps.yml`

## Requirements

1. Audit the repo before editing any guidance.
2. Keep `.github/copilot-instructions.md` short and point back to `AGENTS.md` for repo-wide policy.
3. Match workflow setup to the real toolchain already used here: Python 3.14, Node 24 with Bun, mise, shell tooling, yamlfmt, and PKGBUILD helpers.
4. Keep instruction files focused and avoid restating large rule blocks across files.
5. Preserve the `CLAUDE.md -> AGENTS.md` symlink.
6. Validate every referenced command and path before finishing.
