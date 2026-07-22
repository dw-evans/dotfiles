#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Dotfiles Installation ===${NC}"
echo "Repository directory: ${DOTFILES_DIR}"
echo ""

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

# WezTerm
link_file "$DOTFILES_DIR/wezterm/wezterm.lua" "$HOME/.wezterm.lua"

echo ""
echo -e "${GREEN}=== Setup complete! ===${NC}"
