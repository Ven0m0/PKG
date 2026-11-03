#!/usr/bin/env bash
# Pure decision for bump-pkgbuilds.sh: given one drifted package, say what to
# do without touching any file. Needs vercmp (pacman) on PATH and, relative to
# the current directory, <key>/PKGBUILD and ${OLDVER}.
#
#   bump_decide <nvchecker key> <tracked> <latest>
#   prints:  status TAB detail TAB var TAB new
#     agent    - leave untouched; detail says why
#     recorded - only old_ver.json needs the new value
#     bump     - write ${var}=${new}, pkgrel=1, then refresh checksums
# shellcheck enable=all shell=bash

_BUMP_LIB_DIR=${BASH_SOURCE[0]%/*}
# shellcheck source=tools/lib/policy.sh
source "${_BUMP_LIB_DIR}/../../tools/lib/policy.sh"

OLDVER=${OLDVER:-.github/nvchecker/old_ver.json}

_bump_row() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "${3:-}" "${4:-}"; }

bump_decide() {
  local key=$1 tracked=$2 latest=$3
  local pkgbuild="${key}/PKGBUILD" var new cur cmp

  [[ -f ${pkgbuild} ]] || { _bump_row agent "no PKGBUILD at ${pkgbuild}"; return; }
  grep -qF "\"${key}\": " "${OLDVER}" || { _bump_row agent "not tracked in old_ver.json"; return; }
  [[ ${latest} =~ ^[A-Za-z0-9._+-]+$ ]] || { _bump_row agent "unexpected characters in ${latest}"; return; }

  if grep -qE '^\s*pkgver\s*\(\)' "${pkgbuild}"; then
    if grep -q '#tag=' "${pkgbuild}"; then
      _bump_row agent "pkgver() package with a pinned tag"
    else
      _bump_row recorded "pkgver() tracks the git source; PKGBUILD unchanged"
    fi
    return
  fi

  var=$(update_var "${key}")
  if [[ ${var} == _srctag ]]; then new=${latest}; else new=${latest#v}; fi
  # A source pinned to a literal commit or tag does not follow pkgver.
  if [[ ${var} == pkgver ]] && grep -qE '#(commit|tag)=[^$"]' "${pkgbuild}"; then
    _bump_row agent "source pinned to a literal commit or tag"
    return
  fi
  cur=$(pkgbuild_var "${pkgbuild}" "${var}")
  # old_ver.json often lags the PKGBUILD, so compare against the PKGBUILD. A
  # tracked value that is not the PKGBUILD's own version scheme (an update
  # trigger such as intel-ucode-min, chromium's pkgver-commit pair, a
  # "jdk9-b94" or "release-1.37.0" tag) needs the agent: it is ahead of the
  # PKGBUILD or does not start with a digit.
  if [[ ! ${cur} =~ ^[0-9] || ! ${new} =~ ^[0-9] || ! ${tracked#v} =~ ^[0-9] ]] ||
    (($(vercmp "${tracked#v}" "${cur}") > 0)); then
    _bump_row agent "tracked value does not map onto ${var}=${cur}"
    return
  fi
  [[ ${var} == _srctag || ${new} =~ ^[A-Za-z0-9._+]+$ ]] || { _bump_row agent "${new} is not a valid pkgver"; return; }
  cmp=$(vercmp "${new//-/.}" "${cur//-/.}")
  if ((cmp == 0)); then
    _bump_row recorded "PKGBUILD already at ${cur}"
  elif ((cmp < 0)); then
    _bump_row agent "${new} would downgrade ${var}=${cur}"
  else
    _bump_row bump "${var} ${cur} -> ${new}" "${var}" "${new}"
  fi
}
