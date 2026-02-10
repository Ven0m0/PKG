#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C

# ═══════════════════════════════════════════════════════════════════════════
# PKG - Unified Arch Linux Package Management Tool
# ═══════════════════════════════════════════════════════════════════════════
# Combines build, lint, and srcinfo functionality into a single tool.
# ═══════════════════════════════════════════════════════════════════════════

# Source shared helpers
# shellcheck source=lib/helpers.sh
source "${BASH_SOURCE[0]%/*}/lib/helpers.sh"

readonly ARCH=$(uname -m)
readonly IMAGE="archlinux:latest"
declare -A DOCKER_PKGS=([obs-studio]=1 [firefox]=1 [egl-wayland2]=1 [onlyoffice]=1)

# ─── Config (env overridable) ──────────────────────────────────────────────
MAX_JOBS=${MAX_JOBS:-$(nproc)}
PARALLEL=${PARALLEL:-true}
RETRIES=${RETRIES:-3}
FORCE_BUILD=${FORCE_BUILD:-0}
ONE_PACKAGE=${ONE_PACKAGE:-}
DIST_MODE=${DIST_MODE:-0}
PATCH_ARCH=${PATCH_ARCH:-1}

# ═══════════════════════════════════════════════════════════════════════════
# HELP / USAGE
# ═══════════════════════════════════════════════════════════════════════════
usage() {
  cat <<'EOF'
Usage: pkg.sh <command> [OPTIONS] [PACKAGE...]

Unified Arch Linux package management tool.

COMMANDS:
  build     Build packages via makepkg or Docker
  lint      Lint and format PKGBUILDs
  srcinfo   Update .SRCINFO files for all packages
  help      Show this help message

BUILD OPTIONS:
  -h, --help       Show help
  -j, --jobs N     Max parallel jobs (default: nproc)
  -s, --serial     Disable parallel builds
  -r, --retry N    Retry failed builds N times (default: 3)
  -f, --force      Force build regardless of version
  -d, --dist       Create dist/ with artifacts and checksums
  --one PKG        Only build if matches ONE_PACKAGE

ENVIRONMENT VARIABLES:
  MAX_JOBS, PARALLEL, RETRIES, FORCE_BUILD, ONE_PACKAGE, DIST_MODE

EXAMPLES:
  pkg.sh build aria2 firefox    # Build specific packages
  pkg.sh build                  # Build all packages
  pkg.sh lint                   # Lint all PKGBUILDs
  pkg.sh srcinfo                # Update all .SRCINFO files
EOF
}

# ═══════════════════════════════════════════════════════════════════════════
# BUILD FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

setup_env() {
  case $ARCH in
    x86_64) EXT=zst ;;
    aarch64) EXT=xz ;;
    *) die "Unsupported arch: $ARCH" ;;
  esac
  export ARCH EXT CC=gcc CXX=g++
  export PATH="$PWD:$PWD/bin:$PATH:/usr/bin/core_perl"
  chmod +x "$PWD"/bin/* "$PWD"/*.sh 2>/dev/null || true
  if ((FORCE_BUILD)); then warn "Force build enabled"; fi
}

setup_cache() {
  local pkg=${1:-}
  if [[ $pkg == qt6-base ]]; then
    export CMAKE_C_COMPILER_LAUNCHER=sccache CMAKE_CXX_COMPILER_LAUNCHER=sccache
  else
    export CMAKE_C_COMPILER_LAUNCHER=ccache CMAKE_CXX_COMPILER_LAUNCHER=ccache
  fi
}

show_cache_stats() {
  local pkg=${1:-}
  if [[ $pkg == qt6-base ]] && has sccache; then
    sccache --show-stats
  elif has ccache; then
    ccache -s -v
  fi
}

find_pkgs() {
  local -a pkgs=()
  while IFS= read -r -d '' f; do
    local dir=${f%/PKGBUILD}
    dir=${dir#./}
    pkgs+=("$dir")
  done < <(find . -type f -name PKGBUILD -print0)


  printf '%s\n' "${pkgs[@]}"
}

patch_arch() {
  local -a targets=("${@}")
  # Optimization: only patch if enabled and targets exist
  [[ ${PATCH_ARCH:-1} == 1 ]] || return 0
  ((${#targets[@]})) || return 0

  local -a files=()
  for pkg in "${targets[@]}"; do
    [[ -f "$pkg/PKGBUILD" ]] && files+=("$pkg/PKGBUILD")
  done

  ((${#files[@]})) || return 0

  printf '%s\0' "${files[@]}" | \
    { xargs -0 grep -Z -l -e "arch=(x86_64)" -e "arch=('x86_64')" || true; } | \
    xargs -0 -r sed -i -e "s/arch=(x86_64)/arch=(x86_64_v3)/" \
      -e "s/arch=('x86_64')/arch=('x86_64_v3')/"
}



build_docker() {
  local pkg=$1
  has docker || {
    err "Docker required for $pkg"
    return 1
  }
  log "Building $pkg (Docker)"
  docker run --rm -v "${PWD}:/ws:rw" -w "/ws/$pkg" "$IMAGE" bash -c '
    set -euo pipefail
    pacman -Syu --noconfirm --needed base-devel pacman-contrib sudo
    deps=$(makepkg --printsrcinfo 2>/dev/null | awk "/^[[:space:]]*(make)?depends[[:space:]]*=/{print \$3}" | tr "\n" " ")
    [[ -n "$deps" ]] && pacman -S --noconfirm --needed $deps
    useradd -m builder
    printf "builder ALL=(ALL) NOPASSWD:ALL\n" >/etc/sudoers.d/builder
    chmod 440 /etc/sudoers.d/builder
    chown -R builder:builder .
    sudo -u builder bash -c "MAKEFLAGS=\"-j$(nproc)\" makepkg -fs --noconfirm"
  '
}

build_standard() {
  local pkg=$1
  log "Building $pkg (makepkg)"
  setup_cache "$pkg"
  pushd "$pkg" >/dev/null || return 1
  MAKEFLAGS="-j$(nproc)" makepkg -srC --noconfirm
  local rc=$?
  popd >/dev/null
  return $rc
}

build_with_retry() {
  local pkg=$1 attempt=0
  while ((attempt < RETRIES)); do
    if [[ -n ${DOCKER_PKGS[$pkg]:-} ]]; then
      build_docker "$pkg" && return 0
    else
      build_standard "$pkg" && return 0
    fi
    ((attempt++))
    sep
    err "Build failed for $pkg (attempt $attempt/$RETRIES)"
    sep
  done
  return 1
}

collect_dist() {
  local -a pkgs=(./*.pkg.tar.*)
  ((${#pkgs[@]})) || return 0
  mkdir -p ./dist
  sha256sum "${pkgs[@]}"
  mv "${pkgs[@]}" ./dist/
  log "Artifacts moved to dist/"
}

cmd_build() {
  local -a targets=() args=()
  while (($#)); do
    case $1 in
      -h | --help) usage && exit 0 ;;
      -j | --jobs)
        MAX_JOBS=${2:-$MAX_JOBS}
        shift 2
        ;;
      -s | --serial)
        PARALLEL=false
        shift
        ;;
      -r | --retry)
        RETRIES=${2:-3}
        shift 2
        ;;
      -f | --force)
        FORCE_BUILD=1
        shift
        ;;
      -d | --dist)
        DIST_MODE=1
        shift
        ;;
      --one)
        ONE_PACKAGE=${2:-}
        shift 2
        ;;
      -*)
        die "Unknown option: $1"
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  setup_env

  if ((${#args[@]})); then
    targets=("${args[@]}")
  else
    log "Discovering packages..."
    mapfile -t targets < <(find_pkgs)
  fi

  ((${#targets[@]})) || die "No packages found"

  # ONE_PACKAGE filter
  if [[ -n $ONE_PACKAGE ]]; then
    local -a filtered=()
    for pkg in "${targets[@]}"; do
      [[ ${pkg##*/} == "$ONE_PACKAGE" ]] && filtered+=("$pkg")
    done
    if ((${#filtered[@]} == 0)); then
      warn "ONE_PACKAGE=$ONE_PACKAGE not matched, aborting"
      : >~/OPERATION_ABORTED
      exit 0
    fi
    targets=("${filtered[@]}")
  fi

  patch_arch "${targets[@]}"
  log "Building ${#targets[@]} package(s) [parallel=$PARALLEL, jobs=$MAX_JOBS, retries=$RETRIES]"

  local failed=0
  local -a pids=()
  local -A pid_pkg=()

  for pkg in "${targets[@]}"; do
    [[ -f $pkg/PKGBUILD ]] || {
      err "Missing PKGBUILD: $pkg"
      ((failed++))
      continue
    }
    if [[ $PARALLEL == true ]]; then
      while (($(jobs -rp | wc -l) >= MAX_JOBS)); do sleep 0.1; done
      build_with_retry "$pkg" &
      pids+=($!)
      pid_pkg[$!]=$pkg
    else
      build_with_retry "$pkg" || ((failed++))
      show_cache_stats "$pkg"
    fi
  done

  if [[ $PARALLEL == true ]]; then
    for pid in "${pids[@]}"; do
      if wait "$pid"; then
        log "✓ ${pid_pkg[$pid]}"
        show_cache_stats "${pid_pkg[$pid]}"
      else
        err "✗ ${pid_pkg[$pid]}"
        ((failed++))
      fi
    done
  fi

  if ((DIST_MODE)); then collect_dist; fi
  if ((failed)); then die "$failed package(s) failed" 1; fi

  sep
  log "Success: All packages built"
}

# ═══════════════════════════════════════════════════════════════════════════
# LINT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

lint_pkg() {
  local pkg=$1 root=$2 sc=$3 sh=$4 sf=$5 nc=$6
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

handle_lint_output() {
  local -n errs_ref=$1
  while IFS= read -r line; do
    case $line in
      ERROR:*)
        errs_ref+=("${line#ERROR:}")
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

cmd_lint() {
  cd_to_script_dir
  local root="$PWD"
  local -a pkgs errs=()
  local max_jobs=${MAX_JOBS:-$(nproc)}
  local parallel=${PARALLEL:-true}

  mapfile -t pkgs < <(find_pkgbuilds)

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

      while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
        sleep 0.1
      done

      printf '==> %s\n' "$pkg"
      (lint_pkg "$pkg" "$root" "$sc" "$sh" "$sf" "$nc" >"$tmpdir/$pkg.log" 2>&1) &
      pids+=($!)
    done

    for pid in "${pids[@]}"; do
      wait "$pid" || true
    done

    for logfile in "$tmpdir"/*.log; do
      [[ -f $logfile ]] || continue
      handle_lint_output errs <"$logfile"
    done
  else
    for pkg in "${pkgs[@]}"; do
      [[ -d $pkg ]] || continue
      printf '==> %s\n' "$pkg"

      local output
      output=$(lint_pkg "$pkg" "$root" "$sc" "$sh" "$sf" "$nc" 2>&1)
      handle_lint_output errs <<<"$output"
    done
  fi

  if [[ ${#errs[@]} -gt 0 ]]; then
    printf '\n%bFound %s error(s)%b\n' "$R" "${#errs[@]}" "$D" >&2
    exit 1
  fi
  ok "All checks passed"
}

# ═══════════════════════════════════════════════════════════════════════════
# SRCINFO FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

process_srcinfo_pkg() {
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

handle_srcinfo_output() {
  local -n errs_ref=$1
  while IFS= read -r line; do
    case $line in
      OK:*)
        log "${line#OK:}"
        ;;
      ERROR:*)
        errs_ref+=("${line#ERROR:}")
        err "${line#ERROR:}"
        ;;
    esac
  done
}

cmd_srcinfo() {
  cd_to_script_dir
  local root="$PWD"
  local -a pkgs errs=()
  local max_jobs=${MAX_JOBS:-$(nproc)}
  local parallel=${PARALLEL:-true}

  mapfile -t pkgs < <(find_pkgbuilds)

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

      while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
        sleep 0.1
      done

      (process_srcinfo_pkg "$pkg" "$root" >"$tmpdir/$pkg.log" 2>&1) &
      pids+=($!)
    done

    for pid in "${pids[@]}"; do
      wait "$pid" || true
    done

    for logfile in "$tmpdir"/*.log; do
      [[ -f $logfile ]] || continue
      handle_srcinfo_output errs <"$logfile"
    done
  else
    for pkg in "${pkgs[@]}"; do
      [[ ! -d $pkg ]] && continue

      local output
      output=$(process_srcinfo_pkg "$pkg" "$root" 2>&1)
      handle_srcinfo_output errs <<<"$output"
    done
  fi

  if [[ ${#errs[@]} -gt 0 ]]; then
    err "Failed to process ${#errs[@]} package(s)"
    exit 1
  fi

  log "Done"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN DISPATCHER
# ═══════════════════════════════════════════════════════════════════════════

main() {
  local cmd=${1:-help}
  shift || true

  case $cmd in
    build | b) cmd_build "$@" ;;
    lint | l) cmd_lint "$@" ;;
    srcinfo | s) cmd_srcinfo "$@" ;;
    help | h | -h | --help) usage ;;
    *)
      err "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"

# vim:set sw=2 ts=2 et:
