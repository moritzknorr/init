#!/bin/bash

# This script moves the active window to the next/previous workspace and syncs both monitors
# NUM_WORKSPACES determines the number of workspaces per monitor
NUM_WORKSPACES=5  # Left monitor: 1-5, Right monitor: 6-10

if [ -z "$1" ]; then
    echo "Usage: $0 [next|prev|<workspace_number>]"
    echo "  next - Move window to next workspace and sync both monitors"
    echo "  prev - Move window to previous workspace and sync both monitors"
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

# Determine current position and paired workspace
if [ "$ACTIVE_WORKSPACE" -ge 1 ] && [ "$ACTIVE_WORKSPACE" -le "$NUM_WORKSPACES" ]; then
    # On left monitor (workspaces 1-5)
    CURRENT_MONITOR="left"
    CURRENT_POS=$ACTIVE_WORKSPACE
    PAIRED_WS=$(( ACTIVE_WORKSPACE + NUM_WORKSPACES ))
elif [ "$ACTIVE_WORKSPACE" -ge $((NUM_WORKSPACES + 1)) ] && [ "$ACTIVE_WORKSPACE" -le $((NUM_WORKSPACES * 2)) ]; then
    # On right monitor (workspaces 6-10)
    CURRENT_MONITOR="right"
    CURRENT_POS=$(( ACTIVE_WORKSPACE - NUM_WORKSPACES ))
    PAIRED_WS=$(( ACTIVE_WORKSPACE - NUM_WORKSPACES ))
else
    echo "Active workspace $ACTIVE_WORKSPACE is not in the expected range (1-$((NUM_WORKSPACES * 2)))"
    exit 1
fi

if [ "$1" == "next" ]; then
    # Don't allow next if already at the last workspace
    if [ "$CURRENT_POS" -eq "$NUM_WORKSPACES" ]; then
        echo "Already at the last workspace ($CURRENT_POS/$NUM_WORKSPACES on $CURRENT_MONITOR monitor)"
        exit 0
    fi
    TARGET_POS=$(( CURRENT_POS + 1 ))
    
    # Calculate target workspaces for both monitors
    if [ "$CURRENT_MONITOR" == "left" ]; then
        TARGET_WS=$TARGET_POS
        TARGET_PAIRED_WS=$(( TARGET_POS + NUM_WORKSPACES ))
    else
        TARGET_WS=$(( TARGET_POS + NUM_WORKSPACES ))
        TARGET_PAIRED_WS=$TARGET_POS
    fi
    
elif [ "$1" == "prev" ]; then
    # Don't allow prev if already at the first workspace
    if [ "$CURRENT_POS" -eq 1 ]; then
        echo "Already at the first workspace (1 on $CURRENT_MONITOR monitor)"
        exit 0
    fi
    TARGET_POS=$(( CURRENT_POS - 1 ))
    
    # Calculate target workspaces for both monitors
    if [ "$CURRENT_MONITOR" == "left" ]; then
        TARGET_WS=$TARGET_POS
        TARGET_PAIRED_WS=$(( TARGET_POS + NUM_WORKSPACES ))
    else
        TARGET_WS=$(( TARGET_POS + NUM_WORKSPACES ))
        TARGET_PAIRED_WS=$TARGET_POS
    fi
    
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # Move to specific workspace number (no monitor sync for direct number)
    TARGET_WS=$1
    if [ "$TARGET_WS" -lt 1 ] || [ "$TARGET_WS" -gt $((NUM_WORKSPACES * 2)) ]; then
        echo "Invalid workspace number: $TARGET_WS. Valid range: 1-$((NUM_WORKSPACES * 2))"
        exit 1
    fi
    # Move the active window to the target workspace
    hyprctl dispatch movetoworkspace "$TARGET_WS"
    # Focus the moved window
    hyprctl dispatch focuswindow "address:$ACTIVE_WINDOW"
    echo "Moved window to workspace $TARGET_WS"
    exit 0
else
    echo "Invalid argument: $1. Use 'next', 'prev', or a workspace number (1-$((NUM_WORKSPACES * 2)))."
    exit 1
fi

# Move the active window to the target workspace
hyprctl dispatch movetoworkspace "$TARGET_WS"

# Switch the other monitor to the paired workspace to keep them synchronized
hyprctl dispatch workspace "$TARGET_PAIRED_WS"

# Focus the moved window
hyprctl dispatch focuswindow "address:$ACTIVE_WINDOW"

echo "Moved window to workspace $TARGET_WS and synchronized to workspace $TARGET_PAIRED_WS"