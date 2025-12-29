# TODO - Project Roadmap

This document tracks planned features, improvements, and long-term goals for the PKG repository.

## High Priority

### Documentation

- [x] **Comprehensive README.md** - Added detailed project overview, quick start, features
- [x] **CONTRIBUTING.md** - Created contribution guidelines and workflow documentation
- [x] **Enhanced SECURITY.md** - Expanded security policy with best practices
- [x] **Package README template** - Created standard template for package documentation
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

- [ ] **Package documentation improvements**
  - [ ] Standardize all package READMEs using template
  - [ ] Add performance benchmarks where applicable
  - [ ] Document build options comprehensively

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

- [ ] **Code quality improvements**
  - [x] Pre-commit hooks setup
  - [x] Automated formatting enforcement (yamlfmt, biome integration)
  - [x] Additional linting rules (enhanced shellcheck, ruff, yamlfmt)

- [ ] **Security enhancements**
  - [x] Automated vulnerability scanning (dependency-review with fail-on-severity)
  - [x] Supply chain verification (dependency-review)
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

## Completed

- [x] **Enhanced README.md** (2025-12-20)
- [x] **Created CONTRIBUTING.md** (2025-12-20)
- [x] **Improved SECURITY.md** (2025-12-20)
- [x] **Package README template** (2025-12-20)
- [x] **Better TODO.md organization** (2025-12-20)
- [x] **Git hooks setup with lefthook** (2025-12-24)
- [x] **Workflow refactoring and optimization** (2025-12-29)
  - Removed irrelevant webpack.yml workflow
  - Enhanced build.yml with multi-arch support, Docker security hardening, input validation
  - Upgraded to latest action versions (arch-pkgbuild-builder@v1.25)
  - Replaced yamllint with yamlfmt and prettier with biome in lint.yml
  - Enhanced dependency-review.yml with security options (fail-on-severity, license controls)
  - Added proper error handling with set -euo pipefail across workflows
  - Removed unsafe apt-get upgrade operations from CI
  - Added Docker operation timeouts and security constraints

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
- [pkgforge-dev/Anylinux-AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages)
- [Frogging-Family](https://github.com/Frogging-Family/community-patches)

### Technical Resources

- [Arch Build System](https://wiki.archlinux.org/title/Arch_Build_System)
- [LLVM BOLT](https://github.com/llvm/llvm-project/tree/main/bolt)
- [GCC Profile-Guided Optimization](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html)
- [Reproducible Builds](https://reproducible-builds.org/)

## Contributing to This TODO

To suggest additions or changes to this roadmap:

1. Open an issue with the `enhancement` or `proposal` label
2. Describe the feature/improvement and its benefits
3. Include implementation details if available
4. Link to related issues or PRs

---

**Last Updated**: 2025-12-24
**Maintainer**: Ven0m0