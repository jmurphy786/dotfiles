#!/usr/bin/env bash
# Behind the WezTerm keys in .wezterm.lua (Windows side).
#
#   herdr-notes.sh notes          ctrl+shift+n: in the host's default herdr (the
#                                 Local machine), a notes workspace created or
#                                 focused with nvim open on
#                                 ~/obsidian-vault/main.md, then attach as the
#                                 `local` tab does. If its tab already has nvim
#                                 running in the vault it is left as is; a
#                                 shell prompt is sent to the vault to start
#                                 nvim; anything else running there gets a new
#                                 tab instead.
#   herdr-notes.sh ensure         same, without attaching; WezTerm runs it in
#                                 the background when the local tab is open
#   herdr-notes.sh remote <ssh>   ctrl+shift+1..3: attach straight to a DevPod
#                                 machine's server
#   herdr-notes.sh local          ctrl+shift+4: attach to this host's own herdr
#                                 (the default session, the Local machine),
#                                 knowing no other machine to snap to, on its
#                                 "linux" workspace (focused, or created)
#   herdr-notes.sh ensure-local   same, without attaching; WezTerm runs it in
#                                 the background when the local tab is open
#
# Notes share the default server with the main herdr window, so focusing the
# notes workspace also moves that window's Local focus: clients of one server
# share it.
#
# The client keeps its saved machines and the selected one in
# ~/.local/state/herdr/client/, shared by every client on the host, so a
# second tab opened from a machine snapped back to it once it connected,
# whatever the session. A separate XDG_STATE_HOME gives these clients no saved
# machines to switch to. A separate session alone did not help. The normal
# multi-machine herdr (ctrl+shift+r) keeps the shared state.
#
# --remote-keybindings server: by default `herdr --remote` uses this host's
# keybindings and does not send local [[keys.command]] entries, so the
# plugin_action keys (ctrl+h/j/k/l navigator, prefix+w worktree menu, gh stack)
# were bound to nothing in these tabs. `server` uses the container's own keys,
# the same ones the multi-machine herdr gets.
set -euo pipefail

export XDG_STATE_HOME="$HOME/.local/state-notes"
mkdir -p "$XDG_STATE_HOME"

case ":$PATH:" in
  *:/home/linuxbrew/.linuxbrew/bin:*) ;;
  *) PATH="/home/linuxbrew/.linuxbrew/bin:$PATH" ;;
esac
HERDR="${HERDR_BIN_PATH:-herdr}"
LABEL=notes
VAULT="$HOME/obsidian-vault"
# ~/obsidian-vault is a symlink into /mnt/c, and herdr reports resolved paths.
VAULT_REAL=$(readlink -f "$VAULT")

# Run from inside a herdr pane, the inherited HERDR_* variables would point
# every call at that pane's server.
unset HERDR_SOCKET_PATH HERDR_SESSION HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID

h() { "$HERDR" "$@"; }

mode="${1:-notes}"

if [ "$mode" = remote ]; then
  [ -n "${2:-}" ] || { echo "usage: $0 remote <ssh-target>" >&2; exit 1; }
  exec "$HERDR" --remote "$2" --remote-keybindings server
fi

if [ "$mode" = local ] || [ "$mode" = ensure-local ]; then
  # The default session. The HERDR_* variables are unset above, so this is the
  # host's own server, and the separate XDG_STATE_HOME leaves it no saved
  # machines to switch to. Focus its "linux" workspace, creating it if missing.
  lid=$(h workspace list \
    | jq -r '.result.workspaces[]? | select(.label == "linux") | .workspace_id' | head -n1)
  if [ -n "$lid" ]; then
    h workspace focus "$lid" >/dev/null
  else
    h workspace create --label linux --cwd "$HOME" --focus >/dev/null
  fi
  [ "$mode" = ensure-local ] && exit 0
  exec "$HERDR"
fi

case "$mode" in
  notes | ensure) ;;
  *) echo "usage: $0 [notes|ensure|local|ensure-local|remote <ssh-target>]" >&2; exit 1 ;;
esac

notes_id() {
  h workspace list \
    | jq -r --arg l "$LABEL" '.result.workspaces[]? | select(.label == $l) | .workspace_id' \
    | head -n1
}

# Is pane $1 an nvim/vim running inside the vault?
in_vault_nvim() {
  h pane process-info --pane "$1" 2>/dev/null \
    | jq -e --arg v "$VAULT_REAL" '
        [.result.process_info.foreground_processes[]?
          | select((.name // "") | test("^g?(n?vim?|vimdiff)$"))
          | select((.cwd // "") | startswith($v))] | length > 0' >/dev/null 2>&1
}

# Is pane $1 at a shell prompt? A fresh pane's shell is still sourcing ~/.bashrc
# (bash, bash, ps, ... as foreground), and one with nothing reported yet counts
# too, so give it a couple of seconds to settle before calling it busy.
at_shell() {
  local names i
  for i in $(seq 10); do
    names=$(h pane process-info --pane "$1" 2>/dev/null \
      | jq -r '.result.process_info.foreground_processes[]?.name' 2>/dev/null) || true
    if [ -z "$names" ] || ! grep -qvE '^-?(bash|sh|dash|zsh|fish)$' <<<"$names"; then
      return 0
    fi
    sleep 0.2
  done
  return 1
}

# Put nvim on the vault in workspace $1's visible tab, unless it is already
# there. A shell prompt is sent to the vault to start nvim; anything else
# running in the pane (claude, nvim somewhere else) is left alone and a new
# tab gets the nvim instead.
open_vault_nvim() {
  local id="$1" tab panes pane first before
  tab=$(h workspace list \
    | jq -r --arg w "$id" '.result.workspaces[] | select(.workspace_id == $w) | .active_tab_id')
  panes=$(h pane list \
    | jq -r --arg t "$tab" '.result.panes[] | select(.tab_id == $t) | .pane_id')
  for pane in $panes; do
    in_vault_nvim "$pane" && return 0
  done
  first=$(head -n1 <<<"$panes")
  if [ -n "$first" ] && at_shell "$first"; then
    h pane run "$first" "cd $(printf '%q' "$VAULT") && nvim main.md" >/dev/null
    return 0
  fi
  before=$(h pane list | jq -r '.result.panes[].pane_id')
  h tab create --workspace "$id" --cwd "$VAULT" --focus >/dev/null
  pane=$(h pane list | jq -r '.result.panes[].pane_id' | grep -vxF "$before" | head -n1 || true)
  [ -n "$pane" ] && h pane run "$pane" nvim main.md >/dev/null
  return 0
}

id=$(notes_id)
if [ -n "$id" ]; then
  h workspace focus "$id" >/dev/null
else
  h workspace create --label "$LABEL" --cwd "$VAULT" --focus >/dev/null
  id=$(notes_id)
fi
open_vault_nvim "$id"

[ "$mode" = ensure ] && exit 0
exec "$HERDR"
