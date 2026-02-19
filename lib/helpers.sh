#!/usr/bin/env bash
# shellcheck enable=all shell=bash
# ═══════════════════════════════════════════════════════════════════════════
# Shared Helper Functions for PKG Repository Scripts
# ═══════════════════════════════════════════════════════════════════════════
# Source this file in other scripts:
#   source "${BASH_SOURCE[0]%/*}/lib/helpers.sh"
# ═══════════════════════════════════════════════════════════════════════════

# Prevent double-sourcing
[[ -n ${_PKG_HELPERS_LOADED:-} ]] && return 0
readonly _PKG_HELPERS_LOADED=1

# ─── Terminal Colors ─────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[34m' D=$'\e[0m'

# ─── Logging Functions ───────────────────────────────────────────────────────
has() { command -v -- "$1" &>/dev/null; }
msg() { printf '%s\n' "$@"; }
log() { printf '%b\n' "${G}➜ $*${D}"; }
err() { printf '%b\n' "${R}✘ $*${D}" >&2; }
warn() { printf '%b\n' "${Y}⚠ $*${D}" >&2; }
ok() { printf '%b\n' "${G}✓ $*${D}"; }
die() { err "$1"; exit "${2:-1}"; }
sep() { msg '────────────────────────────────────────'; }

# ─── Package Discovery ───────────────────────────────────────────────────────
# Find all PKGBUILD directories
# Usage: mapfile -t pkgs < <(find_pkgbuilds)
find_pkgbuilds() {
  if [[ -d .git ]] && command -v git >/dev/null; then
    # O(1) using git index, ~10-100x faster than find/fd
    # Use :(glob) pathspec to match recursively and handle root PKGBUILD
    git ls-files ':(glob)**/PKGBUILD' | sed -e 's|/PKGBUILD$||' -e 's|^PKGBUILD$|.|'
    return
  fi

  if has fd; then
    fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u
  else
    find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u
  fi
}

# ─── Parallel Execution Helper ───────────────────────────────────────────────
# Wait until running jobs are below max_jobs
# Usage: wait_for_jobs "$max_jobs"
wait_for_jobs() {
  local max_jobs=${1:-$(nproc)}
  while [[ $(jobs -rp | wc -l) -ge $max_jobs ]]; do
    # Use wait -n if available to avoid busy polling; ignore exit status here
    wait -n 2>/dev/null || true
  done
}

# ─── Script Directory ────────────────────────────────────────────────────────
# Get the directory of the calling script
# Usage: cd_to_script_dir
cd_to_script_dir() {
  local s=${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}
  [[ $s != /* ]] && s=$PWD/$s
  cd -P -- "${s%/*}" || exit 1
}
