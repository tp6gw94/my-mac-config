#!/bin/bash
set -eu

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SELF=$DIR/$(basename -- "$0")
REX=$(command -v rex)
FZF=$(command -v fzf)
TAB=$(printf '\t')

list() {
  "$REX" do "$DIR/list.lua" mode="$1" block="$2" filter="${3:-all}"
}

capture() {
  "$REX" capture -s "$1" -b "$2" --trim --format=vt | tail -n 40
}

reload() {
  local mode=$1 filter=$2 origin=$3 prompt=Agents
  if [ "$mode" = tabs ]; then
    prompt=Tabs
  elif [ "$filter" != all ]; then
    prompt="Agents:$filter"
  fi

  printf "reload-sync(%s list %s '%s' %s)+change-prompt(%s )" "$SELF" "$mode" "$origin" "$filter" "$prompt"
}

toggle() {
  local origin=${1:-}
  case "${FZF_PROMPT%% *}" in
    Tabs) reload agents all "$origin" ;;
    *) reload tabs all "$origin" ;;
  esac
}

filter_state() {
  local origin=${1:-}
  case "$FZF_PROMPT" in
    'Agents ') reload agents attention "$origin" ;;
    'Agents:attention ') reload agents working "$origin" ;;
    'Agents:working ') reload agents idle "$origin" ;;
    'Agents:idle ') reload agents all "$origin" ;;
  esac
}

await_key() {
  printf '\n%s Press any key to close.\n' "$1"
  read -rsn1 < /dev/tty || true
}

focus() {
  "$REX" do "$DIR/focus.lua" session="$1" window="$2" block="$3" kind="$4" || await_key "Jump failed."
}

pick() {
  local origin=${1:-} rows selected
  if ! rows=$(list agents "$origin"); then
    await_key "List failed."
    exit 1
  fi

  selected=$(printf '%s' "$rows" | "$FZF" \
    --delimiter "$TAB" \
    --with-nth 5.. \
    --ansi \
    --prompt 'Agents ' \
    --header 'enter focus · ctrl-space jump · ctrl-t switch · ctrl-s filter · esc close' \
    --preview "$SELF capture {1} {3}" \
    --preview-window 'down,50%,wrap' \
    --bind 'ctrl-space:jump,jump:accept' \
    --bind "ctrl-t:transform:$SELF toggle $origin" \
    --bind "ctrl-s:transform:$SELF filter_state $origin") || exit 0

  IFS=$TAB read -r session window target kind _ <<< "$selected"
  focus "$session" "$window" "$target" "$kind"
}

case "${1:-}" in
  list|capture|toggle|filter_state)
    verb=$1
    shift
    "$verb" "$@"
    ;;
  *) pick "${1:-}" ;;
esac
