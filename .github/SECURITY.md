# Security Policy

## Overview

Security is a top priority for this repository. This document outlines our security practices, supported versions, and the process for reporting vulnerabilities.

## Supported Versions

This repository contains PKGBUILDs for Arch Linux packages. Security updates are provided for the latest version of each package.

| Component | Supported Versions | Notes |
|-----------|-------------------|-------|
| All PKGBUILDs | Latest version only | Follow upstream security updates |
| Build scripts (build.sh, lint.sh, etc.) | Latest commit on main branch | Critical fixes backported if needed |
| CI/CD workflows | Latest version | Automated security updates via Dependabot |
| Documentation | Latest version | Security-related docs updated promptly |

### Version Support Policy

- **PKGBUILDs**: We track the latest upstream versions. When upstream releases security updates, we update our PKGBUILDs accordingly.
- **Build Infrastructure**: Security patches for build scripts and workflows are applied to the main branch only.
- **Dependencies**: External dependencies are updated regularly through automated and manual reviews.

## Security Best Practices

### For Package Maintainers

When creating or updating PKGBUILDs, follow these security guidelines:

#### 1. Source Verification

```bash
# ✅ DO: Use HTTPS for all sources
source=("https://github.com/user/repo/archive/v${pkgver}.tar.gz")

# ❌ DON'T: Use HTTP (vulnerable to MITM attacks)
source=("http://insecure-site.com/package.tar.gz")

# ✅ DO: Verify checksums
sha256sums=('actual_checksum_here')

# ❌ DON'T: Skip verification
sha256sums=('SKIP')  # Only acceptable for local patches
```

#### 2. GPG Signature Verification

When upstream provides GPG signatures:

```bash
validpgpkeys=('FULL_40_CHARACTER_FINGERPRINT')
source=("${url}/package-${pkgver}.tar.gz"
        "${url}/package-${pkgver}.tar.gz.sig")
sha256sums=('checksum'
            'SKIP')
```

#### 3. Patch Security

```bash
# Review all patches before applying
prepare() {
  cd "${srcdir}/${pkgname}-${pkgver}"

  # Document what each patch does
  # Patch from upstream fixing CVE-2024-XXXX
  patch -Np1 -i ../0001-security-fix.patch

  # Never apply untrusted patches
  # Always review patch contents
}
```

#### 4. Build Security Flags

```bash
# Enable security hardening
export CFLAGS="$CFLAGS -fstack-protector-strong"
export CFLAGS="$CFLAGS -fstack-clash-protection"
export CFLAGS="$CFLAGS -D_FORTIFY_SOURCE=2"

# Enable security-focused linker flags
export LDFLAGS="-Wl,-z,relro,-z,now"  # Full RELRO
export LDFLAGS="$LDFLAGS -Wl,-z,noexecstack"  # Non-executable stack
```

#### 5. Avoid Common Vulnerabilities

```bash
# ❌ DON'T: Execute remote code without verification
curl https://example.com/install.sh | bash

# ✅ DO: Download, verify, then execute
source=("https://example.com/install.sh::${url}/install.sh")
sha256sums=('verified_checksum')

# ❌ DON'T: Use eval with user input
eval "$user_input"

# ✅ DO: Validate and sanitize inputs
if [[ "$var" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  # Safe to use
fi
```

#### 6. Dependency Security

```bash
# Keep dependencies minimal
depends=('essential-lib1' 'essential-lib2')

# Document why each dependency is needed
# lib1: Required for feature X
# lib2: Security-critical crypto functions

# Specify version constraints when security-critical
depends=('openssl>=3.0.0')  # Requires specific version
```

### For Build Script Authors

#### Shell Script Security

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Safe word splitting

# Use absolute paths or validate
readonly WORK_DIR="${PWD}"
cd "${WORK_DIR}" || exit 1

# Quote all variables
echo "${variable}"  # ✅
echo $variable      # ❌

# Validate input
if [[ -n "${1:-}" ]] && [[ -d "$1" ]]; then
  process_directory "$1"
fi
```

#### Avoiding Command Injection

```bash
# ❌ DON'T: Use variables in commands without quotes
rm -rf $dir/*

# ✅ DO: Quote variables and validate
if [[ -d "${dir}" ]]; then
  rm -rf "${dir:?}"/*  # :? prevents deletion if empty
fi

# ✅ DO: Use arrays for complex commands
cmd=(makepkg -s --noconfirm)
"${cmd[@]}"
```

## Reporting a Vulnerability

### Scope

We accept vulnerability reports for:

- **PKGBUILDs**: Insecure build practices, malicious code, supply chain risks
- **Build scripts**: Command injection, path traversal, privilege escalation
- **CI/CD workflows**: Workflow injection, secret exposure, unauthorized access
- **Dependencies**: Known vulnerabilities in build dependencies

### Out of Scope

- Vulnerabilities in **upstream software** (report to upstream project)
- **Theoretical attacks** without proof of concept
- **Social engineering** attacks
- **Denial of service** attacks on public infrastructure

### How to Report

If you discover a security vulnerability:

#### 1. Private Disclosure (Preferred)

Use GitHub's private vulnerability reporting:

1. Go to the **Security** tab
2. Click **Report a vulnerability**
3. Fill out the vulnerability details
4. Submit the report

#### 2. Email Disclosure

Send an email to the maintainer with:

- **Subject**: `[SECURITY] Brief description`
- **Affected component**: PKGBUILD name or script
- **Vulnerability type**: Injection, XSS, etc.
- **Impact assessment**: What can an attacker do?
- **Reproduction steps**: Detailed steps to reproduce
- **Proof of concept**: Code or commands demonstrating the issue
- **Suggested fix**: If you have a patch or solution

#### 3. What NOT to Do

- ❌ **Do not** open a public issue
- ❌ **Do not** disclose the vulnerability publicly before we've had time to fix it
- ❌ **Do not** exploit the vulnerability beyond proof-of-concept testing

### Response Timeline

We commit to the following response times:

| Action | Timeline |
|--------|----------|
| **Initial response** | Within 48 hours |
| **Vulnerability confirmation** | Within 5 business days |
| **Fix development** | Depends on severity (see below) |
| **Public disclosure** | After fix is released + 7 days |

### Severity Levels

| Severity | Description | Fix Timeline | Examples |
|----------|-------------|--------------|----------|
| **Critical** | Remote code execution, privilege escalation | 24-48 hours | Arbitrary command execution in build script |
| **High** | Significant security impact | 1 week | Source verification bypass, checksum skipping |
| **Medium** | Moderate security impact | 2-4 weeks | Insecure defaults, weak cryptography |
| **Low** | Minor security concern | 4-8 weeks | Information disclosure, deprecated functions |

### Coordinated Disclosure

We follow **responsible disclosure** practices:

1. **Reporter notifies us** privately
2. **We confirm** the vulnerability
3. **We develop and test** a fix
4. **We release** the fix publicly
5. **We coordinate disclosure** with the reporter
6. **Public disclosure** occurs after fix is widely available

We credit reporters in:
- Release notes
- Security advisories
- Acknowledgments section (if desired)

## Security Advisories

Published security advisories can be found:

- **GitHub Security Advisories**: [View advisories](https://github.com/Ven0m0/PKG/security/advisories)
- **Release Notes**: Major security fixes noted in releases
- **CHANGELOG**: Security-related changes documented

## Security Updates

### Staying Informed

To stay informed about security updates:

1. **Watch this repository** (Settings → Watch → Custom → Security alerts)
2. **Enable GitHub Security Alerts** for your fork
3. **Subscribe to releases** for update notifications
4. **Follow Dependabot PRs** for dependency updates

### Applying Security Updates

When security updates are released:

```bash
# Update your local repository
git fetch upstream
git merge upstream/main

# For affected packages
cd affected-package
makepkg -srC  # Clean rebuild
sudo pacman -U *.pkg.tar.zst
```

## Dependencies and Supply Chain

### Dependency Management

- **Automated scanning**: Dependabot monitors dependencies
- **Regular updates**: Dependencies updated monthly or on security releases
- **Minimal dependencies**: Only essential dependencies included
- **Trusted sources**: Dependencies from official Arch repos or verified sources

### Build Environment Security

- **Isolated builds**: Docker containers for complex packages
- **Minimal images**: Base images kept minimal and updated
- **No network during build**: Builds don't require network access after source fetch
- **Reproducible builds**: Deterministic build process where possible

## Secure Development Practices

### Code Review

All changes undergo:

1. **Automated linting**: shellcheck, shfmt, namcap
2. **CI/CD validation**: Build testing, security scanning
3. **Manual review**: Maintainer code review
4. **Security-focused review**: For sensitive changes

### Access Control

- **Two-factor authentication**: Required for maintainers
- **Signed commits**: Encouraged for all contributors
- **Branch protection**: Main branch requires reviews
- **Least privilege**: Minimal permissions for CI/CD

### Audit Trail

- **Git history**: Complete audit trail of changes
- **Signed releases**: Tags signed by maintainers
- **CI/CD logs**: Build logs retained for audit

## Incident Response

In case of a security incident:

1. **Containment**: Immediately remove vulnerable code
2. **Assessment**: Determine impact and affected versions
3. **Notification**: Inform affected users via security advisory
4. **Remediation**: Release fixed version
5. **Post-mortem**: Document lessons learned

## Security Tools

We use these tools for security:

- **shellcheck**: Static analysis for shell scripts
- **namcap**: PKGBUILD security checks
- **Dependabot**: Automated dependency updates
- **MegaLinter**: Multi-language security linting
- **GitHub Security Scanning**: Automated vulnerability detection

## Additional Resources

### Arch Linux Security

- [Arch Security Team](https://security.archlinux.org/)
- [Arch Security Tracker](https://security.archlinux.org/tracker)
- [Package Signing](https://wiki.archlinux.org/title/Pacman/Package_signing)

### General Security

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Vulnerability Database](https://nvd.nist.gov/)

## Contact

For security-related questions:

- **Security issues**: Use private vulnerability reporting
- **Security questions**: Open a discussion (not for vulnerabilities)
- **General contact**: See repository README

---

**Last Updated**: 2025-12-20
**Policy Version**: 1.0
