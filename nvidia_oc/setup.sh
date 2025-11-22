
if ! command -v nvidia_oc &>/dev/null; then
  if command -v mise &>/dev/null
    mise use -g cargo:nvidia_oc
  else
    cargo install nvidia_oc
  fi
fi
if command -v mise &>/dev/null && mise which nvidia_oc &>/dev/null; then
  fbin="$(mise which nvidia_oc 2>/dev/null || command -v nvidia_oc 2>/dev/null)"
else
  fbin="$(command -v nvidia_oc || echo "$HOME"/.cargo/bin/nvidia_oc)"
fi
fbin="${fbin:-${HOME}/.cargo/bin/nvidia_oc}"
mkdir -p /usr/local/bin
ln -sf "$fbin" "/usr/local/bin/nvidia_oc"

sudo chown root:root "/usr/local/bin/nvidia_oc"
sudo chmod 755 "/usr/local/bin/nvidia_oc"

sudo cat > "/etc/systemd/system/nvidia_oc.service" <<'EOF'
[Unit]
Description=NVIDIA Overclocking Service
After=network.target

[Service]
ExecStart=/usr/local/bin/nvidia_oc set --index 0 --power-limit 200000 --freq-offset 160 --mem-offset 750 --min-clock 0 --max-clock 2000
User=root
Group=root
LimitNOFILE=65536
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now nvidia_oc
echo "nvidia_oc setup complete. Check service status: systemctl status nvidia_oc"
