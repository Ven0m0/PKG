#!/usr/bin/env bash
set -euo pipefail

# Make the dir if it doesnt exist yet (it should be there by default however)
[[ ! -d /usr/local/bin/ ]] && sudo mkdir -p /usr/local/bin/
echo "Sudo earlier in path (at '/usr/local/bin/') as sudo to keep normal sudo installed"
[[ -f /usr/bin/fudo ]] && sudo ln -sf /usr/bin/fudo /usr/local/bin/sudo
# Hide the command translation to stderr https://github.com/FragmentedCurve/fudo#using-fudo
export FUDO_HIDE=1
