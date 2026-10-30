#!/bin/bash
set -eu

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SELF=$DIR/$(basename -- "$0")
REX=$(command -v rex)
FZF=$(command -v fzf)
TAB=$(printf '\t')

list() {
  "$REX" --timeout 3s do "$DIR/list.lua" mode="$1" block="$2" filter="${3:-all}" hosts="${4:-off}"
}

capture() {
  local host_args=
  case "${3:-local}" in
    remote:*) host_args="-S ${3#remote:}" ;;
  esac

  "$REX" $host_args capture -s "$1" -b "$2" --trim --format=vt | tail -n 40
}

read_state() {
  local prompt=${FZF_PROMPT% } hosts=off mode=agents filter=all
  case "$prompt" in
    *' +hosts') hosts=on; prompt=${prompt% +hosts} ;;
  esac
  case "$prompt" in
    Tabs) mode=tabs ;;
    Panes) mode=panes ;;
    Agents:*) filter=${prompt#Agents:} ;;
  esac
  printf '%s %s %s\n' "$mode" "$hosts" "$filter"
}

prompt_for() {
  local mode=$1 filter=$2 hosts=$3 prompt=Agents
  case "$mode" in
    tabs) prompt=Tabs ;;
    panes) prompt=Panes ;;
    *) [ "$filter" = all ] || prompt="Agents:$filter" ;;
  esac
  if [ "$hosts" = on ]; then
    prompt="$prompt +hosts"
  fi
  printf '%s' "$prompt"
}

reload() {
  local mode=$1 filter=$2 hosts=$3 origin=$4
  printf "reload-sync(%s list %s '%s' %s %s)+change-prompt(%s )" "$SELF" "$mode" "$origin" "$filter" "$hosts" "$(prompt_for "$mode" "$filter" "$hosts")"
}

toggle() {
  local origin=${1:-} mode hosts _
  read -r mode hosts _ <<< "$(read_state)"
  case "$mode" in
    agents) reload tabs all "$hosts" "$origin" ;;
    tabs) reload panes all "$hosts" "$origin" ;;
    panes) reload agents all "$hosts" "$origin" ;;
  esac
}

filter_state() {
  local origin=${1:-} mode hosts filter
  read -r mode hosts filter <<< "$(read_state)"
  [ "$mode" = agents ] || return 0
  case "$filter" in
    all) reload agents attention "$hosts" "$origin" ;;
    attention) reload agents working "$hosts" "$origin" ;;
    working) reload agents idle "$hosts" "$origin" ;;
    idle) reload agents all "$hosts" "$origin" ;;
  esac
}

toggle_hosts() {
  local origin=${1:-} mode hosts filter next=on
  read -r mode hosts filter <<< "$(read_state)"
  if [ "$hosts" = on ]; then
    next=off
  fi
  reload "$mode" "$filter" "$next" "$origin"
}

await_key() {
  printf '\n%s Press any key to close.\n' "$1"
  read -rsn1 < /dev/tty || true
}

focus() {
  "$REX" do "$DIR/focus.lua" session="$1" window="$2" block="$3" kind="$4" route="$5" || await_key "Jump failed."
}

pick() {
  local mode=$1 origin=${2:-} rows selected
  if ! rows=$(list "$mode" "$origin"); then
    await_key "List failed."
    exit 1
  fi

  selected=$(printf '%s' "$rows" | "$FZF" \
    --delimiter "$TAB" \
    --with-nth 6.. \
    --ansi \
    --prompt "$(prompt_for "$mode" all off) " \
    --header-lines 1 \
    --preview "$SELF capture {1} {3} {5}" \
    --preview-window 'down,50%,wrap' \
    --bind 'ctrl-space:jump,jump:accept' \
    --bind "ctrl-t:transform:$SELF toggle $origin" \
    --bind "ctrl-s:transform:$SELF filter_state $origin" \
    --bind "ctrl-/:transform:$SELF toggle_hosts $origin") || exit 0

  IFS=$TAB read -r session window target kind route _ <<< "$selected"
  focus "$session" "$window" "$target" "$kind" "$route"
}

case "${1:-}" in
  list|capture|toggle|filter_state|toggle_hosts)
    verb=$1
    shift
    "$verb" "$@"
    ;;
  *) pick "${1:-agents}" "${2:-}" ;;
esac
