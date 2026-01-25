#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

NEW_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \)) | shuf -n 1)

if [ -n "$NEW_WALLPAPER" ]; then
  feh --bg-fill "$NEW_WALLPAPER"
fi

