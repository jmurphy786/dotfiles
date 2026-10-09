#!/usr/bin/env bash
# Setup helpers shared by wsl/setup.sh and omarchy/setup.sh: stowing, the shared
# bashrc hook, WezTerm, and herdr plugins.
#
# Packages that more than one platform uses live at the repo root. To share a
# new tool: make a root folder for it (<pkg>/.config/<pkg>/...) and add its name
# below. Platform-only packages stay in their platform folder and are stowed
# with stow_packages.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SHARED_PACKAGES=(herdr git lazygit bash nvim wezterm)

# stow_packages <dir> <pkg>...  -- (re)stow packages that live in <dir>.
# Any existing file on the system that would conflict is renamed to <file>.bak first.
stow_packages() {
    local dir=$1
    shift
    local pkg f rel target
    for pkg in "$@"; do
        while IFS= read -r -d '' f; do
            rel="${f#"$dir/$pkg/"}"
            target="$HOME/$rel"
            # nothing there, or already pointing at our file (including via a folded dir): fine
            [ -e "$target" ] || [ -L "$target" ] || continue
            [ "$(readlink -f "$target")" = "$(readlink -f "$f")" ] && continue
            mv --backup=numbered "$target" "$target.bak"
            echo "! backed up $target -> $target.bak"
        done < <(find "$dir/$pkg" \( -type f -o -type l \) -print0)
    done
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

# GitHub herdr plugins every host wants. Add an owner/repo here to install it
# from both wsl/setup.sh and omarchy/setup.sh.
HERDR_PLUGINS=(kaar/nvim-herdr-navigator)

# install_herdr_plugins -- link the local portals-bootstrap plugin, install
# HERDR_PLUGINS and the claude integration (lets herdr resume claude sessions).
# Skips quietly if herdr is not installed.
install_herdr_plugins() {
    # the herdr installer may drop the binary in ~/.local/bin before it's on PATH
    if ! command -v herdr >/dev/null 2>&1 && [ -x "$HOME/.local/bin/herdr" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
    if ! command -v herdr >/dev/null 2>&1; then
        echo "! herdr is not installed yet, skipping plugins"
        return 0
    fi
    echo "Registering herdr plugins..."
    # Linked, not installed, so edits in the repo apply live.
    local local_plugin="$HOME/.config/herdr/local-plugins/portals-bootstrap"
    [ -d "$local_plugin" ] && { herdr plugin link "$local_plugin" </dev/null || true; }
    # The list above is the trust decision, so always confirm. </dev/null keeps
    # herdr (or a server it spawns) from holding the session's stdin open.
    local p
    for p in "${HERDR_PLUGINS[@]}"; do
        herdr plugin install --yes "$p" </dev/null || true
    done
    herdr integration install claude </dev/null || true
}
