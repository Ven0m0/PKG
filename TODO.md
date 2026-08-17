# TODO - Project Roadmap

This document tracks planned features, improvements, and long-term goals for the PKG repository.

## High Priority

### Fix packages

- [x] move @.mise/tasks/ into @mise.toml — tasks are now inline `[tasks.*]` entries in `mise.toml`; the now-redundant `.mise/tasks/` script files still need to be deleted by hand (the agent sandbox that did this migration couldn't get permission to delete pre-existing files)
- [x] add "https://github.com/Ven0m0/steelseriesgg-rs as a package — added as `steelseriesgg-rs/` (pkgname `ssgg`), tracked in `nvchecker.toml`/`old_ver.json`; `sha256sums` is still `SKIP` and `.SRCINFO` is not generated because this sandbox has no `makepkg`/working Docker daemon and no direct network access to `codeload.github.com` — run `updpkgsums && makepkg --printsrcinfo > .SRCINFO` on an Arch host
- [x] ensure @.gitattributes allows for cloning and working with this repo on windowd without breaking lf — added explicit `text eol=lf` rules for `.install`, `.hook`, `.timer`, `.desktop`, `.diff`, `.vdf`, `.template`, `.wow64`, and `.patch`/`.gitmodules` so they don't depend solely on `text=auto` autodetection
- [x] `check-updates.yml` still calls the Kilo CLI; decide whether it follows `_run-agent.yml` in dropping it — dropped: the Kilo install step used `curl | bash`, which `AGENTS.md`'s safety rules forbid, and PR creation/agent-driven fixes for package updates are already the job of `_update-pkgbuilds.yml` via `_run-agent.yml`
- [ ] Generate `vscodium-prod-patcher/.SRCINFO` on an Arch host (needs a real clone for `pkgver()`) — confirmed `old_ver.json`'s tracked commit (`e60af1d...`) is current via a real clone; still needs `makepkg` on an Arch host to regenerate `.SRCINFO` itself, unavailable in this sandbox

### External references to review

- [ ] Implement build workflows inspired by [loathingKernel/PKGBUILDs](https://github.com/loathingKernel/PKGBUILDs)
- [ ] Review [John-CPP/ABS](https://github.com/John-CPP/ABS)
- [ ] Review [ms178/archpkgbuilds](https://github.com/ms178/archpkgbuilds)
- [ ] Review [Terromur/PKGBUILDs](https://github.com/Terromur/PKGBUILDs)
- [ ] Review [ms178 vkd3d-proton-mingw-git](https://github.com/ms178/archpkgbuilds/tree/main/packages/vkd3d-proton-mingw-git)
- [ ] Review [ms178 tar-parallel](https://github.com/ms178/archpkgbuilds/tree/main/packages/tar-parallel)
- [ ] Review [FabioLolix/PKGBUILD-AUR_fix](https://github.com/FabioLolix/PKGBUILD-AUR_fix)

### Documentation

- [ ] **Build system documentation** - Detailed guide for build.sh and Docker builds
- [ ] **Optimization guide** - Best practices for optimizing PKGBUILDs
- [ ] **Troubleshooting guide** - Common issues and solutions

### Infrastructure

- [ ] **Automated testing framework** - Test packages in clean chroot environments
- [ ] **Binary repository** - Host pre-built packages for easy installation
- [ ] **Package version tracking** - Automated upstream version checking
- [ ] **Notification system** - Alert on security updates and new versions

## Medium Priority

### Package Improvements

- [ ] **Add more optimized PKGBUILDs**
 - [ ] Python (PGO-optimized build)
 - [ ] GCC (optimized bootstrap)
 - [ ] Node.js (with custom V8 flags)
 - [ ] PostgreSQL (with JIT and optimizations)
 - [ ] Nginx (with custom modules)

- [ ] **Enhance existing packages**
  - [ ] Firefox: BOLT optimization refinement
  - [ ] Chromium: Update to latest patches
  - [ ] Mesa: Latest upstream features
  - [ ] LLVM: PGO instrumentation
  - [ ] gitoxide: Fix optimize.patch to be valid
  - [ ] varia: Create PKGBUILD from make-appimage.sh

- [ ] **Package-specific follow-ups**
  - [ ] DXVK: review [dxvk-mingw-git](https://github.com/ms178/archpkgbuilds/tree/main/packages/dxvk-mingw-git)
  - [ ] DXVK: review [dxvk-pure-clang-git](https://github.com/Terromur/PKGBUILDs/tree/main/dxvk-pure-clang-git)
  - [ ] FFmpeg: review [ms178 ffmpeg PKGBUILD](https://github.com/ms178/archpkgbuilds/tree/main/packages/ffmpeg)
  - [ ] Firefox: review features and patches from [DarkFox](https://github.com/compiledkernel-idk/DarkFox)
  - [ ] Firefox: review updates from [CachyOS firefox-wayland-cachy-hg](https://github.com/CachyOS/firefox-wayland-cachy-hg)
  - [ ] Heroic Games Launcher: review [ms178 heroic-games-launcher PKGBUILD](https://github.com/ms178/archpkgbuilds/blob/main/packages/heroic-games-launcher/PKGBUILD)
  - [ ] Wine CachyOS: review [ms178 wine-cachyos](https://github.com/ms178/archpkgbuilds/tree/main/packages/wine-cachyos)

- [ ] **AppImage integration research**
 - [ ] [Citron AppImage](https://github.com/pkgforge-dev/Citron-AppImage)
 - [ ] [Azahar AppImage Enhanced](https://github.com/pkgforge-dev/Azahar-AppImage-Enhanced)

- [ ] **Package documentation improvements**
 - [ ] Standardize all package READMEs using template
 - [ ] Add performance benchmarks where applicable
 - [ ] Document build options thoroughly

### Build System

- [ ] **Enhanced caching**
 - [ ] Distributed ccache/sccache setup
 - [ ] PGO profile caching and reuse
 - [ ] Source tarball caching

- [ ] **Build optimization**
 - [ ] Parallel package builds
 - [ ] Build dependency graph generation
 - [ ] Incremental build support

- [ ] **Docker improvements**
 - [ ] Multi-stage Docker builds
 - [ ] Smaller base images
 - [ ] Layer optimization

### Quality Assurance

- [ ] **Automated package testing**
 - [ ] Basic functionality tests
 - [ ] Integration tests for complex packages
 - [ ] Performance regression testing

- [ ] **Security enhancements**
 - [ ] Reproducible builds

## Low Priority / Long-term

### Cross-Platform Support

- [ ] **[AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages)**
 - [ ] Research AppImage integration
 - [ ] Create AppImage build pipeline
 - [ ] Compatibility testing (Arch, Debian, Termux)
 - [ ] Documentation for AppImage creation

- [ ] **Container images**
 - [ ] OCI/Docker images from PKGBUILDs
 - [ ] Automated image building
 - [ ] Image registry setup

### Patch Management

- [ ] **[TKG patches integration](https://github.com/Frogging-Family/community-patches)**
 - [ ] Implement autofetch for community patches
 - [ ] Patch compatibility testing
 - [ ] Automated patch updating
 - [ ] User-selectable patch sets

- [ ] **Custom patch repository**
 - [ ] Centralized patch management
 - [ ] Patch versioning and tracking
 - [ ] Automated patch application testing

### Debloating Project

- [ ] **[Archlinux-pkgs-debloated](https://github.com/Ven0m0/archlinux-pkgs-debloated)**
 - [ ] Define debloating criteria
 - [ ] Identify common bloat patterns
 - [ ] Create debloated variants
 - [ ] Document removed features

### Advanced Optimizations

- [ ] **Profile-Guided Optimization (PGO)**
 - [ ] Automated PGO profile generation
 - [ ] Profile sharing infrastructure
 - [ ] Workload-specific profiles

- [ ] **BOLT optimization**
 - [ ] Expand BOLT to more packages
 - [ ] BOLT profile optimization
 - [ ] Performance measurement framework

- [ ] **Architecture-specific builds**
 - [ ] x86-64-v2, v3, v4 variants
 - [ ] ARM64 support
 - [ ] RISC-V experimental builds

### Community Features

- [ ] **Package request system**
 - [ ] Template for package requests
 - [ ] Prioritization mechanism
 - [ ] Community voting

- [ ] **Build farm**
 - [ ] Distributed build infrastructure
 - [ ] Community-contributed builders
 - [ ] Build status dashboard

- [ ] **Package adoption program**
 - [ ] Guidelines for package maintainers
 - [ ] Co-maintainer system
 - [ ] Maintainer documentation

### Automation

- [ ] **CI/CD enhancements**
 - [x] Multi-architecture builds (arm64 support enabled)
 - [x] Enhanced Docker security (capability dropping, no-new-privileges)
 - [x] Input validation for workflow_dispatch
 - [x] Optimized caching strategies
 - [ ] Automated package updates
 - [ ] Upstream monitoring
 - [ ] Changelog generation
 - [ ] Release automation

- [ ] **Bot integration**
 - [ ] Automated issue triage
 - [ ] PR auto-review for common issues
 - [ ] Dependency update automation

- [ ] **Metrics and monitoring**
 - [ ] Build time tracking
 - [ ] Success rate monitoring
 - [ ] Popular package analytics

## Ideas / Research

These are ideas that need more research before committing:

- **Multi-distribution support**: Beyond Arch, support other distros
- **Flatpak integration**: Compile packages as Flatpaks
- **WebAssembly builds**: Experimental WASM compilation
- **GPU-accelerated builds**: Use GPU for certain build tasks
- **Machine learning optimizations**: ML-guided optimization selection
- **Blockchain verification**: Decentralized package verification (research only)

## References

### Projects

- [pkgforge-dev/Anylinux-AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages) - Cross-distro AppImages
- [Frogging-Family/community-patches](https://github.com/Frogging-Family/community-patches) - Community patch repository
- [CachyOS-PKGBUILDS](https://github.com/CachyOS/CachyOS-PKGBUILDS) - Inspiration for optimizations
- [lseman's PKGBUILDs](https://github.com/lseman/PKGBUILDs) - PGO examples

### Technical Resources

- [Arch Build System](https://wiki.archlinux.org/title/Arch_Build_System)
- [LLVM BOLT](https://github.com/llvm/llvm-project/tree/main/bolt)
- [GCC Profile-Guided Optimization](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html)
- [Reproducible Builds](https://reproducible-builds.org/)

---

**Last Updated**: 2026-01-01
**Maintainer**: Ven0m0
