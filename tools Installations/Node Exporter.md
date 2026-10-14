# Prometheus Node Exporter Installation Guide

**Node Exporter** is an official Prometheus exporter for hardware and OS metrics exposed by *NIX kernels (CPU, memory, disk, network usage, etc.).

---

## Quick Reference

| Property | Value |
| :--- | :--- |
| **Default Port** | `9100` |
| **Service Name** | `node_exporter.service` |
| **Binary Path** | `/usr/local/bin/node_exporter` |
| **Metrics URL** | `http://<server-ip>:9100/metrics` |

---

## Step 1: Create a System User

For security, run Node Exporter under its own unprivileged service user:

```bash
sudo useradd --no-create-home --shell /bin/false node_exporter
```

---

## Step 2: Download and Extract Binary

Check the latest release from the [Node Exporter Releases page](https://github.com/prometheus/node_exporter/releases).

```bash
# Set version
NODE_EXPORTER_VERSION="1.8.2"

# Download tarball
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# Extract archive
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
```

> [!WARNING]
> Do NOT use `tar -xf <file> /opt/` without the `-C` flag. In `tar`, specifying a directory without `-C` attempts to extract a member named `/opt/` from the archive and will fail.

---

## Step 3: Install Binary to `/usr/local/bin`

Move the compiled binary to `/usr/local/bin` and assign ownership:

```bash
# Copy binary
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Set ownership and executable permissions
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo chmod +x /usr/local/bin/node_exporter

# Clean up extracted files
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*
```

> [!NOTE]
> Node Exporter is a pre-compiled Go binary, **not a shell script**. Never execute it using `sh node_exporter`. Run it directly as `./node_exporter` or via systemd.

---

## Step 4: Create Systemd Service

Create the systemd service file at `/etc/systemd/system/node_exporter.service`:

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

Add the following unit configuration:

```ini
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

---

## Step 5: Start and Enable Node Exporter

Reload the systemd daemon, enable the service to start automatically on system boot, and start it:

```bash
# Reload daemon after creating new unit file
sudo systemctl daemon-reload

# Enable service on boot
sudo systemctl enable node_exporter

# Start the service
sudo systemctl start node_exporter

# Verify status
sudo systemctl status node_exporter
```

---

## Step 6: Configure Firewall

Allow incoming traffic on port `9100`:

### UFW (Ubuntu / Debian)
```bash
sudo ufw allow 9100/tcp
sudo ufw reload
```

### Firewalld (RHEL / CentOS / AlmaLinux)
```bash
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload
```

---

## Step 7: Verify Metrics Output

Test that Node Exporter is listening and outputting system metrics:

```bash
curl http://localhost:9100/metrics
```

Expected output begins with Prometheus metric headers, for example:
```text
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} ...
```

---

## Step 8: Add to Prometheus Configuration

To collect metrics from this node, add the target to your Prometheus server's `/etc/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['<NODE_IP_OR_HOSTNAME>:9100']
```

Then reload Prometheus:
```bash
sudo systemctl reload prometheus
```
