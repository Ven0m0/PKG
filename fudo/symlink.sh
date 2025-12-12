#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob globstar
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}
[[ $s != /* ]] && s=$PWD/$s
cd -P -- "${s%/*}"

[[ -d /usr/local/bin ]] || sudo mkdir -p /usr/local/bin
printf "Sudo earlier in path (at '/usr/local/bin/') as sudo to keep normal sudo installed\n"
[[ -f /usr/bin/fudo ]] && sudo ln -sf /usr/bin/fudo /usr/local/bin/sudo
export FUDO_HIDE=1
