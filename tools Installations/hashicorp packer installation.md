# HashiCorp Packer Installation Guide

**HashiCorp Packer** is an open-source tool that enables you to create identical machine images for multiple platforms from a single source configuration (AWS AMI, Azure VM images, Google Cloud images, VMware, VirtualBox, Docker, etc.).

---

## 1. Windows Installation

### Method A: Windows Package Manager (`winget` - Recommended)
Open PowerShell and run:
```powershell
winget install HashiCorp.Packer
```

### Method B: Chocolatey
```powershell
choco install packer
```

### Method C: Manual Installation via ZIP
1. Download the latest Windows 64-bit binary from the [Packer Download Page](https://developer.hashicorp.com/packer/install).
2. Extract the archive into a permanent folder, e.g.:
   ```text
   C:\Program Files\Packer\
   ```
3. Add the folder path to your Windows **System Environment Variables**:
   - Press `Win + R`, type `sysdm.cpl`, and press **Enter**.
   - Navigate to the **Advanced** tab > click **Environment Variables**.
   - Under **System variables**, select `Path` and click **Edit**.
   - Click **New** and add your folder path:

> [!CAUTION]
> ❌ **Do NOT include the `.exe` filename in the PATH variable:**
> ```text
> C:\Program Files\Packer\packer.exe   <-- WRONG
> ```
> ✅ **Add only the directory containing the executable:**
> ```text
> C:\Program Files\Packer              <-- CORRECT
> ```

4. Restart any open PowerShell or Command Prompt terminals.

---

## 2. Linux Installation

### Ubuntu / Debian
```bash
# Install GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add official repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update & install
sudo apt update && sudo apt install -y packer
```

### RHEL / CentOS / Fedora / AlmaLinux
```bash
# Install yum-utils
sudo dnf install -y yum-utils

# Add HashiCorp repo
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Packer
sudo dnf install -y packer
```

---

## 3. macOS Installation (Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

---

## 4. Verification & Autocomplete

Verify that Packer is correctly installed and accessible in your shell:

```bash
packer version
```

### Enable Shell Autocomplete (Bash / Zsh)
```bash
packer -autocomplete-install
# Restart your shell session
```

---

## 5. Quick Test

Initialize and validate a basic Packer template:
```bash
packer init .
packer validate .
```