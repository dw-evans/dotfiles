#!/usr/bin/env bash

set -e

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}=== JetBrains Mono Nerd Font Downloader ===${NC}"
echo "Source URL: ${FONT_URL}"
echo ""

# Ensure curl or wget is available
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget -q -O"
else
    echo -e "${RED}[ERROR] Neither curl nor wget was found.${NC}"
    exit 1
fi

# Determine target Downloads folders
DOWNLOADS_LOCATIONS=()

# 1. Linux Downloads folder
LINUX_DOWNLOADS="$HOME/Downloads"
mkdir -p "$LINUX_DOWNLOADS"
DOWNLOADS_LOCATIONS+=("$LINUX_DOWNLOADS")

# 2. Windows Downloads folder if under WSL
if [ -d "/mnt/c/Users" ]; then
    for win_user_dir in /mnt/c/Users/*; do
        win_user="$(basename "$win_user_dir")"
        case "$win_user" in
            Public|Default|Default\ User|desktop.ini|All\ Users) continue ;;
            *)
                if [ -d "$win_user_dir/Downloads" ]; then
                    DOWNLOADS_LOCATIONS+=("$win_user_dir/Downloads")
                fi
                ;;
        esac
    done
fi

# Download to each identified Downloads directory
for downloads_dir in "${DOWNLOADS_LOCATIONS[@]}"; do
    target_zip="$downloads_dir/JetBrainsMono.zip"
    target_dir="$downloads_dir/JetBrainsMono"
    
    echo -e "${BLUE}Downloading to: ${target_zip}${NC}"
    if [ "$DOWNLOAD_CMD" = "curl -fsSL" ]; then
        curl -fsSL "$FONT_URL" -o "$target_zip"
    else
        wget -q "$FONT_URL" -O "$target_zip"
    fi
    
    if command -v unzip >/dev/null 2>&1; then
        echo -e "${BLUE}Extracting to: ${target_dir}${NC}"
        mkdir -p "$target_dir"
        unzip -q -o "$target_zip" -d "$target_dir"
    fi

    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}${BOLD}[LOCATION FLASH] Font successfully downloaded to:${NC}"
    echo -e "  ZIP Archive : ${YELLOW}${target_zip}${NC}"
    if [ -d "$target_dir" ]; then
        echo -e "  Extracted   : ${YELLOW}${target_dir}${NC}"
    fi
    echo -e "${GREEN}================================================================${NC}"
    echo ""

    # Open extracted folder in File Explorer / File Manager
    if [ -d "$target_dir" ]; then
        if command -v explorer.exe >/dev/null 2>&1; then
            echo -e "${BLUE}Opening folder in Windows File Explorer...${NC}"
            if command -v wslpath >/dev/null 2>&1; then
                WIN_PATH="$(wslpath -w "$target_dir")"
                explorer.exe "$WIN_PATH" 2>/dev/null || true
            else
                explorer.exe "$target_dir" 2>/dev/null || true
            fi
        elif command -v xdg-open >/dev/null 2>&1; then
            echo -e "${BLUE}Opening folder in file manager...${NC}"
            xdg-open "$target_dir" 2>/dev/null || true
        fi
    fi
done

echo -e "${BLUE}Instructions to install manually:${NC}"
echo "  • Windows: Select font files (.ttf), right-click and select 'Install' or 'Install for all users'."
echo "  • Linux: Copy .ttf files to ~/.local/share/fonts/ and run 'fc-cache -fv'."
echo ""
