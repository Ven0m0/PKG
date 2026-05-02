# Implementation Plan
_2026-05-02 · 37 tasks_

Consolidates selected open items from `TODO.md` and one in-code security marker
(`filen-desktop/filen-desktop.sh:11`). No `FIXME`/`HACK`/`XXX`/`DEPRECATED` comments
were found in the package/source files covered by this plan; repo docs still contain
placeholders such as `.github/SECURITY.md` with `CVE-2024-XXXX`.

## Index (topological order)

| ID   | Title                                                       | Sev    | Cat      | Sz | Blocks   | Needs  |
|------|-------------------------------------------------------------|--------|----------|----|----------|--------|
| T001 | Remove ELECTRON_DISABLE_SECURITY_WARNINGS from filen-desktop | med  | security | S  | —        | —      |
| T002 | Fix gitoxide optimize.patch to apply cleanly                | med    | bug      | S  | —        | —      |
| T003 | Create varia PKGBUILD from make-appimage.sh                 | med    | feature  | M  | —        | —      |
| T004 | Update Chromium PKGBUILD patches to latest upstream         | med    | refactor | M  | —        | —      |
| T005 | Add LLVM PGO instrumentation to PKGBUILD                    | med    | perf     | L  | T006 T024 T028 | — |
| T006 | Refine Firefox BOLT optimization in PKGBUILD                | med    | perf     | M  | —        | T005   |
| T007 | Add Mesa PKGBUILD with latest upstream features             | med    | feature  | L  | —        | —      |
| T008 | Add Python PGO-optimized PKGBUILD                           | med    | feature  | M  | —        | —      |
| T009 | Add GCC optimized-bootstrap PKGBUILD                        | med    | feature  | L  | —        | —      |
| T010 | Add Node.js PKGBUILD with custom V8 flags                   | med    | feature  | M  | —        | —      |
| T011 | Add PostgreSQL PKGBUILD with JIT and compile-time opts      | med    | feature  | M  | —        | —      |
| T012 | Add Nginx PKGBUILD with custom modules                      | med    | feature  | M  | —        | —      |
| T014 | Add basic per-package functionality test suite              | high   | feature  | L  | T013 T015 | —    |
| T013 | Implement automated chroot-based package test framework     | high   | feature  | L  | T016 T034 | T014  |
| T015 | Add performance regression test harness                     | low    | feature  | L  | —        | T014   |
| T016 | Set up binary repository with pre-built packages            | med    | feature  | XL | —        | T013   |
| T017 | Implement notification system for security/version alerts   | med    | feature  | M  | —        | —      |
| T018 | Write build system documentation for pkg.sh and Docker      | med    | docs     | M  | —        | —      |
| T019 | Write PKGBUILD optimization guide                           | med    | docs     | M  | —        | —      |
| T020 | Write troubleshooting guide for common build failures       | low    | docs     | S  | —        | —      |
| T021 | Standardize all package READMEs using template              | low    | docs     | M  | —        | —      |
| T022 | Add parallel build support to pkg.sh cmd_build              | med    | perf     | M  | —        | —      |
| T023 | Implement distributed ccache/sccache setup in CI            | low    | perf     | M  | —        | —      |
| T024 | Add PGO profile caching and reuse to CI workflows           | low    | perf     | M  | —        | T005   |
| T025 | Generate build dependency graph for packages                | low    | feature  | M  | —        | —      |
| T026 | Convert Dockerfiles to multi-stage with minimal base image  | low    | refactor | M  | T027     | —      |
| T027 | Implement reproducible builds support                       | med    | feature  | L  | —        | T026   |
| T028 | Build PGO automated profile-generation infrastructure       | low    | perf     | XL | T029     | T005   |
| T029 | Expand BOLT optimization to additional packages             | low    | perf     | M  | —        | T028   |
| T030 | Add x86-64-v3/v4 architecture-specific build variants       | low    | feature  | L  | —        | —      |
| T031 | Add automated changelog generation to CI release workflow   | low    | feature  | M  | T032     | —      |
| T032 | Add release automation workflow                             | low    | feature  | M  | —        | T031   |
| T033 | Implement TKG community patch autofetch and testing         | low    | feature  | L  | —        | —      |
| T034 | Create OCI images from PKGBUILDs with automated registry push | low  | feature  | XL | —        | T013   |
| T035 | Review loathingKernel/PKGBUILDs for build workflow patterns | low    | research | S  | —        | —      |
| T036 | Review ms178/archpkgbuilds for optimization patterns        | low    | research | S  | —        | —      |
| T037 | Review FabioLolix/PKGBUILD-AUR_fix for correction patterns  | low    | research | S  | —        | —      |

---

## Tasks

### T001 · Remove ELECTRON_DISABLE_SECURITY_WARNINGS from filen-desktop
`filen-desktop/filen-desktop.sh:11` · medium · security · S · needs:— · blocks:—
Blanket env-var suppresses all Electron security warnings, masking real misconfiguration signals.
- [ ] `export ELECTRON_DISABLE_SECURITY_WARNINGS=true` removed from line 11; Electron launches without it
- [ ] If specific warnings must be silenced, they use `--disable-features=` with per-item inline comment
- [ ] `pkg.sh lint` passes on modified file
> `delete line 11; replace blanket suppression with targeted --disable-features= flags if needed`

### T002 · Fix gitoxide optimize.patch to apply cleanly
`gitoxide/` · medium · bug · S · needs:— · blocks:—
`optimize.patch` no longer applies to current gitoxide source, causing `prepare()` to fail.
- [ ] `patch -Np1 --dry-run < optimize.patch` exits 0 against current source tarball
- [ ] `makepkg -srC` in `gitoxide/` completes without patch errors; `.SRCINFO` regenerated
- [ ] `pkg.sh lint` passes
> `makepkg -o` to unpack; identify rejected hunks; update context lines/offsets; regenerate .SRCINFO`

### T003 · Create varia PKGBUILD from make-appimage.sh
`varia/PKGBUILD` (new) · medium · feature · M · needs:— · blocks:—
The varia project provides `make-appimage.sh` but no Arch package, blocking pacman install and nvchecker tracking.
- [ ] `varia/PKGBUILD` with valid `pkgname`, `pkgver`, `source`, `sha256sums`; `varia/.SRCINFO` matches `makepkg --printsrcinfo`
- [ ] `makepkg -srC` succeeds in clean chroot; `nvchecker.toml` entry added
- [ ] `pkg.sh lint` passes
> `skeleton: pkgname=varia arch=(x86_64) source=("${pkgname}-${pkgver}.tar.gz::${_url}") install -Dm755`

### T004 · Update Chromium PKGBUILD patches to latest upstream
`chromium/PKGBUILD` `chromium/patches/` · medium · refactor · M · needs:— · blocks:—
Custom patches in `chromium/patches/` may reject or have been merged upstream since last sync.
- [ ] All patches apply without rejects against current `pkgver`; `fetch-chromium-release` succeeds
- [ ] `makepkg -o --nocheck` completes without patch errors; `.SRCINFO` regenerated
- [ ] `pkg.sh lint` passes
> `makepkg -o` to detect rejects; update context lines or replace from cromite/CachyOS-chromium-patches; drop merged patches`

### T005 · Add LLVM PGO instrumentation to PKGBUILD
`llvm/PKGBUILD` · medium · perf · L · needs:— · blocks:T006 T024 T028
2-stage PGO build produces a measurably faster LLVM compiler and provides the instrumented toolchain required by T006/T028.
- [ ] PKGBUILD performs instrument → profile-collect → optimized-rebuild; profile stored at `${srcdir}/pgo-data/`
- [ ] `makepkg -srC` succeeds on x86_64; final binary benchmarks ≥3% faster on `llvm-test-suite`
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes
> `stage1: cmake -DLLVM_BUILD_INSTRUMENTED=IR; stage2: llvm-profdata merge; stage3: cmake -DLLVM_PROFDATA_FILE=merged.profdata -DLLVM_ENABLE_PERF_HINTS=ON`

### T006 · Refine Firefox BOLT optimization in PKGBUILD
`firefox/PKGBUILD` · medium · perf · M · needs:T005 · blocks:—
Current BOLT application may use a suboptimal ordering strategy or stale profile, underdelivering on startup/JS speedup.
- [ ] BOLT invoked with `--reorder-blocks=ext-tsp --reorder-functions=hfsort`; profile from Speedometer 3 or equivalent
- [ ] Binary size regression ≤5% vs non-BOLT build; `makepkg -srC` succeeds
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes
> `in package(): perf2bolt/merge-fdata on stored profile, then llvm-bolt ${pkgdir}/usr/lib/firefox/firefox -o ...; ref DarkFox and CachyOS firefox-wayland-cachy-hg`

### T007 · Add Mesa PKGBUILD with latest upstream features
`mesa/PKGBUILD` (new) · medium · feature · L · needs:— · blocks:—
Stable Arch Mesa omits rusticl and newer Vulkan extensions available upstream; custom build enables them with LTO.
- [ ] `mesa/PKGBUILD` with `pkgname=mesa-opt`; meson args include `-Dllvm=enabled -Dlto=thin -Dgallium-rusticl=true`
- [ ] `makepkg -srC` succeeds in clean chroot; `nvchecker.toml` entry added
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes
> `base on Arch extra/mesa PKGBUILD; add _extra_meson_args variable; ref ms178/archpkgbuilds/mesa for flag selection`

### T008 · Add Python PGO-optimized PKGBUILD
`python-opt/PKGBUILD` (new) · medium · feature · M · needs:— · blocks:—
CPython PGO (`--enable-optimizations`) measurably improves CPU-bound workload throughput; not enabled in official Arch package.
- [ ] `python-opt/PKGBUILD` with `pkgname=python-opt conflicts=(python)`; `./configure --enable-optimizations --with-lto=thin`
- [ ] `make profile-opt` training workload runs; `makepkg -srC` succeeds
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes
> `CFLAGS="-O3 -march=x86-64-v3"; use CPython Makefile target profile-opt for PGO training`

### T009 · Add GCC optimized-bootstrap PKGBUILD
`gcc-opt/PKGBUILD` (new) · medium · feature · L · needs:— · blocks:—
GCC `profiledbootstrap` applies PGO+LTO to the compiler itself, producing a faster GCC for compile-heavy workloads.
- [ ] `gcc-opt/PKGBUILD` uses `make profiledbootstrap`; `provides=(gcc) conflicts=(gcc)` declared
- [ ] `makepkg -srC` succeeds in clean chroot; `.SRCINFO` regenerated
- [ ] `pkg.sh lint` passes
> `./configure --with-build-config=bootstrap-lto; make profiledbootstrap; ref ms178/archpkgbuilds/gcc`

### T010 · Add Node.js PKGBUILD with custom V8 flags
`nodejs-opt/PKGBUILD` (new) · medium · feature · M · needs:— · blocks:—
Node.js V8 supports compile-time flags (pointer compression, snapshots) that improve startup time and memory usage.
- [ ] `nodejs-opt/PKGBUILD` with `./configure --ninja --with-intl=small-icu --enable-lto`; custom GN args via `--extra-defines`
- [ ] `node --version` runs correctly; `makepkg -srC` succeeds
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes
> `derive from official nodejs PKGBUILD; pass V8 GN args via --extra-defines`

### T011 · Add PostgreSQL PKGBUILD with JIT and optimizations
`postgresql-opt/PKGBUILD` (new) · medium · feature · M · needs:— · blocks:—
Official distro package omits `--with-llvm` JIT; enabling it with LTO produces measurable query-execution speedups.
- [ ] `postgresql-opt/PKGBUILD` with `--with-llvm LLVM_CONFIG=/usr/bin/llvm-config`; `CFLAGS="-O3 -flto=thin"`
- [ ] `pg_config --configure` confirms `--with-llvm`; `makepkg -srC` succeeds
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes
> `depends+=(llvm-libs); add --with-llvm to ./configure; base on official postgresql PKGBUILD`

### T012 · Add Nginx PKGBUILD with custom modules
`nginx-opt/PKGBUILD` (new) · medium · feature · M · needs:— · blocks:—
Official nginx omits Brotli, headers-more, and PCRE JIT; enabling them at compile time avoids runtime overhead.
- [ ] `nginx-opt/PKGBUILD` compiles `ngx_brotli`, `headers-more-nginx-module`, PCRE2 JIT; `conflicts=(nginx) provides=(nginx)`
- [ ] `nginx -V 2>&1 | grep -q brotli`; `makepkg -srC` succeeds
- [ ] `.SRCINFO` regenerated; `pkg.sh lint` passes
> `source=(ngx_brotli headers-more); ./configure --add-module=${srcdir}/ngx_brotli --with-pcre-jit`

### T013 · Implement automated chroot-based package test framework
`.github/actions/pkgbuild-test/action.yml` (new) · high · feature · L · needs:T014 · blocks:T016 T034
Packages must be validated in a clean `devtools` chroot to catch missing `depends` and implicit host dependencies.
- [ ] Composite action runs `makechrootpkg -c -r ${chroot}`; accepts `package_dir` input; uploads build log on failure
- [ ] New `test.yml` workflow triggers on `push`/`pull_request` for `**/PKGBUILD` paths
- [ ] `permissions: contents: read`; `pkg.sh lint` passes on all new workflow files
> `devtools mkarchroot + makechrootpkg; model after .github/actions/pkgbuild/ composite-action pattern`

### T014 · Add basic per-package functionality test suite
`tests/smoke/` (new) · high · feature · L · needs:— · blocks:T013 T015
Packages lack smoke tests; build regressions are only caught after publish.
- [ ] `tests/smoke/<pkgname>.sh` for ≥10 priority packages; exits 0 on success, non-zero with diagnostic on failure
- [ ] Invocable from T013 action; `shellcheck -s bash` passes on all scripts
- [ ] At least one test verified to catch a real regression
> `pattern: command -v <bin> && <bin> --version 2>&1 | grep -q '<pattern>'; ref tests/test_vp_dev.py naming`

### T015 · Add performance regression test harness
`tests/perf/` (new) · low · feature · L · needs:T014 · blocks:—
Optimization work lacks automated measurement; regressions go undetected across `pkgver` bumps.
- [ ] `tests/perf/<pkgname>.sh` for ≥3 packages; outputs single numeric score to stdout
- [ ] CI fails if score regresses >5% vs `tests/perf/baselines.json`
- [ ] Baselines committed to repo; `shellcheck -s bash` passes
> `hyperfine --export-json for startup benchmarks; compare with jq against baselines.json; exit 1 on regression`

### T016 · Set up binary repository with pre-built packages
`.github/workflows/publish.yml` (new) · medium · feature · XL · needs:T013 · blocks:—
Users must build from source; a hosted binary repo enables `pacman -Sy` installation.
- [ ] `publish.yml` builds, signs, and publishes `.pkg.tar.zst`; `repo-add` produces signed `.db` and `.files`
- [ ] GPG key in GitHub secret `REPO_GPG_KEY` (never hardcoded); `README.md` updated with repo URL
- [ ] `pkg.sh lint` passes on `publish.yml`
> `repo-add for db; gpg --batch --yes --detach-sign; publish via gh release upload or rclone`

### T017 · Implement notification system for security/version alerts
`.github/workflows/check-updates.yml` · medium · feature · M · needs:— · blocks:—
nvchecker detects version deltas silently; maintainers miss updates without manual polling.
- [ ] CI creates GitHub issue via `gh issue create` on version delta; body includes pkg, old ver, new ver, upstream URL
- [ ] Duplicate suppression via `gh issue list --search "title:<pkgname>"`; runs on daily `schedule` + `workflow_dispatch`
- [ ] `pkg.sh lint` passes on modified workflow
> `extend check-updates.yml; use nvchecker --logger json for structured output`

### T018 · Write build system documentation for pkg.sh and Docker
`docs/build-system.md` (new) · medium · docs · M · needs:— · blocks:—
Contributors lack a reference for `pkg.sh` subcommands, `MAX_JOBS`/`PARALLEL` env-vars, and the Docker pipeline.
- [ ] `docs/build-system.md` covers every `cmd_*` subcommand with flags and examples; documents `MAX_JOBS` and `PARALLEL`
- [ ] Includes Docker build walkthrough referencing actual Dockerfile path; `README.md` links to it
- [ ] No broken links
> `extract usage from pkg.sh cmd_* functions and usage(); document find_pkgbuilds behavior`

### T019 · Write PKGBUILD optimization guide
`docs/optimization-guide.md` (new) · medium · docs · M · needs:— · blocks:—
PGO/LTO/BOLT patterns are scattered across PKGBUILDs with no consolidated reference, causing inconsistent adoption.
- [ ] Covers PGO, LTO (full/thin), BOLT, `-march=x86-64-v3`; each technique has a minimal PKGBUILD snippet
- [ ] Documents known incompatibilities; `README.md` links to it
> `extract patterns from firefox/PKGBUILD, chromium/PKGBUILD, llvm/PKGBUILD; cite GCC PGO docs and LLVM BOLT README`

### T020 · Write troubleshooting guide for common build failures
`docs/troubleshooting.md` (new) · low · docs · S · needs:— · blocks:—
Recurring failures (dirty `.SRCINFO`, checksum mismatches, `namcap` warnings) lack a quick-reference resolution guide.
- [ ] ≥8 failure modes documented with verbatim error message and exact fix command
- [ ] Covers all `pkg.sh lint` error codes (`ERROR:`, `WARN:`); `README.md` links to it
> `source cases from pkg.sh error strings: "ERROR:$pkg: .SRCINFO dirty", "WARN:$pkg: shellcheck manual fixes needed", etc.`

### T021 · Standardize all package READMEs using template
`<pkg>/README.md` (55 packages) · low · docs · M · needs:— · blocks:—
Package READMEs vary in structure, degrading discoverability and installation guidance consistency.
- [ ] All 55 package dirs have `README.md` conforming to template (Description/Installation/Build Options/Notes sections)
- [ ] CI lint step validates section presence via `grep -q "## Installation"`
> `git ls-files ':(glob)**/PKGBUILD' to enumerate; generate missing READMEs from docs/package-readme-template.md`

### T022 · Add parallel build support to pkg.sh cmd_build
`pkg.sh` · medium · perf · M · needs:— · blocks:—
`cmd_build` runs sequentially while `cmd_lint` already supports `PARALLEL=true`; full-repo builds are unnecessarily slow.
cmd_build already supports PARALLEL=true; this task focuses on refining output buffering and job control.
- [ ] `PARALLEL=false` disables parallelism; exit code non-zero if any build fails
- [ ] `shellcheck -s bash` passes on `pkg.sh`
> `replicate cmd_lint job-dispatch pattern; tmp_dir for per-package output; wait -n (bash 5.1+) for job completion`

### T023 · Implement distributed ccache/sccache setup in CI
`.github/actions/setup-sccache/action.yml` (new) · low · perf · M · needs:— · blocks:—
Large packages (LLVM, Chromium, Firefox) rebuild from scratch in CI without compiler-output caching.
- [ ] Composite action configures `sccache` as `CC`/`CXX` wrapper; cache hits/misses in workflow summary
- [ ] Credentials injected via GitHub secrets (no hardcoding); `pkg.sh lint` passes
> `RUSTC_WRAPPER=sccache CC="sccache gcc" CXX="sccache g++"; use mozilla/sccache-action or direct binary install`

### T024 · Add PGO profile caching and reuse to CI workflows
`.github/workflows/` · low · perf · M · needs:T005 · blocks:—
PGO training reruns on every commit, wasting CI time when source is unchanged.
- [ ] `actions/cache` key `pgo-${{ hashFiles('PKGBUILD') }}`; training stage skipped on cache hit
- [ ] Profile at `${srcdir}/pgo-data/merged.profdata`; cache invalidated on `pkgver` bump
> `actions/cache restore before cmake configure; skip training if cache-hit output is 'true'`

### T025 · Generate build dependency graph for packages
`tools/dep-graph.py` (new) · low · feature · M · needs:— · blocks:—
Inter-package dependencies (e.g., `llvm` → `mesa`) are implicit; correct build ordering requires an explicit graph.
- [ ] `tools/dep-graph.py` outputs DOT-format graph from all PKGBUILDs; exits non-zero on cycle detected
- [ ] Output verified correct for ≥3 known dependency pairs
> parse depends/makedepends via makepkg --printsrcinfo; graphlib.TopologicalSorter (Python 3.9+)

### T026 · Convert Dockerfiles to multi-stage with minimal base image
`Dockerfile(s)` · low · refactor · M · needs:— · blocks:T027
Single-stage Dockerfiles include build tools in the final image, inflating size unnecessarily.
- [ ] All Dockerfiles use `FROM archlinux:base-devel AS builder` / `FROM archlinux:base AS final` pattern
- [ ] Final image size ≤50% of current size (`docker image ls`); `build-container.yml` passes
> `COPY --from=builder /usr/local/bin/ /usr/local/bin/; --cap-drop ALL --cap-add SETUID --cap-add SETGID`

### T027 · Implement reproducible builds support
`PKGBUILDs` · medium · feature · L · needs:T026 · blocks:—
Builds embed non-deterministic timestamps; independent rebuilds produce different binary hashes, blocking supply-chain verification.
- [ ] SOURCE_DATE_EPOCH handled via makepkg native support for reproducible builds
- [ ] Two independent builds of same `pkgver` produce byte-identical `.pkg.tar.zst`; CI job `reproducible.yml` fails on hash mismatch
> `ref reproducible-builds.org/docs/source-date-epoch; double-build in CI verified via sha256sum`

### T028 · Build PGO automated profile-generation infrastructure
`tools/pgo/` (new) · low · perf · XL · needs:T005 · blocks:T029
PGO profiles are generated manually and inconsistently; no automation exists for collection, merging, or versioned storage.
- [ ] `tools/pgo/collect-profiles.sh` runs per-package workload suite emitting `.profraw`; `merge-profiles.sh` produces `.profdata`
- [ ] CI workflow `pgo-update.yml` on `workflow_dispatch` + `pkgver` bump; profiles stored keyed on `pkgname-pkgver`
- [ ] `shellcheck -s bash` passes on all new scripts
> `LLVM_PROFILE_FILE env var for instrumented binaries; per-package workload in tools/pgo/workloads/<pkgname>.sh`

### T029 · Expand BOLT optimization to additional packages
`PKGBUILDs` · low · perf · M · needs:T028 · blocks:—
BOLT is applied only to Firefox; LLVM, GCC, and Python could benefit from the same post-link optimization.
- [ ] BOLT applied to ≥2 additional packages; each PKGBUILD has `_bolt_profile` variable gating application
- [ ] BOLT size increase ≤10% documented in package `README.md`; `makepkg -srC` succeeds; `pkg.sh lint` passes
> `llvm-bolt ${bin} -o ${bin}.bolt --data ${_bolt_profile} --reorder-functions=hfsort; mv ${bin}.bolt ${bin}; gate on [[ -n ${_bolt_profile} ]]`

### T030 · Add x86-64-v3/v4 architecture-specific build variants
`PKGBUILDs` · low · feature · L · needs:— · blocks:—
Current implementation supports x86-64-v3; this task expands support to include v4 variants for AVX-512 users.
- [ ] CI matrix (`x86_64_v3`, `x86_64_v4`) produces separate archives with suffixed `pkgname`
- [ ] Install script warns on incompatible CPU; `nvchecker.toml` covers all variants; `pkg.sh lint` passes
> `_march=x86-64-v3; CFLAGS+=" -march=${_march}"; pkgname=${_pkgname}-${_march//-/}`

### T031 · Add automated changelog generation to CI release workflow
`.github/scripts/fetch-changelog.sh` · low · feature · M · needs:— · blocks:T032
Release notes are written manually; no structured changelog is generated from nvchecker version deltas.
- [ ] `fetch-changelog.sh` outputs `### <pkg>: <old> → <new>\n<upstream_url>` from nvchecker delta
- [ ] Script invoked from `create-pr.sh`; appended to PR body; `shellcheck -s bash` passes
> `diff old_ver.json vs nvchecker output; look up url from nvchecker.toml [<pkgname>]; extend existing fetch-changelog.sh`

### T032 · Add release automation workflow
`.github/workflows/release.yml` (new) · low · feature · M · needs:T031 · blocks:—
GitHub Releases are created manually; tag pushes do not automatically produce signed, artifact-attached releases.
- [ ] `release.yml` triggers on `push: tags: ['v*']`; creates release via `gh release create` with T031 changelog
- [ ] All `.pkg.tar.zst` for the tag attached; pre-release flag set when tag contains `-rc`
- [ ] `pkg.sh lint` passes
> `gh release create ${{ github.ref_name }} --notes-file changelog.md; gh release upload for artifacts`

### T033 · Implement TKG community patch autofetch and compatibility testing
`.github/scripts/fetch-tkg-patches.sh` (new) · low · feature · L · needs:— · blocks:—
`wine-tkg-git` patches from `Frogging-Family/community-patches` are updated manually; stale patches cause build failures.
- [ ] `fetch-tkg-patches.sh` downloads patches at pinned commit SHA from `.tkg-patches-lock`; validates each with `patch --dry-run`
- [ ] CI workflow checks patch compatibility on push to `wine-tkg-git/` paths; failures name the patch and show rejection context
- [ ] `shellcheck -s bash` passes
> `curl -fsSL raw GitHub URL; store pinned SHA in .tkg-patches-lock; validate with git apply --check`

### T034 · Create OCI images from PKGBUILDs with automated registry push
.github/workflows/publish-oci.yml (new) · low · feature · XL · needs:T016 · blocks:—
No OCI images are published; users must install Arch Linux to use optimized binaries.
- [ ] `publish-oci.yml` builds per-package images pushed to `ghcr.io/${GITHUB_REPOSITORY_OWNER}/<pkgname>:<pkgver>`
- [ ] Base layer `archlinux:base`; manifest includes `org.opencontainers.image.source` label; `pkg.sh lint` passes
> `docker buildx build --platform linux/amd64; generated Dockerfile copies from binary repo artifact; push via GITHUB_TOKEN`

### T035 · Review loathingKernel/PKGBUILDs for build workflow patterns
`TODO.md:9` · low · research · S · needs:— · blocks:—
`loathingKernel/PKGBUILDs` may contain CI/workflow patterns not present in this repo.
- [ ] Review complete; findings documented in a GitHub issue or PR; ≥1 concrete improvement identified and tracked
> `diff .github/workflows/ against upstream; focus on caching strategies, matrix builds, artifact publishing`

### T036 · Review ms178/archpkgbuilds for optimization patterns
`TODO.md:11–14` · low · research · S · needs:— · blocks:—
7 ms178 packages (vkd3d-proton, tar-parallel, DXVK, FFmpeg, Firefox, Heroic, Wine CachyOS) may contain unadopted optimization flags.
- [ ] All 7 packages reviewed; each produces "adopt / skip + reason"; adoptable patterns filed as issues or applied directly
> `diff CFLAGS/CXXFLAGS/cmake args; document measured impact with benchmark source citation`

### T037 · Review FabioLolix/PKGBUILD-AUR_fix for correction patterns
`TODO.md:15` · low · research · S · needs:— · blocks:—
`PKGBUILD-AUR_fix` tracks common AUR correctness issues that may apply to packages in this repo.
- [ ] All relevant open issues filtered by matching `git ls-files ':(glob)**/PKGBUILD'` package names; applicable fixes applied
- [ ] Applied fixes regenerate `.SRCINFO` and pass `pkg.sh lint`; commit messages cite upstream issue URL
> `filter PKGBUILD-AUR_fix issues by pkgname intersection; apply with Fixes: <url> in commit message`

---

## Stats

| Dim      | high | medium | low | S | M  | L | XL | security | bug | feature | perf | refactor | docs | research |
|----------|------|--------|-----|---|----|---|----|----------|-----|---------|------|----------|------|----------|
| Count    | 2    | 16     | 19  | 7 | 20 | 8 | 3  | 1        | 1   | 17      | 8    | 2        | 5    | 3        |
| Tasks    | T013 T014 | T001–T012 T016 T017 T022 T027 | T015 T018–T021 T023–T026 T028–T037 | T001 T002 T020 T035–T037 | T003–T004 T006 T008 T010–T012 T017–T019 T021–T025 T029 T031–T032 | T005 T007 T009 T013–T015 T027 T030 T033 | T016 T028 T034 | T001 | T002 | T003 T007–T014 T016–T017 T025 T027 T030–T034 | T005–T006 T015 T022–T024 T028–T029 | T004 T026 | T018–T021 | T035–T037 |
