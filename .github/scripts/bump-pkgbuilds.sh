#!/usr/bin/env bash
# Mechanical version bump for nvchecker drift, so the agent only sees the
# packages that need judgment. Runs inside archlinux:base-devel via arch-run,
# from the repo root:
#   arch-run . 'bash .github/scripts/bump-pkgbuilds.sh <drift.tsv> <results.tsv>'
# drift.tsv lines:   <nvchecker key> TAB <tracked> TAB <latest>
# results.tsv lines: <status> TAB <key> TAB <tracked> TAB <latest> TAB <detail>
#   updated  - PKGBUILD bumped, checksums and .SRCINFO regenerated
#   recorded - only old_ver.json changes (pkgver() package tracking HEAD)
#   agent    - left untouched; needs the agent
# This script never edits old_ver.json: the caller applies the updated and
# recorded rows with `nvchecker_drift.py record`. The decision itself lives in
# bump-lib.sh; this file only applies it.
set -euo pipefail

drift=${1:?usage: bump-pkgbuilds.sh <drift.tsv> <results.tsv>}
results=${2:?usage: bump-pkgbuilds.sh <drift.tsv> <results.tsv>}
log=$(mktemp)
trap 'rm -f "${log}"' EXIT
: >"${results}"

# shellcheck source=.github/scripts/bump-lib.sh
source "${BASH_SOURCE[0]%/*}/bump-lib.sh"

bump() {
  local key=$1 tracked=$2 latest=$3
  local status detail var new
  result() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "${key}" "${tracked}" "${latest}" "$2" >>"${results}"; }

  IFS=$'\t' read -r status detail var new <<<"$(bump_decide "${key}" "${tracked}" "${latest}")"
  case ${status} in
    agent | recorded)
      result "${status}" "${detail}"
      return
      ;;
  esac

  sed -i -e "s|^${var}=.*|${var}=${new}|" -e 's/^pkgrel=.*/pkgrel=1/' "${key}/PKGBUILD"
  if (cd "${key}" && srcinfo_regenerate "${key}") >"${log}" 2>&1; then
    result updated "${detail}"
  else
    git checkout -- "${key}"
    result agent "updpkgsums/makepkg failed: $(grep -v '^\s*$' "${log}" | tail -n 1 | tr '\t' ' ')"
  fi
  # Drop downloads now so the next package starts with a clean disk.
  rm -rf "${SRCDEST:?}"/*
}

while IFS=$'\t' read -r key tracked latest; do
  if [[ -n ${key} ]]; then
    bump "${key}" "${tracked}" "${latest}"
  fi
done <"${drift}"
