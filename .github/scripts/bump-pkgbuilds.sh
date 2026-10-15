#!/usr/bin/env bash
# Mechanical version bump for nvchecker drift, so the agent only sees the
# packages that need judgment. Runs inside archlinux:base-devel via arch-run,
# from the repo root:
#   arch-run . 'bash .github/scripts/bump-pkgbuilds.sh <drift.tsv> <results.tsv>'
# drift.tsv lines:   <nvchecker key> TAB <tracked> TAB <latest>
# results.tsv lines: <status> TAB <key> TAB <tracked> TAB <latest> TAB <detail>
#   updated  - PKGBUILD bumped, checksums and .SRCINFO regenerated
#   recorded - only old_ver.json changed (pkgver() package tracking HEAD)
#   agent    - left untouched; needs the agent
set -euo pipefail

drift=${1:?usage: bump-pkgbuilds.sh <drift.tsv> <results.tsv>}
results=${2:?usage: bump-pkgbuilds.sh <drift.tsv> <results.tsv>}
oldver=.github/nvchecker/old_ver.json
log=$(mktemp)
: >"${results}"

# old_ver.json is a flat {"key": "value"} map, one entry per line.
record() {
  local key=${1//./\\.} value=$2
  sed -i "s|^\(\s*\"${key}\": \"\)[^\"]*\"|\1${value}\"|" "${oldver}"
}

bump() {
  local key=$1 tracked=$2 latest=$3
  local pkgbuild="${key}/PKGBUILD" var new cur
  result() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "${key}" "${tracked}" "${latest}" "$2" >>"${results}"; }

  [[ -f ${pkgbuild} ]] || { result agent "no PKGBUILD at ${pkgbuild}"; return; }
  grep -qF "\"${key}\": " "${oldver}" || { result agent "not tracked in old_ver.json"; return; }
  [[ ${latest} =~ ^[A-Za-z0-9._+-]+$ ]] || { result agent "unexpected characters in ${latest}"; return; }

  if grep -qE '^\s*pkgver\s*\(\)' "${pkgbuild}"; then
    if grep -q '#tag=' "${pkgbuild}"; then
      result agent "pkgver() package with a pinned tag"
    else
      record "${key}" "${latest}"
      result recorded "pkgver() tracks the git source; PKGBUILD unchanged"
    fi
    return
  fi

  case ${key} in
    proton-cachyos-slr | wine-cachyos) var=_srctag new=${latest} ;;
    *) var=pkgver new=${latest#v} ;;
  esac
  # A source pinned to a literal commit or tag does not follow pkgver.
  if [[ ${var} == pkgver ]] && grep -qE '#(commit|tag)=[^$"]' "${pkgbuild}"; then
    result agent "source pinned to a literal commit or tag"
    return
  fi
  cur=$(sed -n "s/^${var}=//p" "${pkgbuild}")
  # old_ver.json often lags the PKGBUILD, so compare against the PKGBUILD. A
  # tracked value that is not the PKGBUILD's own version scheme (an update
  # trigger such as intel-ucode-min, chromium's pkgver-commit pair, a
  # "jdk9-b94" or "release-1.37.0" tag) needs the agent: it is ahead of the
  # PKGBUILD or does not start with a digit.
  if [[ ! ${cur} =~ ^[0-9] || ! ${new} =~ ^[0-9] || ! ${tracked#v} =~ ^[0-9] ]] ||
    (($(vercmp "${tracked#v}" "${cur}") > 0)); then
    result agent "tracked value does not map onto ${var}=${cur}"
    return
  fi
  [[ ${var} == _srctag || ${new} =~ ^[A-Za-z0-9._+]+$ ]] || { result agent "${new} is not a valid pkgver"; return; }
  local cmp
  cmp=$(vercmp "${new//-/.}" "${cur//-/.}")
  if ((cmp == 0)); then
    record "${key}" "${latest}"
    result recorded "PKGBUILD already at ${cur}"
    return
  elif ((cmp < 0)); then
    result agent "${new} would downgrade ${var}=${cur}"
    return
  fi

  sed -i -e "s|^${var}=.*|${var}=${new}|" -e 's/^pkgrel=.*/pkgrel=1/' "${pkgbuild}"
  if (cd "${key}" && updpkgsums && { [[ ! -f .SRCINFO ]] || makepkg --printsrcinfo >.SRCINFO; }) >"${log}" 2>&1; then
    record "${key}" "${latest}"
    result updated "${var} ${cur} -> ${new}"
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
