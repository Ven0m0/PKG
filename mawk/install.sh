#!/usr/bin/bash
set -euo pipefail

sudo pacman -S mawk
sudo ln -sfn /usr/bin/mawk /usr/local/bin/awk
