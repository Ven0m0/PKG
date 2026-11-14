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
# Packages bump in parallel (max 4 at once): updpkgsums is mostly network-bound
# downloading. 4 keeps the sources within the runner's disk (run 38054504314).
# Row order in results.tsv therefore varies; the output is sorted at the end.
set -euo pipefail

drift=${1:?usage: bump-pkgbuilds.sh <drift.tsv> <results.tsv>}
results=${2:?usage: bump-pkgbuilds.sh <drift.tsv> <results.tsv>}
: >"${results}"

# shellcheck source=.github/scripts/bump-lib.sh
source "${BASH_SOURCE[0]%/*}/bump-lib.sh"

bump() {
  local key=$1 tracked=$2 latest=$3
  local status detail var new log srcdest
  result() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "${key}" "${tracked}" "${latest}" "$2" >>"${results}"; }

  IFS=$'\t' read -r status detail var new <<<"$(bump_decide "${key}" "${tracked}" "${latest}")"
  case ${status} in
    agent | recorded)
      result "${status}" "${detail}"
      return
      ;;
  esac

  sed -i -e "s|^${var}=.*|${var}=${new}|" -e 's/^pkgrel=.*/pkgrel=1/' "${key}/PKGBUILD"
  # Per-call scratch: concurrent bumps must not share a log or a download dir.
  log=$(mktemp)
  srcdest=$(mktemp -d)
  if (cd "${key}" && SRCDEST=${srcdest} srcinfo_regenerate "${key}") >"${log}" 2>&1; then
    result updated "${detail}"
  else
    # No git checkout here: it takes the index lock. Dirs are restored after wait.
    result agent "updpkgsums/makepkg failed: $(grep -v '^\s*$' "${log}" | tail -n 1 | tr '\t' ' ')"
  fi
  rm -rf "${srcdest}" "${log}"
}

while IFS=$'\t' read -r key tracked latest; do
  if [[ -n ${key} ]]; then
    if (($(jobs -rp | wc -l) >= 4)); then wait -n; fi
    bump "${key}" "${tracked}" "${latest}" &
  fi
done <"${drift}"
wait

# Restore failed packages once, serially. Rows from bump_decide never touched
# files, so restoring them is a no-op.
awk -F'\t' '$1=="agent"{print $2}' "${results}" | xargs -r git checkout --
sort -o "${results}" "${results}"
