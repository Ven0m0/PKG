#!/usr/bin/env bash

if command -v fish && [[ -d $HOME/.config/fish/functions/ ]]; then
  wget -N -P "$HOME/.config/fish/functions/" https://raw.githubusercontent.com/denisidoro/navi/refs/heads/master/shell/navi.plugin.fish
elif command -v fish && [[ ! -d $HOME/.config/fish/functions/ ]]; then
  mkdir -p "$HOME/.config/fish/functions/"
  wget -N -P "$HOME/.config/fish/functions/" https://raw.githubusercontent.com/denisidoro/navi/refs/heads/master/shell/navi.plugin.fish
fi
# ~/.config/fish/config.fish
echo 'navi widget fish | source'
# ~/.bashrc
echo 'eval "$(navi widget bash)"'
