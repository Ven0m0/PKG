#!/usr/bin/env bash
# shellcheck enable=all shell=bash
# Per-package rules and PKGBUILD/.SRCINFO primitives shared by tools/pkg.sh,
# the bump script and the editor hooks. The data lives in tools/pkg-policy.txt;
# this file is its only shell reader.
#   source "${BASH_SOURCE[0]%/*}/lib/policy.sh"

[[ -n ${_PKG_POLICY_LOADED:-} ]] && return 0
readonly _PKG_POLICY_LOADED=1

# Absolute, because callers cd into package directories before asking.
_policy_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG_POLICY_FILE=${PKG_POLICY_FILE:-${_policy_dir}/../pkg-policy.txt}

# policy_has <kind> <name>: succeeds when the policy has "<kind> <name>".
policy_has() {
  awk -v k="$1" -v n="$2" '$1 == k && $2 == n { f = 1 } END { exit !f }' "${PKG_POLICY_FILE}"
}

# srcinfo_exempt <package-dir>: the package ships without .SRCINFO on purpose.
srcinfo_exempt() { policy_has nosrcinfo "$1"; }

# update_var <package-dir>: the PKGBUILD variable a version bump writes.
update_var() {
  if policy_has srctag "$1"; then printf '_srctag\n'; else printf 'pkgver\n'; fi
}

# filter_pkg_dirs: read directories on stdin, drop any with a path component
# listed as `skipdir`. This is the single definition of "what is a package".
filter_pkg_dirs() {
  awk 'NR == FNR { if ($1 == "skipdir") s[$2] = 1; next }
       { n = split($0, p, "/"); for (i = 1; i <= n; i++) if (p[i] in s) next; print }' \
    "${PKG_POLICY_FILE}" -
}

# pkgbuild_var <PKGBUILD> <var>: the value makepkg would see. The file is
# sourced in a subshell, so quoting and ${_srctag//-/.} are already expanded.
# Prints nothing when the variable is unset or the file does not source.
pkgbuild_var() {
  (
    set +eu
    cd -- "$(dirname -- "$1")" 2>/dev/null || exit 0
    # shellcheck disable=SC1090
    source "./$(basename -- "$1")" >/dev/null 2>&1
    printf '%s' "${!2-}"
  )
}

# srcinfo_regenerate: in a package directory named $1, refresh checksums and
# .SRCINFO. Exempt packages get checksums only, never a .SRCINFO.
srcinfo_regenerate() {
  updpkgsums || return
  if srcinfo_exempt "$1"; then return 0; fi
  makepkg --printsrcinfo >.SRCINFO
}

# srcinfo_current: in a package directory, .SRCINFO matches PKGBUILD byte for
# byte (the same rule as the pkgbuild action).
srcinfo_current() {
  [[ -f .SRCINFO ]] && makepkg --printsrcinfo 2>/dev/null | cmp -s .SRCINFO -
}
