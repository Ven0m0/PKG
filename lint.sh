#!/usr/bin/env bash
set -euo pipefail; shopt -s globstar nullglob
IFS=$'\n\t'
export LC_ALL=C LANG=C
# ═══════════════════════════════════════════════════════════════════════════
# Lint Script - PKGBUILD & Shell Script Quality Enforcement
# ═══════════════════════════════════════════════════════════════════════════
readonly original_dir="$PWD"
declare -a errs=()
# ─── Tool Availability Cache ───────────────────────────────────────────────
readonly has_shellcheck=$(command -v shellcheck &>/dev/null && echo true || echo false)
readonly has_shellharden=$(command -v shellharden &>/dev/null && echo true || echo false)
readonly has_shfmt=$(command -v shfmt &>/dev/null && echo true || echo false)
readonly has_namcap=$(command -v namcap &>/dev/null && echo true || echo false)
# ─── Color Helpers ─────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
err(){ printf '%b\n' "${R}✘ $*${D}" >&2; }
ok(){ printf '%b\n' "${G}✓ $*${D}"; }
warn(){ printf '%b\n' "${Y}⚠ $*${D}" >&2; }
# ─── Package Discovery ─────────────────────────────────────────────────────
mapfile -t pkgs < <(find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u)
# ─── Linting Pipeline ──────────────────────────────────────────────────────
for pkg in "${pkgs[@]}"; do
  [[ -d $pkg ]] || continue
  cd "$original_dir/$pkg" || { errs+=("$pkg: cd failed"); continue; }
  echo "==> $pkg"
  [[ ! -f PKGBUILD ]] && { errs+=("$pkg: no PKGBUILD"); continue; }
  # ShellCheck: Static analysis with auto-fix
  if [[ "$has_shellcheck" == "true" ]]; then
    if ! shellcheck -x -a -s bash -f diff PKGBUILD 2>/dev/null | patch -Np1 --silent 2>/dev/null; then
      warn "$pkg: shellcheck had suggestions"
    fi
  fi
  # Shellharden: Safety improvements
  if [[ "$has_shellharden" == "true" ]]; then
    if ! shellharden --replace PKGBUILD 2>/dev/null; then
      errs+=("$pkg: shellharden failed")
    fi
  fi
  # shfmt: Code formatting
  if [[ "$has_shfmt" == "true" ]]; then
    if ! shfmt -ln bash -bn -ci -s -i 2 -w PKGBUILD 2>/dev/null; then
      warn "$pkg: shfmt formatting failed"
    fi
  fi
  # namcap: PKGBUILD linting
  if [[ "$has_namcap" == "true" ]]; then
    if ! namcap PKGBUILD >/dev/null 2>&1; then
      warn "$pkg: namcap warnings (non-fatal)"
    fi
  fi
  # .SRCINFO validation
  if [[ -f .SRCINFO ]]; then
    if ! makepkg --printsrcinfo 2>/dev/null | diff --ignore-blank-lines .SRCINFO - &>/dev/null; then
      errs+=("$pkg: .SRCINFO out of sync")
      echo "Run: cd $pkg && makepkg --printsrcinfo > .SRCINFO"
    fi
  else
    errs+=("$pkg: missing .SRCINFO")
    echo "Run: cd $pkg && makepkg --printsrcinfo > .SRCINFO"
  fi
done
# ─── Results ───────────────────────────────────────────────────────────────
cd "$original_dir"
if [[ ${#errs[@]} -gt 0 ]]; then
  echo
  err "Found ${#errs[@]} error(s):"
  printf '  %s\n' "${errs[@]}" >&2
  exit 1
fi

ok "All checks passed"
