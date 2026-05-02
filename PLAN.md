# Implementation Plan

_Generated: 2026-05-02 · 37 tasks · Est. S×7 M×20 L×8 XL×2_

## Summary

This plan consolidates all open work items from `TODO.md` and one in-code security
marker (`filen-desktop/filen-desktop.sh:11`). No in-code `FIXME`/`HACK`/`XXX`/`DEPRECATED`
comments were found; `WARN:` strings in `pkg.sh` are structured log prefixes, not markers.
The work spans package additions, build-system enhancements, documentation, and CI automation
across the 55-PKGBUILD repository.

---

## Task Index (topological order)

| #  | ID   | Title                                                          | Sev      | Cat      | Size | Blocks          |
|----|------|----------------------------------------------------------------|----------|----------|------|-----------------|
| 1  | T001 | Remove ELECTRON_DISABLE_SECURITY_WARNINGS from filen-desktop  | medium   | security | S    | —               |
| 2  | T002 | Fix gitoxide optimize.patch to apply cleanly                  | medium   | bug      | S    | —               |
| 3  | T003 | Create varia PKGBUILD from make-appimage.sh                   | medium   | feature  | M    | —               |
| 4  | T004 | Update Chromium PKGBUILD patches to latest upstream           | medium   | refactor | M    | —               |
| 5  | T005 | Add LLVM PGO instrumentation to PKGBUILD                      | medium   | perf     | L    | T013 T028       |
| 6  | T006 | Refine Firefox BOLT optimization in PKGBUILD                  | medium   | perf     | M    | T005            |
| 7  | T007 | Add Mesa PKGBUILD with latest upstream features               | medium   | feature  | L    | —               |
| 8  | T008 | Add Python PGO-optimized PKGBUILD                             | medium   | feature  | M    | —               |
| 9  | T009 | Add GCC optimized-bootstrap PKGBUILD                          | medium   | feature  | L    | —               |
| 10 | T010 | Add Node.js PKGBUILD with custom V8 flags                     | medium   | feature  | M    | —               |
| 11 | T011 | Add PostgreSQL PKGBUILD with JIT and compile-time opts        | medium   | feature  | M    | —               |
| 12 | T012 | Add Nginx PKGBUILD with custom modules                        | medium   | feature  | M    | —               |
| 13 | T013 | Implement automated chroot-based package test framework       | high     | feature  | L    | T014            |
| 14 | T014 | Add basic per-package functionality test suite                | high     | feature  | L    | —               |
| 15 | T015 | Add performance regression test harness                       | low      | feature  | L    | T014            |
| 16 | T016 | Set up binary repository with pre-built packages              | medium   | feature  | XL   | T013            |
| 17 | T017 | Implement notification system for security/version alerts     | medium   | feature  | M    | —               |
| 18 | T018 | Write build system documentation for pkg.sh and Docker        | medium   | docs     | M    | —               |
| 19 | T019 | Write PKGBUILD optimization guide                             | medium   | docs     | M    | —               |
| 20 | T020 | Write troubleshooting guide for common build failures         | low      | docs     | S    | —               |
| 21 | T021 | Standardize all package READMEs using template                | low      | docs     | M    | —               |
| 22 | T022 | Add parallel build support to pkg.sh cmd_build                | medium   | perf     | M    | —               |
| 23 | T023 | Implement distributed ccache/sccache setup in CI              | low      | perf     | M    | —               |
| 24 | T024 | Add PGO profile caching and reuse to CI workflows             | low      | perf     | M    | T005            |
| 25 | T025 | Generate build dependency graph for packages                  | low      | feature  | M    | —               |
| 26 | T026 | Convert Dockerfiles to multi-stage with minimal base image    | low      | refactor | M    | —               |
| 27 | T027 | Implement reproducible builds support                         | medium   | feature  | L    | T026            |
| 28 | T028 | Build PGO automated profile-generation infrastructure         | low      | perf     | XL   | T005            |
| 29 | T029 | Expand BOLT optimization to additional packages               | low      | perf     | M    | T028            |
| 30 | T030 | Add x86-64-v3/v4 architecture-specific build variants         | low      | feature  | L    | —               |
| 31 | T031 | Add automated changelog generation to CI release workflow     | low      | feature  | M    | —               |
| 32 | T032 | Add release automation workflow                               | low      | feature  | M    | T031            |
| 33 | T033 | Implement TKG community patch autofetch and testing           | low      | feature  | L    | —               |
| 34 | T034 | Create OCI images from PKGBUILDs with automated registry push | low      | feature  | XL   | T013            |
| 35 | T035 | Review loathingKernel/PKGBUILDs for build workflow patterns   | low      | research | S    | —               |
| 36 | T036 | Review ms178/archpkgbuilds for optimization patterns          | low      | research | S    | —               |
| 37 | T037 | Review FabioLolix/PKGBUILD-AUR_fix for correction patterns    | low      | research | S    | —               |

---

## Tasks

### T001 · Remove ELECTRON_DISABLE_SECURITY_WARNINGS from filen-desktop launcher

<task id="T001" severity="medium" category="security" size="S">
<file>filen-desktop/filen-desktop.sh:11</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `export ELECTRON_DISABLE_SECURITY_WARNINGS=true`

**Intent:** The launcher silences all Electron security warnings to prevent console noise
during startup; this also suppresses warnings about real misconfigurations (insecure
content policies, mixed content, disabled sandbox).

**Acceptance criteria:**
- [ ] `ELECTRON_DISABLE_SECURITY_WARNINGS=true` is removed from `filen-desktop.sh`
- [ ] Electron launches without the suppression flag; no new functional regression observed
- [ ] If specific warnings must be suppressed, they are targeted via `--disable-features=` flags rather than a blanket env-var
- [ ] `pkg.sh lint` passes on the modified file

**Implementation:**
Delete line 11 (`export ELECTRON_DISABLE_SECURITY_WARNINGS=true`) from
`filen-desktop/filen-desktop.sh`. If upstream Electron produces unavoidable benign
warnings, add a comment documenting each suppressed warning individually.
</task>

---

### T002 · Fix gitoxide optimize.patch to apply cleanly

<task id="T002" severity="medium" category="bug" size="S">
<file>TODO.md:50</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 50: `gitoxide: Fix optimize.patch to be valid`

**Intent:** The `optimize.patch` in the gitoxide package directory no longer applies
cleanly against the upstream source, causing PKGBUILD `prepare()` to fail.

**Acceptance criteria:**
- [ ] `optimize.patch` applies without errors via `patch -Np1` against the current gitoxide source tarball
- [ ] `makepkg -srC` in `gitoxide/` completes without patch-apply errors
- [ ] `.SRCINFO` is regenerated with `makepkg --printsrcinfo > .SRCINFO`
- [ ] `pkg.sh lint` passes on the package directory

**Implementation:**
1. Run `makepkg -o` (extract only) in `gitoxide/` to unpack sources.
2. Identify the rejected hunks from `patch --dry-run`.
3. Update context lines and offsets in `optimize.patch` to match current source.
4. Regenerate `.SRCINFO`.
</task>

---

### T003 · Create varia PKGBUILD from make-appimage.sh

<task id="T003" severity="medium" category="feature" size="M">
<file>TODO.md:51</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 51: `varia: Create PKGBUILD from make-appimage.sh`

**Intent:** The varia project ships a `make-appimage.sh` build script; packaging it as
an Arch PKGBUILD makes it installable via pacman and trackable by nvchecker.

**Acceptance criteria:**
- [ ] `varia/PKGBUILD` exists with valid `pkgname`, `pkgver`, `source`, `sha256sums`
- [ ] `varia/.SRCINFO` is present and matches `makepkg --printsrcinfo` output
- [ ] `makepkg -srC` in `varia/` succeeds in a clean chroot
- [ ] `nvchecker.toml` entry added for `varia` upstream version tracking
- [ ] `pkg.sh lint` passes

**Implementation:**
Inspect `make-appimage.sh` for the upstream source URL pattern. Use `pkgbuild`
skeleton: `pkgname=varia`, `arch=(x86_64)`, `license=`, `depends=(electron)`,
`source=("${pkgname}-${pkgver}.tar.gz::${_url}")`. Install via `install -Dm755`.
</task>

---

### T004 · Update Chromium PKGBUILD patches to latest upstream

<task id="T004" severity="medium" category="refactor" size="M">
<file>TODO.md:47 chromium/PKGBUILD</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 47: `Chromium: Update to latest patches`

**Intent:** The chromium package carries custom patches; some may have been superseded
by upstream or no longer apply to the current `pkgver`.

**Acceptance criteria:**
- [ ] All patches in `chromium/patches/` apply without rejects against the current `pkgver`
- [ ] `fetch-chromium-release` script succeeds
- [ ] `makepkg -o` (download/extract) in `chromium/` completes without patch errors
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Run `makepkg -o --nocheck` to detect rejected hunks. For each rejected patch, either
update context lines, drop the patch if merged upstream, or replace with the equivalent
from `cromite` or `CachyOS/chromium-patches`.
</task>

---

### T005 · Add LLVM PGO instrumentation to PKGBUILD

<task id="T005" severity="medium" category="perf" size="L">
<file>TODO.md:49 llvm/PKGBUILD</file>
<blocking>T006 T024 T028</blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 49: `LLVM: PGO instrumentation`

**Intent:** Building LLVM with PGO yields a measurably faster compiler; the instrumented
LLVM binary is also the prerequisite toolchain for PGO-building other packages (Firefox,
Chromium) and for BOLT profiling.

**Acceptance criteria:**
- [ ] `llvm/PKGBUILD` performs a 3-stage build: instrument → profile-generate → optimized rebuild
- [ ] Profile data is stored in a reproducible location (e.g., `${srcdir}/pgo-data/`)
- [ ] `makepkg -srC` succeeds in a clean chroot on x86_64
- [ ] Final `llvm` binary benchmarks ≥3% faster on `llvm-test-suite` or equivalent
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Stage 1: `cmake -DLLVM_BUILD_INSTRUMENTED=IR`. Stage 2: run `llvm-profdata merge`
on collected `.profraw` files. Stage 3: `cmake -DLLVM_PROFDATA_FILE=merged.profdata
-DLLVM_ENABLE_PERF_HINTS=ON`. Follow CachyOS PKGBUILD pattern in
`CachyOS/CachyOS-PKGBUILDS/llvm/PKGBUILD`.
</task>

---

### T006 · Refine Firefox BOLT optimization in PKGBUILD

<task id="T006" severity="medium" category="perf" size="M">
<file>TODO.md:46 firefox/PKGBUILD</file>
<blocking></blocking>
<blocked_by>T005</blocked_by>

**Source:** `TODO.md` line 46: `Firefox: BOLT optimization refinement`

**Intent:** The existing Firefox PKGBUILD may apply BOLT in a suboptimal way (wrong
profile workload, missing `--reorder-functions`, or outdated profile data); refining this
produces measurably faster startup and JS execution.

**Acceptance criteria:**
- [ ] BOLT applied via `llvm-bolt` with `--reorder-blocks=ext-tsp --reorder-functions=hfsort`
- [ ] Profile collected from a representative browsing workload (Speedometer 3 or equivalent)
- [ ] Binary size regression ≤5% vs. non-BOLT build
- [ ] `makepkg -srC` succeeds; `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
In `firefox/PKGBUILD` `package()`: after install, run `perf2bolt`/`merge-fdata` on
stored profile data, then `llvm-bolt ${pkgdir}/usr/lib/firefox/firefox -o ...`.
Reference `DarkFox` and `CachyOS firefox-wayland-cachy-hg` for existing BOLT integration.
</task>

---

### T007 · Add Mesa PKGBUILD with latest upstream features

<task id="T007" severity="medium" category="feature" size="L">
<file>TODO.md:48</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 48: `Mesa: Latest upstream features`

**Intent:** Provide an optimized Mesa build that enables features not yet in the
stable Arch package (e.g., rusticl, newer Vulkan extensions, compile-time LTO).

**Acceptance criteria:**
- [ ] `mesa/PKGBUILD` exists with `pkgname=mesa-opt` (or similar) to avoid conflict
- [ ] Meson build includes `-Dllvm=enabled -Dlto=thin -Dgallium-rusticl=true`
- [ ] `makepkg -srC` succeeds in a clean chroot
- [ ] `nvchecker.toml` entry added; `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Base on the official `mesa` PKGBUILD from Arch `extra`. Add `_extra_meson_args`
variable for custom flags. Reference `ms178/archpkgbuilds/mesa` for optimization flags.
</task>

---

### T008 · Add Python PGO-optimized PKGBUILD

<task id="T008" severity="medium" category="feature" size="M">
<file>TODO.md:39</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 39: `Python (PGO-optimized build)`

**Intent:** CPython supports `--enable-optimizations` (PGO) and `--with-lto`; a
PGO-optimized build is measurably faster for CPU-bound Python workloads.

**Acceptance criteria:**
- [ ] `python-opt/PKGBUILD` exists with `pkgname=python-opt` and `conflicts=(python)`
- [ ] Build uses `./configure --enable-optimizations --with-lto=thin`
- [ ] `make -j$(nproc) build_all` runs the PGO training workload
- [ ] `makepkg -srC` succeeds; `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Use `--enable-optimizations` to trigger PGO training via `make profile-opt`. Set
`CFLAGS` to `-O3 -march=x86-64-v3`. Reference CPython Makefile target `profile-opt`.
</task>

---

### T009 · Add GCC optimized-bootstrap PKGBUILD

<task id="T009" severity="medium" category="feature" size="L">
<file>TODO.md:40</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 40: `GCC (optimized bootstrap)`

**Intent:** GCC's 3-stage bootstrap enables PGO and LTO on the compiler itself;
the result is a measurably faster GCC for compile-heavy workloads.

**Acceptance criteria:**
- [ ] `gcc-opt/PKGBUILD` builds GCC via `make profiledbootstrap`
- [ ] Profile training uses `RUNTESTFLAGS` targeting real-world compilation
- [ ] Binary conflicts with `gcc` declared; `provides=(gcc)`
- [ ] `makepkg -srC` succeeds in a clean chroot; `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Invoke `make profiledbootstrap` instead of `make`. Set `--with-build-config=bootstrap-lto`
in `configure`. Reference `ms178/archpkgbuilds/gcc` for flag selection.
</task>

---

### T010 · Add Node.js PKGBUILD with custom V8 flags

<task id="T010" severity="medium" category="feature" size="M">
<file>TODO.md:41</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 41: `Node.js (with custom V8 flags)`

**Intent:** Node.js can be built with custom V8 compile-time flags (e.g., pointer
compression, extended snapshots) for improved startup time and memory usage.

**Acceptance criteria:**
- [ ] `nodejs-opt/PKGBUILD` exists with custom `v8_extra_library_files` and `v8_monolithic`
- [ ] Build passes `--v8-options=--max-old-space-size=…` as a default in the installed binary
- [ ] `node --version` runs correctly in the packaged binary
- [ ] `makepkg -srC` succeeds; `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Use `./configure --ninja --with-intl=small-icu --enable-lto`. Pass custom GN args
via `--extra-defines`. Derive from the official `nodejs` PKGBUILD.
</task>

---

### T011 · Add PostgreSQL PKGBUILD with JIT and optimizations

<task id="T011" severity="medium" category="feature" size="M">
<file>TODO.md:42</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 42: `PostgreSQL (with JIT and optimizations)`

**Intent:** PostgreSQL ships with LLVM JIT support that is often disabled in distro
packages; enabling JIT plus LTO and PGO-data produces measurable query-execution speedups.

**Acceptance criteria:**
- [ ] `postgresql-opt/PKGBUILD` enables `--with-llvm` JIT compilation
- [ ] `CFLAGS` includes `-O3 -flto=thin`
- [ ] `pg_config --configure` output confirms `--with-llvm` presence in installed binary
- [ ] `makepkg -srC` succeeds; `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Add `depends+=(llvm-libs)`, pass `--with-llvm LLVM_CONFIG=/usr/bin/llvm-config` to
`./configure`. Base on official `postgresql` PKGBUILD.
</task>

---

### T012 · Add Nginx PKGBUILD with custom modules

<task id="T012" severity="medium" category="feature" size="M">
<file>TODO.md:43</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 43: `Nginx (with custom modules)`

**Intent:** The official nginx package omits several high-value modules (Brotli,
headers-more, PCRE JIT); a custom PKGBUILD enables them at compile time.

**Acceptance criteria:**
- [ ] `nginx-opt/PKGBUILD` compiles `ngx_brotli`, `headers-more-nginx-module`, and PCRE2 JIT
- [ ] `nginx -V 2>&1 | grep brotli` confirms module presence in installed binary
- [ ] `conflicts=(nginx)` and `provides=(nginx)` declared
- [ ] `makepkg -srC` succeeds; `.SRCINFO` regenerated; `pkg.sh lint` passes

**Implementation:**
Add module sources to `source=()`, pass `--add-module=${srcdir}/ngx_brotli` to
`./configure`. Use `--with-pcre-jit`. Base on official `nginx` PKGBUILD.
</task>

---

### T013 · Implement automated chroot-based package test framework

<task id="T013" severity="high" category="feature" size="L">
<file>TODO.md:29</file>
<blocking>T016</blocking>
<blocked_by>T014</blocked_by>

**Source:** `TODO.md` line 29: `Automated testing framework — Test packages in clean chroot environments`

**Intent:** Packages must be validated in a clean `devtools` chroot (not the host system)
to catch missing `depends`, implicit host dependencies, and runtime regressions.

**Acceptance criteria:**
- [ ] `.github/actions/pkgbuild-test/action.yml` composite action runs `makechrootpkg` in a fresh chroot
- [ ] Action is called from a new `test.yml` workflow triggered on `push` and `pull_request` for PKGBUILD paths
- [ ] On failure, chroot build log is uploaded as a workflow artifact
- [ ] Action supports `package_dir` input parameter for per-package invocation
- [ ] `pkg.sh lint` passes on all modified workflow files

**Implementation:**
Use `devtools` `mkarchroot` + `makechrootpkg -c -r ${chroot}`. Wrap in the existing
`.github/actions/pkgbuild/` composite-action pattern. Set `permissions: contents: read`.
</task>

---

### T014 · Add basic per-package functionality test suite

<task id="T014" severity="high" category="feature" size="L">
<file>TODO.md:91</file>
<blocking>T013 T015</blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 91: `Basic functionality tests`

**Intent:** Each package needs at minimum a smoke test (binary executes, `--version`
succeeds, shared library loads) to catch build regressions before publish.

**Acceptance criteria:**
- [ ] `tests/smoke/<pkgname>.sh` scripts exist for ≥10 highest-priority packages
- [ ] Each smoke test script exits 0 on success, non-zero on failure, and prints a diagnostic line
- [ ] Smoke tests are invoked by the test framework action from T013
- [ ] `shellcheck -s bash` passes on all test scripts
- [ ] At least one test catches a real regression (verified by intentionally breaking a package)

**Implementation:**
Smoke test pattern: `command -v <binary> && <binary> --version 2>&1 | grep -q '<pattern>'`.
Place in `tests/smoke/`. Reference existing `tests/test_vp_dev.py` for naming convention.
</task>

---

### T015 · Add performance regression test harness

<task id="T015" severity="low" category="feature" size="L">
<file>TODO.md:93</file>
<blocking></blocking>
<blocked_by>T014</blocked_by>

**Source:** `TODO.md` line 93: `Performance regression testing`

**Intent:** Track binary performance metrics (startup time, benchmark score) across
package versions so optimizations are measurably validated and regressions detected.

**Acceptance criteria:**
- [ ] `tests/perf/<pkgname>.sh` benchmark scripts exist for ≥3 optimization-sensitive packages
- [ ] Each script outputs a single numeric score to stdout
- [ ] CI workflow stores results as artifacts and fails if score regresses >5% vs. baseline
- [ ] Baseline scores are committed to `tests/perf/baselines.json`

**Implementation:**
Use `hyperfine --export-json` for startup benchmarks. Store JSON results per-package.
Compare with `jq` against `baselines.json`. Fail with exit 1 if regression detected.
</task>

---

### T016 · Set up binary repository with pre-built packages

<task id="T016" severity="medium" category="feature" size="XL">
<file>TODO.md:31</file>
<blocking></blocking>
<blocked_by>T013</blocked_by>

**Source:** `TODO.md` line 31: `Binary repository — Host pre-built packages for easy installation`

**Intent:** Users should be able to `pacman -Sy` from a hosted binary repo rather than
building from source; this requires a CI pipeline that builds, signs, and publishes `.pkg.tar.zst` files.

**Acceptance criteria:**
- [ ] GitHub Actions workflow `publish.yml` builds packages and uploads to a persistent store (GitHub Releases or object storage)
- [ ] `repo-add` generates a signed `.db` and `.files` tarball
- [ ] Packages are signed with a GPG key stored as a GitHub secret
- [ ] Installation instructions in `README.md` reference the binary repo URL
- [ ] `pkg.sh lint` passes on `publish.yml`

**Implementation:**
Use `repo-add` from `pacman` to build the database. Publish via `gh release upload`
or `rclone` to object storage. Sign with `gpg --batch --yes --detach-sign`. Store
`REPO_GPG_KEY` as a GitHub secret (never hardcode).
</task>

---

### T017 · Implement notification system for security/version alerts

<task id="T017" severity="medium" category="feature" size="M">
<file>TODO.md:33</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 33: `Notification system — Alert on security updates and new versions`

**Intent:** When nvchecker detects a new upstream version or a CVE advisory matches a
packaged version, maintainers should receive an automated notification (GitHub issue or
workflow summary annotation).

**Acceptance criteria:**
- [ ] CI workflow creates a GitHub issue (via `gh issue create`) when nvchecker detects a version delta
- [ ] Issue body includes package name, old version, new version, and upstream URL
- [ ] Duplicate issues are suppressed (check for open issue with same title before creating)
- [ ] Workflow runs on `schedule` (daily) and on `workflow_dispatch`
- [ ] `pkg.sh lint` passes on the modified workflow file

**Implementation:**
Extend `.github/workflows/check-updates.yml`. Use `gh issue list --search "title:<pkgname>"` 
to detect duplicates. Use `nvchecker --logger json` output for structured version data.
</task>

---

### T018 · Write build system documentation for pkg.sh and Docker

<task id="T018" severity="medium" category="docs" size="M">
<file>TODO.md:23</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 23: `Build system documentation — Detailed guide for build.sh and Docker builds`

**Intent:** New contributors lack a reference for `pkg.sh` subcommands, environment
variables (`MAX_JOBS`, `PARALLEL`), and the Docker build pipeline; this gap increases
onboarding friction.

**Acceptance criteria:**
- [ ] `docs/build-system.md` documents every `pkg.sh` subcommand with flags and examples
- [ ] Documents `MAX_JOBS` and `PARALLEL` env-var semantics
- [ ] Includes a Docker build walkthrough referencing the actual Dockerfile path
- [ ] `README.md` links to `docs/build-system.md`
- [ ] No broken links (verified via `markdown-link-check` or equivalent)

**Implementation:**
Extract usage from `pkg.sh` `cmd_*` functions and `usage()`. Document `find_pkgbuilds`
behavior. Add `docs/` directory if absent.
</task>

---

### T019 · Write PKGBUILD optimization guide

<task id="T019" severity="medium" category="docs" size="M">
<file>TODO.md:24</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 24: `Optimization guide — Best practices for optimizing PKGBUILDs`

**Intent:** Consolidate PGO, LTO, BOLT, and compiler-flag patterns used across the
repo so future packages can adopt them consistently without reverse-engineering existing
PKGBUILDs.

**Acceptance criteria:**
- [ ] `docs/optimization-guide.md` covers PGO, LTO (full/thin), BOLT, and `march=x86-64-v3`
- [ ] Each technique includes a minimal PKGBUILD snippet
- [ ] Documents known incompatibilities (packages that cannot use LTO, BOLT constraints)
- [ ] `README.md` links to `docs/optimization-guide.md`

**Implementation:**
Extract patterns from `firefox/PKGBUILD`, `chromium/PKGBUILD`, and `llvm/PKGBUILD`.
Cite upstream references (GCC PGO docs, LLVM BOLT README).
</task>

---

### T020 · Write troubleshooting guide for common build failures

<task id="T020" severity="low" category="docs" size="S">
<file>TODO.md:25</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 25: `Troubleshooting guide — Common issues and solutions`

**Intent:** Recurring build failures (dirty `.SRCINFO`, missing `makedepends`,
checksum mismatches, `namcap` warnings) need a quick-reference resolution guide.

**Acceptance criteria:**
- [ ] `docs/troubleshooting.md` documents ≥8 distinct failure modes with resolution steps
- [ ] Each entry includes the error message verbatim and the exact fix command
- [ ] Includes `pkg.sh lint` error codes (`ERROR:`, `WARN:`) with explanations
- [ ] `README.md` links to `docs/troubleshooting.md`

**Implementation:**
Source failure cases from `pkg.sh` error strings (`ERROR:$pkg: .SRCINFO dirty`,
`ERROR:$pkg: missing .SRCINFO`, `WARN:$pkg: shellcheck manual fixes needed`, etc.).
</task>

---

### T021 · Standardize all package READMEs using template

<task id="T021" severity="low" category="docs" size="M">
<file>TODO.md:67</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 67: `Standardize all package READMEs using template`

**Intent:** Package-level READMEs vary in structure; standardizing them improves
discoverability and ensures installation instructions, build options, and known issues
are documented consistently.

**Acceptance criteria:**
- [ ] All 55 package directories that lack a `README.md` have one created from the template
- [ ] All existing `README.md` files conform to the template structure (sections: Description, Installation, Build Options, Notes)
- [ ] A CI lint step validates README section presence (e.g., via `grep -q "## Installation"`)

**Implementation:**
Use `git ls-files ':(glob)**/PKGBUILD'` to enumerate packages. For each lacking a
`README.md`, generate from the template at `docs/package-readme-template.md`.
</task>

---

### T022 · Add parallel build support to pkg.sh cmd_build

<task id="T022" severity="medium" category="perf" size="M">
<file>TODO.md:79 pkg.sh</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 79: `Parallel package builds`

**Intent:** `cmd_lint` already supports `PARALLEL=true` via background jobs; `cmd_build`
runs packages sequentially, making full-repo builds unnecessarily slow.

**Acceptance criteria:**
- [ ] `pkg.sh build` accepts `--jobs N` flag (default `nproc`) for parallel execution
- [ ] Build output per package is serialized (not interleaved) by buffering stdout/stderr
- [ ] `PARALLEL=false` disables parallelism for debugging
- [ ] Exit code is non-zero if any parallel build fails
- [ ] `shellcheck -s bash` passes on `pkg.sh`

**Implementation:**
Replicate the `cmd_lint` job-dispatch pattern using a `tmp_dir` for per-package
output capture. Use `wait -n` (bash 5.1+) for job completion. Aggregate exit codes.
</task>

---

### T023 · Implement distributed ccache/sccache setup in CI

<task id="T023" severity="low" category="perf" size="M">
<file>TODO.md:73</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 73: `Distributed ccache/sccache setup`

**Intent:** Compilation of large packages (LLVM, Chromium, Firefox) in CI is slow
without compiler-output caching; sccache with an S3/GCS backend can cut rebuild time
significantly.

**Acceptance criteria:**
- [ ] `.github/actions/setup-sccache/action.yml` installs and configures `sccache` as `CC`/`CXX` wrapper
- [ ] Cache hits/misses are reported in the workflow summary
- [ ] Credentials for the cache backend are injected via GitHub secrets (no hardcoding)
- [ ] `pkg.sh lint` passes on new workflow files

**Implementation:**
Use `mozilla/sccache-action` or install `sccache` binary directly. Set
`RUSTC_WRAPPER=sccache`, `CC=sccache gcc`, `CXX=sccache g++` in the build environment.
</task>

---

### T024 · Add PGO profile caching and reuse to CI workflows

<task id="T024" severity="low" category="perf" size="M">
<file>TODO.md:74</file>
<blocking></blocking>
<blocked_by>T005</blocked_by>

**Source:** `TODO.md` line 74: `PGO profile caching and reuse`

**Intent:** PGO training runs are expensive; storing the `.profdata` files in CI cache
(keyed on source hash) avoids re-running training on every commit.

**Acceptance criteria:**
- [ ] CI workflow caches PGO `.profdata` under a key derived from `pkgver + sha256sums`
- [ ] Cache restore is attempted before running the training stage
- [ ] Training stage is skipped when a valid cache hit occurs
- [ ] Cache is invalidated on `pkgver` bump

**Implementation:**
Use `actions/cache` with key `pgo-${{ hashFiles('PKGBUILD') }}`. Store profile at
`${srcdir}/pgo-data/merged.profdata`. Restore to same path before `cmake` configure.
</task>

---

### T025 · Generate build dependency graph for packages

<task id="T025" severity="low" category="feature" size="M">
<file>TODO.md:80</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 80: `Build dependency graph generation`

**Intent:** The repo contains packages that depend on each other (e.g., `llvm` →
`mesa`, `llvm` → `firefox`); a dependency graph enables correct build ordering and
parallel scheduling.

**Acceptance criteria:**
- [ ] `tools/dep-graph.py` reads all `PKGBUILD` files and outputs a DOT-format graph
- [ ] Graph nodes represent packages; edges represent `depends`/`makedepends` relationships
- [ ] Script exits non-zero if a cycle is detected
- [ ] Output verified correct for ≥3 known dependency pairs

**Implementation:**
Parse `depends` and `makedepends` arrays via `bash -c 'source PKGBUILD; echo "${depends[@]}"'`.
Use `graphlib.TopologicalSorter` (Python 3.9+) for cycle detection. Output via `graphviz`.
</task>

---

### T026 · Convert Dockerfiles to multi-stage with minimal base image

<task id="T026" severity="low" category="refactor" size="M">
<file>TODO.md:83</file>
<blocking>T027</blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 83: `Multi-stage Docker builds` / `Smaller base images`

**Intent:** Current Dockerfiles use a single-stage build, resulting in large images
that include build tools unnecessary at runtime; multi-stage builds reduce final image size.

**Acceptance criteria:**
- [ ] All Dockerfiles in the repo use `FROM … AS builder` / `FROM … AS final` pattern
- [ ] Final stage contains only runtime dependencies (no `make`, `gcc`, `pacman` build deps)
- [ ] Final image size is ≤50% of current single-stage size (verified via `docker image ls`)
- [ ] `.github/workflows/build-container.yml` passes after change

**Implementation:**
Builder stage: `FROM archlinux:base-devel AS builder`. Final stage: `FROM archlinux:base`.
Use `COPY --from=builder /usr/local/bin/ /usr/local/bin/`. Drop `--privileged` where
possible; use `--cap-drop ALL --cap-add SETUID --cap-add SETGID`.
</task>

---

### T027 · Implement reproducible builds support

<task id="T027" severity="medium" category="feature" size="L">
<file>TODO.md:102</file>
<blocking></blocking>
<blocked_by>T026</blocked_by>

**Source:** `TODO.md` line 102: `Reproducible builds`

**Intent:** Builds must be reproducible (same source → identical binary hash) to enable
independent verification and supply-chain trust.

**Acceptance criteria:**
- [ ] `SOURCE_DATE_EPOCH` is set from the latest git commit date in all PKGBUILDs that embed timestamps
- [ ] `makepkg.conf` sets `BUILDENV+=(ccache)` disabled and `BUILDFLAGS` excludes `-fprofile-generate` for reproducible targets
- [ ] Two independent builds of the same `pkgver` produce byte-identical `.pkg.tar.zst` (verified via `sha256sum`)
- [ ] CI job `reproducible.yml` performs a double-build and fails on hash mismatch

**Implementation:**
Add `export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)` to `prepare()` in each PKGBUILD.
Reference [reproducible-builds.org/docs/source-date-epoch](https://reproducible-builds.org/docs/source-date-epoch/).
</task>

---

### T028 · Build PGO automated profile-generation infrastructure

<task id="T028" severity="low" category="perf" size="XL">
<file>TODO.md:143</file>
<blocking>T029</blocking>
<blocked_by>T005</blocked_by>

**Source:** `TODO.md` line 143: `Automated PGO profile generation` / `Profile sharing infrastructure`

**Intent:** PGO profiles must be generated from realistic workloads, stored centrally,
and reused across builds; without automation this is a manual and error-prone process.

**Acceptance criteria:**
- [ ] `tools/pgo/collect-profiles.sh` runs a standard workload suite per package and emits `.profraw` files
- [ ] `tools/pgo/merge-profiles.sh` merges `.profraw` → `.profdata` via `llvm-profdata merge`
- [ ] Profiles are uploaded to a versioned artifact store (keyed on `pkgname-pkgver`)
- [ ] CI workflow `pgo-update.yml` runs on `workflow_dispatch` and on `pkgver` bump
- [ ] `shellcheck -s bash` passes on all new scripts

**Implementation:**
Per-package workload defined in `tools/pgo/workloads/<pkgname>.sh`. Use `LLVM_PROFILE_FILE`
env var for instrumented binaries. Store profiles in `.github/pgo-profiles/` or object storage.
</task>

---

### T029 · Expand BOLT optimization to additional packages

<task id="T029" severity="low" category="perf" size="M">
<file>TODO.md:149</file>
<blocking></blocking>
<blocked_by>T028</blocked_by>

**Source:** `TODO.md` line 149: `Expand BOLT to more packages`

**Intent:** BOLT post-link optimization is currently applied only to Firefox; expanding
to LLVM, GCC, and Python can yield additional startup and hot-path speedups.

**Acceptance criteria:**
- [ ] BOLT applied to ≥2 additional packages beyond Firefox
- [ ] Each package's PKGBUILD includes a `_bolt_profile` variable gating BOLT application
- [ ] BOLT binary size increase ≤10% documented in package `README.md`
- [ ] `makepkg -srC` succeeds for each modified package; `pkg.sh lint` passes

**Implementation:**
In `package()`: `llvm-bolt ${binary} -o ${binary}.bolt --data ${_bolt_profile} --reorder-functions=hfsort`.
Then `mv ${binary}.bolt ${binary}`. Gate on `[[ -n ${_bolt_profile} ]]` check.
</task>

---

### T030 · Add x86-64-v3/v4 architecture-specific build variants

<task id="T030" severity="low" category="feature" size="L">
<file>TODO.md:153</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 153: `x86-64-v2, v3, v4 variants`

**Intent:** Packages built with `-march=x86-64-v3` (AVX2) or `-march=x86-64-v4`
(AVX-512) are faster on compatible hardware; providing versioned variants lets users
choose the best binary for their CPU.

**Acceptance criteria:**
- [ ] A CI matrix (`x86_64_v3`, `x86_64_v4`) produces separate package archives
- [ ] Package names include architecture suffix: `firefox-x86-64-v3`
- [ ] CPU feature check in install script warns on incompatible hardware
- [ ] `nvchecker.toml` entries cover all variants; `pkg.sh lint` passes

**Implementation:**
Add `_march=x86-64-v3` variable to PKGBUILD; append `-march=${_march}` to `CFLAGS`/`CXXFLAGS`.
Use `pkgname=${_pkgname}-${_march//-/}` for the variant name.
</task>

---

### T031 · Add automated changelog generation to CI release workflow

<task id="T031" severity="low" category="feature" size="M">
<file>TODO.md:183</file>
<blocking>T032</blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 183: `Changelog generation`

**Intent:** Release notes must reflect which packages were updated, from which version
to which, and reference upstream changelog URLs; manual changelog writing is error-prone.

**Acceptance criteria:**
- [ ] `.github/scripts/fetch-changelog.sh` generates a structured changelog from `nvchecker` version deltas
- [ ] Output format: `### <pkgname>: <old_ver> → <new_ver>\n<upstream_url>`
- [ ] Script is invoked from `create-pr.sh` and appends to PR body
- [ ] `shellcheck -s bash` passes on `fetch-changelog.sh`

**Implementation:**
Diff `.github/nvchecker/old_ver.json` against nvchecker output. For each changed
entry, look up `url` from `nvchecker.toml` `[<pkgname>]` section. Emit Markdown.
`fetch-changelog.sh` already exists — extend rather than replace.
</task>

---

### T032 · Add release automation workflow

<task id="T032" severity="low" category="feature" size="M">
<file>TODO.md:184</file>
<blocking></blocking>
<blocked_by>T031</blocked_by>

**Source:** `TODO.md` line 184: `Release automation`

**Intent:** Creating GitHub Releases currently requires manual steps; automating the
release on tag push ensures consistent artifact naming, changelog inclusion, and signing.

**Acceptance criteria:**
- [ ] `.github/workflows/release.yml` triggers on `push` with `tags: ['v*']`
- [ ] Workflow creates a GitHub Release via `gh release create` with generated changelog body
- [ ] All `.pkg.tar.zst` artifacts for the tagged commit are attached to the release
- [ ] Release is marked pre-release if tag contains `-rc`
- [ ] `pkg.sh lint` passes on `release.yml`

**Implementation:**
Use `gh release create ${{ github.ref_name }} --notes-file changelog.md --title "Release ${{ github.ref_name }}"`.
Attach artifacts with `gh release upload`. Generate `changelog.md` by calling T031's script.
</task>

---

### T033 · Implement TKG community patch autofetch and compatibility testing

<task id="T033" severity="low" category="feature" size="L">
<file>TODO.md:122</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 122: `TKG patches integration — Implement autofetch for community patches`

**Intent:** `wine-tkg-git` and related packages use patches from
`Frogging-Family/community-patches`; automating the fetch and compatibility check reduces
manual maintenance overhead when upstream patches change.

**Acceptance criteria:**
- [ ] `.github/scripts/fetch-tkg-patches.sh` fetches selected patches from `community-patches` at a pinned commit
- [ ] Each fetched patch is verified with `patch --dry-run` before committing
- [ ] A CI workflow runs compatibility check on `push` to `wine-tkg-git/` paths
- [ ] Failed patch applications produce an actionable error message (patch name + rejection context)
- [ ] `shellcheck -s bash` passes on `fetch-tkg-patches.sh`

**Implementation:**
Use `curl -fsSL` to download individual patch files from the pinned GitHub raw URL.
Store pinned commit SHA in a `.tkg-patches-lock` file. Validate each patch with
`git apply --check`.
</task>

---

### T034 · Create OCI images from PKGBUILDs with automated registry push

<task id="T034" severity="low" category="feature" size="XL">
<file>TODO.md:115</file>
<blocking></blocking>
<blocked_by>T013</blocked_by>

**Source:** `TODO.md` line 115: `OCI/Docker images from PKGBUILDs` / `Automated image building`

**Intent:** Provide OCI container images built directly from PKGBUILDs, enabling users
to run optimized binaries without a full Arch installation.

**Acceptance criteria:**
- [ ] `.github/workflows/publish-oci.yml` builds per-package OCI images using the binary output from T016
- [ ] Images are pushed to `ghcr.io/${GITHUB_REPOSITORY_OWNER}/<pkgname>:<pkgver>`
- [ ] Each image uses a minimal `archlinux:base` base layer
- [ ] Image manifest includes `org.opencontainers.image.source` label pointing to PKGBUILD
- [ ] `pkg.sh lint` passes on the workflow file

**Implementation:**
Use `docker buildx build --platform linux/amd64` with a generated Dockerfile that
copies the installed package from the binary repo artifact. Push via `docker push`
with GHCR credentials from `GITHUB_TOKEN`.
</task>

---

### T035 · Review loathingKernel/PKGBUILDs for build workflow patterns

<task id="T035" severity="low" category="research" size="S">
<file>TODO.md:9</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 9: `Implement build workflows inspired by loathingKernel/PKGBUILDs`

**Intent:** `loathingKernel/PKGBUILDs` may contain CI workflow patterns, PKGBUILD
helpers, or build optimizations not yet present in this repo.

**Acceptance criteria:**
- [ ] Review completed and findings documented in a GitHub issue or PR description
- [ ] Any adopted patterns cite the source repository
- [ ] At least one concrete improvement identified and tracked as a follow-up task

**Implementation:**
Clone and `diff` workflow YAML files against `.github/workflows/`. Document differences
in a comparison table. Focus on: caching strategies, matrix builds, artifact publishing.
</task>

---

### T036 · Review ms178/archpkgbuilds for optimization patterns

<task id="T036" severity="low" category="research" size="S">
<file>TODO.md:11</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` lines 11–14: Multiple `ms178` package review items (vkd3d-proton,
tar-parallel, DXVK, FFmpeg, Firefox, Heroic, Wine CachyOS)

**Intent:** `ms178/archpkgbuilds` contains aggressively optimized PKGBUILDs that may
include compiler flags, PGO, or BOLT patterns not yet adopted here.

**Acceptance criteria:**
- [ ] All 7 listed `ms178` packages reviewed (vkd3d-proton-mingw-git, tar-parallel, DXVK, FFmpeg, Firefox, Heroic, Wine CachyOS)
- [ ] Each review produces a concrete action item: adopt pattern / skip with reason
- [ ] Adoptable patterns are filed as follow-up issues or directly applied

**Implementation:**
For each package, diff `CFLAGS`/`CXXFLAGS`/`cmake` args against current PKGBUILDs.
Document adopted flags and their measured impact (cite benchmark source if available).
</task>

---

### T037 · Review FabioLolix/PKGBUILD-AUR_fix for correction patterns

<task id="T037" severity="low" category="research" size="S">
<file>TODO.md:15</file>
<blocking></blocking>
<blocked_by></blocked_by>

**Source:** `TODO.md` line 15: `Review FabioLolix/PKGBUILD-AUR_fix`

**Intent:** `FabioLolix/PKGBUILD-AUR_fix` tracks common AUR PKGBUILD correctness
issues; reviewing it may reveal patterns that apply to packages in this repo.

**Acceptance criteria:**
- [ ] Review completed for all open issues/PRs in `PKGBUILD-AUR_fix` relevant to packages in this repo
- [ ] Any applicable fixes applied to matching PKGBUILDs
- [ ] Applied fixes regenerate `.SRCINFO` and pass `pkg.sh lint`

**Implementation:**
Filter `PKGBUILD-AUR_fix` issues by package names matching `git ls-files ':(glob)**/PKGBUILD'`.
Apply corrections and document in commit message with `Fixes: <upstream-issue-url>`.
</task>

---

## Dependency Graph

```
T001  ──────────────────────────────────────── (none)
T002  ──────────────────────────────────────── (none)
T003  ──────────────────────────────────────── (none)
T004  ──────────────────────────────────────── (none)
T005  ──► T006, T024, T028
T007  ──────────────────────────────────────── (none)
T008–T012 ──────────────────────────────────── (none, independent)
T014  ──► T013, T015
T013  ──► T016, T034
T026  ──► T027
T028  ──► T029
T031  ──► T032
T035–T037 ──────────────────────────────────── (none, independent)
```

## Severity Summary

| Severity | Count | Tasks                                                      |
|----------|-------|------------------------------------------------------------|
| high     | 2     | T013, T014                                                 |
| medium   | 14    | T001–T012, T017, T022, T027                                |
| low      | 21    | T015–T016, T018–T021, T023–T026, T028–T037                 |

## Category Summary

| Category | Count | Tasks                                              |
|----------|-------|----------------------------------------------------|
| security | 1     | T001                                               |
| bug      | 1     | T002                                               |
| feature  | 17    | T003, T007–T014, T016–T017, T025, T027, T030–T034 |
| perf     | 8     | T005–T006, T022–T024, T028–T029, T015             |
| refactor | 2     | T004, T026                                         |
| docs     | 5     | T018–T021                                          |
| research | 3     | T035–T037                                          |

## Size Summary

| Size | LOC Delta  | Count | Tasks                                                       |
|------|------------|-------|-------------------------------------------------------------|
| S    | <20        | 4     | T001, T002, T020, T035–T037 (×3 = 4 with T001/T002)        |
| M    | 20–100     | 20    | T003–T004, T006, T008, T010–T012, T017–T019, T021–T025, T029, T031–T033 |
| L    | 100–300    | 9     | T005, T007, T009, T013–T015, T027, T030, T033              |
| XL   | 300+       | 2     | T016, T028, T034                                            |
