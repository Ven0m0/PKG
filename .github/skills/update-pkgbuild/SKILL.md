---
name: update-pkgbuild
description: "Bump a PKGBUILD to a new upstream version: update pkgver/pkgrel, regenerate checksums, sync .SRCINFO, and verify the build. Use when asked to update a package, bump a version, or apply upstream changes. Triggers on: 'update package', 'bump version', 'new release', 'pkgver bump'."
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
---

# Update PKGBUILD

Bump a package to a new upstream version with a clean, verifiable diff.

## Steps

1. **Identify the change** — determine `OLD_VERSION` and `NEW_VERSION` from the
   issue, PR, or `nvchecker.toml` / `.github/nvchecker/old_ver.json`.

2. **Update `pkgver`** in `<package>/PKGBUILD`. Reset `pkgrel=1` unless only
   `pkgrel` is being bumped (e.g., a patch with no upstream change).

3. **Refresh checksums** — run inside the package directory:
   ```bash
   cd <package>
   makepkg -g 2>/dev/null
   ```
   Replace the old `sha256sums`/`sha512sums` arrays with the output.
   Never use `SKIP` for remote sources.

4. **Regenerate `.SRCINFO`**:
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

5. **Apply patch conflicts** (if any) — check that existing patches in
   `prepare()` still apply cleanly; update or drop as needed.

6. **Validate**:
   ```bash
   ./pkg.sh lint          # from repo root
   makepkg -srC           # clean build in package dir (optional but preferred)
   ```

7. **Commit**:
   ```
   <package>: update to <NEW_VERSION>
   ```

## Invariants

- `.SRCINFO` must always be committed alongside any PKGBUILD change.
- Never commit `pkg/`, `src/`, `*.tar.*`, `*.zip`.
- CI (`build.yml`) will rebuild the package on push — a passing `./pkg.sh lint`
  is the minimum gate before committing.

## Automated path

The `.github/scripts/try-update.sh` script handles mechanical bumps for npm,
GitHub-release, and `-git` packages. Invoke it when the version change is
straightforward and no patch conflicts are expected:

```bash
PKG_DIR=<package> OLD_VERSION=<old> NEW_VERSION=<new> .github/scripts/try-update.sh
```

If the script exits non-zero, fall back to the manual steps above.
