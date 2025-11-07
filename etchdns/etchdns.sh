#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C LANGUAGE=C HOME="/home/${SUDO_USER:-$USER}"
cd -P -- "$(cd -P -- "${BASH_SOURCE[0]%/*}" && echo "$PWD")" || exit 1

# Request sudo once at the start
sudo -v

if command -v sccache &>/dev/null; then
  export CC="sccache clang" CXX="sccache clang++" RUSTC_WRAPPER=sccache SCCACHE_IDLE_TIMEOUT=10800
  sccache --start-server &>/dev/null
fi
export RUSTFLAGS="-Copt-level=3 -Ctarget-cpu=native -Ccodegen-units=1 -Cstrip=symbols -Clto=fat -Clink-arg=-fuse-ld=mold -Cpanic=immediate-abort -Zunstable-options \
-Ztune-cpu=native -Cllvm-args=-enable-dfa-jump-thread -Zfunction-sections -Zfmt-debug=none -Zlocation-detail=none"
MALLOC_CONF="thp:always,metadata_thp:always,tcache:true,percpu_arena:percpu"
export MALLOC_CONF _RJEM_MALLOC_CONF="$MALLOC_CONF" RUSTC_BOOTSTRAP=1 CARGO_INCREMENTAL=0 OPT_LEVEL=3 CARGO_PROFILE_RELEASE_LTO=true CARGO_CACHE_RUSTC_INFO=1 
cargo +nightly -Zunstable-options -Zavoid-dev-deps install etchdns -f
pbin="$(command -v etchdns || echo ${HOME}/.cargo/bin/etchdns)"

# Consolidate all sudo operations into a single block
sudo bash <<SUDO_BLOCK
ln -sf "$pbin" "/usr/local/bin/\$(basename "$pbin")"
# chown root:root "/usr/local/bin/\$(basename "$pbin")"; chmod 755 "/usr/local/bin/\$(basename "$pbin")"

# Prepare config - write directly instead of using cat
cat > /etc/etchdns.toml <<'EOF'
listen_addr = "127.0.0.1:53"
cache = true
cache_size = 10000
cache_ttl_cap = 86400
cache_in_memory_only = false
prefetch_popular_queries = true
prefetch_threshold = 5
log_level = "warn"
listen_addresses = ["0.0.0.0:53"]
dns_packet_len_max = 4096
upstream_servers = [
  "1.1.1.2:53",
  "1.0.0.2:53",
  "1.1.1.1:53",
  "1.0.0.1:53"
]
load_balancing_strategy = "fastest"
server_timeout = 3
probe_interval = 60
max_udp_clients = 1000
max_tcp_clients = 1000
max_doh_connections = 100
max_inflight_queries = 1000
authoritative_dns = false
serve_stale_grace_time = 86400
serve_stale_ttl = 120
negative_cache_ttl = 120
min_cache_ttl = 1
udp_rate_limit_window = 0
udp_rate_limit_count = 1000
udp_rate_limit_max_clients = 100000
tcp_rate_limit_window = 0
tcp_rate_limit_count = 100
tcp_rate_limit_max_clients = 50000
doh_rate_limit_window = 0
doh_rate_limit_count = 400
doh_rate_limit_max_clients = 50000
metrics_address = "127.0.0.1:9100"
metrics_path = "/metrics"
max_metrics_connections = 25
control_listen_addresses = ["127.0.0.1:8080"]
control_path = "/control"
max_control_connections = 16
query_log_include_client_addr = false
query_log_include_query_type = false
enable_ecs = true
ecs_prefix_v4 = 24
ecs_prefix_v6 = 56
enable_strict_ip_validation = false
block_private_ips = false
block_loopback_ips = false
min_client_port = 1024
blocked_ip_ranges = []
user = "$USER"
group = "\$(id -gn $USER)"
EOF

# Create service
cat > /etc/systemd/system/etchdns.service <<'EOF'
[Unit]
Description=EtchDNS high-performance DNS proxy
After=network.target

[Service]
ExecStart=/usr/local/bin/etchdns -c /etc/etchdns.toml
User=root
Group=root
LimitNOFILE=65536
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
systemctl disable --now systemd-resolved-monitor.socket
systemctl disable --now systemd-resolved-varlink.socket
systemctl disable --now systemd-resolved.service
systemctl enable --now etchdns
systemctl daemon-reload
SUDO_BLOCK

echo "EtchDNS setup complete. Check service status: systemctl status etchdns"
