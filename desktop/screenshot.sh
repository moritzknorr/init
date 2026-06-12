#!/bin/sh
FILE_NAME=screenshot_$(date +'%Y%m%d-%H%M%S').png
TEMP_FILE_PATH=/tmp/$FILE_NAME
OUTPUT_FILE_PATH="$HOME/Pictures/Screenshots/$FILE_NAME"
mkdir -p "$HOME/Pictures/Screenshots"
hyprshot -s -z -m region --filename "$FILE_NAME" --output-folder /tmp && \
sleep 0.5 && \
satty -f "$TEMP_FILE_PATH" --output-filename "$OUTPUT_FILE_PATH" && \
rm "$TEMP_FILE_PATH"
