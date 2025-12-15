#!/usr/bin/env bash

# This script refreshes the aerospace workspace layout in sketchybar
# It groups workspaces by monitor and adds separators between different monitors

# Get workspace to monitor mapping
workspace_list=$(mktemp)
aerospace list-workspaces --monitor all --format "%{workspace} %{monitor-name}" > "$workspace_list"

# Get monitor list in order
monitor_list=$(mktemp)
aerospace list-monitors --format "%{monitor-name}" > "$monitor_list"

# Remove all existing separators
for sid in {0..9}; do
    sketchybar --remove monitor_sep_$sid 2>/dev/null
done

# Check if we have multiple monitors
monitor_count=$(wc -l < "$monitor_list" | tr -d ' ')

if [ "$monitor_count" -gt 1 ]; then
    order=""
    first_monitor=true
    first_item=true

    # Iterate through monitors in order
    while IFS= read -r monitor_name; do
        # Find all workspaces (0-9) for this monitor and sort them
        workspaces=$(grep -F "$monitor_name" "$workspace_list" | awk '{print $1}' | grep -E '^[0-9]$' | sort -n)

        if [ -z "$workspaces" ]; then
            continue
        fi

        # Add separator before this monitor's workspaces (except for first monitor)
        if [ "$first_monitor" = false ]; then
            # Use the first workspace ID of this monitor for the separator name
            first_ws=$(echo "$workspaces" | head -1)
            sketchybar --add item "monitor_sep_${first_ws}" left \
                --set "monitor_sep_${first_ws}" \
                icon="│" \
                label.drawing=off \
                icon.color=0x80ffffff \
                icon.padding_left=4 \
                icon.padding_right=4 \
                background.drawing=off

            order="${order} monitor_sep_${first_ws}"
        fi

        # Add all workspaces for this monitor
        for ws in $workspaces; do
            if [ "$first_item" = true ]; then
                order="space.$ws"
                first_item=false
            else
                order="${order} space.$ws"
            fi
        done

        first_monitor=false
    done < "$monitor_list"

    # Reorder all workspace items in one go
    if [[ -n "$order" ]]; then
        sketchybar --reorder $order 2>/dev/null
    fi
fi

rm "$workspace_list" "$monitor_list"

# Trigger a refresh of all workspace states
sketchybar --trigger aerospace_workspace_change
