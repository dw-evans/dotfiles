# dotfiles

## Quick Start (Linux / WSL)

```bash
sudo apt update && sudo apt install -y git curl
cd ~
git clone --recurse-submodules https://github.com/dw-evans/dotfiles.git
cd dotfiles
./install.sh
```

## Windows Setup (WezTerm)

To automatically download WezTerm and link `wezterm.lua` on Windows:

**Using PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File .\setup-wezterm-windows.ps1
```

**Or using Command Prompt / Double-Click:**
Run `setup-wezterm-windows.bat`

**Or from WSL / Git Bash:**
```bash
./setup-wezterm-windows.sh
```

## Downloading JetBrains Mono Nerd Font

WezTerm is configured to use `JetBrainsMono Nerd Font`. The font script downloads `JetBrainsMono.zip` (v3.4.0) to your `Downloads` directory and extracts it, flashing the exact location for manual installation:

**On Linux / WSL:**
```bash
./install-font.sh
```

**On Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .\install-font.ps1
```
*(Or double-click `install-font.bat` on Windows)*



