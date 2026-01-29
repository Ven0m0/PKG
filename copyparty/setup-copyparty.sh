#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob globstar
export LC_ALL=C HOME="/home/${SUDO_USER:-${USER:-$(id -un)}}" DEBIAN_FRONTEND=noninteractive
IFS=$'\n\t'
s=${BASH_SOURCE[0]}
[[ $s != /* ]] && s=$PWD/$s
cd -P -- "${s%/*}"
has() { command -v -- "$1" &>/dev/null; }

readonly COPYPARTY_PORT=3923 COPYPARTY_DIR="$HOME/Public"
printf 'Setting up Copyparty with network access and Samba support...\nInstalling packages...\n'
sudo apt-get update && sudo apt-get install -y python3-pip samba avahi-daemon libnss-mdns || {
  printf 'Error: Failed to install required packages\n' >&2
  exit 1
}
has copyparty || {
  printf 'Installing copyparty via pip...\n'
  pip3 install --user copyparty
}
mkdir -p ~/.config/copyparty
cat >~/.config/copyparty/config.py <<'EOF'
#!/usr/bin/env python3
"""copyparty config"""
import socket
def get_local_ip():
  s = socket.socket(socket.AF_INET, SOCK_DGRAM)
  try:
    s.connect(("8.8.8.8", 80))
    IP = s.getsockname()[0]
  except Exception:
    IP = "127.0.0.1"
  finally:
    s.close()
  return IP
LOCAL_IP = get_local_ip()
CFG = {
  "addr": [f"{LOCAL_IP}:3923"],
  "vols": {
    "~": {"path": "~/Public", "auth": "any", "perm": "ro"},
    "upload": {"path": "~/Public/uploads", "auth": "any", "perm": "wo"},
    "share": {"path": "~/Public/share", "auth": "any", "perm": "rw"}
  },
  "smbscan": True,
  "smbsrv": True,
}
users = {
  "admin": {"pass": "changeThisPassword", "perm": "*:rwm"}
}
EOF
chmod +x ~/.config/copyparty/config.py
mkdir -p ~/Public/uploads ~/Public/share
printf 'Configuring Samba...\n'
CURRENT_USER=$(whoami)
sudo tee /etc/samba/smb.conf >/dev/null <<EOF
[global]
  workgroup = WORKGROUP
  server string = Copyparty Samba Server
  server role = standalone server
  log file = /var/log/samba/%m.log
  max log size = 50
  dns proxy = no
  map to guest = Bad User
  usershare allow guests = yes

[copyparty]
  comment = Copyparty Shared Folders
  path = /home/${CURRENT_USER}/Public
  browseable = yes
  read only = no
  guest ok = yes
  create mask = 0644
  directory mask = 0755
EOF
mkdir -p ~/.config/systemd/user
cat >~/.config/systemd/user/copyparty.service <<'EOF'
[Unit]
Description=Copyparty web server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/copyparty -c %h/.config/copyparty/config.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
printf 'Enabling and starting services...\n'
sudo systemctl enable --now smbd nmbd avahi-daemon || printf 'Warning: Failed to enable some system services\n' >&2
systemctl --user daemon-reload
systemctl --user enable copyparty.service
systemctl --user start copyparty.service || {
  printf 'Error: Failed to start copyparty service\nCheck logs with: systemctl --user status copyparty.service\n' >&2
  exit 1
}
sudo loginctl enable-linger "$(whoami)"
systemctl is-active --quiet ufw && {
  printf 'Configuring ufw...\n'
  sudo ufw allow "$COPYPARTY_PORT"/tcp
  sudo ufw allow Samba
}
IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
printf '\n\n==============================================\nCopyparty setup complete!\n==============================================\n'
printf 'Access: https://%s:%s\n\nIMPORTANT: Change admin password in ~/.config/copyparty/config.py\nThen restart: systemctl --user restart copyparty.service\n\n' "$IP" "$COPYPARTY_PORT"
printf 'Status: systemctl --user status copyparty.service\n==============================================\n'
