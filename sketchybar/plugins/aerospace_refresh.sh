#!/usr/bin/env bash

# This script refreshes the aerospace workspace layout in sketchybar
# It only removes and re-adds separators, and reorders items efficiently

# Get current workspace to monitor mapping
workspace_list=$(mktemp)
aerospace list-workspaces --monitor all --format "%{workspace} %{monitor-name}" > "$workspace_list"

# Remove all existing separators
for sid in {1..9}; do
    sketchybar --remove monitor_sep_$sid 2>/dev/null
done

# Check if we have multiple monitors
monitor_count=$(aerospace list-monitors | wc -l | tr -d ' ')

if [ "$monitor_count" -gt 1 ]; then
    # Multi-monitor setup: re-add separators in the correct positions
    prev_monitor=""
    order=""

    while IFS=' ' read -r sid monitor_name; do
        # Only handle workspaces 1-9
        if [[ $sid -gt 9 ]]; then
            continue
        fi

        # Add separator between different monitors
        if [[ -n "$prev_monitor" && "$monitor_name" != "$prev_monitor" ]]; then
            # Add separator before this workspace
            sketchybar --add item "monitor_sep_${sid}" left \
                --set "monitor_sep_${sid}" \
                icon="│" \
                label.drawing=off \
                icon.color=0x80ffffff \
                icon.padding_left=4 \
                icon.padding_right=4 \
                background.drawing=off

            order="$order monitor_sep_${sid}"
        fi

        order="$order space.$sid"
        prev_monitor="$monitor_name"
    done < "$workspace_list"

    # Reorder all workspace items in one go
    # This moves items efficiently without recreating them
    if [[ -n "$order" ]]; then
        sketchybar --reorder $order 2>/dev/null
    fi
fi

rm "$workspace_list"

# Trigger a refresh of all workspace states
sketchybar --trigger aerospace_workspace_change
