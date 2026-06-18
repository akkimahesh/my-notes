# Claude Code + Ollama Setup Guide (Windows)

## Prerequisites

* Windows 10/11
* PowerShell
* Internet Connection
* Administrator Access (recommended)

---

## Step 1: Install Claude Code

Search for **Claude Code** and open the official documentation:

* Claude Code Quick Start: https://code.claude.com/docs/en/quickstart

Run the following command in **PowerShell**:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Verify the installation:

```powershell
claude --version
```

---

## Step 2: Configure Claude Path

If the `claude` command is not recognized, add the Claude installation directory to the system PATH.

Default location:

```text
%USERPROFILE%\.local\bin
```

### Add to Environment Variables

1. Open **System Properties**
2. Click **Advanced System Settings**
3. Click **Environment Variables**
4. Select **Path**
5. Click **Edit**
6. Add:

```text
%USERPROFILE%\.local\bin
```

7. Save and restart PowerShell

Verify again:

```powershell
claude --version
```

---

## Step 3: Install Ollama

Download Ollama for Windows from the official website:

https://ollama.com/download

Install the executable and complete the setup.

Verify installation:

```powershell
ollama --version
```

---

## Step 4: Download a Claude Model in Ollama

List available models:

```powershell
ollama list
```

Download a Claude-compatible/community model (example):

```powershell
ollama pull claude-sonnet
```

or any model supported by your Ollama setup.

Verify:

```powershell
ollama list
```

---

## Step 5: Run the Model

Start the model:

```powershell
ollama run claude-sonnet
```

Example:

```powershell
ollama run claude-sonnet "Explain Docker multi-stage builds."
```

---

## Troubleshooting

### Claude command not found

Verify PATH contains:

```text
%USERPROFILE%\.local\bin
```

Restart PowerShell after updating environment variables.

### Ollama command not found

Restart PowerShell or reinstall Ollama.

### Installation Security Note

Always download Claude Code and Ollama from their official websites and documentation. Avoid third-party installers or links found in advertisements, as fake installers have been used to distribute malware.

---

## Verification Commands

```powershell
claude --version
ollama --version
ollama list
```

If all commands return successfully, the setup is complete.
