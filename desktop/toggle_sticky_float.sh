#!/bin/bash

# Get the active window address
active_window=$(hyprctl activewindow -j | jq -r '.address')

if [ "$active_window" = "null" ] || [ -z "$active_window" ]; then
    exit 1
fi

# Check if window is currently floating
is_floating=$(hyprctl activewindow -j | jq -r '.floating')

# Make window float if it's not already floating
if [ "$is_floating" = "false" ]; then
    hyprctl dispatch togglefloating address:$active_window
fi

# Make window sticky (pin to all workspaces)
hyprctl dispatch pin address:$active_window