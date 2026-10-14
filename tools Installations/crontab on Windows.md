# Scheduling Tasks on Windows (Crontab Alternatives)

When running **Git Bash (MINGW64)** or PowerShell on Windows, running `crontab` results in:

```bash
bash: crontab: command not found
```

`crontab` is a Unix daemon and does not exist natively in the Windows kernel. You have two primary approaches to automate scripts on Windows:
1. **Windows Task Scheduler** (Native, high performance, recommended).
2. **WSL2 (Windows Subsystem for Linux)** (Full native Linux cron).

---

## Option 1: Windows Task Scheduler (Recommended)

Windows Task Scheduler is the built-in Windows equivalent of cron.

### Method A: Execute a Git Bash Shell Script (`.sh`) via Task Scheduler GUI

1. Open Task Scheduler (`Win + R`, type `taskschd.msc`, press **Enter**).
2. Click **Create Task** (not Basic Task for advanced options).
3. **General Tab:**
   - Name: `RunMyScript`
   - Select **Run whether user is logged on or not**.
   - Check **Run with highest privileges**.
4. **Triggers Tab:**
   - Click **New...**
   - Select your schedule (e.g., Daily, or At startup, with repeat options like "Every 5 minutes").
5. **Actions Tab:**
   - Click **New...**
   - **Action:** `Start a program`
   - **Program/script:**
     ```text
     "C:\Program Files\Git\bin\bash.exe"
     ```
   - **Add arguments:**
     ```text
     -c "/c/Users/mahesh.a/scripts/my_script.sh"
     ```
   - **Start in:**
     ```text
     C:\Users\mahesh.a\scripts
     ```
6. Click **OK** and enter your Windows credentials when prompted.

---

### Method B: PowerShell Command Line (Quick Automated Creation)

You can create scheduled tasks directly from an Administrator PowerShell prompt without the GUI:

```powershell
# Define action to run bash script
$Action = New-ScheduledTaskAction -Execute "C:\Program Files\Git\bin\bash.exe" -Argument '-c "/c/Users/mahesh.a/scripts/my_script.sh"'

# Define trigger (e.g., Daily at 2:00 AM)
$Trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM

# Register the task
Register-ScheduledTask -TaskName "DailyBashBackup" -Action $Action -Trigger $Trigger -User "SYSTEM" -RunLevel Highest
```

To list or delete scheduled tasks:
```powershell
# Check status
Get-ScheduledTask -TaskName "DailyBashBackup"

# Delete task
Unregister-ScheduledTask -TaskName "DailyBashBackup" -Confirm:$false
```

---

## Option 2: Linux Crontab via WSL2

If your workflow strictly requires the standard Linux `cron` syntax:

### 1. Launch Ubuntu WSL
```powershell
wsl -d Ubuntu
```

### 2. Install and Start Cron
```bash
sudo apt update
sudo apt install -y cron
sudo service cron start
```

### 3. Edit Crontab
```bash
crontab -e
```

Example cron job running every 5 minutes:
```cron
*/5 * * * * /bin/bash /mnt/c/Users/mahesh.a/scripts/backup.sh >> /mnt/c/Users/mahesh.a/scripts/backup.log 2>&1
```

> [!IMPORTANT]
> **WSL2 does not run background daemons automatically on boot.**
> If Windows restarts, Ubuntu stops and the cron service terminates.
> See [automatic crontab.md](automatic%20crontab.md) for how to keep WSL cron running or invoke WSL scripts directly through Windows Task Scheduler.
