#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail; shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C
has(){ command -v -- "$1" &>/dev/null; }
die(){ printf '%s\n' "$1" >&2; exit "${2:-1}"; }

sudo -v

readonly MALLOC_CONF="thp:always,metadata_thp: always,tcache:true,percpu_arena:percpu"
export MALLOC_CONF _RJEM_MALLOC_CONF="$MALLOC_CONF" RUSTC_BOOTSTRAP=1 CARGO_INCREMENTAL=0 CARGO_PROFILE_RELEASE_LTO=true CARGO_CACHE_RUSTC_INFO=1

if has sccache; then
  export CC="sccache clang" CXX="sccache clang++" RUSTC_WRAPPER=sccache SCCACHE_IDLE_TIMEOUT=10800
fi

export RUSTFLAGS="-Copt-level=3 -Ctarget-cpu=native -Ccodegen-units=1 -Cstrip=symbols -Clto=fat -Clink-arg=-fuse-ld=mold -Cpanic=immediate-abort"
[[ ${CARGO_NIGHTLY:-} == 1 ]] && RUSTFLAGS+=" -Zunstable-options -Ztune-cpu=native"

cargo +nightly install etchdns -f 2>/dev/null || cargo install etchdns -f
pbin=$(command -v etchdns || printf '%s\n' "$HOME/.cargo/bin/etchdns")
[[ -x $pbin ]] || die "etchdns binary not found after install"
pbin_name=$(basename "$pbin")

sudo bash <<'SUDO_BLOCK'
set -euo pipefail
pbin="$1" pbin_name="$2"
ln -sf "$pbin" "/usr/local/bin/$pbin_name"

cat >/etc/etchdns.toml <<'EOF'
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
user = "root"
group = "root"
EOF

cat >/etc/systemd/system/etchdns.service <<'EOF'
[Unit]
Description=EtchDNS high-performance DNS proxy
After=network.target

[Service]
ExecStart=/usr/local/bin/etchdns -c /etc/etchdns. toml
User=root
Group=root
LimitNOFILE=65536
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
for unit in systemd-resolved-monitor.socket systemd-resolved-varlink.socket systemd-resolved.service; do
  systemctl is-enabled "$unit" &>/dev/null && systemctl disable --now "$unit"
done
systemctl enable --now etchdns
SUDO_BLOCK "$pbin" "$pbin_name"

printf 'EtchDNS setup complete. Check: systemctl status etchdns\n'
