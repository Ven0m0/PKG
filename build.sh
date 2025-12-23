#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail; shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C
# ═══════════════════════════════════════════════════════════════════════════
# Unified Arch Linux Package Builder
# ═══════════════════════════════════════════════════════════════════════════
readonly ARCH=$(uname -m)
readonly IMAGE="archlinux:latest"
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
declare -A DOCKER_PKGS=([obs-studio]=1 [firefox]=1 [egl-wayland2]=1 [onlyoffice]=1)
# ─── Config (env overridable) ──────────────────────────────────────────────
MAX_JOBS=${MAX_JOBS:-$(nproc)}
PARALLEL=${PARALLEL:-true}
RETRIES=${RETRIES:-3}
FORCE_BUILD=${FORCE_BUILD:-0}
ONE_PACKAGE=${ONE_PACKAGE:-}
DIST_MODE=${DIST_MODE:-0}

# ─── Helpers ───────────────────────────────────────────────────────────────
has(){ command -v -- "$1" &>/dev/null; }
msg(){ printf '%s\n' "$@"; }
log(){ printf '%b\n' "${G}➜ $*${D}"; }
err(){ printf '%b\n' "${R}✘ $*${D}" >&2; }
warn(){ printf '%b\n' "${Y}⚠ $*${D}" >&2; }
die(){ err "$1"; exit "${2:-1}"; }
sep(){ msg '────────────────────────────────────────'; }
usage(){
  cat <<'EOF'
Usage: build.sh [OPTIONS] [PACKAGE...]
Build Arch Linux packages via makepkg or Docker.

OPTIONS:
  -h, --help       Show help
  -j, --jobs N     Max parallel jobs (default: nproc)
  -s, --serial     Disable parallel builds
  -r, --retry N    Retry failed builds N times (default: 3)
  -f, --force      Force build regardless of version
  -d, --dist       Create dist/ with artifacts and checksums
  --one PKG        Only build if matches ONE_PACKAGE

ENVIRONMENT:
  MAX_JOBS, PARALLEL, RETRIES, FORCE_BUILD, ONE_PACKAGE, DIST_MODE
EOF
}
# ─── Setup ─────────────────────────────────────────────────────────────────
setup_env(){
  case $ARCH in
    x86_64)  EXT=zst ;;
    aarch64) EXT=xz ;;
    *) die "Unsupported arch: $ARCH" ;;
  esac
  export ARCH EXT CC=gcc CXX=g++
  export PATH="$PWD:$PWD/bin:$PATH:/usr/bin/core_perl"
  chmod +x "$PWD"/bin/* "$PWD"/*.sh 2>/dev/null || true
  ((FORCE_BUILD)) && warn "Force build enabled"
}
setup_cache(){
  local pkg=${1:-}
  if [[ $pkg == qt6-base ]]; then
    export CMAKE_C_COMPILER_LAUNCHER=sccache CMAKE_CXX_COMPILER_LAUNCHER=sccache
  else
    export CMAKE_C_COMPILER_LAUNCHER=ccache CMAKE_CXX_COMPILER_LAUNCHER=ccache
  fi
}
show_cache_stats(){
  local pkg=${1:-}
  if [[ $pkg == qt6-base ]] && has sccache; then
    sccache --show-stats
  elif has ccache; then
    ccache -s -v
  fi
}
# ─── Discovery ─────────────────────────────────────────────────────────────
find_pkgs(){
  local -a pkgs=()
  while IFS= read -r -d '' f; do
    local dir=${f%/PKGBUILD}
    dir=${dir#./}
    pkgs+=("$dir")
    # Patch arch for x86_64_v3
    sed -i -e "s/arch=(x86_64)/arch=(x86_64_v3)/" \
           -e "s/arch=('x86_64')/arch=('x86_64_v3')/" "$f"
  done < <(find . -type f -name PKGBUILD -print0)
  printf '%s\n' "${pkgs[@]}"
}

# ─── Builders ──────────────────────────────────────────────────────────────
build_docker(){
  local pkg=$1
  has docker || { err "Docker required for $pkg"; return 1; }
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
build_standard(){
  local pkg=$1
  log "Building $pkg (makepkg)"
  setup_cache "$pkg"
  pushd "$pkg" >/dev/null || return 1
  MAKEFLAGS="-j$(nproc)" makepkg -srC --noconfirm
  local rc=$?
  popd >/dev/null
  return $rc
}
build_with_retry(){
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
  done; return 1
}

# ─── Dist Mode ─────────────────────────────────────────────────────────────
collect_dist(){
  local -a pkgs=(./*.pkg.tar.*)
  ((${#pkgs[@]})) || return 0
  mkdir -p ./dist
  sha256sum "${pkgs[@]}"
  mv "${pkgs[@]}" ./dist/
  log "Artifacts moved to dist/"
}

# ─── Main ──────────────────────────────────────────────────────────────────
main(){
  local -a targets=() args=()
  while (($#)); do
    case $1 in
      -h|--help) usage; exit 0 ;;
      -j|--jobs) MAX_JOBS=${2:-$MAX_JOBS}; shift 2 ;;
      -s|--serial) PARALLEL=false; shift ;;
      -r|--retry) RETRIES=${2:-3}; shift 2 ;;
      -f|--force) FORCE_BUILD=1; shift ;;
      -d|--dist) DIST_MODE=1; shift ;;
      --one) ONE_PACKAGE=${2:-}; shift 2 ;;
      -*) die "Unknown option: $1" ;;
      *) args+=("$1"); shift ;;
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
  log "Building ${#targets[@]} package(s) [parallel=$PARALLEL, jobs=$MAX_JOBS, retries=$RETRIES]"
  local failed=0
  local -a pids=()
  local -A pid_pkg=()
  for pkg in "${targets[@]}"; do
    [[ -f $pkg/PKGBUILD ]] || { err "Missing PKGBUILD: $pkg"; ((failed++)); continue; }
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
  ((DIST_MODE)) && collect_dist
  ((failed)) && die "$failed package(s) failed" 1
  sep
  log "Success: All packages built"
}
main "$@"

# vim:set sw=2 ts=2 et:
