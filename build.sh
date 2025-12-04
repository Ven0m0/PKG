#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly DOCKER_REGEX="^(obs-studio|firefox|egl-wayland2|onlyoffice)$"
readonly IMAGE="archlinux:latest"

# Helpers
err(){ printf "\e[31m✘ %s\e[0m\n" "$*" >&2; }
log(){ printf "\e[32m➜ %s\e[0m\n" "$*"; }
has(){ command -v "$1" &>/dev/null; }

# Detect packages
find_pkgs(){
  if has fd; then
    fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u
  else
    find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u
  fi
}

validate_pkg(){
  local pkg="$1"
  if [[ ! -d "$pkg" ]]; then
    err "Package directory '$pkg' does not exist"; return 1
  fi
  if [[ ! -f "$pkg/PKGBUILD" ]]; then
    err "No PKGBUILD found in '$pkg'"; return 1
  fi
  if !  bash -n "$pkg/PKGBUILD" 2>/dev/null; then
    err "PKGBUILD syntax error in '$pkg'"; return 1
  fi
  return 0
}

# Build logic
build_pkg(){
  local pkg="$1" method="standard"
  # Detect method
  if [[ "$pkg" =~ $DOCKER_REGEX ]]; then
    method="docker"
  fi
  log "Building $pkg (Method: $method)"
  if [[ "$method" == "docker" ]]; then
    if ! has docker; then
      err "Docker required for $pkg but not found. Skipping."; return 1
    fi
    # Replicates CI Docker logic
    docker run --rm -it \
      -v "${PWD}:/ws:rw" \
      -w "/ws/$pkg" \
      "$IMAGE" \
      bash -c "
        set -euo pipefail
        pacman -Syu --noconfirm --needed base-devel pacman-contrib sudo
        
        # Dynamic dep extraction
        deps=\$(makepkg --printsrcinfo | awk '/^\s*(make)?depends\s*=/ { \$1=\"\"; print \$0 }' | tr '\n' ' ')
        [[ -n \"\$deps\" ]] && pacman -S --noconfirm --needed \$deps
        
        # Build
        useradd -m builder
        echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder
        chmod 440 /etc/sudoers.d/builder
        chown -R builder:builder .
        sudo -u builder makepkg -fs --noconfirm
      "
  else
    # Standard local build
    pushd "$pkg" >/dev/null
    # -s: install deps, -r: remove deps after, -C: clean
    if ! makepkg -srC --noconfirm; then
      err "Failed to build $pkg"
      popd >/dev/null; return 1
    fi
    popd >/dev/null
  fi
}

main(){
  local targets=()
  # Parse args
  if [[ $# -gt 0 ]]; then
    targets=("$@")
  else
    log "No package specified, detecting all..."
    mapfile -t targets < <(find_pkgs)
  fi
  if [[ ${#targets[@]} -eq 0 ]]; then
    err "No packages found."; exit 1
  fi
  log "Queue: ${targets[*]}"
  for pkg in "${targets[@]}"; do
    build_pkg "$pkg"
  done
}
main "$@"
