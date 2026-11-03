#!/usr/bin/env bash
# PostToolUse(Edit|Write): lint what was just touched; non-blocking, advisory output only.
set -uo pipefail
f=$(jq -r '.tool_input.file_path // empty')
[[ -n "$f" ]] || exit 0
case "$f" in
*.sh)
  command -v shellcheck >/dev/null && shellcheck "$f"
  command -v shfmt >/dev/null && shfmt -d "$f"
  ;;
*/.github/workflows/*.yml | */.github/actions/*.yml)
  command -v actionlint >/dev/null && actionlint "$f"
  ;;
*/PKGBUILD)
  # Packages listed as `nosrcinfo` in tools/pkg-policy.txt deliberately have none.
  root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null) || exit 0
  # shellcheck source=tools/lib/policy.sh
  source "$root/tools/lib/policy.sh"
  pkg=$(dirname "${f#"$root"/}")
  srcinfo_exempt "$pkg" ||
    echo "PKGBUILD changed: regenerate .SRCINFO (tools/pkg.sh srcinfo, Arch/container only)."
  ;;
esac
exit 0
