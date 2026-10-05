#!/usr/bin/env bash
# prefix+shift+u, or run from a terminal after booting -- bring every saved
# DevPod machine back: start its container, start its herdr server, and
# reconnect.
#
# Shutting the laptop down stops WSL, Docker and every devcontainer, and with
# them each container's herdr server. herdr's background reconnect never
# restarts a remote server, so the machines sit unreachable until something
# does. Once a server is up again it restores its own session.json: the
# workspaces, tabs and pane directories, and claude sessions where the herdr
# claude integration is installed in that container.
set -uo pipefail

case ":$PATH:" in
  *:/home/linuxbrew/.linuxbrew/bin:*) ;;
  *) PATH="/home/linuxbrew/.linuxbrew/bin:$PATH" ;;
esac
HERDR="${HERDR_BIN_PATH:-herdr}"

# herdr sits in linuxbrew where setup.sh installed it, or in ~/.local/bin
# where `herdr machine add` put it. SSH's non-login shell has neither on PATH.
REMOTE_PATH='PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"'

command -v devpod >/dev/null 2>&1 \
  || { echo "No devpod here -- run this on the host, with Local selected."; exit 1; }

# id <TAB> label <TAB> ssh target <TAB> remote session <TAB> enabled|disabled
machines=$("$HERDR" machine list 2>/dev/null | awk -F'\t' 'NF >= 5 && $5 == "enabled"')
[ -n "$machines" ] || { echo "No enabled machines."; exit 0; }

failed=0
while IFS=$'\t' read -r id label target session _status; do
  echo "== $label ($target)"
  case "$target" in
    *.devpod) ws=${target%.devpod} ;;
    *) echo "   not a DevPod host, only reconnecting"; ws= ;;
  esac

  # devpod status reports on stderr.
  if [ -n "$ws" ] && ! devpod status "$ws" 2>&1 | grep -q "'Running'"; then
    echo "   starting container"
    # --open-ide=false: bring the container up without launching VS Code.
    if ! devpod up "$ws" --open-ide=false >/dev/null 2>&1; then
      echo "   devpod up $ws failed"; failed=1; continue
    fi
  fi

  # tuicr and gh-stack run in the container and need gh auth, but herdr
  # reaches it over plain ssh, so the env-var token `dpod` sends never gets
  # here. Persist the host login once instead. The token rides ssh stdin, so
  # it stays out of argv. (No </dev/null here: stdin is the token.)
  if [ -n "$ws" ] && ! ssh -o BatchMode=yes -o ConnectTimeout=30 "$target" \
       "$REMOTE_PATH; gh auth status" >/dev/null 2>&1 </dev/null; then
    if gh auth token 2>/dev/null | ssh -o BatchMode=yes -o ConnectTimeout=30 "$target" \
         "$REMOTE_PATH; gh auth login --with-token" >/dev/null 2>&1; then
      echo "   gh authenticated"
    else
      echo "   gh auth failed (is gh installed in the container?)"
    fi
  fi

  # </dev/null on every ssh: it would otherwise swallow the rest of the
  # machine list this loop is reading.
  if ssh -o BatchMode=yes -o ConnectTimeout=30 "$target" \
       "$REMOTE_PATH; herdr --session '$session' status server" >/dev/null 2>&1 </dev/null; then
    echo "   herdr server already running"
  else
    echo "   starting herdr server"
    ssh -o BatchMode=yes -o ConnectTimeout=30 "$target" \
      "$REMOTE_PATH; setsid -f herdr --session '$session' server >/dev/null 2>&1 </dev/null" </dev/null \
      || { echo "   could not start the herdr server"; failed=1; continue; }
    sleep 2
  fi

  # Interactive when it has to be (authentication); otherwise just a check.
  if "$HERDR" machine reconnect "$id" </dev/tty; then
    echo "   connected"
  else
    echo "   reconnect failed"; failed=1
  fi
done <<<"$machines"

if [ -t 0 ] && [ -n "${HERDR_SOCKET_PATH:-}" ]; then
  # Opened as a popup: keep the summary on screen.
  printf '\n[any key to close] '; read -rsn1 _ || true; echo
fi
exit "$failed"
