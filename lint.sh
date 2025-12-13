#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s globstar nullglob
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}
[[ $s != /* ]] && s=$PWD/$s
cd -P -- "${s%/*}"

# ═══════════════════════════════════════════════════════════════════════════
# Lint Script - PKGBUILD & Shell Script Quality Enforcement
# ═══════════════════════════════════════════════════════════════════════════

# ─── Helpers ───────────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
err() { printf '%b\n' "${R}✘ $*${D}" >&2; }
ok() { printf '%b\n' "${G}✓ $*${D}"; }
warn() { printf '%b\n' "${Y}⚠ $*${D}" >&2; }
has() { command -v -- "$1" &>/dev/null; }

# ─── Lint Package ─────────────────────────────────────────────────────────
lint_pkg() {
  local pkg=$1 root=$2 sc=$3 sh=$4 sf=$5 nc=$6
  local -a errs=() warnings=()
  local diff_out

  builtin cd "$pkg" || {
    echo "ERROR:$pkg: cd failed"
    return 1
  }

  [[ ! -f PKGBUILD ]] && {
    echo "ERROR:$pkg: no PKGBUILD"
    builtin cd "$root"
    return 1
  }

  if [[ $sc -eq 1 ]]; then
    diff_out=$(shellcheck -x -a -s bash -f diff PKGBUILD 2>/dev/null || true)
    if [[ -n $diff_out ]]; then
      if printf '%s\n' "$diff_out" | patch -Np1 --silent 2>/dev/null; then
        echo "WARN:$pkg: shellcheck auto-fixed"
      else
        echo "WARN:$pkg: shellcheck manual fixes needed"
      fi
    fi
  fi

  [[ $sh -eq 1 ]] && { shellharden --replace PKGBUILD &>/dev/null || echo "ERROR:$pkg: shellharden failed"; }
  [[ $sf -eq 1 ]] && { shfmt -ln bash -bn -ci -s -i 2 -w PKGBUILD &>/dev/null || echo "WARN:$pkg: shfmt failed"; }
  [[ $nc -eq 1 ]] && { namcap PKGBUILD &>/dev/null || echo "WARN:$pkg: namcap issues"; }

  if [[ -f .SRCINFO ]]; then
    makepkg --printsrcinfo 2>/dev/null | diff -B .SRCINFO - &>/dev/null || {
      echo "ERROR:$pkg: .SRCINFO dirty"
      echo "INFO:    Run: makepkg --printsrcinfo > .SRCINFO"
    }
  else
    echo "ERROR:$pkg: missing .SRCINFO"
  fi

  builtin cd "$root"
}

handle_output() {
  while IFS= read -r line; do
    case $line in
    ERROR:*)
      errs+=("${line#ERROR:}")
      err "${line#ERROR:}"
      ;;
    WARN:*)
      warn "${line#WARN:}"
      ;;
    INFO:*)
      printf '  %s\n' "${line#INFO:}" >&2
      ;;
    esac
  done
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

  local sc=0 sh=0 sf=0 nc=0
  has shellcheck && sc=1 || warn "shellcheck not found"
  has shellharden && sh=1 || warn "shellharden not found"
  has shfmt && sf=1 || warn "shfmt not found"
  has namcap && nc=1 || warn "namcap not found"

  [[ ${#pkgs[@]} -eq 0 ]] && {
    err "No PKGBUILDs found"
    exit 1
  }

  printf 'Linting %d package(s) [parallel=%s, max_jobs=%d]\n' "${#pkgs[@]}" "$parallel" "$max_jobs"

  if [[ $parallel == true ]]; then
    local -a pids=()
    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    for pkg in "${pkgs[@]}"; do
      [[ -d $pkg ]] || continue

      # Wait if we've hit max jobs
      while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
        sleep 0.1
      done

      printf '==> %s\n' "$pkg"
      (lint_pkg "$pkg" "$root" "$sc" "$sh" "$sf" "$nc" >"$tmpdir/$pkg.log" 2>&1) &
      pids+=($!)
    done

    # Wait for all jobs
    for pid in "${pids[@]}"; do
      wait "$pid" || true
    done

    # Collect results
    for logfile in "$tmpdir"/*.log; do
      [[ -f $logfile ]] || continue
      handle_output <"$logfile"
    done
  else
    # Serial execution
    for pkg in "${pkgs[@]}"; do
      [[ -d $pkg ]] || continue
      printf '==> %s\n' "$pkg"

      local output
      output=$(lint_pkg "$pkg" "$root" "$sc" "$sh" "$sf" "$nc" 2>&1)
      handle_output <<<"$output"
    done
  fi

  if [[ ${#errs[@]} -gt 0 ]]; then
    printf '\n%bFound %s error(s)%b\n' "$R" "${#errs[@]}" "$D" >&2
    exit 1
  fi
  ok "All checks passed"
}

main "$@"
