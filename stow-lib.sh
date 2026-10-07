#!/usr/bin/env bash
# Shared stow helpers, sourced by wsl/setup.sh and omarchy/setup.sh.
#
# Packages that more than one platform uses live at the repo root. To share a
# new tool: make a root folder for it (<pkg>/.config/<pkg>/...) and add its name
# below. Platform-only packages stay in their platform folder and are stowed
# with stow_packages.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SHARED_PACKAGES=(herdr git lazygit)

# stow_packages <dir> <pkg>...  -- (re)stow packages that live in <dir>
stow_packages() {
    local dir=$1
    shift
    (cd "$dir" && stow --restow --target="$HOME" "$@")
}

# stow_shared -- stow every package in SHARED_PACKAGES
stow_shared() {
    stow_packages "$REPO_ROOT" "${SHARED_PACKAGES[@]}"
}
