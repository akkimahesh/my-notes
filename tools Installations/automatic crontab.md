# PostgreSQL Backup Automation on Windows using WSL2 (Ubuntu)

This guide provides an end-to-end reference for automating PostgreSQL database backups on Windows using WSL2 (Ubuntu) and either the WSL `cron` service or the native Windows Task Scheduler.

---

## Environment Architecture

| Component | Value | Notes |
| :--- | :--- | :--- |
| **Host OS** | Windows 11 | Runs PostgreSQL Server |
| **Linux Subsystem** | Ubuntu (WSL2) | Runs backup script (`pg_dump`) |
| **PostgreSQL** | Version 18 (Installed on Windows) | Listening on port `5432` |
| **Database Name** | `management` | Target database |
| **Database User** | `postgres` | Backup user |
| **Backup Format** | Custom Format (`.backup`) | Compressed and restorable via `pg_restore` |
| **Target Directory** | `C:\Users\mahesh.a\PostgresBackups` | `/mnt/c/Users/mahesh.a/PostgresBackups` in WSL |

---

## 1. Problem Faced & Root Cause

### The Problem
When running `pg_dump` from inside WSL2 targeting `localhost:5432`:
```text
pg_dump: connection to server at "localhost" (127.0.0.1), port 5432 failed: Connection refused
localhost:5432 - no response
```

### The Root Cause
In WSL2, **`localhost` inside Ubuntu is NOT the Windows host `localhost`**. WSL2 runs inside an isolated virtualized Hyper-V network switch with its own IP address. To reach Windows services from WSL2, you must connect to the **Windows Host Gateway IP**, dynamically found in `/etc/resolv.conf`.

---

## 2. PostgreSQL Server Configuration (Windows)

To accept connections from WSL2, PostgreSQL must listen on all network interfaces and trust incoming connections from the WSL subnet.

### Step 1: Update `postgresql.conf`
**Path:** `C:\Program Files\PostgreSQL\18\data\postgresql.conf`

Change the `listen_addresses` directive:
```conf
listen_addresses = '*'
```

---

### Step 2: Update `pg_hba.conf`
**Path:** `C:\Program Files\PostgreSQL\18\data\pg_hba.conf`

Add an authentication entry allowing host connections:
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             0.0.0.0/0               scram-sha-256
```

> [!NOTE]
> Restart the PostgreSQL service in Windows (`services.msc` > **postgresql-x64-18** > **Restart**) after saving changes.

---

### Step 3: Windows Firewall Inbound Rule
Open PowerShell **as Administrator** and allow incoming connections on port 5432:

```powershell
New-NetFirewallRule `
  -DisplayName "Allow PostgreSQL 5432 from WSL" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5432 `
  -Action Allow
```

---

## 3. Resolving the Windows Host IP inside WSL2

To dynamically resolve the Windows host IP inside Ubuntu WSL2:

```bash
awk '/nameserver/ {print $2}' /etc/resolv.conf
```

### Test Connectivity from WSL2
Verify database connectivity from Ubuntu terminal:

```bash
# Test connection readiness
pg_isready -h $(awk '/nameserver/ {print $2}' /etc/resolv.conf) -p 5432 -U postgres

# Test interactive connection
psql -h $(awk '/nameserver/ {print $2}' /etc/resolv.conf) -p 5432 -U postgres -d management
```

---

## 4. Production Backup Script

Save this script inside WSL2 at `/mnt/c/Users/mahesh.a/scripts/backup_script.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Dynamic Windows Host IP
PGHOST=$(awk '/nameserver/ {print $2}' /etc/resolv.conf)
PGPORT="5432"
PGUSER="postgres"
PGPASSWORD="chrpindia@123"
PGDATABASE="management"

# Storage paths
BACKUP_DIR="/mnt/c/Users/mahesh.a/PostgresBackups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/${PGDATABASE}_${TIMESTAMP}.backup"

export PGPASSWORD

echo "========================================"
echo "Starting PostgreSQL Backup..."
echo "Timestamp: $TIMESTAMP"
echo "Host     : $PGHOST:$PGPORT"
echo "Database : $PGDATABASE"
echo "Target   : $BACKUP_FILE"
echo "========================================"

# Perform backup using pg_dump
if pg_dump \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$PGUSER" \
    -F c \
    -b \
    -v \
    -f "$BACKUP_FILE" \
    "$PGDATABASE"; then
    echo "SUCCESS: Backup created successfully at $BACKUP_FILE"
else
    echo "ERROR: Backup failed!" >&2
    exit 1
fi

unset PGPASSWORD
```

Make the script executable:
```bash
chmod +x /mnt/c/Users/mahesh.a/scripts/backup_script.sh
```

---

## 5. Scheduling Options

### Strategy A: Windows Task Scheduler Invoking WSL (Recommended)

This strategy is **superior** because it requires zero background RAM footprint: Windows Task Scheduler launches WSL only when it is time to take a backup, executes the script, and then lets WSL sleep.

1. Open **Task Scheduler** (`taskschd.msc`).
2. Click **Create Task**.
3. **General Tab:**
   - Name: `PostgreSQL Daily Backup via WSL`
   - Select **Run whether user is logged on or not**.
   - Check **Run with highest privileges**.
4. **Trigger Tab:**
   - Set trigger to Daily, or Repeat every `X` hours/minutes.
5. **Action Tab:**
   - **Action:** `Start a program`
   - **Program/script:** `C:\Windows\System32\wsl.exe`
   - **Arguments:**
     ```text
     -d Ubuntu --exec bash -c "/mnt/c/Users/mahesh.a/scripts/backup_script.sh >> /mnt/c/Users/mahesh.a/scripts/backup.log 2>&1"
     ```
6. Save task.

---

### Strategy B: WSL Ubuntu Cron Daemon

If you prefer using Linux `cron`:

```bash
# Edit crontab
crontab -e

# Add entry (every 5 minutes):
*/5 * * * * /bin/bash /mnt/c/Users/mahesh.a/scripts/backup_script.sh >> /mnt/c/Users/mahesh.a/scripts/backup.log 2>&1
```

> [!WARNING]
> Because WSL2 does not start automatically on Windows boot, cron will NOT run after a reboot unless Ubuntu is kept alive.
> To run the cron daemon on boot, create a Windows scheduled task at Windows Startup that executes:
> ```powershell
> wsl -d Ubuntu --exec bash -c "sudo service cron start"
> ```

---

## 6. Verification and Maintenance

- **Inspect backup logs:**
  ```bash
  cat /mnt/c/Users/mahesh.a/scripts/backup.log
  ```
- **List generated backup files:**
  ```powershell
  Get-ChildItem -Path "C:\Users\mahesh.a\PostgresBackups"
  ```
- **Test restoring a backup:**
  ```bash
  pg_restore -h "$PGHOST" -p 5432 -U postgres -d management_test -v /mnt/c/Users/mahesh.a/PostgresBackups/<backup_file>.backup
  ```
