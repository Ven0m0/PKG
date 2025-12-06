#!/usr/bin/env bash
# Optimized PKG Build Wrapper - Statically Linked Standalone Version
# Designed for CI/CD environments with GitHub Actions integration
set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob

# ─── Configuration ───
readonly DOCKER_PKGS="obs-studio|firefox|egl-wayland2|onlyoffice"
readonly IMAGE="archlinux:latest"
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'

# ─── Logging Helpers ───
log_err() { printf '%b%s%b\n' "$R" "✘ $*" "$D" >&2; }
log_ok() { printf '%b%s%b\n' "$G" "✓ $*" "$D"; }
log_info() { printf '%b%s%b\n' "$Y" "ℹ $*" "$D"; }

# ─── GitHub Actions Integration ───
gh_group() {
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    echo "::group::$*"
  else
    log_info ">>> $*"
  fi
}

gh_endgroup() {
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    echo "::endgroup::"
  fi
}

gh_error() {
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    echo "::error::$*"
  else
    log_err "$*"
  fi
}

# ─── Docker Build (Optimized) ───
build_docker() {
  local pkg="$1"

  command -v docker &>/dev/null || {
    gh_error "Docker not found"
    return 1
  }

  gh_group "Building $pkg (Docker)"

  docker run --rm \
    -v "$(pwd):/ws:rw" \
    -w "/ws/$pkg" \
    "$IMAGE" \
    bash -c '
      set -euo pipefail

      # Update system and install base tools
      pacman -Syu --noconfirm --needed base-devel pacman-contrib sudo

      # Extract dependencies in a single pass
      deps=$(makepkg --printsrcinfo 2>/dev/null | awk '\''
        /^\s*(make)?depends\s*=/ {
          $1="";
          sub(/^[[:space:]]+/, "");
          print
        }
      '\'' | tr '\''\n'\'' '\'' '\'' | sed '\''s/[[:space:]]*$//'\'' )

      # Install dependencies if found
      [[ -n "$deps" ]] && {
        echo "Installing: $deps"
        pacman -S --noconfirm --needed $deps
      }

      # Setup non-root builder user
      useradd -m builder
      echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
      chmod 440 /etc/sudoers.d/builder
      chown -R builder:builder .

      # Build package
      sudo -u builder makepkg -fs --noconfirm
    ' || {
      gh_error "Docker build failed for $pkg"
      gh_endgroup
      return 1
    }

  gh_endgroup
  log_ok "Docker build completed: $pkg"
  return 0
}

# ─── Standard Build (Optimized) ───
build_standard() {
  local pkg="$1"

  gh_group "Building $pkg (Standard)"

  [[ ! -d "$pkg" ]] && {
    gh_error "Package directory not found: $pkg"
    gh_endgroup
    return 1
  }

  cd "$pkg" || {
    gh_error "Failed to enter directory: $pkg"
    gh_endgroup
    return 1
  }

  # -s: sync deps, -i: install, --noconfirm: non-interactive
  if makepkg -si --noconfirm 2>&1 | tee build.log; then
    log_ok "Standard build completed: $pkg"
    gh_endgroup
    cd ..
    return 0
  else
    gh_error "Standard build failed for $pkg"
    [[ -f build.log ]] && cat build.log >&2
    gh_endgroup
    cd ..
    return 1
  fi
}

# ─── Main Entry Point ───
main() {
  local pkg="${1:?Package name required}"
  local method="${2:-auto}"

  # Auto-detect build method if not specified
  if [[ "$method" == "auto" || -z "${2:-}" ]]; then
    if [[ "$pkg" =~ ^($DOCKER_PKGS)$ ]]; then
      method="docker"
    else
      method="standard"
    fi
  fi

  log_info "Package: $pkg"
  log_info "Method: $method"

  case "$method" in
    docker)
      build_docker "$pkg"
      ;;
    standard)
      build_standard "$pkg"
      ;;
    *)
      gh_error "Unknown build method: $method"
      echo "Usage: $0 PACKAGE [standard|docker|auto]" >&2
      return 1
      ;;
  esac
}

main "$@"
