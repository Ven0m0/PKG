#!/usr/bin/env bash
set -euo pipefail; shopt -s globstar nullglob; IFS=$'\n\t'
export LC_ALL=C LANG=C

# ═══════════════════════════════════════════════════════════════════════════
# Lint Script - PKGBUILD & Shell Script Quality Enforcement
# ═══════════════════════════════════════════════════════════════════════════

# ─── Helpers ───────────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
err(){ printf '%b\n' "${R}✘ $*${D}" >&2; }
ok(){ printf '%b\n' "${G}✓ $*${D}"; }
warn(){ printf '%b\n' "${Y}⚠ $*${D}" >&2; }
has(){ command -v "$1" &>/dev/null; }

# ─── Main ──────────────────────────────────────────────────────────────────
main(){
  local root="$PWD"
  local -a pkgs errs=()
  local diff_out

  # Discovery (Prioritize fd)
  if has fd; then
    mapfile -t pkgs < <(fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u)
  else
    mapfile -t pkgs < <(find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u)
  fi

  # Tool Availability
  local sc=0 sh=0 sf=0 nc=0
  has shellcheck && sc=1 || warn "shellcheck not found"
  has shellharden && sh=1 || warn "shellharden not found"
  has shfmt && sf=1 || warn "shfmt not found"
  has namcap && nc=1 || warn "namcap not found"

  for pkg in "${pkgs[@]}"; do
    [[ -d "$pkg" ]] || continue
    printf '==> %s\n' "$pkg"
    
    # Context switch
    builtin cd "$pkg" || { errs+=("$pkg: cd failed"); continue; }
    [[ ! -f PKGBUILD ]] && { errs+=("$pkg: no PKGBUILD"); builtin cd "$root"; continue; }

    # ShellCheck: Fix safely (avoid pipefail on clean files)
    if [[ $sc -eq 1 ]]; then
      diff_out=$(shellcheck -x -a -s bash -f diff PKGBUILD 2>/dev/null || true)
      if [[ -n "$diff_out" ]]; then
        if echo "$diff_out" | patch -Np1 --silent 2>/dev/null; then
          warn "$pkg: shellcheck auto-fixed"
        else
          warn "$pkg: shellcheck manual fixes needed"
        fi
      fi
    fi

    # Shellharden
    if [[ $sh -eq 1 ]]; then
      shellharden --replace PKGBUILD &>/dev/null || errs+=("$pkg: shellharden failed")
    fi

    # shfmt
    if [[ $sf -eq 1 ]]; then
      shfmt -ln bash -bn -ci -s -i 2 -w PKGBUILD &>/dev/null || warn "$pkg: shfmt failed"
    fi

    # namcap
    if [[ $nc -eq 1 ]]; then
      namcap PKGBUILD &>/dev/null || warn "$pkg: namcap issues"
    fi

    # .SRCINFO sync
    if [[ -f .SRCINFO ]]; then
      if ! makepkg --printsrcinfo 2>/dev/null | diff -B .SRCINFO - &>/dev/null; then
        errs+=("$pkg: .SRCINFO dirty")
        printf '    Run: makepkg --printsrcinfo > .SRCINFO\n' >&2
      fi
    else
      errs+=("$pkg: missing .SRCINFO")
    fi

    builtin cd "$root"
  done

  if [[ ${#errs[@]} -gt 0 ]]; then
    printf '\n%bFound %s error(s):%b\n' "$R" "${#errs[@]}" "$D" >&2
    printf '  %s\n' "${errs[@]}" >&2
    exit 1
  fi

  ok "All checks passed"
}

main "$@"
