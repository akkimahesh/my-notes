# SonarQube Server Installation & Production Setup Guide

**SonarQube** is an automatic code review tool to detect bugs, code smells, and security vulnerabilities in your source code.

---

## Quick Reference

| Property | Value |
| :--- | :--- |
| **Default Port** | `9000` |
| **Default Credentials** | `admin` / `admin` |
| **Java Requirement** | OpenJDK 17 (Required for SonarQube 10.x+) |
| **Database** | PostgreSQL 13+ |
| **Service File** | `/etc/systemd/system/sonarqube.service` |
| **Logs Path** | `/opt/sonarqube/logs/` (`sonar.log`, `es.log`, `web.log`) |

---

## Step 1: Kernel & System Tuning (Mandatory for Elasticsearch)

SonarQube bundles an embedded Elasticsearch engine. If kernel memory map counts and file descriptor limits are not set, **Elasticsearch will fail to start and SonarQube will crash**.

### 1. Set Kernel Parameters
Edit `/etc/sysctl.conf`:

```bash
sudo bash -c 'cat <<EOF >> /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
vm.swappiness=1
EOF'

# Apply immediately without rebooting
sudo sysctl --system
```

### 2. Set Security Limits
Edit `/etc/security/limits.conf`:

```bash
sudo bash -c 'cat <<EOF >> /etc/security/limits.conf
sonar   nofile   65536
sonar   nproc    4096
EOF'
```

---

## Step 2: Install Java 17

SonarQube 10.x requires Java 17:

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk

# Verify Java version
java -version
```

---

## Step 3: Install and Configure PostgreSQL

SonarQube requires a dedicated database.

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Enable and start PostgreSQL service
sudo systemctl enable --now postgresql
```

### Create Sonar Database & User
Switch to the postgres user and execute the setup commands:

```bash
sudo -i -u postgres psql <<EOF
CREATE USER sonar WITH ENCRYPTED PASSWORD 'sonar_strong_password';
CREATE DATABASE sonarqube OWNER sonar;
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
EOF
```

> [!NOTE]
> On PostgreSQL 15+, ensure the `sonar` user has full permissions on the `public` schema:
> ```bash
> sudo -i -u postgres psql -d sonarqube -c "GRANT ALL ON SCHEMA public TO sonar;"
> ```

---

## Step 4: Download and Install SonarQube

```bash
sudo apt install -y wget unzip

# Define version
SONAR_VERSION="10.5.1.90531"

# Download distribution
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip

# Unzip to /opt
sudo unzip sonarqube-${SONAR_VERSION}.zip -d /opt/

# Rename directory for clean pathing
sudo mv /opt/sonarqube-${SONAR_VERSION} /opt/sonarqube

# Create dedicated unprivileged system user
sudo useradd --system --no-create-home --shell /bin/bash --home /opt/sonarqube sonar

# Set directory permissions
sudo chown -R sonar:sonar /opt/sonarqube
sudo chmod -R 755 /opt/sonarqube

# Cleanup zip
rm -f sonarqube-${SONAR_VERSION}.zip
```

---

## Step 5: Configure `sonar.properties`

Edit the SonarQube configuration file at `/opt/sonarqube/conf/sonar.properties`:

```bash
sudo nano /opt/sonarqube/conf/sonar.properties
```

Update or uncomment the following settings:

```properties
# Database credentials
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar_strong_password
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

# Web server configuration
sonar.web.host=0.0.0.0
sonar.web.port=9000

# Logs directory
sonar.path.logs=/opt/sonarqube/logs
```

---

## Step 6: Create Systemd Service

Create `/etc/systemd/system/sonarqube.service`:

```bash
sudo nano /etc/systemd/system/sonarqube.service
```

Add the following unit definition:

```ini
[Unit]
Description=SonarQube service
After=syslog.target network.target postgresql.service

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
```

---

## Step 7: Start and Enable SonarQube

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable sonarqube

# Start SonarQube
sudo systemctl start sonarqube

# Check systemd status
sudo systemctl status sonarqube
```

---

## Step 8: Configure Firewall

Allow inbound traffic on port `9000`:

### UFW (Ubuntu / Debian)
```bash
sudo ufw allow 9000/tcp
sudo ufw reload
```

### Firewalld (RHEL / CentOS / AlmaLinux)
```bash
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --reload
```

---

## Step 9: Monitor Logs & Verification

SonarQube startup takes approximately 1 to 2 minutes while database schemas and Elasticsearch indices initialize.

Monitor logs using:
```bash
# Main orchestrator log
tail -f /opt/sonarqube/logs/sonar.log

# Web server log
tail -f /opt/sonarqube/logs/web.log

# Elasticsearch log
tail -f /opt/sonarqube/logs/es.log
```

Once you see `SonarQube is operational` in `sonar.log`, open your browser:
```text
http://<SERVER_IP>:9000
```
- **Username:** `admin`
- **Password:** `admin`
- Follow prompts to change the password immediately.
