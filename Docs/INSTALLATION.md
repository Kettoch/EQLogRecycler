# Installation Guide - EverQuest Log Recycler

A comprehensive guide for installing EQLogRecycler on Windows systems.

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Methods](#installation-methods)
3. [Troubleshooting Installation](#troubleshooting-installation)
4. [Uninstallation](#uninstallation)
5. [Advanced Configuration](#advanced-configuration)

---

## 🖥️ System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | Windows 7 SP1 or later |
| **RAM** | 512 MB free (1 GB recommended) |
| **Disk Space** | 1 MB |
| **PowerShell** | 5.1 or higher |
| **.NET Framework** | 3.5 SP1 or later |
| **Permissions** | User or Administrator |

### Supported Operating Systems

- ✅ Windows 7 (SP1+)
- ✅ Windows 8 / 8.1
- ✅ Windows 10 (all versions)
- ✅ Windows 11
- ✅ Windows Server 2016, 2019, 2022 (with GUI)

### PowerShell Versions

Check your PowerShell version:
```powershell
$PSVersionTable.PSVersion
```

| Version | Support | Notes |
|---------|---------|-------|
| 5.0 | ⚠️ Limited | Windows 7/8 only |
| 5.1 | ✅ Full | Windows 10/11 default |
| 7.0+ | ✅ Full | PowerShell Core (7+) |

---

## 📦 Installation Methods

### Method 1: Windows Installer (Recommended)

**Best for**: Most users, simple one-click installation

**Steps**:

1. **Download**
   - Visit [Releases](https://github.com/YourUsername/EQLogRecycler/releases)
   - Download `EQLogRecycler_Setup_v1.0.exe`
   - Verify file hash (optional): `sha256sum EQLogRecycler_Setup_v1.0.exe`

2. **Install**
   - Right-click `EQLogRecycler_Setup_v1.0.exe`
   - Select **"Run as Administrator"**
   - Click **"Next"** on welcome screen

3. **Select Installation Options**
   ```
   Installation Options:
   ☐ Create Desktop Shortcut
   ☑ Create Start Menu Folder
   ☐ Start automatically when Windows starts
   ```
   - Check **"Start automatically"** if you want auto-start
   - Check **"Desktop Shortcut"** for easy access

4. **Completion**
   - ✅ Check **"Configure and run now"** to setup after install
   - Click **"Finish"**
   - Setup wizard launches automatically

**Installation Location**: `C:\Program Files\TRTools\EQLogRecycler\`

**Uninstall**: Settings → Apps → Apps & Features → "EverQuest Log Recycler" → Uninstall

---

### Method 2: PowerShell Gallery

**Best for**: PowerShell users, version management

**Requirements**:
- PowerShell 5.0+
- NuGet package provider
- Internet connection

**Installation**:

```powershell
# Step 1: Update PowerShellGet (recommended)
Install-Module PowerShellGet -Force -AllowClobber

# Step 2: Install EQLogRecycler
Install-Module -Name EQLogRecycler -Scope CurrentUser

# Step 3: Create shortcut (optional)
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut([Environment]::GetFolderPath("Desktop") + "\EQ Log Recycler.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"Import-Module EQLogRecycler; Start-EQLogRecycler`""
$shortcut.IconLocation = "C:\Program Files\PowerShell\7\pwsh.exe,0"
$shortcut.Save()
```

**Update**:
```powershell
Update-Module -Name EQLogRecycler
```

**Location**: `$PROFILE\..\Modules\EQLogRecycler\`

---

### Method 3: Manual Installation

**Best for**: Advanced users, custom deployment, offline systems

**Step 1: Choose Installation Location**

```powershell
# Option A: User AppData (no admin required)
$installPath = "$env:APPDATA\Local\EQLogRecycler"

# Option B: Program Files (admin required)
$installPath = "C:\Program Files\EQLogRecycler"

# Create directory
New-Item -ItemType Directory -Path $installPath -Force | Out-Null
```

**Step 2: Download Files**

Download and extract to `$installPath`:
- `EQLogRecycler.ps1`
- `README.md`
- `LICENSE`

**Step 3: Configure PowerShell Execution Policy**

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

**Step 4: Create Shortcut**

For system tray mode:

**Via GUI**:
1. Right-click on Desktop
2. New → Shortcut
3. Location: `powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\full\path\EQLogRecycler.ps1"`
4. Name: `EQ Log Recycler`
5. Next → Finish

**Via PowerShell**:
```powershell
$shell = New-Object -ComObject WScript.Shell
$desk = [Environment]::GetFolderPath("Desktop")
$shortcut = $shell.CreateShortcut("$desk\EQ Log Recycler.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installPath\EQLogRecycler.ps1`""
$shortcut.WorkingDirectory = $installPath
$shortcut.Save()

Write-Host "Shortcut created on Desktop"
```

**Step 5: Auto-Start (Optional)**

For auto-start on login:

```powershell
# Create shortcut in Startup folder
$startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$startup\EQ Log Recycler.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installPath\EQLogRecycler.ps1`""
$shortcut.Save()
```

**Step 6: Run Application**

```powershell
# Run directly
& "$installPath\EQLogRecycler.ps1"

# Or via shortcut
Invoke-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\EQ Log Recycler.lnk"
```

---

### Method 4: Portable Installation

**Best for**: No permanent installation, testing, multiple profiles

**Setup**:

```powershell
# 1. Create portable folder
$portablePath = "E:\Portable\EQLogRecycler"  # Any location
New-Item -ItemType Directory -Path $portablePath -Force

# 2. Copy EQLogRecycler.ps1 to folder

# 3. Create batch launcher
@"
@echo off
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0EQLogRecycler.ps1"
"@ | Set-Content "$portablePath\Launch.bat"

# 4. Run from batch file or PowerShell
& "$portablePath\Launch.bat"
```

**Advantages**:
- No system registry modification
- Can run from USB drive
- Multiple independent instances

---

## 🔧 Post-Installation Setup

### First Run Configuration

1. **Select Log File**
   ```
   Log file location: C:\Users\YourName\AppData\Local\EverQuest\Logs\
   Select: eqlog_CharacterName_ServerName.txt
   ```

2. **Choose Archive Folder**
   ```
   Suggested: C:\Users\YourName\Documents\EQ Archives\
   Or: External drive for large archives
   ```

3. **Set Recycle Time**
   ```
   Format: HH:mm (24-hour)
   Default: 00:00 (midnight)
   Recommended: Off-peak time (3:00 AM for raid guilds)
   ```

### Verify Installation

```powershell
# Test PowerShell execution
. "C:\path\to\EQLogRecycler.ps1"

# List configured logs
.\EQLogRecycler.ps1 -ListLogs

# Check registry
reg query "HKEY_CURRENT_USER\Software\EQTools\EQLogRecycler"
```

---

## 🆘 Troubleshooting Installation

### "Access Denied" Error

**Cause**: Insufficient permissions

**Solution**:
```powershell
# Run PowerShell as Administrator
# Then set execution policy:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### "Cannot run scripts" Error

**Cause**: PowerShell execution policy too restrictive

**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set to RemoteSigned (allows local scripts)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Verify
Get-ExecutionPolicy
```

### Installer Fails with "No valid source found"

**Cause**: Network issue downloading dependencies

**Solution**:
1. Check internet connection
2. Disable antivirus temporarily
3. Try manual installation method
4. Download offline installer package

### "PowerShell 5.1 required" Error

**Cause**: Running on PowerShell 4.0 or earlier

**Solution**:
```powershell
# Check version
$PSVersionTable.PSVersion

# Upgrade PowerShell:
# For Windows 7/8: Download Windows Management Framework 5.1
# For Windows 10/11: Built-in, run Windows Update
```

**Download WMF 5.1**: https://www.microsoft.com/en-us/download/details.aspx?id=54616

### Registry Errors After Installation

**Cause**: Registry permissions issue

**Solution**:
```powershell
# Restart PowerShell as Administrator
# Delete problematic registry key
Remove-Item -Path "HKCU:\Software\EQTools\EQLogRecycler" -Force -ErrorAction Continue

# Re-run application to recreate
.\EQLogRecycler.ps1
```

### Icon Doesn't Appear in System Tray

**Cause**: System tray setting or UAC

**Solution**:
1. Check system tray settings (Windows 10/11):
   - Settings → Taskbar → Notification icons
   - Turn ON "Show EverQuest Log Recycler" option

2. Check Windows permissions:
   - Shortcut properties → Advanced → Check "Run as administrator"

3. Try running directly:
   ```powershell
   .\EQLogRecycler.ps1 -Tray
   ```

### File Recycling Not Starting at Scheduled Time

**Cause**: Application not running, time format incorrect, or logs recycled already today

**Solution**:
```powershell
# Verify log files configured
.\EQLogRecycler.ps1 -ListLogs

# Test immediate recycle
.\EQLogRecycler.ps1 -RecycleNow

# Check recycle time format (should be HH:mm)
# Right-click tray icon → Configuration → Check "Next recycle" time
```

---

## 🗑️ Uninstallation

### Via Windows Control Panel (Recommended)

1. Open **Settings** → **Apps** → **Apps & features**
2. Search for **"EverQuest Log Recycler"**
3. Click the entry → **Uninstall**
4. Confirm removal
5. Optionally keep configuration/archives

### Manual Removal

```powershell
# Stop running instance
Stop-Process -Name powershell -ErrorAction Continue

# Delete installation folder
Remove-Item -Path "C:\Program Files\TRTools\EQLogRecycler" -Recurse -Force

# Remove shortcuts
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\TRTools" -Recurse -Force
Remove-Item -Path "$env:PUBLIC\Desktop\EQ Log Recycler.lnk" -Force -ErrorAction Continue

# Remove registry (optional - keeps settings)
# Remove-Item -Path "HKCU:\Software\EQTools" -Recurse -Force
```

### PowerShell Gallery Removal

```powershell
Uninstall-Module -Name EQLogRecycler -Force
```

### Preserve Archives

**Important**: Archived log files are NOT deleted during uninstallation.

To keep your archives:
1. Note the archive folder location
2. Uninstall application
3. Archives remain in the folder you selected

---

## ⚙️ Advanced Configuration

### Batch Installation for Multiple Users

```powershell
# Install for all users in domain (requires admin)
$users = Get-WmiObject -Class Win32_UserProfile -Filter "LocalPath LIKE '%Users%'" 
foreach ($user in $users) {
    $sid = $user.SID
    # Configure registry for each user...
}
```

### Silent Installation

```powershell
# Installer silent mode
EQLogRecycler_Setup_v1.0.exe /SILENT /NORESTART
```

### Group Policy Deployment (Enterprises)

```powershell
# Deploy via Group Policy (requires SCCM/GPO setup)
# Store MSI in shared folder
# Deploy via Group Policy: Computer/User Configuration → Software
```

### Network Installation

```powershell
# Install from network share
net use Z: \\server\share
Z:\EQLogRecycler_Setup_v1.0.exe
```

---

## 📊 Installation Verification

Run this script to verify successful installation:

```powershell
# Installation Verification Script
$checks = @{
    "PowerShell Version" = $PSVersionTable.PSVersion.Major -ge 5
    "Execution Policy" = (Get-ExecutionPolicy) -in @("RemoteSigned", "Unrestricted")
    "Script Location" = Test-Path "C:\Program Files\TRTools\EQLogRecycler\EQLogRecycler.ps1"
    "Registry Configured" = Test-Path "HKCU:\Software\EQTools\EQLogRecycler"
    ".NET Framework" = $null -ne ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -like "*System.Windows.Forms*" })
}

Write-Host "Installation Verification:" -ForegroundColor Cyan
foreach ($check in $checks.GetEnumerator()) {
    $status = if ($check.Value) { "✓ PASS" } else { "✗ FAIL" }
    Write-Host "$($check.Name): $status" -ForegroundColor $(if ($check.Value) { "Green" } else { "Red" })
}
```

---

## 📞 Support

If installation fails:

1. **Check documentation**: See README.md
2. **Search issues**: [GitHub Issues](https://github.com/YourUsername/EQLogRecycler/issues)
3. **Report problem**: Create new issue with details:
   - Windows version
   - PowerShell version (`$PSVersionTable`)
   - Error message
   - Steps you followed

---

## ✅ Installation Checklist

Before first run, verify:

- [ ] Windows 7 or later
- [ ] PowerShell 5.1+
- [ ] .NET Framework 3.5+
- [ ] Downloaded from official source
- [ ] Installer run as Administrator
- [ ] All dialogs completed
- [ ] Configuration saved (icon in tray)
- [ ] Registry has configuration entry

---

**Happy log recycling!** 🎉

For more help, see:
- [README.md](README.md) - User guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [CODE_REVIEW.md](CODE_REVIEW.md) - Technical details