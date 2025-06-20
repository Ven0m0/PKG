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
dig @127.0.0.1 google.com
```
or manually specify the port to test:
```bash
dig @127.0.0.1 -p 2345 example.com
```


   - 1. [Testing the resolver via CLI with resolve](https://github.com/hickory-dns/hickory-dns/blob/main/crates/resolver/README.md#testing-the-resolver-via-cli-with-resolve)
```bash
cargo install --bin resolve hickory-util
```

```bash
$ resolve www.example.com.
Querying for www.example.com. A from udp:8.8.8.8:53, tcp:8.8.8.8:53, udp:8.8.4.4:53, tcp:8.8.4.4:53, udp:[2001:4860:4860::8888]:53, tcp:[2001:4860:4860::8888]:53, udp:[2001:4860:4860::8844]:53, tcp:[2001:4860:4860::8844]:53
Success for query name: www.example.com. type: A class: IN
        www.example.com. 21063 IN A 93.184.215.14
```
