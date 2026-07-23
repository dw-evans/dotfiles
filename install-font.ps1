<#
.SYNOPSIS
    Downloads JetBrains Mono Nerd Font v3.4.0 to the user's Downloads folder and opens the extracted folder in File Explorer.

.DESCRIPTION
    1. Downloads JetBrainsMono.zip from GitHub releases to %USERPROFILE%\Downloads.
    2. Extracts the zip into %USERPROFILE%\Downloads\JetBrainsMono.
    3. Displays the path and automatically opens the extracted folder in File Explorer.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install-font.ps1
#>

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Highlight($msg) { Write-Host "[LOCATION] $msg" -ForegroundColor Yellow }

Write-Host "=== JetBrains Mono Nerd Font Downloader ===" -ForegroundColor Blue
Write-Host ""

$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
$downloadsDir = Join-Path $env:USERPROFILE "Downloads"
$targetZip = Join-Path $downloadsDir "JetBrainsMono.zip"
$targetFolder = Join-Path $downloadsDir "JetBrainsMono"

if (-not (Test-Path $downloadsDir)) {
    New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
}

Write-Info "Downloading JetBrains Mono Nerd Font to $targetZip..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $fontUrl -OutFile $targetZip

Write-Info "Extracting font archive to $targetFolder..."
if (Test-Path $targetFolder) {
    Remove-Item -Path $targetFolder -Recurse -Force
}
Expand-Archive -Path $tempZip -DestinationPath $targetFolder -Force 2>$null
if (-not (Test-Path $targetFolder)) {
    Expand-Archive -Path $targetZip -DestinationPath $targetFolder -Force
}

Write-Host ""
Write-Success "=== Download complete! ==="
Write-Host ""
Write-Highlight "Font files saved to:"
Write-Host "  ZIP Archive : $targetZip" -ForegroundColor White
Write-Host "  Extracted   : $targetFolder" -ForegroundColor White
Write-Host ""

Write-Info "Opening extracted folder in File Explorer..."
try {
    Start-Process explorer.exe -ArgumentList "`"$targetFolder`""
} catch {
    Invoke-Item $targetFolder
}

Write-Host ""
Write-Host "Instructions to install:" -ForegroundColor Cyan
Write-Host "  1. Select the font files (.ttf)"
Write-Host "  2. Right-click and choose 'Install' or 'Install for all users'."
Write-Host ""
