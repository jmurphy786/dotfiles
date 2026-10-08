#!/usr/bin/env bash
# Omarchy (Arch + Hyprland) side of the herdr/kitty setup. The WSL equivalent,
# with WezTerm instead of kitty, is wsl/setup.sh.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# herdr itself: `brew install herdr` as on WSL, or put the binary in
# ~/.local/bin; the scripts look in both.
sudo pacman -S --needed --noconfirm stow fzf jq neovim lazygit wezterm starship ttf-jetbrains-mono-nerd zoxide tuicr yazi ripgrep

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
stow_packages "$SCRIPT_DIR" hypr 

install_herdr_plugins
