#!/usr/bin/env bash
# Omarchy (Arch + Hyprland) side of the herdr/kitty setup. The WSL equivalent,
# with WezTerm instead of kitty, is wsl/setup.sh.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# herdr itself: `brew install herdr` as on WSL, or put the binary in
# ~/.local/bin; the scripts look in both.
sudo pacman -S --needed --noconfirm stow fzf jq neovim lazygit wezterm starship ttf-jetbrains-mono-nerd zoxide tuicr yazi ripgrep obsidian docker docker-compose github-cli android-udev

# Needed for android
sudo udevadm control --reload-rules && sudo udevadm trigger

# Enable Docker at boot and start it immediately.
sudo systemctl enable --now docker.service

# Let this user talk to the Docker socket without sudo (devpod needs it).
# Group membership only applies to new login sessions, so the first run
# needs a re-login (or `newgrp docker` in the current shell).
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    sudo usermod -aG docker "$USER"
    echo "Added $USER to the docker group. Log out and back in for it to take effect."
fi

curl -fsSL https://herdr.dev/install.sh | sh
if ! command -v devpod >/dev/null 2>&1; then
    curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64"
    sudo install -m 0755 devpod /usr/local/bin/devpod
    rm -f devpod
fi

# Shared packages (listed in shared-setup.sh; the shared bashrc is appended to the
# distro ~/.bashrc, not replacing it), then the kitty config
. "$SCRIPT_DIR/../shared-setup.sh"
stow_shared
stow_packages "$SCRIPT_DIR" hypr noctalia

install_herdr_plugins
