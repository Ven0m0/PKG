🔒 Fix GitHub Actions code execution vulnerability

🎯 **What:**
Removed the `source PKGBUILD` command in `.github/workflows/build.yml` and replaced it with a safe bash string manipulation script to extract package variables directly from the generated package filename.

⚠️ **Risk:**
By sourcing an untrusted arbitrary file (`PKGBUILD`) in the CI environment without a sandbox, a malicious actor or an compromised dependency could exfiltrate secrets and obtain uncontrolled execution within the runner.

🛡️ **Solution:**
The updated logic leverages native string parsing on the built package file (`pkgname-[epoch:]pkgver-pkgrel-arch.pkg.tar.*`). This allows us to securely extract the necessary metadata (package name, version, release) to generate GitHub tags and artifacts without executing potentially malicious code. Tested with epochs and hyphens properly.
