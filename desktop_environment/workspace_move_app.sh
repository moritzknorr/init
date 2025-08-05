#!/bin/bash

# This script moves the active window to the next/previous workspace pair
# NUM_WORKSPACES determines the number of pairs: 1=2 workspaces, 3=6 workspaces, 5=10 workspaces, etc.
NUM_WORKSPACES=5  # Change this to configure number of workspace pairs

if [ $((NUM_WORKSPACES % 2)) -eq 0 ]; then
    echo "Error: NUM_WORKSPACES must be odd (represents number of pairs)"
    echo "Current value: $NUM_WORKSPACES"
    echo "Valid values: 1 (2 workspaces), 3 (6 workspaces), 5 (10 workspaces), etc."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 [next|prev|<workspace_number>]"
    echo "  next - Move window to next workspace pair"
    echo "  prev - Move window to previous workspace pair"
    echo "  <number> - Move window to specific workspace (1-$((NUM_WORKSPACES * 2)))"
    exit 1
fi

# Get the currently active window
ACTIVE_WINDOW=$(hyprctl activewindow -j | jq -r ".address")
if [ "$ACTIVE_WINDOW" == "null" ] || [ -z "$ACTIVE_WINDOW" ]; then
    echo "No active window found"
    exit 1
fi

# Get current workspace
ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j | jq -r ".id")

# Determine the current pair (1-NUM_WORKSPACES)
if [ "$ACTIVE_WORKSPACE" -ge 1 ] && [ "$ACTIVE_WORKSPACE" -le "$NUM_WORKSPACES" ]; then
    CURRENT_PAIR=$ACTIVE_WORKSPACE
elif [ "$ACTIVE_WORKSPACE" -ge $((NUM_WORKSPACES + 1)) ] && [ "$ACTIVE_WORKSPACE" -le $((NUM_WORKSPACES * 2)) ]; then
    CURRENT_PAIR=$(( ACTIVE_WORKSPACE - NUM_WORKSPACES ))
else
    echo "Active workspace $ACTIVE_WORKSPACE is not in the expected range (1-$((NUM_WORKSPACES * 2)))"
    exit 1
fi

if [ "$1" == "next" ]; then
    # Don't allow next if already at the last pair
    if [ "$CURRENT_PAIR" -eq "$NUM_WORKSPACES" ]; then
        echo "Already at the last workspace pair ($NUM_WORKSPACES/$((NUM_WORKSPACES * 2)))"
        exit 0
    fi
    TARGET_PAIR=$(( CURRENT_PAIR + 1 ))
    
    # Move to the corresponding workspace on the same monitor
    if [ "$ACTIVE_WORKSPACE" -le "$NUM_WORKSPACES" ]; then
        TARGET_WS=$TARGET_PAIR
    else
        TARGET_WS=$(( TARGET_PAIR + NUM_WORKSPACES ))
    fi
    
elif [ "$1" == "prev" ]; then
    # Don't allow prev if already at the first pair
    if [ "$CURRENT_PAIR" -eq 1 ]; then
        echo "Already at the first workspace pair (1/$((NUM_WORKSPACES + 1)))"
        exit 0
    fi
    TARGET_PAIR=$(( CURRENT_PAIR - 1 ))
    
    # Move to the corresponding workspace on the same monitor
    if [ "$ACTIVE_WORKSPACE" -le "$NUM_WORKSPACES" ]; then
        TARGET_WS=$TARGET_PAIR
    else
        TARGET_WS=$(( TARGET_PAIR + NUM_WORKSPACES ))
    fi
    
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # Move to specific workspace number
    TARGET_WS=$1
    if [ "$TARGET_WS" -lt 1 ] || [ "$TARGET_WS" -gt $((NUM_WORKSPACES * 2)) ]; then
        echo "Invalid workspace number: $TARGET_WS. Valid range: 1-$((NUM_WORKSPACES * 2))"
        exit 1
    fi
else
    echo "Invalid argument: $1. Use 'next', 'prev', or a workspace number (1-$((NUM_WORKSPACES * 2)))."
    exit 1
fi

# Move the active window to the target workspace
hyprctl dispatch movetoworkspace "$TARGET_WS"

echo "Moved window to workspace $TARGET_WS"