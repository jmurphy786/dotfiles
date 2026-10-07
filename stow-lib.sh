#!/usr/bin/env bash
# Shared stow helpers, sourced by wsl/setup.sh and omarchy/setup.sh.
#
# Packages that more than one platform uses live at the repo root. To share a
# new tool: make a root folder for it (<pkg>/.config/<pkg>/...) and add its name
# below. Platform-only packages stay in their platform folder and are stowed
# with stow_packages.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SHARED_PACKAGES=(herdr git lazygit bash)

# stow_packages <dir> <pkg>...  -- (re)stow packages that live in <dir>
stow_packages() {
    local dir=$1
    shift
    (cd "$dir" && stow --restow --target="$HOME" "$@")
}

# ensure_bashrc_hook -- append a line to ~/.bashrc that sources ~/.bashrc.shared
# (the stowed bash/.bashrc.shared). Appends only: omarchy ships its own ~/.bashrc
# and it must survive. Idempotent, so re-running setup adds nothing.
BASHRC_HOOK_MARK="# >>> dotfiles shared bashrc >>>"
ensure_bashrc_hook() {
    local rc="$HOME/.bashrc"
    touch "$rc"
    grep -qF "$BASHRC_HOOK_MARK" "$rc" && return 0
    cat >>"$rc" <<'HOOK'

# >>> dotfiles shared bashrc >>>
[ -f "$HOME/.bashrc.shared" ] && . "$HOME/.bashrc.shared"
# <<< dotfiles shared bashrc <<<
HOOK
}

# stow_shared -- stow every package in SHARED_PACKAGES and hook the shared bashrc
stow_shared() {
    stow_packages "$REPO_ROOT" "${SHARED_PACKAGES[@]}"
    ensure_bashrc_hook
}

# install_wezterm -- WezTerm on WSL runs on Windows, which stow cannot link into,
# so copy the config to the Windows home (a differing existing one is kept as
# .bak). Re-run after editing wezterm/.wezterm.lua. Elsewhere, stow it.
install_wezterm() {
    if command -v wslpath >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
        local win_home
        win_home="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
        if [ -d "$win_home" ]; then
            local src="$REPO_ROOT/wezterm/.wezterm.lua" dst="$win_home/.wezterm.lua"
            [ -f "$dst" ] && ! cmp -s "$src" "$dst" && cp "$dst" "$dst.bak"
            cp "$src" "$dst"
            echo "V copied .wezterm.lua to $win_home"
        fi
    else
        stow_packages "$REPO_ROOT" wezterm
    fi
}
