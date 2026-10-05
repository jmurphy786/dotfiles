#!/usr/bin/env bash
# herdr-tab.sh [-e <ensure-cmd>] <title> <command...>
#
# kitty's counterpart of goto_tab() in .wezterm.lua: focus the tab titled
# <title>, or open it running <command> (then drop to a shell when it exits).
# With -e, <ensure-cmd> is also run in the background when the tab already
# exists, so the key never waits on herdr.
#
# <command> may name the scripts next to this one without a path
# (herdr-notes.sh remote x). Needs kitty's remote control, which kitty.conf
# turns on, and KITTY_LISTEN_ON, which kitty sets in what it launches.
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib.sh"
SELF_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

ensure=
if [ "${1:-}" = -e ]; then
  ensure="${2:-}"
  shift 2 || true
fi
[ $# -ge 2 ] || { echo "usage: $0 [-e <ensure-cmd>] <title> <command...>" >&2; exit 1; }
title="$1"
shift
cmd="$*"

need kitten || exit 1
[ -n "${KITTY_LISTEN_ON:-}" ] \
  || { echo "herdr-tab: not started from kitty (no KITTY_LISTEN_ON); see listen_on in kitty.conf" >&2; exit 1; }

# The title was fixed with --tab-title when the tab was made, so herdr
# changing the terminal title cannot make the match miss.
if kitten @ focus-tab --match "title:^${title}\$" >/dev/null 2>&1; then
  if [ -n "$ensure" ]; then
    # Detached: the login shell's own PATH is fixed up inside, as below.
    setsid -f bash -lc "PATH=\"$SELF_DIR:\$PATH\"; $ensure" >/dev/null 2>&1 </dev/null
  fi
  exit 0
fi

exec kitten @ launch --type=tab --tab-title "$title" \
  bash -lc "PATH=\"$SELF_DIR:\$PATH\"; $cmd; exec bash -l"
