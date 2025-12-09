#!/usr/bin/env bash
set -euo pipefail; shopt -s nullglob extglob; IFS=$'\n\t'

# ═══════════════════════════════════════════════════════════════════════════
# Build Script - Arch Linux Package Builder
# ═══════════════════════════════════════════════════════════════════════════

# ─── Config ────────────────────────────────────────────────────────────────
readonly IMAGE="archlinux:latest"
declare -A DOCKER_PKGS=([obs-studio]=1 [firefox]=1 [egl-wayland2]=1 [onlyoffice]=1)

# ─── Helpers ───────────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
err(){ printf '%b\n' "${R}✘ $*${D}" >&2; }
log(){ printf '%b\n' "${G}➜ $*${D}"; }
warn(){ printf '%b\n' "${Y}⚠ $*${D}" >&2; }
has(){ command -v "$1" &>/dev/null; }

usage(){
  cat <<'EOF'
Usage: build.sh [OPTIONS] [PACKAGE...]
Build Arch Linux packages via makepkg or Docker.
OPTIONS: -h, --help  Show help
EOF
}

# ─── Discovery ─────────────────────────────────────────────────────────────
find_pkgs(){
  if has fd; then fd -t f -g 'PKGBUILD' -x printf '%{//}\n' | sort -u
  else find . -type f -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort -u; fi
}

# ─── Builders ──────────────────────────────────────────────────────────────
build_docker(){
  local pkg="$1"
  has docker || { err "Docker required for $pkg"; return 1; }
  log "Building $pkg (Docker)"

  docker run --rm -v "${PWD}:/ws:rw" -w "/ws/$pkg" "$IMAGE" bash -c '
    set -euo pipefail; shopt -s extglob
    pacman -Syu --noconfirm --needed base-devel pacman-contrib sudo
    
    # Robust dependency extraction
    mapfile -t deps < <(makepkg --printsrcinfo 2>/dev/null | \
      awk "/^\s*(make)?depends\s*=/ { \$1=\"\"; print \$0 }")
    
    # Trim whitespace
    deps=("${deps[@]##+([[:space:]])}")
    
    if [[ ${#deps[@]} -gt 0 ]]; then
      pacman -S --noconfirm --needed "${deps[@]}"
    fi

    # Build as user
    useradd -m builder
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
    chmod 440 /etc/sudoers.d/builder
    chown -R builder:builder .
    sudo -u builder makepkg -fs --noconfirm
  '
}

build_standard(){
  local pkg="$1"
  log "Building $pkg (Standard)"
  builtin cd "$pkg" || return 1
  if ! makepkg -srC --noconfirm; then
    err "Failed to build $pkg"
    builtin cd ..; return 1
  fi
  builtin cd ..
}

# ─── Main ──────────────────────────────────────────────────────────────────
main(){
  local -a targets=()
  [[ "${1:-}" =~ ^(-h|--help)$ ]] && { usage; exit 0; }

  if [[ $# -gt 0 ]]; then targets=("$@")
  else log "Detecting packages..."; mapfile -t targets < <(find_pkgs); fi

  [[ ${#targets[@]} -eq 0 ]] && { err "No packages found"; exit 1; }

  local failed=0
  for pkg in "${targets[@]}"; do
    [[ ! -f "$pkg/PKGBUILD" ]] && { err "Missing PKGBUILD: $pkg"; ((failed++)); continue; }
    
    # O(1) Dispatch
    if [[ -n "${DOCKER_PKGS[$pkg]:-}" ]]; then build_docker "$pkg"
    else build_standard "$pkg"; fi || ((failed++))
  done

  [[ $failed -gt 0 ]] && { err "$failed package(s) failed"; exit 1; }
  log "Success"
}

main "$@"
