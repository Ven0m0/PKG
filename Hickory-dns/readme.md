# [Hickory-dns](https://github.com/hickory-dns/hickory-dns)


## Setting Up Hickory DNS as Your System DNS Client

### 1. Install Hickory DNS
```bash
git clone https://github.com/hickory-dns/hickory-dns.git
cd hickory-dns/hickory-server
cargo build --release --features "sqlite"
sudo cp target/release/hickory-server /usr/local/bin/hickory-server
```

fork from pull request:
```
git clone --branch cpu-comment-crawl_dev --single-branch https://github.com/cpu/trust-dns.git
```

### 2. Configure Hickory DNS

Create a configuration file at /etc/hickory/hickory.toml:
```
[server]
listen = ["127.0.0.1:53"]  # Listen on localhost UDP and TCP port 53

[resolver]
upstream = ["1.1.1.1:53", "8.8.8.8:53"]  # Upstream DNS servers

[logging]
level = "info"
```

### 3. Create a Systemd Service
```
[Unit]
Description=Hickory DNS Server
After=network.target

[Service]
ExecStart=/usr/local/bin/hickory-server --config /etc/hickory/hickory.toml
Restart=on-failure
User=nobody
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hickory.service
```

### 4. Update `/etc/resolv.conf`
```bash
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
```

### 5. Test the Setup
```bash

```
