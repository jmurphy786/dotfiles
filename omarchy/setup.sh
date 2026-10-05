#!/usr/bin/env bash
# Omarchy (Arch + Hyprland) side of the herdr/kitty setup. The WSL equivalent,
# with WezTerm instead of kitty, is wsl/setup.sh.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# herdr itself: `brew install herdr` as on WSL, or put the binary in
# ~/.local/bin; the scripts look in both.
sudo pacman -S --needed --noconfirm stow kitty fzf jq neovim lazygit

if ! command -v devpod >/dev/null 2>&1; then
    curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64"
    sudo install -m 0755 devpod /usr/local/bin/devpod
    rm -f devpod
fi

# herdr config + scripts (shared with wsl/), then the kitty config
cd "$SCRIPT_DIR/.."
stow --target="$HOME" herdr
cd "$SCRIPT_DIR"
stow --target="$HOME" kitty

command -v herdr >/dev/null 2>&1 || echo "! herdr is not installed yet"
command -v herdr >/dev/null 2>&1 && herdr plugin install kaar/nvim-herdr-navigator || true
