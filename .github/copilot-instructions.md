# GitHub Copilot Bootstrap

- `AGENTS.md` is the canonical repo-wide guide. Keep `CLAUDE.md` as a symlink to it.
- Precedence: user request, then `AGENTS.md`, then path-specific instructions and skills, then this bootstrap file.
- This repository manages Arch Linux PKGBUILDs in root-level and grouped package directories. Prefer `git ls-files ':(glob)**/PKGBUILD'` for package discovery and `rg` for content search.
- Canonical commands: `tools/pkg.sh lint`, `tools/pkg.sh build <package>`, `tools/pkg.sh srcinfo`, and `makepkg -srC` inside a package directory.
- Version tracking and automated update flow live in `nvchecker.toml`, `.github/nvchecker/old_ver.json`, `.github/scripts/try-update.sh`, `.github/scripts/create-pr.sh`, and `.github/workflows/_update-pkgbuilds.yml`.
- Detailed rules live in the shell, PKGBUILD, and GitHub Actions instruction files plus the `update-pkgbuild` skill.
- Bootstrap environment setup belongs in `.github/workflows/copilot-setup-steps.yml`.
