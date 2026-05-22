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
