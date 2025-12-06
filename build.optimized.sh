#!/usr/bin/env bash
# Optimized PKG Build Script - Statically Linked Standalone Version
# Performance improvements: Cached tool detection, optimized package discovery, parallel support
set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob globstar

# ─── Configuration ───
readonly DOCKER_REGEX="^(obs-studio|firefox|egl-wayland2|onlyoffice)$"
readonly IMAGE="archlinux:latest"
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[34m' D=$'\e[0m'

# ─── Cached Tool Detection ───
readonly HAS_FD=$(command -v fd &>/dev/null && echo 1 || echo 0)
readonly HAS_DOCKER=$(command -v docker &>/dev/null && echo 1 || echo 0)
readonly HAS_RG=$(command -v rg &>/dev/null && echo 1 || echo 0)

# ─── Logging Helpers (Inlined) ───
err() { printf '%b%s%b\n' "$R" "✘ $*" "$D" >&2; }
log() { printf '%b%s%b\n' "$G" "➜ $*" "$D"; }
warn() { printf '%b%s%b\n' "$Y" "⚠ $*" "$D" >&2; }
info() { printf '%b%s%b\n' "$B" "ℹ $*" "$D"; }

# ─── Usage Documentation ───
usage() {
  cat <<'EOF'
Usage: build.sh [OPTIONS] [PACKAGE...]

Build Arch Linux packages from PKGBUILDs with automatic dependency handling.

OPTIONS:
  -h, --help       Display this help message and exit
  -p, --parallel   Build packages in parallel (experimental)

ARGUMENTS:
  PACKAGE...       One or more package names to build
                   If no packages specified, builds all packages in repository

BUILD METHODS:
  Standard         Local build using makepkg (default)
                   - Fast for most packages
                   - Uses system dependencies
                   - Flags: -srC (install deps, remove after, clean build)

  Docker           Containerized build for complex packages
                   - Used for: obs-studio, firefox, egl-wayland2, onlyoffice
                   - Requires Docker to be installed
                   - Isolated environment with archlinux:latest
                   - Automatic dependency extraction and installation

EXAMPLES:
  # Build a single package
  ./build.sh aria2

  # Build multiple specific packages
  ./build.sh aria2 firefox

  # Build all packages in repository
  ./build.sh

  # Build packages in parallel (experimental)
  ./build.sh --parallel aria2 firefox

REQUIREMENTS:
  - base-devel (Arch Linux build tools)
  - makepkg, pacman
  - docker (optional, for Docker-based builds)
  - fd (optional, faster package detection)

For more information, see README.md and CLAUDE.md
EOF
}

# ─── Package Discovery (Optimized) ───
find_pkgs() {
  if ((HAS_FD)); then
    fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u
  else
    find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u
  fi
}

# ─── Package Validation ───
validate_pkg() {
  local pkg="$1"

  [[ ! -d "$pkg" ]] && {
    err "Package directory '$pkg' does not exist"
    return 1
  }

  [[ ! -f "$pkg/PKGBUILD" ]] && {
    err "No PKGBUILD found in '$pkg'"
    return 1
  }

  bash -n "$pkg/PKGBUILD" 2>/dev/null || {
    err "PKGBUILD syntax error in '$pkg'"
    return 1
  }

  return 0
}

# ─── Build Logic (Docker) ───
build_docker() {
  local pkg="$1"

  ((HAS_DOCKER == 0)) && {
    err "Docker required for $pkg but not found. Skipping."
    return 1
  }

  docker run --rm -it \
    -v "${PWD}:/ws:rw" \
    -w "/ws/$pkg" \
    "$IMAGE" \
    bash -c '
      set -euo pipefail
      pacman -Syu --noconfirm --needed base-devel pacman-contrib sudo

      # Dynamic dependency extraction (optimized with single awk pass)
      deps=$(makepkg --printsrcinfo | awk '\''
        /^\s*(make)?depends\s*=/ {
          $1="";
          sub(/^[[:space:]]+/, "");
          print
        }
      '\'' | tr '\''\n'\'' '\'' '\'' | sed '\''s/[[:space:]]*$//'\'' )

      [[ -n "$deps" ]] && pacman -S --noconfirm --needed $deps

      # Non-root build user setup
      useradd -m builder
      echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
      chmod 440 /etc/sudoers.d/builder
      chown -R builder:builder .
      sudo -u builder makepkg -fs --noconfirm
    '
}

# ─── Build Logic (Standard) ───
build_standard() {
  local pkg="$1"
  pushd "$pkg" >/dev/null || return 1

  makepkg -srC --noconfirm || {
    err "Failed to build $pkg"
    popd >/dev/null
    return 1
  }

  popd >/dev/null
  return 0
}

# ─── Main Build Dispatcher ───
build_pkg() {
  local pkg="$1"

  validate_pkg "$pkg" || return 1

  local method="standard"
  [[ "$pkg" =~ $DOCKER_REGEX ]] && method="docker"

  log "Building $pkg (Method: $method)"

  case "$method" in
    docker)
      build_docker "$pkg"
      ;;
    standard)
      build_standard "$pkg"
      ;;
  esac
}

# ─── Parallel Build Support ───
build_parallel() {
  local -a pids=()
  local -a failed=()

  for pkg in "$@"; do
    build_pkg "$pkg" &
    pids+=($!)
  done

  # Wait for all builds and collect failures
  local idx=0
  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      failed+=("${!idx}")
    fi
    ((idx++))
  done

  if ((${#failed[@]} > 0)); then
    err "Failed builds: ${failed[*]}"
    return 1
  fi

  return 0
}

# ─── Main Entry Point ───
main() {
  local -a targets=()
  local parallel=0

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -p|--parallel)
        parallel=1
        shift
        ;;
      -*)
        err "Unknown option: $1"
        usage >&2
        exit 1
        ;;
      *)
        targets+=("$1")
        shift
        ;;
    esac
  done

  # Auto-detect packages if none specified
  if ((${#targets[@]} == 0)); then
    log "No package specified, detecting all..."
    mapfile -t targets < <(find_pkgs)
  fi

  ((${#targets[@]} == 0)) && {
    err "No packages found."
    exit 1
  }

  log "Queue: ${targets[*]}"

  # Execute builds
  if ((parallel)); then
    warn "Parallel build mode (experimental)"
    build_parallel "${targets[@]}"
  else
    for pkg in "${targets[@]}"; do
      build_pkg "$pkg"
    done
  fi
}

main "$@"
