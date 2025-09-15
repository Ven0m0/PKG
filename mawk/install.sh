#!/usr/bin/bash
set -euo pipefail

sudo pacman -S mawk
sudo mkdir -p /usr/local/bin && sudo mkdir -p /usr/local/share/man/man1
sudo ln -sfn /usr/bin/mawk /usr/local/bin/awk
sudo ln -sfn /usr/share/man/man1/mawk.1.gz /usr/local/share/man/man1/awk.1

# All
#sudo ln -sfn /usr/bin/mawk /usr/bin/awk
#sudo ln -sfn /usr/share/man/man1/mawk.1.gz /usr/share/man/man1p/awk.1p.gz
