#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'

# ═══════════════════════════════════════════════════════════════════════════
# ISA Level Detection Utility - Check x86-64 microarchitecture levels
# ═══════════════════════════════════════════════════════════════════════════
# Based on: https://github.com/CachyOS/cachyos-repo-add-script
#
# x86-64 microarchitecture levels:
#   v1: Original AMD64 baseline (2003)
#   v2: +CMPXCHG16B, LAHF-SAHF, POPCNT, SSE3, SSE4.1, SSE4.2, SSSE3 (2009)
#   v3: +AVX, AVX2, BMI1, BMI2, F16C, FMA, LZCNT, MOVBE, XSAVE (2015)
#   v4: +AVX512F, AVX512BW, AVX512CD, AVX512DQ, AVX512VL (2017)
# ═══════════════════════════════════════════════════════════════════════════

# ─── Config ────────────────────────────────────────────────────────────────
# Try multiple common locations for the dynamic linker
readonly DYNAMIC_LINKER_PATHS=(
  "/lib/ld-linux-x86-64.so.2"
  "/lib64/ld-linux-x86-64.so.2"
  "/usr/lib/ld-linux-x86-64.so.2"
)
readonly SUPPORTED_LEVELS=("x86-64" "x86-64-v2" "x86-64-v3" "x86-64-v4")

# Find the dynamic linker
find_dynamic_linker(){
  for path in "${DYNAMIC_LINKER_PATHS[@]}"; do
    [[ -x $path ]] && printf '%s' "$path" && return 0
  done
  return 1
}

DYNAMIC_LINKER=""
# shellcheck disable=SC2310
if ! DYNAMIC_LINKER=$(find_dynamic_linker); then
  # Only error if we're trying to use it
  :
fi

# ─── Helpers ───────────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[34m' D=$'\e[0m'
err(){ printf '%b\n' "${R}✘ $*${D}" >&2; }
log(){ printf '%b\n' "${G}➜ $*${D}"; }
warn(){ printf '%b\n' "${Y}⚠ $*${D}" >&2; }
info(){ printf '%b\n' "${B}ℹ $*${D}"; }

# ─── Core Functions ────────────────────────────────────────────────────────

# Check if a specific ISA level is supported
# Returns: 0 if supported, 1 if not supported
check_supported_isa_level(){
  local level="${1:-}"
  
  [[ -z $level ]] && {
    err "Usage: check_supported_isa_level <level>"
    return 2
  }
  
  [[ -z $DYNAMIC_LINKER ]] && {
    err "Dynamic linker not found in standard locations"
    return 2
  }
  
  if "$DYNAMIC_LINKER" --help 2>/dev/null | grep -qF "$level (supported, searched)"; then
    return 0
  else
    return 1
  fi
}

# Get the highest supported ISA level
get_highest_isa_level(){
  local highest="x86-64"
  
  for level in "${SUPPORTED_LEVELS[@]}"; do
    # shellcheck disable=SC2310
    if check_supported_isa_level "$level"; then
      highest="$level"
    fi
  done
  
  printf '%s\n' "$highest"
}

# Check all ISA levels and display results
display_isa_support(){
  info "Checking x86-64 microarchitecture level support..."
  printf '\n'
  
  for level in "${SUPPORTED_LEVELS[@]}"; do
    # shellcheck disable=SC2310
    if check_supported_isa_level "$level"; then
      printf '%b%-15s%b %s\n' "$G" "$level" "$D" "[SUPPORTED]"
    else
      printf '%b%-15s%b %s\n' "$R" "$level" "$D" "[NOT SUPPORTED]"
    fi
  done
  
  printf '\n'
  local highest
  highest=$(get_highest_isa_level)
  log "Highest supported level: $highest"
}

# Get recommended compiler flags for the current CPU
get_recommended_march(){
  local highest
  highest=$(get_highest_isa_level)
  
  case $highest in
  x86-64-v4)
    printf '%s\n' "-march=x86-64-v4"
    ;;
  x86-64-v3)
    printf '%s\n' "-march=x86-64-v3"
    ;;
  x86-64-v2)
    printf '%s\n' "-march=x86-64-v2"
    ;;
  *)
    printf '%s\n' "-march=x86-64"
    ;;
  esac
}

# Display detailed CPU information from /proc/cpuinfo
display_cpu_info(){
  info "CPU Information:"
  printf '\n'
  
  if [[ -f /proc/cpuinfo ]]; then
    local model_name flags
    model_name=$(grep -m1 "^model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[[:space:]]*//')
    flags=$(grep -m1 "^flags" /proc/cpuinfo | cut -d: -f2)
    
    printf 'Model: %s\n' "$model_name"
    printf '\nRelevant instruction set flags:\n'
    
    # Check for specific important flags
    local important_flags=(
      "sse3" "ssse3" "sse4_1" "sse4_2" "popcnt" "lahf_lm"
      "avx" "avx2" "bmi1" "bmi2" "fma" "f16c" "movbe" "lzcnt"
      "avx512f" "avx512bw" "avx512cd" "avx512dq" "avx512vl"
    )
    
    for flag in "${important_flags[@]}"; do
      if grep -qw "$flag" <<<"$flags"; then
        printf '%b  %-12s%b [present]\n' "$G" "$flag" "$D"
      else
        printf '%b  %-12s%b [missing]\n' "$R" "$flag" "$D"
      fi
    done
  else
    warn "/proc/cpuinfo not available"
  fi
}

# ─── Usage ─────────────────────────────────────────────────────────────────
usage(){
  cat <<EOF
Usage: ${0##*/} [COMMAND] [LEVEL]

Check x86-64 microarchitecture level support on the current CPU.

COMMANDS:
  check [LEVEL]    Check if specific ISA level is supported (returns 0/1)
                   Levels: x86-64, x86-64-v2, x86-64-v3, x86-64-v4
  highest          Display the highest supported ISA level
  march            Display recommended -march compiler flag
  all              Display support for all ISA levels (default)
  cpu              Display detailed CPU information
  help             Show this help message

EXAMPLES:
  ${0##*/}                    # Show all ISA levels
  ${0##*/} check x86-64-v3    # Check if v3 is supported
  ${0##*/} highest            # Show highest supported level
  ${0##*/} march              # Show recommended -march flag

EXIT CODES:
  0 - Success (or ISA level is supported)
  1 - Failure (or ISA level is not supported)
  2 - Invalid usage or system error

For more information, see:
  https://en.wikipedia.org/wiki/X86-64#Microarchitecture_levels
  https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
EOF
}

# ─── Main ──────────────────────────────────────────────────────────────────
main(){
  case ${1:-all} in
  check)
    [[ -z ${2:-} ]] && {
      err "Missing ISA level argument"
      usage
      exit 2
    }
    check_supported_isa_level "$2"
    ;;
  highest)
    get_highest_isa_level
    ;;
  march)
    get_recommended_march
    ;;
  all)
    display_isa_support
    ;;
  cpu)
    display_cpu_info
    printf '\n'
    display_isa_support
    ;;
  help | --help | -h)
    usage
    exit 0
    ;;
  *)
    err "Unknown command: $1"
    usage
    exit 2
    ;;
  esac
}

# Only run main if script is executed directly (not sourced)
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
