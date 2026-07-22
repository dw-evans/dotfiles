#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Dotfiles Installation ===${NC}"
echo "Repository directory: ${DOTFILES_DIR}"
echo ""

# Prevent running from Windows /mnt/c/ filesystem under WSL
if [[ "$DOTFILES_DIR" == /mnt/c/* ]]; then
    echo -e "${RED}[ERROR] You are running install.sh from /mnt/c/... (Windows filesystem)!${NC}"
    echo -e "${YELLOW}Symlinks and file permissions do not work properly on Windows mounts.${NC}"
    echo -e "${YELLOW}Please clone into your Linux home directory (~) and run setup from there:${NC}"
    echo ""
    echo "  cd ~"
    echo "  git clone --recurse-submodules https://github.com/dw-evans/dotfiles.git ~/dotfiles"
    echo "  cd ~/dotfiles"
    echo "  ./install.sh"
    echo ""
    exit 1
fi

# Auto-install system packages if CLI binaries are missing
REQUIRED_PACKAGES=()

command -v tmux >/dev/null 2>&1 || REQUIRED_PACKAGES+=(tmux)
command -v unzip >/dev/null 2>&1 || REQUIRED_PACKAGES+=(unzip)
command -v rg >/dev/null 2>&1 || REQUIRED_PACKAGES+=(ripgrep)
command -v fdfind >/dev/null 2>&1 || command -v fd >/dev/null 2>&1 || REQUIRED_PACKAGES+=(fd-find)
command -v gcc >/dev/null 2>&1 || command -v make >/dev/null 2>&1 || REQUIRED_PACKAGES+=(build-essential)

if [ ${#REQUIRED_PACKAGES[@]} -ne 0 ]; then
    echo -e "${BLUE}Installing missing packages (${REQUIRED_PACKAGES[*]})...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "${REQUIRED_PACKAGES[@]}"
    else
        echo -e "${RED}[ERROR] Could not auto-install ${REQUIRED_PACKAGES[*]}. Please install them manually.${NC}"
        exit 1
    fi
    echo ""
fi

# Helper to check required tools
check_tool() {
    local tool="$1"
    if ! command -v "$tool" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Export PATH for current script execution
export PATH="$HOME/.local/share/bob/nvim-bin:$HOME/.local/bin:$PATH"

# Ensure PATH exports are added to shell config files (~/.bashrc and ~/.zshrc)
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] || [ "$rc" = "$HOME/.bashrc" ]; then
        touch "$rc"
        if ! grep -qs 'bob/nvim-bin' "$rc"; then
            echo -e '\n# Bob & Neovim PATH\nexport PATH="$HOME/.local/share/bob/nvim-bin:$HOME/.local/bin:$PATH"' >> "$rc"
            echo -e "${GREEN}Added Bob & Neovim PATH to $rc${NC}"
        fi
    fi
done

# Ensure git submodules are initialized and updated
if [ -d "$DOTFILES_DIR/.git" ] || [ -f "$DOTFILES_DIR/.git" ]; then
    echo -e "${BLUE}Initializing and updating submodules...${NC}"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
    echo ""
fi

# Ensure bob & Neovim 0.11.7 are installed
echo -e "${BLUE}Checking Neovim installation via bob...${NC}"
if ! check_tool bob; then
    echo -e "${YELLOW}Installing bob (Neovim version manager)...${NC}"
    curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
fi

echo -e "${BLUE}Setting Neovim version to 0.11.7...${NC}"
"$HOME/.local/bin/bob" use 0.11.7

echo -e "${GREEN}Current Neovim version:${NC}"
nvim --version | head -n 3
echo ""

# Ensure Tmux Plugin Manager (TPM) is installed
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "${BLUE}Installing Tmux Plugin Manager (TPM)...${NC}"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    if [ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
        echo -e "${BLUE}Installing Tmux plugins (Catppuccin, etc.)...${NC}"
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    fi
fi

# Helper function to create symlinks safely
link_file() {
    local src="$1"
    local target="$2"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        local current_link
        current_link="$(readlink "$target")"
        if [ "$current_link" = "$src" ]; then
            echo -e "  [${GREEN}EXISTS${NC}] $target -> $src"
            return 0
        else
            echo -e "  [${YELLOW}UPDATE${NC}] Updating symlink for $target"
            rm -f "$target"
        fi
    elif [ -e "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        echo -e "  [${YELLOW}BACKUP${NC}] Moving existing file/dir $target to $backup"
        mv "$target" "$backup"
    fi

    ln -sfn "$src" "$target"
    echo -e "  [${GREEN}LINKED${NC}] $target -> $src"
}

echo -e "${BLUE}Linking configuration files...${NC}"

# Git
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Tmux
link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# Neovim
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Lazygit
link_file "$DOTFILES_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

# WezTerm (Linux location)
link_file "$DOTFILES_DIR/wezterm/wezterm.lua" "$HOME/.wezterm.lua"

# WezTerm (Windows WSL location if present)
if [ -d "/mnt/c/Users" ]; then
    for win_user_dir in /mnt/c/Users/*; do
        win_user="$(basename "$win_user_dir")"
        case "$win_user" in
            Public|Default|Default\ User|desktop.ini|All\ Users) continue ;;
            *)
                if [ -d "$win_user_dir" ]; then
                    echo -e "${BLUE}Syncing WezTerm config to Windows user ($win_user)...${NC}"
                    cp "$DOTFILES_DIR/wezterm/wezterm.lua" "$win_user_dir/.wezterm.lua"
                fi
                ;;
        esac
    done
fi

echo ""
echo -e "${GREEN}=== Setup complete! ===${NC}"
