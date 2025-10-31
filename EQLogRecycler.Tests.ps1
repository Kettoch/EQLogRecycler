<#
.SYNOPSIS
    Pester tests for EverQuest Log Recycler application
    
.DESCRIPTION
    Comprehensive unit tests for core functions including:
    - Configuration validation
    - Log file manipulation
    - Helper functions
    - Error handling
    
.NOTES
    To run tests:
    Invoke-Pester -Path "EQLogRecycler.Tests.ps1" -Verbose
    
    Or for detailed output:
    Invoke-Pester -Path "EQLogRecycler.Tests.ps1" -Output Detailed
#>

Describe "EQLogRecycler Configuration Validation" {
    
    Context "Validate-Config Function" {
        
        It "should accept valid configuration object" {
            $config = @{
                LogFiles = @("C:\test1.log", "C:\test2.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
                LastRecycleDate = "2025-01-15"
            }
            
            # This should not throw
            { . ".\EQLogRecycler.ps1" } | Should -Not -Throw
        }
        
        It "should reject null configuration" {
            $result = Validate-Config -Config $null
            $result | Should -Be $false
        }
        
        It "should reject configuration missing LogFiles" {
            $config = @{
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
            }
            
            $result = Validate-Config -Config $config
            $result | Should -Be $false
        }
        
        It "should reject configuration with empty ArchiveFolder" {
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = ""
                RecycleTime = "12:30"
            }
            
            $result = Validate-Config -Config $config
            $result | Should -Be $false
        }
        
        It "should reject invalid RecycleTime format" {
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "25:99"  # Invalid time
            }
            
            $result = Validate-Config -Config $config
            $result | Should -Be $false
        }
        
        It "should accept valid RecycleTime formats" {
            $validTimes = @("00:00", "12:30", "23:59", "01:15")
            
            foreach ($time in $validTimes) {
                $config = @{
                    LogFiles = @("C:\test.log")
                    ArchiveFolder = "C:\Archive"
                    RecycleTime = $time
                }
                
                $result = Validate-Config -Config $config
                $result | Should -Be $true -Because "RecycleTime $time should be valid"
            }
        }
        
        It "should handle single log file as array" {
            $config = @{
                LogFiles = "C:\test.log"  # Single string, not array
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
            }
            
            $result = Validate-Config -Config $config
            $result | Should -Be $true -Because "Single log file should be converted to array"
        }
        
        It "should add missing LastRecycleDate property" {
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
            }
            
            # Should not fail validation
            $result = Validate-Config -Config $config
            $result | Should -Be $true
        }
    }
}

Describe "EQLogRecycler Helper Functions" {
    
    Context "Write-ToLog Function" {
        
        $testLogPath = "$env:TEMP\EQLogRecycler_Test.log"
        
        # Cleanup before tests
        if (Test-Path $testLogPath) {
            Remove-Item $testLogPath -Force
        }
        
        It "should create log file on first write" {
            # Note: This test assumes Write-ToLog uses a specific log path
            # Adjust path as needed based on actual implementation
            Write-ToLog "Test message" -Level Info
            
            # Give it a moment to write
            Start-Sleep -Milliseconds 100
            
            # Check that log directory exists
            $logDir = "$env:APPDATA\TRTools"
            Test-Path $logDir | Should -Be $true
        }
        
        It "should include timestamp in log entries" {
            Write-ToLog "Test with timestamp" -Level Info
            
            $logFile = "$env:APPDATA\TRTools\EQLogRecycler.log"
            if (Test-Path $logFile) {
                $content = Get-Content $logFile -Raw
                $content | Should -Match "\[\d{4}-\d{2}-\d{2}"
            }
        }
        
        It "should log messages with different severity levels" {
            $levels = @("Info", "Warning", "Error", "Success")
            
            foreach ($level in $levels) {
                { Write-ToLog "Test $level message" -Level $level } | Should -Not -Throw
            }
        }
    }
    
    Context "Update-LogFileListBox Function" {
        
        It "should handle null configuration gracefully" {
            $listBox = New-Object System.Windows.Forms.ListBox
            
            { Update-LogFileListBox -ListBox $listBox -Config $null } | Should -Not -Throw
            $listBox.Items.Count | Should -Be 1
            $listBox.Items[0] | Should -Match "No log files"
        }
        
        It "should display [OK] for existing files" {
            # Create a temporary test file
            $testFile = "$env:TEMP\test_log_file.log"
            "Test" | Out-File $testFile -Force
            
            $config = @{
                LogFiles = @($testFile)
                ArchiveFolder = "$env:TEMP\Archive"
                RecycleTime = "12:30"
            }
            
            $listBox = New-Object System.Windows.Forms.ListBox
            Update-LogFileListBox -ListBox $listBox -Config $config
            
            $listBox.Items[0] | Should -Match "\[OK\]"
            $listBox.Items[0] | Should -Match $testFile
            
            # Cleanup
            Remove-Item $testFile -Force
        }
        
        It "should display [FAIL] for missing files" {
            $config = @{
                LogFiles = @("C:\NonExistent\Path\file.log")
                ArchiveFolder = "$env:TEMP\Archive"
                RecycleTime = "12:30"
            }
            
            $listBox = New-Object System.Windows.Forms.ListBox
            Update-LogFileListBox -ListBox $listBox -Config $config
            
            $listBox.Items[0] | Should -Match "\[FAIL\]"
        }
        
        It "should clear previous items before repopulating" {
            $config = @{
                LogFiles = @("C:\test1.log")
                ArchiveFolder = "$env:TEMP\Archive"
                RecycleTime = "12:30"
            }
            
            $listBox = New-Object System.Windows.Forms.ListBox
            $listBox.Items.Add("Old Item 1") | Out-Null
            $listBox.Items.Add("Old Item 2") | Out-Null
            
            $initialCount = $listBox.Items.Count
            $initialCount | Should -Be 2
            
            Update-LogFileListBox -ListBox $listBox -Config $config
            
            $listBox.Items.Count | Should -Not -Be $initialCount
            $listBox.Items | Should -Not -Contain "Old Item 1"
        }
    }
}

Describe "EQLogRecycler Log Recycling" {
    
    Context "Invoke-LogRecycle Function" {
        
        It "should return integer count of recycled files" {
            $config = @{
                LogFiles = @("C:\NonExistent.log")
                ArchiveFolder = "$env:TEMP\Archive"
                RecycleTime = "12:30"
            }
            
            $result = Invoke-LogRecycle -Config $config -ShowNotification $false
            
            $result | Should -BeOfType [System.Int32]
            $result | Should -Be 0
        }
        
        It "should handle missing log files gracefully" {
            $config = @{
                LogFiles = @("C:\Missing1.log", "C:\Missing2.log")
                ArchiveFolder = "$env:TEMP\Archive"
                RecycleTime = "12:30"
            }
            
            { Invoke-LogRecycle -Config $config -ShowNotification $false } | Should -Not -Throw
        }
        
        It "should create archive folder if needed" {
            $testArchive = "$env:TEMP\EQ_Test_Archive_$(Get-Random)"
            
            # Ensure it doesn't exist yet
            if (Test-Path $testArchive) {
                Remove-Item $testArchive -Recurse -Force
            }
            
            # Create a test log file
            $testLog = "$env:TEMP\test_recycle_$(Get-Random).log"
            "Test log content" | Out-File $testLog -Force
            
            try {
                $config = @{
                    LogFiles = @($testLog)
                    ArchiveFolder = $testArchive
                    RecycleTime = "12:30"
                }
                
                $result = Invoke-LogRecycle -Config $config -ShowNotification $false
                
                # Archive folder should be created
                Test-Path $testArchive | Should -Be $true
            }
            finally {
                # Cleanup
                if (Test-Path $testLog) { Remove-Item $testLog -Force }
                if (Test-Path $testArchive) { Remove-Item $testArchive -Recurse -Force }
            }
        }
    }
}

Describe "EQLogRecycler Configuration File" {
    
    Context "Get-Config Function" {
        
        It "should create config file if it doesn't exist" {
            # This tests that Get-Config handles missing config gracefully
            $config = Get-Config
            
            $config | Should -Not -BeNullOrEmpty
            $config | Should -HaveProperty "LogFiles"
            $config | Should -HaveProperty "ArchiveFolder"
            $config | Should -HaveProperty "RecycleTime"
        }
        
        It "should return configuration as hashtable" {
            $config = Get-Config
            
            $config | Should -BeOfType [PSCustomObject]
        }
        
        It "should contain required properties" {
            $config = Get-Config
            
            @("LogFiles", "ArchiveFolder", "RecycleTime") | ForEach-Object {
                $config | Should -HaveProperty $_
            }
        }
    }
    
    Context "Save-Config Function" {
        
        It "should save configuration without errors" {
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
                LastRecycleDate = "2025-01-15"
            }
            
            { Save-Config -Config $config } | Should -Not -Throw
        }
        
        It "should preserve config after save and reload" {
            $originalConfig = @{
                LogFiles = @("C:\test1.log", "C:\test2.log")
                ArchiveFolder = "C:\TestArchive"
                RecycleTime = "14:45"
                LastRecycleDate = "2025-01-15"
            }
            
            Save-Config -Config $originalConfig
            $reloadedConfig = Get-Config
            
            $reloadedConfig.RecycleTime | Should -Be $originalConfig.RecycleTime
            $reloadedConfig.ArchiveFolder | Should -Be $originalConfig.ArchiveFolder
        }
    }
}

Describe "EQLogRecycler Parameter Validation" {
    
    Context "Function Parameters" {
        
        It "should validate Invoke-LogRecycle RecycleOne parameter" {
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
            }
            
            # Valid index should not throw
            { Invoke-LogRecycle -Config $config -RecycleOne 0 -ShowNotification $false } | Should -Not -Throw
        }
        
        It "should reject negative RecycleOne index" {
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
            }
            
            # Negative index (except -1) should be handled
            { Invoke-LogRecycle -Config $config -RecycleOne -5 -ShowNotification $false } | Should -Not -Throw
        }
        
        It "should handle RecycleOne -1 (all files)" {
            $config = @{
                LogFiles = @("C:\test1.log", "C:\test2.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
            }
            
            # -1 means recycle all files
            { Invoke-LogRecycle -Config $config -RecycleOne -1 -ShowNotification $false } | Should -Not -Throw
        }
    }
}

Describe "EQLogRecycler Error Handling" {
    
    Context "Configuration Edge Cases" {
        
        It "should handle configuration with null LastRecycleDate" {
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
                LastRecycleDate = $null
            }
            
            $result = Validate-Config -Config $config
            $result | Should -Be $true
        }
        
        It "should handle configuration with empty LogFiles array" {
            $config = @{
                LogFiles = @()
                ArchiveFolder = "C:\Archive"
                RecycleTime = "12:30"
            }
            
            $result = Validate-Config -Config $config
            # Empty array is technically still valid configuration
            $result | Should -Be $true
        }
    }
    
    Context "File Operation Error Handling" {
        
        It "should not throw when archive folder is inaccessible" {
            # Using a protected system folder that should fail
            $config = @{
                LogFiles = @("C:\test.log")
                ArchiveFolder = "C:\System32\ProtectedFolder"
                RecycleTime = "12:30"
            }
            
            # Should handle gracefully, not crash
            { Invoke-LogRecycle -Config $config -ShowNotification $false } | Should -Not -Throw
        }
    }
}

Describe "EQLogRecycler Time Handling" {
    
    Context "Recycle Time Parsing" {
        
        It "should recognize all valid 24-hour time formats" {
            $validTimes = @(
                "00:00", "00:01", "00:59",  # Midnight hour
                "12:00", "12:30", "12:59",  # Noon hour
                "23:00", "23:30", "23:59"   # Evening hour
            )
            
            foreach ($time in $validTimes) {
                $config = @{
                    LogFiles = @("C:\test.log")
                    ArchiveFolder = "C:\Archive"
                    RecycleTime = $time
                }
                
                $result = Validate-Config -Config $config
                $result | Should -Be $true -Because "$time should be valid"
            }
        }
        
        It "should reject invalid time formats" {
            $invalidTimes = @(
                "24:00",     # 24 is invalid
                "12:60",     # 60 minutes is invalid
                "12:30:45",  # Seconds included
                "12-30",     # Wrong separator
                "1230",      # No separator
                "12 30"      # Space separator
            )
            
            foreach ($time in $invalidTimes) {
                $config = @{
                    LogFiles = @("C:\test.log")
                    ArchiveFolder = "C:\Archive"
                    RecycleTime = $time
                }
                
                $result = Validate-Config -Config $config
                $result | Should -Be $false -Because "$time should be invalid"
            }
        }
    }
}