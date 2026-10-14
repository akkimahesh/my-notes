# Alertmanager Installation and Configuration Guide

Prometheus **Alertmanager** handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver (Email, Slack, PagerDuty, Webhooks, etc.). It also handles silencing and inhibition of alerts.

---

## Quick Reference

| Property | Value |
| :--- | :--- |
| **Default Port** | `9093` |
| **Service Name** | `alertmanager.service` |
| **Config File** | `/etc/alertmanager/alertmanager.yml` |
| **Data Directory** | `/var/lib/alertmanager/` |
| **Web UI** | `http://<server-ip>:9093` |

---

## Step 1: Create Dedicated System User and Directories

For security reasons, do not run Alertmanager as root. Create a dedicated system user and required directories:

```bash
# Create system user
sudo useradd --no-create-home --shell /bin/false alertmanager

# Create directories for configuration and storage
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager

# Set initial permissions
sudo chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager
```

---

## Step 2: Download and Extract Alertmanager

Check the latest version from the [Prometheus GitHub Releases page](https://github.com/prometheus/alertmanager/releases).

```bash
# Define version (adjust if a newer version is desired)
ALERTMANAGER_VERSION="0.27.0"

# Download the tarball
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz

# Extract archive
tar -xzf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
```

---

## Step 3: Install Binaries

Move the `alertmanager` and `amtool` binaries to `/usr/local/bin`:

```bash
cd alertmanager-${ALERTMANAGER_VERSION}.linux-amd64

# Copy binaries
sudo cp alertmanager amtool /usr/local/bin/

# Set ownership
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool

# Verify installation
alertmanager --version
amtool --version
```

---

## Step 4: Configure Alertmanager

Create the base configuration file at `/etc/alertmanager/alertmanager.yml`:

```bash
sudo nano /etc/alertmanager/alertmanager.yml
```

Paste the following sample configuration:

```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default-receiver'

receivers:
- name: 'default-receiver'
  # Example: Add email, slack, or webhook configurations here
  # webhook_configs:
  # - url: 'http://127.0.0.1:5001/'
```

Set the correct ownership on the configuration file:

```bash
sudo chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
```

Verify configuration syntax using `amtool`:

```bash
amtool check-config /etc/alertmanager/alertmanager.yml
```

---

## Step 5: Create Systemd Service

Create a systemd unit file at `/etc/systemd/system/alertmanager.service`:

```bash
sudo nano /etc/systemd/system/alertmanager.service
```

Add the following configuration:

```ini
[Unit]
Description=Alertmanager for Prometheus
Documentation=https://prometheus.io/docs/alerting/latest/alertmanager/
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager/ \
  --web.listen-address=0.0.0.0:9093
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

## Step 6: Start and Enable the Service

Reload systemd daemon, enable automatic start on boot, and start Alertmanager:

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable alertmanager

# Start the service
sudo systemctl start alertmanager

# Check service status
sudo systemctl status alertmanager
```

---

## Step 7: Configure Firewall

Allow incoming traffic on port `9093`:

### UFW (Ubuntu / Debian)
```bash
sudo ufw allow 9093/tcp
sudo ufw reload
```

### Firewalld (RHEL / CentOS / AlmaLinux)
```bash
sudo firewall-cmd --permanent --add-port=9093/tcp
sudo firewall-cmd --reload
```

---

## Step 8: Verification

Test if Alertmanager is responding:

```bash
# Check health status
curl -s http://localhost:9093/-/ready
# Output should return: OK

# View web interface in browser:
# http://<SERVER_IP>:9093
```

---

## Connecting Prometheus to Alertmanager

In your `prometheus.yml` file, configure the `alerting` block to point to Alertmanager:

```yaml
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - 'localhost:9093'
```

After updating `prometheus.yml`, reload Prometheus:

```bash
sudo systemctl reload prometheus
```
