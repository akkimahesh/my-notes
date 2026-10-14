# Certbot SSL/TLS Certificate Installation & Auto-Renewal Guide

**Certbot** is an open-source, automatic tool developed by the Electronic Frontier Foundation (EFF) that issues and renews free SSL/TLS certificates from **Let's Encrypt**.

---

## Quick Reference

| Property | Value |
| :--- | :--- |
| **Ports Required** | `80` (HTTP challenge) and `443` (HTTPS) |
| **Certificate Path** | `/etc/letsencrypt/live/<domain>/fullchain.pem` |
| **Private Key Path** | `/etc/letsencrypt/live/<domain>/privkey.pem` |
| **Certificate Validity** | 90 days (Auto-renewed every 60 days) |
| **Timer / Service** | `certbot.timer` / `certbot.service` |

---

## Prerequisites

Before running Certbot:
1. Ensure your domain's DNS `A` or `AAAA` record points directly to your server's public IP address.
2. Inbound traffic on ports **80** (HTTP) and **443** (HTTPS) must be allowed in your cloud security group and local firewall.

---

## Step 1: Install Certbot

### Ubuntu / Debian
```bash
sudo apt update
sudo apt install -y certbot
```

### Install Web Server Plugins
- For **Nginx**:
  ```bash
  sudo apt install -y python3-certbot-nginx
  ```
- For **Apache**:
  ```bash
  sudo apt install -y python3-certbot-apache
  ```

---

## Step 2: Obtain SSL Certificates

### Option A: Automatic Nginx Setup (Recommended for Nginx)
Certbot automatically modifies your Nginx configuration files to enable HTTPS:

```bash
# Recommended with an email address for urgent renewal notices:
sudo certbot --nginx -d example.com -d www.example.com --agree-tos -m admin@example.com

# Without email registration:
sudo certbot --nginx -d example.com -d www.example.com --agree-tos --register-unsafely-without-email
```

---

### Option B: Automatic Apache Setup
```bash
sudo certbot --apache -d example.com -d www.example.com --agree-tos -m admin@example.com
```

---

### Option C: Standalone Mode (No Web Server or During Custom Deployments)
Certbot spins up its own temporary webserver on port 80 to complete the ACME challenge.

> [!CAUTION]
> If Nginx or Apache is already running, **you must temporarily stop it first**; otherwise, Certbot cannot bind to port 80.

```bash
# 1. Stop conflicting web server
sudo systemctl stop nginx # or sudo systemctl stop apache2

# 2. Issue certificate
sudo certbot certonly --standalone -d example.com -d www.example.com --agree-tos -m admin@example.com

# 3. Start web server again
sudo systemctl start nginx
```

---

### Option D: Webroot Mode (Zero Downtime without Plugin)
Validates ownership by writing challenge tokens to your website's existing document root without restarting web services:

```bash
sudo certbot certonly --webroot -w /var/www/html -d example.com -d www.example.com
```

---

## Step 3: Certificate Locations

All generated certificates are symlinked inside:
```bash
/etc/letsencrypt/live/<your-domain>/
├── cert.pem          # Server certificate
├── chain.pem         # Intermediate CA certificate
├── fullchain.pem     # Combined server and intermediate certificates (Use this in Nginx/Apache)
└── privkey.pem       # Private key (Keep secure!)
```

---

## Step 4: Automated Certificate Renewal

Let's Encrypt certificates are valid for **90 days**. Certbot automatically renews certificates within 30 days of expiration.

### 1. Test Renewal Process (Dry Run)
Verify that your renewal path works properly without actually renewing:

```bash
sudo certbot renew --dry-run
```

---

### 2. Built-in Systemd Timer (Default on Ubuntu/Debian)
Modern Debian and Ubuntu packages include a pre-configured systemd timer that checks twice daily:

```bash
# Check timer status
sudo systemctl status certbot.timer

# View timer triggers
systemctl list-timers | grep certbot
```

To automatically reload your web server whenever a certificate is renewed, add a deploy hook script:

```bash
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy/

sudo bash -c 'cat <<EOF > /etc/letsencrypt/renewal-hooks/deploy/reload-webserver.sh
#!/bin/bash
systemctl reload nginx 2>/dev/null || systemctl reload apache2 2>/dev/null
EOF'

sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-webserver.sh
```

---

### 3. Alternative: Cron Job Setup
If your distribution does not use systemd timers, schedule a cron job:

```bash
sudo crontab -e
```

Add the following entry (runs daily at 3:30 AM):

```cron
30 3 * * * /usr/bin/certbot renew --quiet --deploy-hook "systemctl reload nginx"
```
