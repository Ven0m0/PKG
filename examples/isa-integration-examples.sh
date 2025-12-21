#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'

# ═══════════════════════════════════════════════════════════════════════════
# Example: Integration of ISA Level Detection in Build Scripts
# ═══════════════════════════════════════════════════════════════════════════
# This demonstrates how to use check-isa-level.sh in your build workflow

# Locate the ISA check script
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ISA_CHECK="$SCRIPT_DIR/check-isa-level.sh"

# Colors for output
readonly EX_G=$'\e[32m' EX_Y=$'\e[33m' EX_D=$'\e[0m'
log(){ printf '%b\n' "${EX_G}➜ $*${EX_D}"; }
warn(){ printf '%b\n' "${EX_Y}⚠ $*${EX_D}" >&2; }

# ─── Example 1: Auto-detect optimal compiler flags ─────────────────────────
example_1_autodetect_flags(){
  log "Example 1: Auto-detect optimal compiler flags"
  
  if [[ ! -x $ISA_CHECK ]]; then
    warn "ISA check script not found, using baseline flags"
    export CFLAGS="-O2 -pipe"
    export CXXFLAGS="-O2 -pipe"
    return
  fi
  
  # Get recommended march flag
  local march_flag
  march_flag=$("$ISA_CHECK" march)
  
  log "Detected CPU supports: $march_flag"
  
  # Set compiler flags
  export CFLAGS="$march_flag -O3 -pipe -fno-plt"
  export CXXFLAGS="$march_flag -O3 -pipe -fno-plt"
  export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
  
  log "CFLAGS: $CFLAGS"
  log "CXXFLAGS: $CXXFLAGS"
}

# ─── Example 2: Conditional builds based on ISA level ──────────────────────
example_2_conditional_build(){
  log "Example 2: Conditional builds based on ISA level"
  
  if [[ ! -x $ISA_CHECK ]]; then
    warn "ISA check script not found, building baseline version"
    return
  fi
  
  # Check if CPU supports v3
  if "$ISA_CHECK" check x86-64-v3; then
    log "Building optimized x86-64-v3 version"
    export CFLAGS="-march=x86-64-v3 -O3"
    export PACKAGE_VARIANT="v3"
  elif "$ISA_CHECK" check x86-64-v2; then
    log "Building x86-64-v2 version"
    export CFLAGS="-march=x86-64-v2 -O2"
    export PACKAGE_VARIANT="v2"
  else
    log "Building baseline x86-64 version"
    export CFLAGS="-march=x86-64 -O2"
    export PACKAGE_VARIANT="baseline"
  fi
  
  log "Package variant: $PACKAGE_VARIANT"
}

# ─── Example 3: Source as library ───────────────────────────────────────────
example_3_library_usage(){
  log "Example 3: Using as a library"
  
  if [[ ! -f $ISA_CHECK ]]; then
    warn "ISA check script not found"
    return
  fi
  
  # Source the script to use its functions
  # shellcheck source=/dev/null
  source "$ISA_CHECK"
  
  # Use functions directly
  local highest
  highest=$(get_highest_isa_level)
  log "Highest ISA level: $highest"
  
  # Check multiple levels
  local -a supported_levels=()
  for level in "x86-64-v2" "x86-64-v3" "x86-64-v4"; do
    # shellcheck disable=SC2310
    if check_supported_isa_level "$level"; then
      supported_levels+=("$level")
    fi
  done
  
  if [[ ${#supported_levels[@]} -gt 0 ]]; then
    log "Supported levels: ${supported_levels[*]}"
  fi
}

# ─── Example 4: Integration in PKGBUILD ────────────────────────────────────
example_4_pkgbuild_integration(){
  cat <<'EOF'

Example 4: Integration in PKGBUILD

# In your PKGBUILD, add this to the build() or prepare() function:

build() {
  cd "$srcdir/$pkgname-$pkgver"
  
  # Auto-detect ISA level and set optimization flags
  if [[ -x /path/to/check-isa-level.sh ]]; then
    _march=$(/path/to/check-isa-level.sh march)
    export CFLAGS="${CFLAGS/-O2/$_march -O3}"
    export CXXFLAGS="${CXXFLAGS/-O2/$_march -O3}"
  fi
  
  # Your build commands
  ./configure --prefix=/usr
  make
}

# Or conditionally build different variants:

package() {
  if [[ -x /path/to/check-isa-level.sh ]]; then
    if /path/to/check-isa-level.sh check x86-64-v3; then
      pkgdesc+=" (optimized for x86-64-v3)"
    fi
  fi
  
  cd "$srcdir/$pkgname-$pkgver"
  make DESTDIR="$pkgdir" install
}

EOF
}

# ─── Main ───────────────────────────────────────────────────────────────────
main(){
  echo "═══════════════════════════════════════════════════════════════════"
  echo "ISA Level Detection - Integration Examples"
  echo "═══════════════════════════════════════════════════════════════════"
  echo
  
  example_1_autodetect_flags
  echo
  
  example_2_conditional_build
  echo
  
  example_3_library_usage
  echo
  
  example_4_pkgbuild_integration
}

main "$@"
