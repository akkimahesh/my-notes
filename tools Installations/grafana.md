# Grafana Installation and Setup Guide

**Grafana** is an open-source analytics and interactive data visualization web application. It connects to data sources such as Prometheus, PostgreSQL, InfluxDB, and Elasticsearch to provide real-time dashboards and alerting.

---

## Quick Reference

| Property | Value |
| :--- | :--- |
| **Default Port** | `3000` |
| **Service Name** | `grafana-server.service` |
| **Default Credentials** | Username: `admin` \| Password: `admin` |
| **Configuration File** | `/etc/grafana/grafana.ini` |
| **Log Directory** | `/var/log/grafana/` |
| **Web UI** | `http://<server-ip>:3000` |

---

## Installation on Ubuntu / Debian

### Step 1: Install Dependencies & Import GPG Key
```bash
sudo apt update
sudo apt install -y apt-transport-https software-properties-common wget gpg

# Create keyrings directory
sudo mkdir -p /etc/apt/keyrings/

# Import Grafana GPG key
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
```

### Step 2: Add Grafana APT Repository
```bash
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
```

### Step 3: Install Grafana (OSS)
```bash
sudo apt update
sudo apt install -y grafana
```

---

## Installation on RHEL / CentOS / Fedora / AlmaLinux

### Step 1: Add the YUM/DNF Repository
Create `/etc/yum.repos.d/grafana.repo`:

```bash
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF'
```

### Step 2: Install Grafana
```bash
sudo dnf install -y grafana
# or on older CentOS/RHEL systems:
# sudo yum install -y grafana
```

---

## Step 4: Start and Enable Grafana Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable grafana-server

# Start service
sudo systemctl start grafana-server

# Verify running status
sudo systemctl status grafana-server
```

---

## Step 5: Configure Firewall

Allow incoming web traffic on port `3000`:

### UFW (Ubuntu / Debian)
```bash
sudo ufw allow 3000/tcp
sudo ufw reload
```

### Firewalld (RHEL / CentOS / AlmaLinux)
```bash
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

---

## Step 6: Initial Login & Configuration

1. Open your browser and navigate to:
   ```text
   http://<SERVER_IP>:3000
   ```
2. Enter the default credentials:
   - **Username:** `admin`
   - **Password:** `admin`
3. Prompt will ask to set a new secure password.

### Reset Forgotten Admin Password via CLI:
If you are locked out of the `admin` account:
```bash
sudo grafana-cli admin reset-admin-password <NEW_STRONG_PASSWORD>
```

---

## Step 7: Connecting Grafana to Prometheus

1. In the Grafana sidebar, click **Connections** (or gear icon) > **Data Sources**.
2. Click **Add data source** and select **Prometheus**.
3. Under **Connection**, set the Prometheus server URL:
   ```text
   http://localhost:9090
   ```
4. Click **Save & test**. A green banner saying *"Successfully queried the Prometheus API."* confirms connectivity.
