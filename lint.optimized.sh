#!/usr/bin/env bash
# Optimized PKG Lint Script - Statically Linked Standalone Version
# Performance improvements: Parallel processing, cached tool detection, optimized file discovery
set -euo pipefail
IFS=$'\n\t'
shopt -s globstar nullglob
export LC_ALL=C LANG=C

# ─── Configuration ───
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
readonly ORIGINAL_DIR="$PWD"
readonly NPROC=$(nproc 2>/dev/null || echo 4)

# ─── Cached Tool Detection (One-Time Lookup) ───
readonly HAS_SHELLCHECK=$(command -v shellcheck &>/dev/null && echo 1 || echo 0)
readonly HAS_SHELLHARDEN=$(command -v shellharden &>/dev/null && echo 1 || echo 0)
readonly HAS_SHFMT=$(command -v shfmt &>/dev/null && echo 1 || echo 0)
readonly HAS_FD=$(command -v fd &>/dev/null && echo 1 || echo 0)
readonly HAS_RG=$(command -v rg &>/dev/null && echo 1 || echo 0)
readonly HAS_NAMCAP=$(command -v namcap &>/dev/null && echo 1 || echo 0)

# ─── Logging Helpers ───
log_err() { printf '%b%s%b\n' "$R" "✘ $*" "$D" >&2; }
log_ok() { printf '%b%s%b\n' "$G" "✓ $*" "$D"; }
log_warn() { printf '%b%s%b\n' "$Y" "⚠ $*" "$D"; }
log_info() { printf '==> %s\n' "$*"; }

# ─── Package Discovery (Optimized with fd/find) ───
find_packages() {
  if ((HAS_FD)); then
    fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u
  else
    find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u
  fi
}

# ─── PKGBUILD Linting Function ───
lint_pkgbuild() {
  local pkg="$1"
  local -a pkg_errors=()

  [[ ! -d "$pkg" ]] && return 0

  cd "$ORIGINAL_DIR/$pkg" || {
    log_err "$pkg: cd failed"
    return 1
  }

  log_info "$pkg"

  [[ ! -f PKGBUILD ]] && {
    log_err "$pkg: no PKGBUILD"
    return 1
  }

  # ShellCheck: Apply patches for auto-fixable issues
  if ((HAS_SHELLCHECK)); then
    if ! shellcheck -x -a -s bash -f diff PKGBUILD 2>/dev/null | patch -Np1 --silent 2>/dev/null; then
      pkg_errors+=("$pkg: shellcheck failed")
    else
      log_ok "$pkg: shellcheck passed"
    fi
  fi

  # Shellharden: Safety improvements
  if ((HAS_SHELLHARDEN)); then
    if shellharden --replace PKGBUILD 2>/dev/null; then
      log_ok "$pkg: shellharden passed"
    else
      pkg_errors+=("$pkg: shellharden failed")
    fi
  fi

  # shfmt: Format code
  if ((HAS_SHFMT)); then
    if shfmt -ln bash -bn -ci -s -i 2 -w PKGBUILD 2>/dev/null; then
      log_ok "$pkg: shfmt passed"
    else
      pkg_errors+=("$pkg: shfmt failed")
    fi
  fi

  # namcap: PKGBUILD-specific linting
  if ((HAS_NAMCAP)); then
    if namcap PKGBUILD 2>&1 | grep -qi 'error'; then
      pkg_errors+=("$pkg: namcap errors found")
    else
      log_ok "$pkg: namcap passed"
    fi
  fi

  # .SRCINFO validation: Check if synchronized with PKGBUILD
  if [[ -f .SRCINFO ]]; then
    if ! makepkg --printsrcinfo 2>/dev/null | diff --brief --ignore-blank-lines .SRCINFO - &>/dev/null; then
      pkg_errors+=("$pkg: .SRCINFO out of sync")
      log_warn "Run: cd $pkg && makepkg --printsrcinfo > .SRCINFO"
    else
      log_ok "$pkg: .SRCINFO in sync"
    fi
  else
    pkg_errors+=("$pkg: missing .SRCINFO")
    log_warn "Run: cd $pkg && makepkg --printsrcinfo > .SRCINFO"
  fi

  # Return errors via stdout for collection
  if ((${#pkg_errors[@]} > 0)); then
    printf '%s\n' "${pkg_errors[@]}"
    return 1
  fi

  return 0
}

# ─── Parallel Linting (Experimental) ───
lint_parallel() {
  local -a packages=("$@")
  local -a pids=()
  local -a results=()
  local tmpdir

  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  # Launch background jobs
  for pkg in "${packages[@]}"; do
    {
      lint_pkgbuild "$pkg" >"$tmpdir/${pkg//\//_}.log" 2>&1
      echo $? >"$tmpdir/${pkg//\//_}.exit"
    } &
    pids+=($!)
  done

  # Wait for all jobs
  for pid in "${pids[@]}"; do
    wait "$pid" || true
  done

  # Collect results
  local total_errors=0
  for pkg in "${packages[@]}"; do
    local safe_name="${pkg//\//_}"
    local exit_code
    exit_code=$(cat "$tmpdir/${safe_name}.exit" 2>/dev/null || echo 1)

    if ((exit_code != 0)); then
      ((total_errors++))
      cat "$tmpdir/${safe_name}.log"
    fi
  done

  return "$total_errors"
}

# ─── Sequential Linting (Stable) ───
lint_sequential() {
  local -a packages=("$@")
  local -a errors=()

  for pkg in "${packages[@]}"; do
    if ! lint_pkgbuild "$pkg"; then
      errors+=("$pkg")
    fi
  done

  cd "$ORIGINAL_DIR"

  if ((${#errors[@]} > 0)); then
    log_err "Failed packages: ${errors[*]}"
    return 1
  fi

  log_ok "All checks passed"
  return 0
}

# ─── Main Entry Point ───
main() {
  local -a packages=()
  local use_parallel=0

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--parallel)
        use_parallel=1
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage: lint.sh [OPTIONS]

Lint and validate all PKGBUILDs in the repository.

OPTIONS:
  -p, --parallel   Use parallel linting (experimental)
  -h, --help       Display this help message

TOOLS USED (if available):
  - shellcheck: Static analysis for shell scripts
  - shellharden: Safety and robustness checks
  - shfmt: Shell script formatting
  - namcap: PKGBUILD-specific linting
  - makepkg: .SRCINFO validation

EOF
        exit 0
        ;;
      *)
        packages+=("$1")
        shift
        ;;
    esac
  done

  # Auto-discover packages if none specified
  if ((${#packages[@]} == 0)); then
    mapfile -t packages < <(find_packages)
  fi

  ((${#packages[@]} == 0)) && {
    log_err "No packages found"
    exit 1
  }

  log_info "Linting ${#packages[@]} packages..."
  log_warn "Tools available: shellcheck=$HAS_SHELLCHECK shellharden=$HAS_SHELLHARDEN shfmt=$HAS_SHFMT namcap=$HAS_NAMCAP"

  # Execute linting
  if ((use_parallel)); then
    log_warn "Using parallel mode (experimental)"
    lint_parallel "${packages[@]}"
  else
    lint_sequential "${packages[@]}"
  fi
}

main "$@"
