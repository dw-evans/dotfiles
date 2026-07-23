#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_CONFIG="$DOTFILES_DIR/wezterm/wezterm.lua"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== WezTerm Windows Setup ===${NC}"

# Delegate to PowerShell script if powershell.exe is available (WSL, Git Bash, MSYS)
if command -v powershell.exe >/dev/null 2>&1; then
    if command -v wslpath >/dev/null 2>&1; then
        WIN_SCRIPT_PATH="$(wslpath -w "$SCRIPT_DIR/setup-wezterm-windows.ps1")"
    elif command -v cygpath >/dev/null 2>&1; then
        WIN_SCRIPT_PATH="$(cygpath -w "$SCRIPT_DIR/setup-wezterm-windows.ps1")"
    else
        WIN_SCRIPT_PATH="$SCRIPT_DIR/setup-wezterm-windows.ps1"
    fi
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_SCRIPT_PATH"
    exit 0
fi

echo -e "${RED}[ERROR] powershell.exe not found in PATH. Please run setup-wezterm-windows.ps1 directly inside Windows PowerShell.${NC}"
exit 1
