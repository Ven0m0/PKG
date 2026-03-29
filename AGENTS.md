# Agent Directives & Coding Standards

> **Role:** Technical contributor to an Arch Linux PKGBUILD repository.
> **Tone:** Blunt, technical, concise. Result-first. Tradeoffs as `✅ Pro ❌ Con ⇒ Decision ∵ Reason`.
> **Constraint:** No external libraries unless explicitly permitted.
> **Note:** `CLAUDE.md` is a symlink to this file. Edit only `AGENTS.md`.

---

## 1. Communication & Workflow

**Style:** No filler. Reasoning structure: `Approach A vs B: ✅ Pro ❌ Con ⇒ Recommendation ∵ Rationale`.

**Process:**
1. **Analyze** — Read existing code, understand state, constraints, goals.
2. **Design** — Compare tradeoffs, choose the minimal-diff approach.
3. **Validate** — Identify risks, edge cases, lint failures.
4. **Execute** — Implement, update `.SRCINFO`, run `./pkg.sh lint`.

**Output format:** Plan (3–6 bullets) → Unified diff or code block → Risk note if applicable.

---

## 2. File Discovery

**Always use `rg` (ripgrep) for searching file contents; use `fd` for finding files by name.**

```bash
# Find all PKGBUILDs (in git repos, prefer index lookup)
git ls-files ':(glob)**/PKGBUILD'   # fastest — O(1) index lookup
fd -t f -g 'PKGBUILD'               # fallback when not in a git repo

# Search file contents
rg 'pattern'                         # search all files
rg 'pattern' --glob '*.sh'          # restrict to shell scripts
rg 'pattern' --glob 'PKGBUILD'      # restrict to PKGBUILDs
rg -l 'pkgver='                      # list files containing pkgver
rg -n 'depends=' firefox/PKGBUILD   # show line numbers

# Quick file listing (no grep/find)
fd -t f -e sh                        # all .sh files
fd -t f -g '*.patch'                 # all patches
fd -t d -d 1                         # top-level directories (packages)
```

**Forbidden for search:** `grep`, `find`, `ls | grep`, parsing `ls` output.

---

## 3. Bash Standards

**Every script must start with:**

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

**Formatting:** `shfmt -i 2 -bn -ci -ln bash` (2-space indent, bash dialect).

**Linting:** `shellcheck --severity=error` + `shellharden --replace`. Both must pass.

**Idioms:**
- Tests: `[[ ... ]]` not `[ ... ]`; regex: `=~`
- Arrays: `mapfile -t arr < <(cmd)`, `read -ra arr`
- Strings: `${v//pat/rep}`, `${v%%pat*}` — avoid `sed`/`awk` for simple edits
- Loops: `while IFS= read -r line`
- I/O: `<<< "$v"`, `< <(cmd)`, process substitution over temp files

**Toolchain preference:**

| Avoid | Prefer |
|-------|--------|
| `find` | `fd` (fallback: `git ls-files ':(glob)**/PKGBUILD'`) |
| `grep` | `rg` |
| `jq` | `jaq` |
| `xargs` | `parallel` |
| `wget`/`curl` | `aria2` |
| `cut` | `choose` |

**Forbidden:** `eval`, backticks, parsing `ls`, unquoted expansions, `/bin/sh` shebang, `curl | bash`.

---

## 4. PKGBUILD Standards

**Mandatory after every PKGBUILD edit:**

```bash
makepkg --printsrcinfo > .SRCINFO
```

**Standard structure:**

```bash
# Maintainer: Name <email>
_pkgname=originalname
pkgname="${_pkgname}-custom"
pkgver=1.0.0
pkgrel=1
pkgdesc='Description'
arch=('x86_64')
url='https://upstream.url'
license=('LICENSE-TYPE')
depends=('dep1')
makedepends=('makedep1')
provides=("${_pkgname}")
conflicts=("${_pkgname}")
source=("https://upstream.url/${_pkgname}-${pkgver}.tar.gz"
        '0001-patch.patch')
sha256sums=('CHECKSUM'
            'SKIP')

prepare() {
  cd "${_pkgname}-${pkgver}" || exit
  patch -Np1 -i ../0001-patch.patch
}

build() {
  cd "${_pkgname}-${pkgver}" || exit
  export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
  export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
  export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
  export MAKEFLAGS="-j$(nproc)"
  ./configure --prefix=/usr
  make
}

check() {
  cd "${_pkgname}-${pkgver}" || exit
  make check
}

package() {
  cd "${_pkgname}-${pkgver}" || exit
  make DESTDIR="${pkgdir}" install
}
```

**Optimization flags (standard):**

```bash
# C/C++
export CFLAGS="${CFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export CXXFLAGS="${CXXFLAGS/-O2/-O3} -pipe -fno-plt -fstack-protector-strong"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
export MAKEFLAGS="-j$(nproc)"

# Rust
export RUSTFLAGS="-C target-cpu=native -C opt-level=3 -C lto=fat -C codegen-units=1"
```

**Security requirements:**
- HTTPS sources only
- `sha256sums` or `sha512sums` on all remote sources; `SKIP` only for local files
- `validpgpkeys` when GPG signatures are available
- Review every patch before applying — understand what it does

**Patch naming:** `0001-descriptive-name.patch`, `0002-next-change.patch`

---

## 5. Build System

**Build a package:**

```bash
./pkg.sh build <package>       # single package (Docker auto-detected)
./pkg.sh build                 # all packages
makepkg -srC                   # clean build in package dir
```

**Lint everything:**

```bash
./pkg.sh lint                  # shellcheck + shellharden + shfmt + .SRCINFO check
```

**Docker builds** are auto-selected for `obs-studio`, `firefox`, `egl-wayland2`, `onlyoffice` (see `DOCKER_PKGS` in `pkg.sh`). The script handles container setup, mirror optimization, and non-root build user automatically.

**Package discovery** (`lib/helpers.sh`):

```bash
# Inside git repo (used by pkg.sh)
git ls-files ':(glob)**/PKGBUILD'   # O(1) index lookup — preferred
# Fallback
fd -t f -g 'PKGBUILD'
```

---

## 6. Automation (nvchecker + mise)

**Version detection:** `nvchecker` reads `nvchecker.toml` at repo root; tracked versions stored in `.github/nvchecker/old_ver.json`.

**Mise tasks** (run from repo root):

| Task | Purpose |
|------|---------|
| `mise r setup-workspace` | Clone/prepare upstream workspace |
| `mise r aur-push` | Push package files to AUR (requires `.aur-files` per package) |
| `mise r export-patches` | Export patches from workspace |
| `mise r sync-upstream` | Sync with upstream source |
| `mise r gather-context` | Collect context for LLM review |

**Adding a package to nvchecker:** Add an entry in `nvchecker.toml` using the `["package-name"]` key format with appropriate `source` (github, pypi, npm, etc.).

**CI workflows** (`.github/workflows/`):

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build.yml` | PKGBUILD change | Build affected packages |
| `lint.yml` | push/PR | shellcheck + shfmt + yamlfmt + MegaLinter |
| `check-updates.yml` | daily schedule | nvchecker version bump |
| `aur-push.yml` | manual | Publish packages to AUR |

---

## 7. Git & PR Workflow

**Commit message format:**

```
package-name: Short summary (≤50 chars)

- Bullet detail
- Fixes #issue (if applicable)
```

**One logical change per commit.** Don't mix packages or unrelated changes.

**Branch names:** `feature/package-name`, `fix/package-name-issue`.

**Before every commit:**

```bash
makepkg --printsrcinfo > .SRCINFO   # if PKGBUILD was changed
./pkg.sh lint                        # from repo root
```

---

## 8. Pre-Commit Checklist

- [ ] `.SRCINFO` updated after PKGBUILD changes?
- [ ] `./pkg.sh lint` passes (no shellcheck/shfmt/shellharden errors)?
- [ ] Build tested locally (`makepkg -srC`)?
- [ ] Sources use HTTPS with valid checksums?
- [ ] No build artifacts committed (`pkg/`, `src/`, `*.tar.*`, `*.zip`)?
- [ ] No secrets, credentials, or tokens in any file?
- [ ] Used `rg`/`fd` (not `grep`/`find`) for any file search?
- [ ] Complexity O(n) or better (no accidental O(n²) loops)?

---

## 9. EditorConfig Standards

- **Indent:** 2 spaces (except Makefiles/Go/Rust/Zig: tabs)
- **Line endings:** LF only
- **Charset:** UTF-8
- **Max line length:** 128 chars (140 for Markdown, 120 for YAML/Python)
- **Trailing whitespace:** stripped (except `.md` and `.patch`)
- **Final newline:** always
