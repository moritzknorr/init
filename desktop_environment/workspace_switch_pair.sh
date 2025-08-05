#!/bin/bash

NUM_WORKSPACES=5  # Change this to configure number of workspace pairs

if [ $((NUM_WORKSPACES % 2)) -eq 0 ]; then
    echo "Error: NUM_WORKSPACES must be odd (represents number of pairs)"
    echo "Current value: $NUM_WORKSPACES"
    echo "Valid values: 1 (2 workspaces), 3 (6 workspaces), 5 (10 workspaces), etc."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 [next|prev]"
    exit 1
fi

ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j | jq -r ".id")

if [ "$ACTIVE_WORKSPACE" -ge 1 ] && [ "$ACTIVE_WORKSPACE" -le "$NUM_WORKSPACES" ]; then
    CURRENT_PAIR=$ACTIVE_WORKSPACE
elif [ "$ACTIVE_WORKSPACE" -ge $((NUM_WORKSPACES + 1)) ] && [ "$ACTIVE_WORKSPACE" -le $((NUM_WORKSPACES * 2)) ]; then
    CURRENT_PAIR=$(( ACTIVE_WORKSPACE - NUM_WORKSPACES ))
else
    echo "Active workspace $ACTIVE_WORKSPACE is not in the expected range (1-$((NUM_WORKSPACES * 2)))"
    exit 1
fi

if [ "$1" == "next" ]; then
    if [ "$CURRENT_PAIR" -eq "$NUM_WORKSPACES" ]; then
        echo "Already at the last workspace pair ($NUM_WORKSPACES/$((NUM_WORKSPACES * 2)))"
        exit 0
    fi
    TARGET_PAIR=$(( CURRENT_PAIR + 1 ))
elif [ "$1" == "prev" ]; then
    if [ "$CURRENT_PAIR" -eq 1 ]; then
        echo "Already at the first workspace pair (1/$((NUM_WORKSPACES + 1)))"
        exit 0
    fi
    TARGET_PAIR=$(( CURRENT_PAIR - 1 ))
else
    echo "Invalid argument: $1. Use 'next' or 'prev'."
    exit 1
fi

TARGET_WS_1=$TARGET_PAIR
TARGET_WS_2=$(( TARGET_PAIR + NUM_WORKSPACES ))

hyprctl --batch "dispatch workspace $TARGET_WS_1; dispatch workspace $TARGET_WS_2"