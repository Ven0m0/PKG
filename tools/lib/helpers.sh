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
info() { printf '%b\n' "${B}ℹ $*${D}"; }
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

# ─── Parallel/Serial Batch Execution Helper ──────────────────────────────────
# Run tasks in batch (parallel or serial) for list of directories
# Usage: run_task_batch "$parallel" "$max_jobs" "handler_func" "errs_var" "items_var" "pre_task_func" "processor_func"
run_task_batch() {
  local parallel=$1 max_jobs=$2 handler=$3 errs_var=$4 items_var=$5 pre_task=$6 processor=$7
  local -n items_ref=$items_var

  if [[ $parallel == true ]]; then
    local -a pids=()
    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN

    for item in "${items_ref[@]}"; do
      [[ -d "$item" ]] || continue

      wait_for_jobs "$max_jobs"

      if [[ -n $pre_task ]]; then "$pre_task" "$item"; fi

      ("$processor" "$item" >"$tmpdir/job_${item//\//_}.log" 2>&1) &
      pids+=($!)
    done

    for pid in "${pids[@]}"; do wait "$pid" || true; done

    for logfile in "$tmpdir"/job_*.log; do
      [[ -f $logfile ]] || continue
      "$handler" "$errs_var" <"$logfile"
    done
  else
    for item in "${items_ref[@]}"; do
      [[ -d "$item" ]] || continue

      if [[ -n $pre_task ]]; then "$pre_task" "$item"; fi

      local output
      output=$("$processor" "$item" 2>&1)
      "$handler" "$errs_var" <<<"$output"
    done
  fi
}

# ─── Repository Root ─────────────────────────────────────────────────────────
# cd to the repository root so package discovery and relative paths resolve the
# same way regardless of where the entry-point script lives or is invoked from.
# Usage: cd_to_repo_root
cd_to_repo_root() {
  local root
  if root=$(git rev-parse --show-toplevel 2>/dev/null) && [[ -n $root ]]; then
    cd -- "$root" || exit 1
  else
    # Fallback: this file lives at <root>/tools/lib/helpers.sh
    cd -P -- "${BASH_SOURCE[0]%/*}/../.." || exit 1
  fi
}
