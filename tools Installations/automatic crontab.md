Great! Since it's working now, here's a reference document you can save for future use.

---

# PostgreSQL Backup Automation on Windows using WSL (Ubuntu)

## Environment

| Component     | Value                             |
| ------------- | --------------------------------- |
| OS            | Windows 11                        |
| WSL           | Ubuntu (WSL2)                     |
| PostgreSQL    | Version 18 (Installed on Windows) |
| Database      | management                        |
| User          | postgres                          |
| Backup Type   | Custom Format (.backup)           |
| Backup Script | `backup_script.sh`                |
| Scheduler     | Cron inside Ubuntu WSL            |

---

# Problem Faced

The backup script worked in Git Bash but failed in WSL.

Errors included:

```
pg_dump: connection to server at "localhost" (127.0.0.1), port 5432 failed
```

and

```
localhost:5432 - no response
```

---

# Root Cause

WSL2 `localhost` is **not the Windows localhost**.

Windows PostgreSQL was listening on:

```
0.0.0.0:5432
```

But Ubuntu WSL could not reach it using:

```
localhost
```

Instead, WSL had to connect using the Windows host IP.

---

# PostgreSQL Configuration

### postgresql.conf

Location

```
C:\Program Files\PostgreSQL\18\data\postgresql.conf
```

Required setting

```conf
listen_addresses='*'
```

---

### pg_hba.conf

Location

```
C:\Program Files\PostgreSQL\18\data\pg_hba.conf
```

Added entry

```conf
host    all    all    0.0.0.0/0    scram-sha-256
```

> **Note:** This is convenient for testing. For better security, replace it with a more restrictive network (for example, your WSL subnet) if appropriate.

Restart PostgreSQL after making changes.

---

# Firewall

Run PowerShell **as Administrator**

```powershell
New-NetFirewallRule `
-DisplayName "Allow PostgreSQL 5432" `
-Direction Inbound `
-Protocol TCP `
-LocalPort 5432 `
-Action Allow
```

---

# Finding the Windows Host IP

Inside Ubuntu

```bash
awk '/nameserver/ {print $2}' /etc/resolv.conf
```

Example

```
172.29.80.1
```

---

# Final Backup Script

```bash
#!/bin/bash

PGHOST=$(awk '/nameserver/ {print $2}' /etc/resolv.conf)
PGPORT="5432"
PGUSER="postgres"
PGPASSWORD="chrpindia@123"
PGDATABASE="management"

BACKUP_DIR="/mnt/c/Users/mahesh.a/PostgresBackups"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

BACKUP_FILE="$BACKUP_DIR/${PGDATABASE}_${TIMESTAMP}.backup"

export PGPASSWORD

echo "========================================"
echo "Starting PostgreSQL Backup..."
echo "Host     : $PGHOST"
echo "Database : $PGDATABASE"
echo "Backup   : $BACKUP_FILE"
echo "========================================"

pg_dump \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$PGUSER" \
    -F c \
    -b \
    -v \
    -f "$BACKUP_FILE" \
    "$PGDATABASE"

if [ $? -eq 0 ]; then
    echo ""
    echo "Backup completed successfully."
else
    echo ""
    echo "Backup failed."
fi

unset PGPASSWORD
```

---

# Test Commands

Check PostgreSQL

```bash
pg_isready -h $(awk '/nameserver/ {print $2}' /etc/resolv.conf) \
-p 5432 \
-U postgres
```

Connect

```bash
psql \
-h $(awk '/nameserver/ {print $2}' /etc/resolv.conf) \
-U postgres \
-d management
```

Run Backup

```bash
sh backup_script.sh
```

---

# Cron Configuration

Edit crontab

```bash
crontab -e
```

Run every 5 minutes

```cron
*/5 * * * * /bin/bash /mnt/c/Users/mahesh.a/scripts/backup_script.sh >> /mnt/c/Users/mahesh.a/scripts/backup.log 2>&1
```

Verify

```bash
crontab -l
```

---

# Start Cron

```bash
sudo service cron start
```

Check status

```bash
service cron status
```

---

# After Windows Restart

WSL does **not** automatically start after Windows boots, so cron won't run until Ubuntu is started.

Start Ubuntu:

```powershell
wsl -d Ubuntu
```

Start cron:

```bash
sudo service cron start
```

Verify:

```bash
service cron status
```

---

# Useful Commands

Find Windows Host IP

```bash
awk '/nameserver/ {print $2}' /etc/resolv.conf
```

List cron jobs

```bash
crontab -l
```

Edit cron

```bash
crontab -e
```

Run backup manually

```bash
sh /mnt/c/Users/mahesh.a/scripts/backup_script.sh
```

Check PostgreSQL

```bash
pg_isready \
-h $(awk '/nameserver/ {print $2}' /etc/resolv.conf) \
-p 5432 \
-U postgres
```

---

# Final Notes

* PostgreSQL runs on **Windows**.
* Backup script runs from **Ubuntu WSL2**.
* Use the Windows host IP (obtained dynamically from `/etc/resolv.conf`) instead of `localhost`.
* Store backups under:

  ```
  C:\Users\mahesh.a\PostgresBackups
  ```
* Start Ubuntu (`wsl -d Ubuntu`) and ensure the `cron` service is running after a Windows reboot if you rely on cron for scheduling. For unattended backups immediately after boot, consider using **Windows Task Scheduler** to launch WSL and start the cron service automatically.

turn on firewall in windows security

Yes. By default, **WSL distributions do not start automatically** when Windows boots. They only start when you run:

```powershell
wsl -d Ubuntu
```

Since your **cron job runs inside Ubuntu**, if Ubuntu is stopped, **cron is also stopped**, so your backup won't run.

## Solution: Start Ubuntu Automatically at Windows Startup

### Step 1: Create a PowerShell script

Create a file:

```
C:\Scripts\StartUbuntu.ps1
```

Contents:

```powershell
# Start Ubuntu WSL
wsl -d Ubuntu --exec bash -c "sudo service cron start"

# Keep WSL running
wsl -d Ubuntu --exec bash -c "tail -f /dev/null"
```

---

## Step 2: Create a Scheduled Task

Open **Task Scheduler**

Click **Create Task**

### General

* Name: `Start Ubuntu WSL`
* ✅ Run whether user is logged on or not
* ✅ Run with highest privileges

---

### Trigger

* At startup

---

### Action

**Program**

```
powershell.exe
```

**Arguments**

```text
-ExecutionPolicy Bypass -File "C:\Scripts\StartUbuntu.ps1"
```

---

### Conditions

Uncheck

```
Start the task only if the computer is on AC power
```

---

### Settings

Enable

```
Run task as soon as possible after a scheduled start is missed
```

Click **OK**

---

## Step 3: Verify

Restart Windows.

Run:

```powershell
wsl -l -v
```

You should see:

```
NAME              STATE     VERSION
Ubuntu            Running   2
docker-desktop    Stopped   2
```

Then inside Ubuntu:

```bash
service cron status
```

should show

```
active (running)
```

---

# Better Solution (Recommended)

Instead of keeping Ubuntu running all the time, **use Windows Task Scheduler** to start WSL only every 5 minutes and execute the backup script.

Create a scheduled task:

**Program**

```
C:\Windows\System32\wsl.exe
```

**Arguments**

```text
-d Ubuntu --exec bash -c "/mnt/c/Users/mahesh.a/scripts/backup_script.sh"
```

Trigger:

```
Repeat every 5 minutes
```

Benefits:

* ✅ No need to keep Ubuntu running 24/7.
* ✅ No need for cron.
* ✅ Works immediately after Windows starts.
* ✅ Uses less memory and CPU.
* ✅ More reliable because Windows Task Scheduler starts WSL only when needed.

## Recommendation

Since your goal is **a PostgreSQL backup every 5 minutes**, I recommend **removing cron entirely** and using **Windows Task Scheduler + `wsl.exe`** to invoke your script. It's simpler, more reliable after reboots, and avoids having to keep the Ubuntu distribution running continuously.
