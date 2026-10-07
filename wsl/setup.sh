#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

echo "?? Installing Homebrew packages..."
PACKAGES=(
    stow
    zoxide
    glow
    neovim
    npm
    opencode
    btop
    yazi
    starship
    luarocks
    ripgrep
    resvg
    lazydocker
    imagemagick
    fzf
    lazygit
    herdr
    jq
)
for package in "${PACKAGES[@]}"; do
    if brew list "$package" &>/dev/null; then
        echo "V $package already installed, skipping"
    else
        echo "Installing $package..."
        brew install "$package"
    fi
done

# Install DevPod CLI
curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64"
sudo mv devpod /usr/local/bin/devpod
sudo chmod +x /usr/local/bin/devpod

# Packages shared with omarchy/ live at the repo root and are listed in
# shared-setup.sh (herdr client config + host popup scripts, lazygit, git colours, the
# shared .bashrc hooked into ~/.bashrc).
# The containers get their own herdr config from devpod-brew-dotfiles.
. "$SCRIPT_DIR/../shared-setup.sh"
stow_shared

# Host-only bashrc bits (~/.bashrc.host), then WezTerm (copied to the Windows
# home; see install_wezterm in shared-setup.sh).
stow_packages "$SCRIPT_DIR" bash
install_wezterm

# herdr plugins (HERDR_PLUGINS in shared-setup.sh): nvim-aware ctrl+hjkl pane focus
# for the ctrl+hjkl keys in herdr/config.toml, plus the claude resume integration.
install_herdr_plugins
