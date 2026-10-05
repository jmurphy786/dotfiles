# shellcheck shell=bash
# Shared by the herdr scripts in this directory; source it, don't run it:
#   . "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib.sh"
# readlink -f so it still finds this file when the script was reached through
# a stow symlink.
#
# Nothing here assumes WSL, Linuxbrew or a particular terminal: it only puts
# whatever install locations exist on PATH and says what is missing.

# Where herdr, fzf, jq, devpod... may live. Listed lowest priority first, since
# each existing directory is prepended: Linuxbrew ends up ahead of ~/.local/bin,
# as it did before.
for _d in "$HOME/.local/bin" /opt/homebrew/bin "$HOME/.linuxbrew/bin" /home/linuxbrew/.linuxbrew/bin; do
  [ -d "$_d" ] || continue
  case ":$PATH:" in
    *":$_d:"*) ;;
    *) PATH="$_d:$PATH" ;;
  esac
done
unset _d
export PATH

HERDR="${HERDR_BIN_PATH:-herdr}"

# PATH for commands run over ssh: a non-login shell has none of the above, and
# which of them holds herdr on the remote is not known from here.
# shellcheck disable=SC2016  # expanded by the remote shell, not this one
HERDR_REMOTE_PATH='PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$HOME/.linuxbrew/bin:/opt/homebrew/bin:$PATH"'

# need <binary>...: succeed if all are on PATH; otherwise list every missing
# one on stderr and fail. "herdr" means $HERDR.
need() {
  local b missing=()
  for b in "$@"; do
    [ "$b" = herdr ] && b="$HERDR"
    command -v "$b" >/dev/null 2>&1 || missing+=("$b")
  done
  [ ${#missing[@]} -eq 0 ] && return 0
  printf 'missing: %s\n' "${missing[*]}" >&2
  echo "install with your package manager (brew install / pacman -S), then retry." >&2
  return 1
}

# Print the obsidian vault directory: $OBSIDIAN_VAULT if set, else the usual
# places. Fails (printing nothing) when there is none. -d follows symlinks, so
# the WSL link into /mnt/c counts.
find_vault() {
  local c
  for c in "${OBSIDIAN_VAULT:-}" "$HOME/obsidian-vault" "$HOME/Documents/obsidian-vault"; do
    [ -n "$c" ] && [ -d "$c" ] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

# For the popup scripts (run via [[keys.command]] popups): keep the message on
# screen until a key is pressed, otherwise the popup closes with it unread.
hold() {
  [ -n "${1:-}" ] && printf '%s\n' "$1"
  printf '\n[any key to close] '
  read -rsn1 _ 2>/dev/null || true
  echo
}
die() { printf '%s\n' "$*" >&2; hold ""; exit 1; }
