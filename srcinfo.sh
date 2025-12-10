#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}; [[ $s != /* ]] && s=$PWD/$s; cd -P -- "${s%/*}"

# ═══════════════════════════════════════════════════════════════════════════
# SRCINFO Generator - Update .SRCINFO files for all PKGBUILDs
# ═══════════════════════════════════════════════════════════════════════════

# ─── Helpers ───────────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
err(){ printf '%b\n' "${R}✘ $*${D}" >&2; }
log(){ printf '%b\n' "${G}➜ $*${D}"; }
has(){ command -v -- "$1" &>/dev/null; }

# ─── Main ──────────────────────────────────────────────────────────────────
main(){
  local root="$PWD"
  local -a pkgs

  if has fd; then
    mapfile -t pkgs < <(fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u)
  else
    mapfile -t pkgs < <(find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u)
  fi

  [[ ${#pkgs[@]} -eq 0 ]] && { err "No PKGBUILDs found"; exit 1; }

  for pkg in "${pkgs[@]}"; do
    [[ ! -d $pkg ]] && continue
    log "Processing $pkg"
    builtin cd "$pkg" || { err "$pkg: cd failed"; builtin cd "$root"; continue; }

    updpkgsums 2>/dev/null || { err "$pkg: updpkgsums failed"; builtin cd "$root"; continue; }
    makepkg --printsrcinfo > .SRCINFO 2>/dev/null || { err "$pkg: makepkg failed"; builtin cd "$root"; continue; }

    builtin cd "$root"
  done

  log "Done"
}

main "$@"
