#!/bin/bash

# Make the dir if it doesnt exist yet (it should be there by default however)
[ ! -d ~/.local/bin ] && mkdir -p ~/.local/bin
echo "Sudo earlier in path (at '~/.local/bin') as sudo to keep normal sudo installed"
[ -f /usr/bin/fudo ] && ln -sf /usr/bin/fudo ~/.local/bin/sudo
