#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob extglob globstar
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}
[[ $s != /* ]] && s=$PWD/$s
cd -P -- "${s%/*}"

# ═══════════════════════════════════════════════════════════════════════════
# Build Script - Arch Linux Package Builder
# ═══════════════════════════════════════════════════════════════════════════

# ─── Config ────────────────────────────────────────────────────────────────
readonly IMAGE="archlinux:latest"
declare -A DOCKER_PKGS=([obs-studio]=1 [firefox]=1 [egl-wayland2]=1 [onlyoffice]=1)
readonly MAX_JOBS=${MAX_JOBS:-$(nproc)}
PARALLEL=${PARALLEL:-true}

# ─── Helpers ───────────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
err() { printf '%b\n' "${R}✘ $*${D}" >&2; }
log() { printf '%b\n' "${G}➜ $*${D}"; }
warn() { printf '%b\n' "${Y}⚠ $*${D}" >&2; }
has() { command -v -- "$1" &>/dev/null; }

usage() {
  cat <<EOF
Usage: build.sh [OPTIONS] [PACKAGE...]
Build Arch Linux packages via makepkg or Docker.
OPTIONS:
  -h, --help     Show help
  -j, --jobs N   Max parallel jobs (default: $(nproc))
  -s, --serial   Disable parallel builds
Environment:
  MAX_JOBS       Override max parallel jobs
  PARALLEL       Enable/disable parallel builds (true/false)
EOF
}

# ─── Discovery ─────────────────────────────────────────────────────────────
find_pkgs() {
  if has fd; then
    fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u
  else
    find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u
  fi
}

# ─── Builders ──────────────────────────────────────────────────────────────
build_docker() {
  local pkg="$1"
  has docker || {
    err "Docker required for $pkg"
    return 1
  }
  log "Building $pkg (Docker)"
  docker run --rm -v "${PWD}:/ws:rw" -w "/ws/$pkg" "$IMAGE" bash -c '
    set -euo pipefail
    pacman -Syu --noconfirm --needed base-devel pacman-contrib sudo
    # Optimized dependency extraction (single awk pass)
    deps=$(makepkg --printsrcinfo 2>/dev/null | awk "/^\s*(make)?depends\s*=/ {sub(/^[[:space:]]+/, \"\", \$2); print \$2}" | tr "\n" " ")
    [[ -n "$deps" ]] && pacman -S --noconfirm --needed $deps
    useradd -m builder
    printf "builder ALL=(ALL) NOPASSWD:ALL\n" >/etc/sudoers.d/builder
    chmod 440 /etc/sudoers.d/builder
    chown -R builder:builder .
    sudo -u builder bash -c "export MAKEFLAGS=\"-j\$(nproc)\"; makepkg -fs --noconfirm"
  '
}

build_standard() {
  local pkg="$1"
  log "Building $pkg (Standard)"
  builtin cd "$pkg" || return 1
  export MAKEFLAGS="-j$(nproc)"
  makepkg -srC --noconfirm || {
    err "Failed to build $pkg"
    builtin cd ..
    return 1
  }
  builtin cd ..
}

# ─── Main ──────────────────────────────────────────────────────────────────
main() {
  local -a targets=() args=()
  local max_jobs=$MAX_JOBS

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    -j | --jobs)
      max_jobs=${2:-$MAX_JOBS}
      shift 2
      ;;
    -s | --serial)
      PARALLEL=false
      shift
      ;;
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      args+=("$1")
      shift
      ;;
    esac
  done

  if [[ ${#args[@]} -gt 0 ]]; then
    targets=("${args[@]}")
  else
    log "Detecting packages..."
    mapfile -t targets < <(find_pkgs)
  fi

  [[ ${#targets[@]} -eq 0 ]] && {
    err "No packages found"
    exit 1
  }

  log "Building ${#targets[@]} package(s) [parallel=$PARALLEL, max_jobs=$max_jobs]"

  local failed=0
  local -a pids=()
  local -A pkg_status=()

  for pkg in "${targets[@]}"; do
    [[ ! -f $pkg/PKGBUILD ]] && {
      err "Missing PKGBUILD: $pkg"
      ((failed++))
      continue
    }

    if [[ $PARALLEL == true ]]; then
      # Wait if we've hit max jobs
      while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
        sleep 0.1
      done

      # Build in background
      (
        if [[ -n ${DOCKER_PKGS[$pkg]:-} ]]; then
          build_docker "$pkg"
        else
          build_standard "$pkg"
        fi
      ) &
      pids+=($!)
      pkg_status[$!]=$pkg
    else
      # Serial execution
      if [[ -n ${DOCKER_PKGS[$pkg]:-} ]]; then
        build_docker "$pkg"
      else
        build_standard "$pkg"
      fi || ((failed++))
    fi
  done

  # Wait for all background jobs if parallel
  if [[ $PARALLEL == true ]]; then
    for pid in "${pids[@]}"; do
      if wait "$pid"; then
        log "✓ ${pkg_status[$pid]} completed"
      else
        err "✗ ${pkg_status[$pid]} failed"
        ((failed++))
      fi
    done
  fi

  [[ $failed -gt 0 ]] && {
    err "$failed package(s) failed"
    exit 1
  }
  log "Success: All packages built"
}

main "$@"
