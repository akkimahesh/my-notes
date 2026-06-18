# ASP.NET Core Configuration and Secrets Management on Ubuntu VM

## Overview

This document describes recommended practices for managing configuration and secrets for ASP.NET Core applications running on an Ubuntu VM, both with and without Docker.

## Principles

Separate **configuration** from **secrets**.

### Configuration Examples

Store in `appsettings.json` or `appsettings.Production.json`:

* Log levels
* Feature flags
* Application name
* Cache settings
* Timeouts
* Non-sensitive URLs

Example:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "Application": {
    "Name": "MyApp"
  }
}
```

### Secrets Examples

Do NOT store these in source control or Docker images:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "..."
  },
  "Jwt": {
    "Secret": "..."
  },
  "RedisPassword": "..."
}
```

Examples:

* Database passwords
* JWT secrets
* SMTP passwords
* API keys
* Third-party credentials

---

# Docker Deployment

## Recommended Directory Structure

```text
/opt/myapp/
└── docker-compose.yml

/etc/myapp/
├── app.env
└── appsettings.Production.json
```

## appsettings.Production.json

Store non-sensitive configuration:

```json
{
  "Application": {
    "Name": "MyApp"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

## app.env

Store secrets:

```env
DB_CONNECTION=Server=db;Database=AppDb;User Id=app;Password=secret;
JWT_SECRET=xxxxxxxx
SMTP_PASSWORD=xxxxxxxx
REDIS_PASSWORD=xxxxxxxx
```

## File Permissions

```bash
sudo chown root:root /etc/myapp/app.env
sudo chmod 600 /etc/myapp/app.env
```

## Docker Compose Configuration

```yaml
services:
  api:
    image: myapp:latest

    env_file:
      - /etc/myapp/app.env

    volumes:
      - /etc/myapp/appsettings.Production.json:/app/appsettings.Production.json:ro
```

### Benefits

* No secrets in Git
* No secrets in Docker image
* Easy configuration changes
* Clear separation of configuration and secrets
* Easy migration to a cloud secrets manager

---

# ASP.NET Core Environment Variables

ASP.NET Core automatically reads environment variables.

Example:

```csharp
var connectionString =
    builder.Configuration["DB_CONNECTION"];

var jwtSecret =
    builder.Configuration["JWT_SECRET"];
```

For nested configuration, use double underscores:

```env
ConnectionStrings__DefaultConnection=Server=db;Database=AppDb;...
Jwt__Secret=xxxxxxxx
Smtp__Password=xxxxxxxx
```

Read in code:

```csharp
builder.Configuration["ConnectionStrings:DefaultConnection"];
builder.Configuration["Jwt:Secret"];
builder.Configuration["Smtp:Password"];
```

---

# Non-Docker Deployment

## Recommended Directory Structure

```text
/opt/myapp/
├── MyApp.dll
├── appsettings.json
└── other binaries

/etc/myapp/
├── appsettings.Production.json
└── app.env
```

## Application Files

Location:

```text
/opt/myapp/
```

Contains:

* Published .NET binaries
* Default appsettings.json
* Static assets

## Configuration Files

Location:

```text
/etc/myapp/appsettings.Production.json
```

Example:

```json
{
  "Application": {
    "Name": "MyApp"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

## Secrets File

Location:

```text
/etc/myapp/app.env
```

Example:

```env
ConnectionStrings__DefaultConnection=Server=db;Database=AppDb;...
Jwt__Secret=xxxxxxxx
Smtp__Password=xxxxxxxx
```

---

# Permissions

If running as ubuntu user:

```bash
sudo chown root:ubuntu /etc/myapp/app.env
sudo chmod 640 /etc/myapp/app.env
```

If running as a dedicated application user:

```bash
sudo chown root:myapp /etc/myapp/app.env
sudo chmod 640 /etc/myapp/app.env
```

Meaning:

| User              | Access     |
| ----------------- | ---------- |
| root              | Read/Write |
| application group | Read       |
| others            | No access  |

---

# systemd Service Configuration

Create:

```text
/etc/systemd/system/myapp.service
```

Example:

```ini
[Unit]
Description=My ASP.NET Core Application
After=network.target

[Service]
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/dotnet /opt/myapp/MyApp.dll

EnvironmentFile=/etc/myapp/app.env

Environment=ASPNETCORE_ENVIRONMENT=Production

User=ubuntu
Group=ubuntu

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
```

Check status:

```bash
sudo systemctl status myapp
```

View logs:

```bash
journalctl -u myapp -f
```

---

# Loading External appsettings.Production.json

## Option 1: Symbolic Link

```bash
ln -s /etc/myapp/appsettings.Production.json \
      /opt/myapp/appsettings.Production.json
```

## Option 2: Explicit Loading (Recommended)

```csharp
builder.Configuration
    .AddJsonFile(
        "/etc/myapp/appsettings.Production.json",
        optional: true,
        reloadOnChange: true);
```

---

# Cloud Secrets Manager (Best Practice)

For production environments hosted in cloud providers:

```text
VM
  ↓
Docker Container / ASP.NET Core App
  ↓
Managed Identity / IAM Role
  ↓
Secrets Manager
```

Store:

* Database passwords
* JWT secrets
* API keys
* SMTP credentials
* Third-party secrets

Benefits:

* Centralized secret management
* Secret rotation support
* Audit logs
* No secrets stored on disk
* Better compliance and security

---

# Recommended Production Architecture

## Docker

```text
/opt/myapp/
    docker-compose.yml

/etc/myapp/
    app.env
    appsettings.Production.json
```

## Non-Docker

```text
/opt/myapp/
    Application binaries

/etc/myapp/
    Configuration files
    Secret files

systemd
    Service management

journalctl
    Logging
```

## Summary

Recommended locations:

| Purpose              | Location                                 |
| -------------------- | ---------------------------------------- |
| Application binaries | `/opt/myapp`                             |
| Configuration        | `/etc/myapp/appsettings.Production.json` |
| Secrets              | `/etc/myapp/app.env`                     |
| Service definition   | `/etc/systemd/system/myapp.service`      |

This approach provides:

* Separation of code, configuration, and secrets
* Safer deployments
* Easier backups
* Easier configuration management
* Compatibility with future migration to Docker, Kubernetes, or cloud secret managers
