`crontab` is a Linux/Unix utility and is **not available natively on Windows**, which is why you're seeing:

```bash
bash: crontab: command not found
```

Since you're using **Git Bash (MINGW64)** on Windows, here are your options:

### Option 1: Use Windows Task Scheduler (Recommended)

Windows has its own scheduler instead of cron.

1. Press **Win + R**
2. Type:

   ```
   taskschd.msc
   ```
3. Click **Create Basic Task**
4. Give it a name.
5. Choose the schedule (Daily, Weekly, etc.).
6. Select **Start a Program**.
7. Browse to your script (`.bat`, `.ps1`, `.exe`, etc.).
8. Finish.

This is the Windows equivalent of cron.

---

### Option 2: Install Cron via WSL (If you need actual crontab)

If you have **Windows Subsystem for Linux (WSL)** installed:

```bash
wsl
```

Then inside Ubuntu:

```bash
sudo apt update
sudo apt install cron
sudo service cron start

crontab -e
```

---
