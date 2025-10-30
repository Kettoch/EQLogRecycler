# Contributing to EverQuest Log Recycler

Thank you for your interest in contributing! This document provides guidelines for reporting issues, submitting code, and improving the project.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Types of Contributions](#types-of-contributions)
- [Development Setup](#development-setup)
- [PowerShell Style Guide](#powershell-style-guide)
- [Commit Conventions](#commit-conventions)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)

---

## 💪 Code of Conduct

### Our Standards

- **Inclusive**: We welcome contributors of all backgrounds and skill levels
- **Respectful**: Be courteous and professional in all interactions
- **Constructive**: Focus on ideas, not individuals, in feedback
- **Collaborative**: Work together toward the project's goals

### Unacceptable Behavior

- Harassment, discrimination, or hateful language
- Personal attacks or insults
- Spam or off-topic content
- Attempts to exploit the project

**Reporting Issues**: [Report to maintainers]

---

## 🚀 Getting Started

### Prerequisites

1. **Windows 7 or later** (10/11 recommended)
2. **PowerShell 5.1+**
   ```powershell
   $PSVersionTable.PSVersion  # Check your version
   ```
3. **Inno Setup** (for building installers)
   - Download: https://jrsoftware.com/isdl.php
   - Used for: Creating `.exe` installers

4. **Git** and **GitHub account**
   - https://git-scm.com/
   - https://github.com

### Fork & Clone

```powershell
# 1. Fork on GitHub (click Fork button)

# 2. Clone your fork
git clone https://github.com/YOUR-USERNAME/EQLogRecycler.git
cd EQLogRecycler

# 3. Add upstream remote
git remote add upstream https://github.com/OriginalAuthor/EQLogRecycler.git

# 4. Create feature branch
git checkout -b feature/your-feature-name
```

---

## 📝 Types of Contributions

### 🐛 Bug Reports

**Before reporting**, check if the issue already exists.

**Create a new issue** with:
```markdown
**Describe the bug**
A clear description of what went wrong.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What should happen instead.

**Environment**
- Windows: [e.g., Windows 10, Build 19041]
- PowerShell: [e.g., 5.1, 7.2]
- EQLogRecycler: [e.g., 1.0]

**Logs or Screenshots**
If applicable, attach error messages or screenshots.
```

### ✨ Feature Requests

**Describe the feature**:
```markdown
**Is your feature request related to a problem?**
What problem does it solve?

**Describe the solution**
Clear description of what you want to happen.

**Describe alternatives**
Other approaches you've considered.

**Additional context**
Screenshots or examples.
```

### 📖 Documentation Improvements

Help us improve:
- README.md
- Inline code comments
- Troubleshooting guides
- Tutorial documentation

### 🔧 Code Improvements

- Bug fixes
- Performance optimizations
- Code quality improvements
- New features

---

## 💻 Development Setup

### Environment Setup

```powershell
# 1. Install IntelliSense and PowerShell extensions for VSCode
# Download: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell

# 2. Install Pester for testing
Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck

# 3. Verify setup
$PSVersionTable
```

### Project Structure

```
EQLogRecycler/
├── EQLogRecycler.ps1          # Main application (875 lines)
├── setup.iss                  # Installer script (Inno Setup)
├── README.md                  # User documentation
├── CONTRIBUTING.md            # This file
├── LICENSE                    # MIT License
├── CODE_REVIEW.md             # Code review and metrics
│
├── Tests/                     # Test suite (Pester)
│   ├── Unit/                  # Unit tests
│   ├── Integration/           # Integration tests
│   └── E2E/                   # End-to-end tests
│
├── Docs/                      # Additional documentation
│   ├── INSTALLATION.md
│   ├── TROUBLESHOOTING.md
│   └── ARCHITECTURE.md
│
└── Installer/                 # Built installers
    └── EQLogRecycler_Setup_v1.0.exe
```

### Opening in VSCode

```powershell
# Navigate to project
cd EQLogRecycler

# Open in VSCode
code .

# Or from VSCode: File → Open Folder
```

---

## 🎨 PowerShell Style Guide

### Naming Conventions

```powershell
# ✅ GOOD
$logFilePath
$isValidConfiguration
function Get-ConfigFromRegistry { }
function Invoke-LogRecycle { }

# ❌ BAD
$lp
$valid
function getConfig { }
function LogRecycle { }
```

### Formatting

```powershell
# Functions
function Get-Config {
    <#
    .SYNOPSIS
        Brief description
    .DESCRIPTION
        Detailed description
    .PARAMETER ConfigPath
        Description of parameter
    .EXAMPLE
        Get-Config -ConfigPath "HKCU:\..."
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    try {
        # Implementation
    }
    catch {
        Write-Error "Descriptive error message: $_"
    }
}
```

### Comments

```powershell
# ✅ GOOD
# Validate that configuration contains required properties
if ($null -eq $config.LogFiles) {
    Write-Error "Configuration missing LogFiles property"
}

# ❌ BAD
# check config
if ($null -eq $config.LogFiles) {

}
```

### Error Handling

```powershell
# ✅ GOOD
try {
    $result = [System.IO.File]::WriteAllText($path, $content)
}
catch [System.IO.IOException] {
    Write-Error "Failed to write file: $_"
}
catch {
    Write-Error "Unexpected error: $_"
}

# ❌ BAD
$result = [System.IO.File]::WriteAllText($path, $content)  # No error handling
```

### Array Handling

```powershell
# ✅ GOOD - Handles single items and arrays consistently
$items = @($config.LogFiles)  # Always creates array
$count = $items.Count

# ❌ BAD
$count = $config.LogFiles.Count  # Fails if single item
```

---

## 📝 Commit Conventions

Use conventional commits for clear history:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Code formatting (no logic change)
- **refactor**: Code restructuring
- **perf**: Performance improvement
- **test**: Adding/updating tests
- **chore**: Maintenance tasks

### Examples

```bash
# Good commit messages
git commit -m "feat(gui): add pause/resume button to configuration dialog"
git commit -m "fix(recycler): prevent recycling files in use by EverQuest"
git commit -m "docs(readme): add troubleshooting section"
git commit -m "refactor(config): extract duplicate listbox update logic"
git commit -m "test(recycler): add unit tests for Invoke-LogRecycle"
```

---

## 🔄 Pull Request Process

### Before Creating PR

1. **Sync with upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**:
   ```powershell
   Invoke-Pester Tests/ -Verbose
   ```

3. **Check code style**:
   ```powershell
   # Use PSScriptAnalyzer
   Invoke-ScriptAnalyzer EQLogRecycler.ps1 -Severity Warning
   ```

4. **Update documentation** if needed

### Creating the PR

1. **Push feature branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request** on GitHub with:
   ```markdown
   ## Description
   Brief overview of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Performance improvement
   
   ## How to Test
   Steps to verify the changes work
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex logic
   - [ ] Documentation updated
   - [ ] Tests added/updated
   - [ ] All tests pass
   
   ## Related Issues
   Fixes #(issue number)
   ```

### Review Process

- Maintainers review within 48 hours
- May request changes before approval
- Once approved, maintainers merge PR
- Branch is deleted after merge

---

## 🧪 Testing Guidelines

### Running Tests

```powershell
# All tests
Invoke-Pester Tests/ -Verbose

# Specific test file
Invoke-Pester Tests/Unit/Configuration.Tests.ps1 -Verbose

# With code coverage
Invoke-Pester Tests/ -CodeCoverage EQLogRecycler.ps1 -Show All
```

### Writing Tests

```powershell
# Tests/Unit/MyFeature.Tests.ps1
BeforeAll {
    . $PSScriptRoot\..\..\EQLogRecycler.ps1
}

Describe "Feature Name" {
    Context "When condition is met" {
        It "Should perform expected action" {
            # Arrange
            $testData = @{
                LogFiles = @("C:\logs\test.txt")
                ArchiveFolder = "C:\archive"
            }
            
            # Act
            $result = Get-Config -Config $testData
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
```

### Test Coverage Goals

- Unit tests: >80% coverage
- Integration tests: Critical paths
- E2E tests: User workflows

---

## 📚 Documentation Guidelines

### Code Comments

```powershell
# ✅ GOOD
# Validate that the archive folder is writable before attempting save
$testFile = Join-Path $archiveFolder ".write_test"
[System.IO.File]::WriteAllText($testFile, "test")

# ❌ BAD
# test if writable
$testFile = Join-Path $archiveFolder ".write_test"
[System.IO.File]::WriteAllText($testFile, "test")
```

### Function Documentation

```powershell
# ✅ GOOD
function Invoke-LogRecycle {
    <#
    .SYNOPSIS
        Moves EverQuest log files to archive folder with timestamp.
    
    .DESCRIPTION
        Takes configured log files and moves them to the archive folder
        with a timestamp appended. EverQuest will create new fresh logs
        when the game detects missing files.
    
    .PARAMETER Config
        Configuration object containing LogFiles and ArchiveFolder paths.
    
    .PARAMETER Index
        If specified, only recycles the log file at this index.
    
    .PARAMETER ShowNotification
        If true, shows balloon notification in system tray.
    
    .EXAMPLE
        Invoke-LogRecycle -Config $config -ShowNotification
    
    .INPUTS
        System.Object[] - Configuration object
    
    .OUTPUTS
        System.Int32 - Number of files recycled
    
    .NOTES
        Requires administrative permissions to modify registry.
    #>
    param(...)
}
```

### README Sections

Update README.md if your change affects:
- Installation process
- Usage instructions
- Feature functionality
- Supported systems

---

## 🚦 Before You Submit

### Checklist

- [ ] Code follows [PowerShell Style Guide](#powershell-style-guide)
- [ ] All tests pass: `Invoke-Pester Tests/ -Verbose`
- [ ] Code analyzed: `Invoke-ScriptAnalyzer EQLogRecycler.ps1`
- [ ] Comments added for complex sections
- [ ] No debug code left in (Write-Host, breakpoints)
- [ ] README.md updated if needed
- [ ] Commit messages follow conventions
- [ ] No unrelated changes in PR

### Common Issues to Avoid

```powershell
# ❌ Don't: Write-Host in production code
Write-Host "Debug message"  # Unacceptable

# ✅ Do: Use Write-Verbose
Write-Verbose "Debug message"

# ❌ Don't: Hardcoded paths
$path = "C:\Users\Username\Documents"

# ✅ Do: Use environment variables
$path = "$env:USERPROFILE\Documents"

# ❌ Don't: Silent error suppression
Get-Item $file -ErrorAction SilentlyContinue | Out-Null

# ✅ Do: Handle errors explicitly
if (Test-Path $file) {
    Get-Item $file
} else {
    Write-Warning "File not found: $file"
}
```

---

## 🆘 Getting Help

### Questions?

- **Ask in Discussions**: Start a discussion thread
- **Review Issues**: Others may have similar questions
- **Check Documentation**: Most answers in README.md
- **Contact Maintainers**: [Email/Discord/etc.]

### Common Questions

**Q: How do I run the application locally?**
A: `.\EQLogRecycler.ps1` in PowerShell

**Q: How do I build the installer?**
A: Install Inno Setup, then: `iscc setup.iss`

**Q: Can I modify the icon?**
A: Icon is rendered dynamically. See `Start-TrayMonitor` function.

**Q: How do I test my changes with multiple log files?**
A: Create test log files and add them via Configuration GUI.

---

## 🏆 Recognition

### Contributors Hall of Fame

Contributors will be recognized in:
- README.md under "Acknowledgments"
- GitHub contributors page
- Release notes for their version

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## 🎯 Project Goals

This project aims to:
- Keep EverQuest player experience smooth and lag-free
- Provide an easy-to-use utility for log management
- Demonstrate PowerShell GUI development best practices
- Build a collaborative open-source community

---

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/YourUsername/EQLogRecycler/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YourUsername/EQLogRecycler/discussions)
- **Email**: [your-email@example.com]

---

Thank you for contributing to EverQuest Log Recycler! 🎉

Your efforts help make this utility better for the entire EverQuest community.

**Happy coding!** 🚀