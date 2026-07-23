<#
.SYNOPSIS
    Installs WezTerm on Windows and symlinks wezterm.lua to the user profile folder.

.DESCRIPTION
    This script automates setting up WezTerm on Windows machines:
    1. Checks if WezTerm is installed. If missing, installs it via winget or direct GitHub release download.
    2. Links dotfiles/wezterm/wezterm.lua to %USERPROFILE%\.wezterm.lua (with symlink, hardlink, or copy fallbacks).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\setup-wezterm-windows.ps1
#>

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARNING] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

Write-Host "=== WezTerm Windows Setup ===" -ForegroundColor Blue
Write-Host ""

# Determine dotfiles root directory from script location
$DOTFILES_DIR = Split-Path $PSScriptRoot -Parent
$SOURCE_CONFIG = Join-Path $DOTFILES_DIR "wezterm\wezterm.lua"
$TARGET_CONFIG = Join-Path $env:USERPROFILE ".wezterm.lua"

# 1. Check & Install WezTerm
function Test-CommandExists($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

$weztermPaths = @(
    "C:\Program Files\WezTerm\wezterm.exe",
    "C:\Program Files (x86)\WezTerm\wezterm.exe",
    "$env:LOCALAPPDATA\Programs\WezTerm\wezterm.exe"
)

$installedPath = $weztermPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (Test-CommandExists "wezterm" -or $installedPath) {
    Write-Success "WezTerm is already installed."
} else {
    Write-Info "WezTerm not found. Proceeding with installation..."
    $installed = $false

    # Try Winget installation
    if (Test-CommandExists "winget") {
        Write-Info "Attempting installation via winget..."
        try {
            winget install --id WezTerm.WezTerm -e --source winget --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Success "WezTerm installed successfully via winget."
                $installed = $true
            } else {
                Write-Warn "winget exited with code $LASTEXITCODE. Trying GitHub release fallback..."
            }
        } catch {
            Write-Warn "winget installation failed: $_. Trying GitHub release fallback..."
        }
    }

    # Fallback to direct download from GitHub Releases
    if (-not $installed) {
        Write-Info "Fetching latest WezTerm release from GitHub..."
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $releaseUrl = "https://api.github.com/repos/wez/wezterm/releases/latest"
            $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ "User-Agent" = "PowerShell" }
            
            # Find Windows installer asset (.setup.exe or .msi)
            $asset = $release.assets | Where-Object { $_.name -like "*setup.exe" -or $_.name -like "*.msi" } | Select-Object -First 1
            
            if ($asset) {
                $downloadUrl = $asset.browser_download_url
                $tempPath = Join-Path $env:TEMP $asset.name
                Write-Info "Downloading WezTerm installer from $downloadUrl..."
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath

                Write-Info "Running installer..."
                if ($tempPath.EndsWith(".exe")) {
                    Start-Process -FilePath $tempPath -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
                } elseif ($tempPath.EndsWith(".msi")) {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempPath`" /qn /norestart" -Wait
                }

                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
                Write-Success "WezTerm installed successfully."
                $installed = $true
            } else {
                Write-Err "Could not find a Windows installer (.setup.exe or .msi) in the latest GitHub release."
            }
        } catch {
            Write-Err "Failed to download or install WezTerm from GitHub: $_"
        }
    }
}

# Update PATH for current session if installed in standard location
if (Test-Path "C:\Program Files\WezTerm") {
    if ($env:PATH -notlike "*C:\Program Files\WezTerm*") {
        $env:PATH += ";C:\Program Files\WezTerm"
    }
}

Write-Host ""

# 2. Symlink wezterm.lua to USERPROFILE folder
if (-not (Test-Path $SOURCE_CONFIG)) {
    Write-Err "Source configuration file not found at: $SOURCE_CONFIG"
    exit 1
}

Write-Info "Setting up WezTerm configuration link..."
Write-Info "  Source: $SOURCE_CONFIG"
Write-Info "  Target: $TARGET_CONFIG"

$alreadyLinked = $false

if (Test-Path $TARGET_CONFIG) {
    $item = Get-Item $TARGET_CONFIG -ErrorAction SilentlyContinue
    if ($item.Attributes -match "ReparsePoint") {
        $currentTarget = $item.Target
        if ($currentTarget -eq $SOURCE_CONFIG -or $currentTarget -eq (Resolve-Path $SOURCE_CONFIG).Path) {
            Write-Success "  [EXISTS] Symlink already exists and points to $SOURCE_CONFIG"
            $alreadyLinked = $true
        } else {
            Write-Warn "  [UPDATE] Removing existing symlink pointing to $currentTarget"
            Remove-Item $TARGET_CONFIG -Force
        }
    } else {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "${TARGET_CONFIG}.bak.${timestamp}"
        Write-Warn "  [BACKUP] Existing file found. Backing up to $backupPath"
        Move-Item -Path $TARGET_CONFIG -Destination $backupPath -Force
    }
}

if (-not $alreadyLinked) {
    $linked = $false
    
    # Attempt 1: Symbolic Link
    try {
        New-Item -ItemType SymbolicLink -Path $TARGET_CONFIG -Value $SOURCE_CONFIG -Force -ErrorAction Stop | Out-Null
        Write-Success "  [LINKED] Successfully created symbolic link!"
        $linked = $true
    } catch {
        Write-Warn "  [NOTICE] Symbolic link creation required Developer Mode or Administrator rights."
    }

    # Attempt 2: Hard Link fallback
    if (-not $linked) {
        try {
            New-Item -ItemType HardLink -Path $TARGET_CONFIG -Value $SOURCE_CONFIG -Force -ErrorAction Stop | Out-Null
            Write-Success "  [LINKED] Successfully created hard link!"
            $linked = $true
        } catch {
            Write-Warn "  [NOTICE] Hard link fallback failed."
        }
    }

    # Attempt 3: Copy fallback
    if (-not $linked) {
        Copy-Item -Path $SOURCE_CONFIG -Destination $TARGET_CONFIG -Force
        Write-Success "  [COPIED] Copied wezterm.lua to $TARGET_CONFIG"
        Write-Info "  (Tip: Enable Windows Developer Mode to allow native symbolic links without admin rights)"
    }
}

Write-Host ""
Write-Success "=== WezTerm Windows setup complete! ==="
