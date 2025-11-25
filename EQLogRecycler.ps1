#Requires -Version 5.1
<#
.SYNOPSIS
    EverQuest Log File Recycler
.DESCRIPTION
    Monitors and recycles EverQuest log files at a specified time daily.
    Can run as a system tray application or silently in background.
.VERSION
    1.0 - Initial Release
.PARAMETER RecycleNow
    Immediately recycle all configured log files and exit
.PARAMETER RecycleOne
    Recycle a specific log file by index number and exit
.PARAMETER ListLogs
    Display all configured log files with their index numbers and exit
.PARAMETER Tray
    Run as a system tray application (default if configuration exists)
.PARAMETER Silent
    Run silently in background without GUI
.EXAMPLE
    .\EQLogRecycler.ps1
    Run in system tray mode
.EXAMPLE
    .\EQLogRecycler.ps1 -Silent
    Run silently in background
.EXAMPLE
    .\EQLogRecycler.ps1 -RecycleNow
    Immediately recycle all configured logs
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$RecycleNow,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(-1, [int]::MaxValue)]
    [int]$RecycleOne = -1,
    
    [Parameter(Mandatory = $false)]
    [switch]$ListLogs,
    
    [Parameter(Mandatory = $false)]
    [switch]$Tray,
    
    [Parameter(Mandatory = $false)]
    [switch]$Silent
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Application version
$Script:Version = "1.0"
$Script:VersionReleaseType = "Initial Release"

# Registry configuration
$Script:RegPath = "HKCU:\Software\EQTools"
$Script:RegKey = "EQLogRecycler"

# Configuration constants (remove hardcoded values)
$Script:Config_Settings = @{
    TimerIntervalMs = 30000              # 30 seconds
    MonitorLoopDelaySeconds = 30
    ConfigFormWidth = 400
    ConfigFormHeight = 320
    ManageFormWidth = 600
    ManageFormHeight = 400
    BalloonTipDurationMs = 3000
}

# Logging configuration
$Script:LogPath = Join-Path $env:APPDATA "TRTools\EQLogRecycler.log"
$Script:LogEnabled = $true
$Script:MaxLogSizeBytes = 1MB  # Roll over log after 1MB

# Function to create registry structure if it doesn't exist
#STUB - FUNCTION - Initialize-Registry
function Initialize-Registry {
    if (!(Test-Path $Script:RegPath)) {
        New-Item -Path $Script:RegPath -Force | Out-Null
    }
}

# Function to write messages to file log with rotation
#STUB - FUNCTION - Write-ToLog
function Write-ToLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    if (-not $Script:LogEnabled) { return }
    
    try {
        # Ensure log directory exists
        $logDir = Split-Path $Script:LogPath
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop | Out-Null
        }
        
        # Check if log file exists and is too large
        if ((Test-Path $Script:LogPath) -and (Get-Item $Script:LogPath).Length -gt $Script:MaxLogSizeBytes) {
            $archivePath = "$Script:LogPath.$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
            Move-Item $Script:LogPath -Destination $archivePath -Force -ErrorAction SilentlyContinue
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        Add-Content -Path $Script:LogPath -Value $logEntry -ErrorAction Stop
    } catch {
        # Silently fail on logging errors to avoid breaking application flow
        Write-Debug "Failed to write log: $_"
    }
}

# Function to get configuration from registry
#STUB - FUNCTION - Get-Config
function Get-Config {
    Initialize-Registry
    
    try {
        $config = Get-ItemProperty -Path $Script:RegPath -Name $Script:RegKey -ErrorAction Stop
        $jsonString = $config.$Script:RegKey
        
        if ([string]::IsNullOrEmpty($jsonString)) {
            Write-Warning "Configuration registry value is empty"
            return $null
        }
        
        $parsedConfig = $jsonString | ConvertFrom-Json -ErrorAction Stop
        
        # Validate required properties
        if ($null -eq $parsedConfig.LogFiles -or $null -eq $parsedConfig.ArchiveFolder -or $null -eq $parsedConfig.RecycleTime) {
            Write-Warning "Configuration is missing required properties (LogFiles, ArchiveFolder, or RecycleTime)"
            return $null
        }
        
        return $parsedConfig
    }
    catch {
        Write-Warning "Failed to load configuration from registry: $_"
        return $null
    }
}

# Function to save configuration to registry
#STUB - FUNCTION - Save-Config
function Save-Config {
    param($Config)
    
    try {
        Initialize-Registry
        
        if ($null -eq $Config) {
            throw "Configuration object is null"
        }
        
        $jsonConfig = $Config | ConvertTo-Json -Compress -ErrorAction Stop
        
        if ([string]::IsNullOrEmpty($jsonConfig)) {
            throw "Failed to convert configuration to JSON"
        }
        
        Set-ItemProperty -Path $Script:RegPath -Name $Script:RegKey -Value $jsonConfig -Force -ErrorAction Stop
        Write-Verbose "Configuration saved successfully to registry"
    }
    catch {
        Write-Error "Failed to save configuration: $_"
        return $false
    }
    
    return $true
}

# Function to validate and normalize configuration object
#STUB - FUNCTION - Validate-Config
function Validate-Config {
    param($Config)
    
    Write-ToLog "Validating configuration object" -Level Info
    
    try {
        # Check if config is null
        if ($null -eq $Config) {
            Write-ToLog "Configuration object is null" -Level Warning
            return $false
        }
        
        # Ensure required properties exist
        $requiredProperties = @('LogFiles', 'ArchiveFolder', 'RecycleTime')
        foreach ($prop in $requiredProperties) {
            if (-not (Get-Member -InputObject $Config -Name $prop -ErrorAction SilentlyContinue)) {
                Write-ToLog "Configuration missing required property: $prop" -Level Warning
                return $false
            }
        }
        
        # Validate LogFiles - handle single item or array
        if (-not $Config.LogFiles) {
            Write-ToLog "Initializing empty LogFiles array" -Level Info
            $Config.LogFiles = @()
        } elseif ($Config.LogFiles -isnot [array]) {
            # Convert single item to array
            $Config.LogFiles = @($Config.LogFiles)
        }
        
        # Ensure ArchiveFolder is a string
        if ($Config.ArchiveFolder -isnot [string] -or [string]::IsNullOrWhiteSpace($Config.ArchiveFolder)) {
            Write-ToLog "Invalid ArchiveFolder: $($Config.ArchiveFolder)" -Level Warning
            return $false
        }
        
        # Ensure RecycleTime matches HH:mm format
        if ($Config.RecycleTime -notmatch '^\d{2}:\d{2}$') {
            Write-ToLog "Invalid RecycleTime format: $($Config.RecycleTime)" -Level Warning
            return $false
        }
        
        # Ensure LastRecycleDate exists (can be $null)
        if (-not (Get-Member -InputObject $Config -Name LastRecycleDate -ErrorAction SilentlyContinue)) {
            $Config | Add-Member -NotePropertyName LastRecycleDate -NotePropertyValue $null
        }
        
        Write-ToLog "Configuration validation successful" -Level Success
        return $true
    } catch {
        Write-ToLog "Configuration validation error: $_" -Level Error
        return $false
    }
}

# Function to show file picker dialog
#STUB - FUNCTION - Select-LogFile
function Select-LogFile {
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    try {
        $fileDialog.Filter = "EverQuest Log Files (eqlog_*.txt)|eqlog_*.txt|All Files (*.*)|*.*"
        $fileDialog.Title = "Select EverQuest Log File"
        $fileDialog.Multiselect = $false
        
        $result = $null
        if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $result = $fileDialog.FileName
        }
        
        return $result
    }
    finally {
        $fileDialog.Dispose()
    }
}

# Function to show folder picker dialog
#STUB - FUNCTION - Select-ArchiveFolder
function Select-ArchiveFolder {
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    try {
        $folderDialog.Description = "Select Archive Folder for Recycled Logs"
        $folderDialog.ShowNewFolderButton = $true
        
        $result = $null
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selectedPath = $folderDialog.SelectedPath
            
            # Validate that the folder is accessible and writable
            try {
                $testFile = Join-Path $selectedPath ".write_test_$([System.IO.Path]::GetRandomFileName())"
                [System.IO.File]::WriteAllText($testFile, "test")
                Remove-Item $testFile -Force
                $result = $selectedPath
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Error: Archive folder is not writable. Please select a different folder.", "Access Denied", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, 
                    [System.Windows.Forms.MessageBoxIcon]::Error)
                return $null
            }
        }
        
        return $result
    }
    finally {
        $folderDialog.Dispose()
    }
}

# Function to prompt for recycle time with validation
#STUB - FUNCTION - Get-RecycleTime
function Get-RecycleTime {
    $form = New-Object System.Windows.Forms.Form
    try {
        $form.Text = "Set Recycle Time"
        $form.Size = New-Object System.Drawing.Size(300, 150)
        $form.StartPosition = "CenterScreen"
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Enter recycle time (HH:mm format, 24-hour):"
        $label.Location = New-Object System.Drawing.Point(10, 20)
        $label.Size = New-Object System.Drawing.Size(280, 20)
        $form.Controls.Add($label)
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Location = New-Object System.Drawing.Point(10, 50)
        $textBox.Size = New-Object System.Drawing.Size(260, 20)
        $textBox.Text = "00:00"
        $form.Controls.Add($textBox)
        
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(110, 80)
        $okButton.Size = New-Object System.Drawing.Size(75, 23)
        $okButton.Text = "OK"
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $okButton
        $form.Controls.Add($okButton)
        
        # Validate time format on OK button click
        $okButton.Add_Click({
            $timeInput = $textBox.Text.Trim()
            
            # Validate HH:mm format
            if ($timeInput -notmatch '^\d{2}:\d{2}$') {
                [System.Windows.Forms.MessageBox]::Show("Invalid time format. Please enter time in HH:mm format (24-hour).", "Invalid Input", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, 
                    [System.Windows.Forms.MessageBoxIcon]::Warning)
                $form.DialogResult = [System.Windows.Forms.DialogResult]::None
                return
            }
            
            # Validate hours and minutes are in valid range
            $hours, $minutes = $timeInput -split ':'
            [int]$h = $hours
            [int]$m = $minutes
            
            if ($h -lt 0 -or $h -gt 23 -or $m -lt 0 -or $m -gt 59) {
                [System.Windows.Forms.MessageBox]::Show("Invalid time values. Hours must be 00-23 and minutes must be 00-59.", "Invalid Input", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, 
                    [System.Windows.Forms.MessageBoxIcon]::Warning)
                $form.DialogResult = [System.Windows.Forms.DialogResult]::None
                return
            }
            
            # Time is valid, proceed with OK
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        })
        
        if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $textBox.Text
        }
        return "00:00"
    }
    finally {
        $form.Dispose()
    }
}

# Function to recycle log files
#STUB - FUNCTION - Invoke-LogRecycle
function Invoke-LogRecycle {
    param(
        $Config,
        [int]$Index = -1,
        [switch]$ShowNotification
    )
    
    # Validate configuration
    if ($null -eq $Config -or $null -eq $Config.LogFiles -or $null -eq $Config.ArchiveFolder) {
        Write-Error "Invalid configuration provided to Invoke-LogRecycle"
        return 0
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $recycledCount = 0
    
    # Create archive folder if it doesn't exist
    if (!(Test-Path $Config.ArchiveFolder)) {
        try {
            New-Item -Path $Config.ArchiveFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Verbose "Created archive folder: $($Config.ArchiveFolder)"
        }
        catch {
            Write-Error "Failed to create archive folder '$($Config.ArchiveFolder)': $_"
            return 0
        }
    }
    
    # Validate archive folder is writable
    try {
        $testFile = Join-Path $Config.ArchiveFolder ".write_test_$([System.IO.Path]::GetRandomFileName())"
        [System.IO.File]::WriteAllText($testFile, "test")
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Archive folder '$($Config.ArchiveFolder)' is not writable: $_"
        return 0
    }
    
    # Validate index if specified
    if ($Index -ge 0) {
        if ($Index -ge $Config.LogFiles.Count) {
            Write-Error "Index $Index is out of range (valid range: 0-$($Config.LogFiles.Count - 1))"
            return 0
        }
        $logsToProcess = @($Config.LogFiles[$Index])
    } else {
        $logsToProcess = $Config.LogFiles
    }
    
    foreach ($logPath in $logsToProcess) {
        if ($logPath -and (Test-Path $logPath)) {
            try {
                $fileName = [System.IO.Path]::GetFileNameWithoutExtension($logPath)
                $extension = [System.IO.Path]::GetExtension($logPath)
                $archiveName = "${fileName}_${timestamp}${extension}"
                $archivePath = Join-Path $Config.ArchiveFolder $archiveName
                
                # Move the file to archive (EverQuest will create a new one)
                Move-Item -Path $logPath -Destination $archivePath -Force
                
                $recycledCount++
                Write-Host "Recycled: $logPath -> $archivePath" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to recycle $logPath : $_"
            }
        }
        elseif ($logPath) {
            Write-Warning "Log file not found: $logPath"
        }
    }
    
    if ($recycledCount -gt 0) {
        # Update last recycle date
        $Config.LastRecycleDate = Get-Date -Format "yyyy-MM-dd"
        Save-Config -Config $Config
        
        if ($ShowNotification -and $Script:NotifyIcon) {
            $Script:NotifyIcon.ShowBalloonTip(3000, "EQ Log Recycler", "$recycledCount log file(s) recycled", [System.Windows.Forms.ToolTipIcon]::Info)
        }
    }
    
    Write-Host "Log recycle completed. $recycledCount file(s) processed at $(Get-Date)" -ForegroundColor Cyan
    Write-ToLog "Recycled $recycledCount log file(s)" -Level Info
    return $recycledCount
}

# Helper function to update log file listbox (DRY principle - eliminates duplication)
#STUB - FUNCTION - Update-LogFileListBox
function Update-LogFileListBox {
    param(
        [System.Windows.Forms.ListBox]$ListBox,
        $Config
    )
    
    try {
        $ListBox.Items.Clear()
        
        if ($null -eq $Config -or $null -eq $Config.LogFiles) {
            $ListBox.Items.Add("[No log files configured]") | Out-Null
            return
        }
        
        $logFileCount = @($Config.LogFiles).Count
        if ($logFileCount -eq 0) {
            $ListBox.Items.Add("[No log files configured]") | Out-Null
        } else {
            for ($i = 0; $i -lt $logFileCount; $i++) {
                if ($Config.LogFiles[$i]) {
                    $exists = if (Test-Path $Config.LogFiles[$i]) { "[OK]" } else { "[FAIL]" }
                    $ListBox.Items.Add("[$i] $exists $($Config.LogFiles[$i])") | Out-Null
                }
            }
        }
    } catch {
        Write-ToLog "Error updating log file listbox: $_" -Level Error
    }
}

# Function to show and manage log files
#STUB - FUNCTION - Show-LogFileManager
function Show-LogFileManager {
    param($Config)
    
    $manageForm = New-Object System.Windows.Forms.Form
    try {
        # Validate configuration
        if ($null -eq $Config -or $null -eq $Config.LogFiles) {
            [System.Windows.Forms.MessageBox]::Show("Invalid configuration.", "Error")
            return
        }
        
        $manageForm.Text = "Manage Log Files"
        $manageForm.Size = New-Object System.Drawing.Size(600, 400)
        $manageForm.StartPosition = "CenterScreen"
        $manageForm.FormBorderStyle = "FixedDialog"
        $manageForm.MaximizeBox = $false
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Monitored Log Files:"
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.Size = New-Object System.Drawing.Size(570, 20)
        $manageForm.Controls.Add($label)
        
        # ListBox to show files
        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Location = New-Object System.Drawing.Point(10, 35)
        $listBox.Size = New-Object System.Drawing.Size(570, 280)
        $listBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        
        # Populate listbox using helper function (DRY principle)
        Update-LogFileListBox -ListBox $listBox -Config $Config
    
    $manageForm.Controls.Add($listBox)
    
    # Remove button
    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Location = New-Object System.Drawing.Point(10, 325)
    $removeButton.Size = New-Object System.Drawing.Size(150, 30)
    $removeButton.Text = "Remove Selected"
    $removeButton.Add_Click({
        if ($listBox.SelectedIndex -ge 0) {
            $selectedText = $listBox.SelectedItem.ToString()
            # Extract index from the text [0]
            if ($selectedText -match '^\[(\d+)\]') {
                $index = [int]$matches[1]
                $fileToRemove = $Config.LogFiles[$index]
                
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "Remove this log file from monitoring?`n`n$fileToRemove",
                    "Confirm Removal",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    # Remove from array
                    $newList = @()
                    $logFileCount = @($Config.LogFiles).Count
                    for ($i = 0; $i -lt $logFileCount; $i++) {
                        if ($i -ne $index) {
                            $newList += $Config.LogFiles[$i]
                        }
                    }
                    $Config.LogFiles = $newList
                    Save-Config -Config $Config
                    
                    # Refresh listbox using helper function (DRY principle)
                    Update-LogFileListBox -ListBox $listBox -Config $Config
                    Write-ToLog "Removed log file from monitoring" -Level Info
                    
                    [System.Windows.Forms.MessageBox]::Show("Log file removed from monitoring.", "Success")
                }
            }
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Please select a log file to remove.", "No Selection")
        }
    })
    $manageForm.Controls.Add($removeButton)
    
        # Refresh button
        $refreshButton = New-Object System.Windows.Forms.Button
        $refreshButton.Location = New-Object System.Drawing.Point(170, 325)
        $refreshButton.Size = New-Object System.Drawing.Size(150, 30)
        $refreshButton.Text = "Refresh Status"
        $refreshButton.Add_Click({
            Update-LogFileListBox -ListBox $listBox -Config $Config
            Write-ToLog "Refreshed log file status display" -Level Info
        })
        $manageForm.Controls.Add($refreshButton)
        
        # Close button
        $closeButton = New-Object System.Windows.Forms.Button
        $closeButton.Location = New-Object System.Drawing.Point(430, 325)
        $closeButton.Size = New-Object System.Drawing.Size(150, 30)
        $closeButton.Text = "Close"
        $closeButton.Add_Click({ $manageForm.Close() })
        $manageForm.Controls.Add($closeButton)
        
        $manageForm.ShowDialog() | Out-Null
    }
    finally {
        $manageForm.Dispose()
    }
}

# Function to show configuration dialog
#STUB - FUNCTION - Show-ConfigDialog
function Show-ConfigDialog {
    param($Config)
    
    $form = New-Object System.Windows.Forms.Form
    try {
        # Validate configuration
        if ($null -eq $Config) {
            [System.Windows.Forms.MessageBox]::Show("Invalid configuration.", "Error")
            return
        }
        
        $form.Text = "EverQuest Log Recycler - Configuration"
        $form.Size = New-Object System.Drawing.Size(400, 320)
        $form.StartPosition = "CenterScreen"
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Current Configuration:"
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $label.Size = New-Object System.Drawing.Size(370, 20)
    $form.Controls.Add($label)
    
    $configLabel = New-Object System.Windows.Forms.Label
    $configText = "Recycle Time: $($Config.RecycleTime)`n"
    $configText += "Archive Folder: $($Config.ArchiveFolder)`n"
    $configText += "Monitored Files: $($Config.LogFiles.Count)`n"
    if ($Config.LastRecycleDate) {
        $configText += "Last Recycle: $($Config.LastRecycleDate)"
    } else {
        $configText += "Last Recycle: Never"
    }
    $configLabel.Text = $configText
    $configLabel.Location = New-Object System.Drawing.Point(10, 35)
    $configLabel.Size = New-Object System.Drawing.Size(370, 80)
    $form.Controls.Add($configLabel)
    
    $addButton = New-Object System.Windows.Forms.Button
    $addButton.Location = New-Object System.Drawing.Point(10, 125)
    $addButton.Size = New-Object System.Drawing.Size(180, 30)
    $addButton.Text = "Add Log File"
    $addButton.Add_Click({
        $logFile = Select-LogFile
        if ($logFile) {
            if ($Config.LogFiles -notcontains $logFile) {
                $Config.LogFiles += $logFile
                Save-Config -Config $Config
                Write-ToLog "Added log file to monitoring: $logFile" -Level Info
                [System.Windows.Forms.MessageBox]::Show("Log file added successfully!", "Success")
                # Update the display
                $configText = "Recycle Time: $($Config.RecycleTime)`n"
                $configText += "Archive Folder: $($Config.ArchiveFolder)`n"
                $configText += "Monitored Files: $($Config.LogFiles.Count)`n"
                if ($Config.LastRecycleDate) {
                    $configText += "Last Recycle: $($Config.LastRecycleDate)"
                } else {
                    $configText += "Last Recycle: Never"
                }
                $configLabel.Text = $configText
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("This file is already being monitored.", "Info")
            }
        }
    })
    $form.Controls.Add($addButton)
    
    $changeTimeButton = New-Object System.Windows.Forms.Button
    $changeTimeButton.Location = New-Object System.Drawing.Point(200, 125)
    $changeTimeButton.Size = New-Object System.Drawing.Size(180, 30)
    $changeTimeButton.Text = "Change Recycle Time"
    $changeTimeButton.Add_Click({
        $newTime = Get-RecycleTime
        $Config.RecycleTime = $newTime
        Save-Config -Config $Config
        Write-ToLog "Changed recycle time to: $newTime" -Level Info
        [System.Windows.Forms.MessageBox]::Show("Recycle time updated to $newTime", "Success")
        $form.Close()
    })
    $form.Controls.Add($changeTimeButton)
    
    $changeFolderButton = New-Object System.Windows.Forms.Button
    $changeFolderButton.Location = New-Object System.Drawing.Point(10, 165)
    $changeFolderButton.Size = New-Object System.Drawing.Size(180, 30)
    $changeFolderButton.Text = "Change Archive Folder"
    $changeFolderButton.Add_Click({
        $newFolder = Select-ArchiveFolder
        if ($newFolder) {
            $Config.ArchiveFolder = $newFolder
            Save-Config -Config $Config
            Write-ToLog "Changed archive folder to: $newFolder" -Level Info
            [System.Windows.Forms.MessageBox]::Show("Archive folder updated!", "Success")
            $form.Close()
        }
    })
    $form.Controls.Add($changeFolderButton)
    
    $listLogsButton = New-Object System.Windows.Forms.Button
    $listLogsButton.Location = New-Object System.Drawing.Point(200, 165)
    $listLogsButton.Size = New-Object System.Drawing.Size(180, 30)
    $listLogsButton.Text = "Manage Log Files"
    $listLogsButton.Add_Click({
        Show-LogFileManager -Config $Config
        # Update the display after managing files
        $configText = "Recycle Time: $($Config.RecycleTime)`n"
        $configText += "Archive Folder: $($Config.ArchiveFolder)`n"
        $configText += "Monitored Files: $($Config.LogFiles.Count)`n"
        if ($Config.LastRecycleDate) {
            $configText += "Last Recycle: $($Config.LastRecycleDate)"
        } else {
            $configText += "Last Recycle: Never"
        }
        $configLabel.Text = $configText
    })
    $form.Controls.Add($listLogsButton)
    
    $recycleNowButton = New-Object System.Windows.Forms.Button
    $recycleNowButton.Location = New-Object System.Drawing.Point(10, 205)
    $recycleNowButton.Size = New-Object System.Drawing.Size(370, 30)
    $recycleNowButton.Text = "Recycle Now (Manual)"
    $recycleNowButton.Add_Click({
        Write-ToLog "Manual recycle initiated by user" -Level Info
        $count = Invoke-LogRecycle -Config $Config -ShowNotification
        [System.Windows.Forms.MessageBox]::Show("Manual recycle completed! $count file(s) recycled.", "Success")
        $form.Close()
    })
    $form.Controls.Add($recycleNowButton)
    
        $closeButton = New-Object System.Windows.Forms.Button
        $closeButton.Location = New-Object System.Drawing.Point(10, 245)
        $closeButton.Size = New-Object System.Drawing.Size(370, 30)
        $closeButton.Text = "Close"
        $closeButton.Add_Click({ $form.Close() })
        $form.Controls.Add($closeButton)
        
        $form.ShowDialog() | Out-Null
    }
    finally {
        $form.Dispose()
    }
}

# Function to create system tray icon
#STUB - FUNCTION - Start-TrayMonitor
function Start-TrayMonitor {
    param($Config)
    
    Write-ToLog "Starting tray monitor" -Level Info
    
    # Create the NotifyIcon
    $Script:NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
    
    # Create a fun scroll/log book icon
    $bitmap = New-Object System.Drawing.Bitmap 16, 16
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Background - parchment color
    $parchmentBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 245, 222, 179))
    $graphics.FillRectangle($parchmentBrush, 2, 2, 12, 12)
    
    # Brown border (scroll edges)
    $brownPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 139, 90, 43), 1)
    $graphics.DrawRectangle($brownPen, 2, 2, 11, 11)
    
    # Draw scroll curves at top and bottom
    $graphics.DrawArc($brownPen, 1, 1, 4, 3, 180, 180)
    $graphics.DrawArc($brownPen, 11, 1, 4, 3, 0, 180)
    $graphics.DrawArc($brownPen, 1, 12, 4, 3, 0, 180)
    $graphics.DrawArc($brownPen, 11, 12, 4, 3, 180, 180)
    
    # Draw text lines on scroll (like log entries)
    $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 100, 70, 40), 1)
    $graphics.DrawLine($linePen, 4, 5, 11, 5)
    $graphics.DrawLine($linePen, 4, 7, 11, 7)
    $graphics.DrawLine($linePen, 4, 9, 11, 9)
    $graphics.DrawLine($linePen, 4, 11, 9, 11)
    
    # Green recycling arrow/checkmark
    $greenPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 34, 139, 34), 2)
    $greenPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $greenPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    
    # Draw a curved recycling arrow using individual lines
    $graphics.DrawLine($greenPen, 10, 10, 12, 12)
    $graphics.DrawLine($greenPen, 12, 12, 14, 10)
    
    # Arrow head
    $arrowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 34, 139, 34), 1)
    $graphics.DrawLine($arrowPen, 14, 10, 13, 9)
    $graphics.DrawLine($arrowPen, 14, 10, 13, 11)
    
    # Cleanup
    $graphics.Dispose()
    $parchmentBrush.Dispose()
    $brownPen.Dispose()
    $linePen.Dispose()
    $greenPen.Dispose()
    $arrowPen.Dispose()
    
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $Script:NotifyIcon.Icon = $icon
    $Script:NotifyIcon.Text = "EQ Log Recycler - Monitoring"
    $Script:NotifyIcon.Visible = $true
    
    # Create context menu
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    
    $statusItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $statusItem.Text = "Next recycle: $($Config.RecycleTime)"
    $statusItem.Enabled = $false
    $contextMenu.Items.Add($statusItem) | Out-Null
    
    $contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
    
    $configItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $configItem.Text = "Configuration..."
    $configItem.Add_Click({
        Show-ConfigDialog -Config $Config
        # Reload config in case it changed
        $Script:Config = Get-Config
    })
    $contextMenu.Items.Add($configItem) | Out-Null
    
    $recycleItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $recycleItem.Text = "Recycle Now"
    $recycleItem.Add_Click({
        Write-ToLog "Manual recycle initiated from tray context menu" -Level Info
        Invoke-LogRecycle -Config $Config -ShowNotification
    })
    $contextMenu.Items.Add($recycleItem) | Out-Null
    
    $contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
    
    $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exitItem.Text = "Exit"
    $exitItem.Add_Click({
        $Script:NotifyIcon.Visible = $false
        $Script:NotifyIcon.Dispose()
        [System.Windows.Forms.Application]::Exit()
    })
    $contextMenu.Items.Add($exitItem) | Out-Null
    
    $Script:NotifyIcon.ContextMenuStrip = $contextMenu
    
    # Double-click to show config
    $Script:NotifyIcon.Add_DoubleClick({
        Show-ConfigDialog -Config $Config
        $Script:Config = Get-Config
    })
    
    # Create timer for monitoring
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 30000 # 30 seconds
    $timer.Add_Tick({
        $currentTime = Get-Date -Format "HH:mm"
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        
        # Reload config to get latest LastRecycleDate
        $Script:Config = Get-Config
        
        # Validate config before using it
        if ($null -ne $Script:Config -and $null -ne $Script:Config.RecycleTime) {
            if ($currentTime -eq $Script:Config.RecycleTime -and ($null -eq $Script:Config.LastRecycleDate -or $Script:Config.LastRecycleDate -ne $currentDate)) {
                Write-ToLog "Scheduled recycle time reached: $currentTime" -Level Info
                Invoke-LogRecycle -Config $Script:Config -ShowNotification
            }
        }
    })
    $timer.Start()
    
    Write-Host "System tray monitoring started. Right-click the tray icon for options." -ForegroundColor Green
    
    # Trap cleanup on exit
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Write-Verbose "Cleaning up tray monitor resources..."
        $timer.Stop()
        $timer.Dispose()
        $Script:NotifyIcon.Visible = $false
        $Script:NotifyIcon.Dispose()
    }
    
    # Run the application
    [System.Windows.Forms.Application]::Run()
}

# Function to start silent monitoring
#STUB - FUNCTION - Start-SilentMonitor
function Start-SilentMonitor {
    param($Config)
    
    # Validate configuration
    if ($null -eq $Config) {
        Write-Error "Invalid configuration provided to Start-SilentMonitor"
        Write-ToLog "Invalid configuration provided to Start-SilentMonitor" -Level Error
        return
    }
    
    Write-ToLog "Starting silent background monitoring" -Level Info
    Write-Host "Starting silent background monitoring..." -ForegroundColor Green
    Write-Host "Recycle Time: $($Config.RecycleTime)" -ForegroundColor Cyan
    Write-Host "Archive Folder: $($Config.ArchiveFolder)" -ForegroundColor Cyan
    Write-Host "Monitoring $(@($Config.LogFiles).Count) file(s)" -ForegroundColor Cyan
    
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    if ($Config.LastRecycleDate -eq $currentDate) {
        Write-Host "Note: Logs were already recycled today ($currentDate)" -ForegroundColor Yellow
    }
    
    Write-Host "Press Ctrl+C to stop monitoring...`n" -ForegroundColor Yellow
    
    # Create a cancellation token for graceful shutdown
    $shouldExit = $false
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        $shouldExit = $true
        Write-Host "`n`nShutting down silent monitor...`n" -ForegroundColor Yellow
    }
    
    try {
        while (-not $shouldExit) {
            $currentTime = Get-Date -Format "HH:mm"
            $currentDate = Get-Date -Format "yyyy-MM-dd"
            
            # Reload config to check for changes
            $Config = Get-Config
            
            # Validate config before using
            if ($null -ne $Config -and $null -ne $Config.RecycleTime) {
                if ($currentTime -eq $Config.RecycleTime -and ($null -eq $Config.LastRecycleDate -or $Config.LastRecycleDate -ne $currentDate)) {
                    Write-ToLog "Scheduled recycle time reached in silent monitor: $currentTime" -Level Info
                    Write-Host "`n=== Recycle Time Reached ===" -ForegroundColor Green
                    Invoke-LogRecycle -Config $Config
                }
            }
            else {
                Write-Warning "Configuration became invalid during monitoring"
                Write-ToLog "Configuration became invalid during silent monitoring" -Level Warning
            }
            
            Start-Sleep -Seconds 30
        }
    }
    catch [System.OperationCanceledException] {
        Write-Host "Silent monitoring cancelled by user" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Error in silent monitoring: $_"
    }
    finally {
        Write-Host "Silent monitoring stopped" -ForegroundColor Green
    }
}

# Main execution
Write-Host "EverQuest Log Recycler Starting..." -ForegroundColor Cyan

# Load or create configuration
$Script:Config = Get-Config

if ($null -eq $Script:Config) {
    Write-Host "No configuration found. Starting setup..." -ForegroundColor Yellow
    
    # Initial setup
    $logFile = Select-LogFile
    if ($null -eq $logFile) {
        Write-Host "No log file selected. Exiting." -ForegroundColor Red
        exit
    }
    
    $archiveFolder = Select-ArchiveFolder
    if ($null -eq $archiveFolder) {
        Write-Host "No archive folder selected. Exiting." -ForegroundColor Red
        exit
    }
    
    $recycleTime = Get-RecycleTime
    
    $Script:Config = @{
        LogFiles = @($logFile)
        ArchiveFolder = $archiveFolder
        RecycleTime = $recycleTime
        LastRecycleDate = $null
    }
    
    Save-Config -Config $Script:Config
    Write-Host "Configuration saved!" -ForegroundColor Green
}

# Handle command line parameters
if ($ListLogs) {
    Write-Host "`nConfigured Log Files:" -ForegroundColor Cyan
    $logFileCount = @($Script:Config.LogFiles).Count
    if ($logFileCount -eq 0) {
        Write-Host "  [No log files configured]" -ForegroundColor Yellow
    } else {
        for ($i = 0; $i -lt $logFileCount; $i++) {
            if ($Script:Config.LogFiles[$i]) {
                $exists = if (Test-Path $Script:Config.LogFiles[$i]) { "EXISTS" } else { "NOT FOUND" }
                Write-Host "  [$i] $($Script:Config.LogFiles[$i]) - $exists"
            }
        }
    }
    Write-Host "`nUse -RecycleOne <index> to recycle a specific log" -ForegroundColor Yellow
    exit
}

if ($RecycleOne -ge 0) {
    $logFileCount = @($Script:Config.LogFiles).Count
    if ($RecycleOne -lt $logFileCount) {
        Write-Host "`nRecycling log file at index $RecycleOne..." -ForegroundColor Yellow
        Invoke-LogRecycle -Config $Script:Config -Index $RecycleOne
    }
    else {
        Write-Host "Error: Index $RecycleOne is out of range (valid range: 0-$($logFileCount - 1)). Use -ListLogs to see valid indices." -ForegroundColor Red
    }
    exit
}

if ($RecycleNow) {
    Write-Host "`nRecycling all configured log files..." -ForegroundColor Yellow
    Invoke-LogRecycle -Config $Script:Config
    exit
}

# Start monitoring
if ($Silent) {
    Start-SilentMonitor -Config $Script:Config
}
else {
    # Default to tray mode
    Start-TrayMonitor -Config $Script:Config
}
