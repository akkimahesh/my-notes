# How to Add 2 GB Swap Memory on Ubuntu

A step-by-step guide to configuring and verifying 2 GB of swap memory on Ubuntu.

---

## Step 1: Check Existing RAM and Swap

Verify current memory and swap allocation:

```bash
free -h
```

---

## Step 2: Create a 2 GB Swap File

Allocate a 2 GB file dedicated for swap:

```bash
sudo fallocate -l 2G /swapfile
```

---

## Step 3: Set Secure Permissions

Restrict read and write permissions to the root user only:

```bash
sudo chmod 600 /swapfile
```

---

## Step 4: Format the File as Swap

Set up the Linux swap area on the newly created file:

```bash
sudo mkswap /swapfile
```

---

## Step 5: Enable Swap Immediately

Activate the swap file:

```bash
sudo swapon /swapfile
```

---

## Step 6: Enable Swap Automatically After Reboot

> [!IMPORTANT]
> Run this command **only once** if the `/swapfile` entry is not already present in `/etc/fstab`.

Append the swap configuration to `/etc/fstab`:

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Step 7: Verify Swap is Enabled

1. **Check memory status:**
   ```bash
   free -h
   ```
   *You should see approximately `2.0Gi` in the **Swap** row.*

2. **Check active swap devices:**
   ```bash
   sudo swapon --show
   ```

---

## Step 8: Monitor Memory During Application Builds

* **Monitor live memory usage (refreshes every second):**
  ```bash
  watch -n 1 free -h
  ```
  *(Press `Ctrl + C` to exit)*

* **Monitor swap in/out activity:**
  ```bash
  vmstat 1
  ```
  *Observe the `si` (swap-in) and `so` (swap-out) columns. (Press `Ctrl + C` to exit)*

---

## Notes & Troubleshooting

> [!NOTE]
> **Expected Result:** Approximately 2 GB physical RAM + 2 GB swap capacity. Swap helps processes finish under memory pressure, but note that disk swap is significantly slower than physical RAM.

> [!WARNING]
> Since you already ran the creation, formatting, and `/etc/fstab` commands, **do not** repeat Steps 2, 4, or 6 unnecessarily.
> 
> If swap is currently disabled on your server, simply run:
> ```bash
> sudo swapon /swapfile
> free -h
> ```