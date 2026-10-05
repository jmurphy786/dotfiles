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

# herdr client config and the host popup scripts (devpod-add, devpod-manage,
# herdr-up). The containers get their own herdr config from
# devpod-brew-dotfiles.
cd "$SCRIPT_DIR"
stow --target="$HOME" herdr

# nvim-aware ctrl+hjkl pane focus for Local workspaces. The plugin the
# ctrl+hjkl keys in herdr/config.toml run; it comes from GitHub, not this repo.
herdr plugin install kaar/nvim-herdr-navigator || true
