# Prometheus Server Installation and Setup Guide

**Prometheus** is an open-source systems monitoring and alerting toolkit that collects and stores metrics as time-series data (key-value pairs timestamped at ingestion).

---

## Quick Reference

| Property | Value |
| :--- | :--- |
| **Default Port** | `9090` |
| **Service Name** | `prometheus.service` |
| **Config Directory** | `/etc/prometheus/` |
| **Data Directory** | `/var/lib/prometheus/` |
| **Binaries** | `/usr/local/bin/prometheus`, `/usr/local/bin/promtool` |
| **Web UI** | `http://<server-ip>:9090` |

---

## Step 1: Create Dedicated System User and Directories

Create an isolated system user without shell access:

```bash
# Create system user
sudo useradd --no-create-home --shell /bin/false prometheus

# Create required directories
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

# Set ownership
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

---

## Step 2: Download and Extract Prometheus

Find the desired version from the [Prometheus GitHub Releases](https://github.com/prometheus/prometheus/releases).

```bash
# Define version
PROMETHEUS_VERSION="3.0.0"

# Download official release tarball
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# Extract archive
tar -xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
```

> [!WARNING]
> Do NOT extract directly using `tar -xf <file> /opt/`. Specifying a path at the end of tar without the `-C` flag tells tar to extract a member with that name from inside the archive, which causes an error.

---

## Step 3: Copy Binaries and Console Files

```bash
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64

# Copy binaries to /usr/local/bin
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/

# Set ownership on binaries
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Copy console libraries and default configuration
sudo cp -r consoles /etc/prometheus/
sudo cp -r console_libraries /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/

# Set ownership on configuration files
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Verify binary installation
prometheus --version
promtool --version
```

> [!NOTE]
> Prometheus is a compiled binary. **Never run `sh prometheus`** as shell cannot interpret a compiled Go binary. Use `./prometheus` or manage it via systemd.

---

## Step 4: Verify Default Configuration

Check your Prometheus configuration file syntax using `promtool`:

```bash
promtool check config /etc/prometheus/prometheus.yml
```

Expected output:
```text
Checking /etc/prometheus/prometheus.yml
  SUCCESS: 0 rule files found
```

---

## Step 5: Create Systemd Service

> [!IMPORTANT]
> The systemd unit file must be located in `/etc/systemd/system/` (NOT `/etc/system/system/`).

Create `/etc/systemd/system/prometheus.service`:

```bash
sudo nano /etc/systemd/system/prometheus.service
```

Add the following service configuration:

```ini
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

> [!TIP]
> The `--web.enable-lifecycle` flag allows reloading Prometheus configurations on-the-fly without restarting the service by sending an HTTP POST request:
> ```bash
> curl -X POST http://localhost:9090/-/reload
> ```

---

## Step 6: Start and Enable Prometheus

```bash
# Reload systemd manager configuration
sudo systemctl daemon-reload

# Enable service to run on boot
sudo systemctl enable prometheus

# Start Prometheus
sudo systemctl start prometheus

# Check service status
sudo systemctl status prometheus
```

---

## Step 7: Configure Firewall

Allow incoming traffic on port `9090`:

### UFW (Ubuntu / Debian)
```bash
sudo ufw allow 9090/tcp
sudo ufw reload
```

### Firewalld (RHEL / CentOS / AlmaLinux)
```bash
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --reload
```

---

## Step 8: Verification

1. **Verify Health Endpoint:**
   ```bash
   curl -s http://localhost:9090/-/healthy
   # Output: Prometheus Server is Healthy.
   ```

2. **Access the Web UI:**
   Open your browser and navigate to:
   ```text
   http://<SERVER_IP>:9090
   ```
   Navigate to **Status > Targets** to view your active scraping endpoints.
