#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}
[[ $s != /* ]] && s=$PWD/$s
cd -P -- "${s%/*}"

# ═══════════════════════════════════════════════════════════════════════════
# SRCINFO Generator - Update .SRCINFO files for all PKGBUILDs
# ═══════════════════════════════════════════════════════════════════════════

# ─── Helpers ───────────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
err() { printf '%b\n' "${R}✘ $*${D}" >&2; }
log() { printf '%b\n' "${G}➜ $*${D}"; }
has() { command -v -- "$1" &>/dev/null; }

# ─── Process Package ──────────────────────────────────────────────────────
process_pkg() {
  local pkg=$1 root=$2

  builtin cd "$pkg" || {
    echo "ERROR:$pkg: cd failed"
    return 1
  }

  updpkgsums 2>/dev/null || {
    echo "ERROR:$pkg: updpkgsums failed"
    builtin cd "$root"
    return 1
  }

  makepkg --printsrcinfo >.SRCINFO 2>/dev/null || {
    echo "ERROR:$pkg: makepkg failed"
    builtin cd "$root"
    return 1
  }

  builtin cd "$root"
  echo "OK:$pkg"
}

# ─── Main ──────────────────────────────────────────────────────────────────
main() {
  local root="$PWD"
  local -a pkgs errs=()
  local max_jobs=${MAX_JOBS:-$(nproc)}
  local parallel=${PARALLEL:-true}

  if has fd; then
    mapfile -t pkgs < <(fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u)
  else
    mapfile -t pkgs < <(find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u)
  fi

  [[ ${#pkgs[@]} -eq 0 ]] && {
    err "No PKGBUILDs found"
    exit 1
  }

  log "Processing ${#pkgs[@]} package(s) [parallel=$parallel, max_jobs=$max_jobs]"

  if [[ $parallel == true ]]; then
    local -a pids=()
    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    for pkg in "${pkgs[@]}"; do
      [[ ! -d $pkg ]] && continue

      # Wait if we've hit max jobs
      while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
        sleep 0.1
      done

      (process_pkg "$pkg" "$root" >"$tmpdir/$pkg.log" 2>&1) &
      pids+=($!)
    done

    # Wait for all jobs
    for pid in "${pids[@]}"; do
      wait "$pid" || true
    done

    # Collect results
    for logfile in "$tmpdir"/*.log; do
      [[ -f $logfile ]] || continue
      while IFS= read -r line; do
        case $line in
        OK:*)
          log "${line#OK:}"
          ;;
        ERROR:*)
          errs+=("${line#ERROR:}")
          err "${line#ERROR:}"
          ;;
        esac
      done <"$logfile"
    done
  else
    # Serial execution
    for pkg in "${pkgs[@]}"; do
      [[ ! -d $pkg ]] && continue

      local output
      output=$(process_pkg "$pkg" "$root" 2>&1)
      while IFS= read -r line; do
        case $line in
        OK:*)
          log "${line#OK:}"
          ;;
        ERROR:*)
          errs+=("${line#ERROR:}")
          err "${line#ERROR:}"
          ;;
        esac
      done <<<"$output"
    done
  fi

  if [[ ${#errs[@]} -gt 0 ]]; then
    err "Failed to process ${#errs[@]} package(s)"
    exit 1
  fi

  log "Done"
}

main "$@"
