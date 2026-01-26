#!/usr/bin/env bash

## Gnome version:
#current=$(dconf read /org/gnome/desktop/peripherals/mouse/left-handed)
#if [[ "$current" == "true" ]]; then
#  dconf write /org/gnome/desktop/peripherals/mouse/left-handed false
#else
#  dconf write /org/gnome/desktop/peripherals/mouse/left-handed true
#fi

DEVICE_ID=$(xinput list | grep -i "kensington" | grep -o 'id=[0-9]*' | grep -o '[0-9]*' | head -n 1)

if [ -z $DEVICE_ID ]; then
  echo "Kensington device not found"
  exit 1
fi

# Swap left and right mouse button (1 and 3)
# Default mapping is: 1 2 3 4 5 6 7 8 9
# Swapped mapping is: 3 2 1 4 5 6 7 8 9
xinput set-button-map "$DEVICE_ID" 3 2 1 4 5 6 7 8 9

echo "Mouse buttons swapped for DEVICE ID: $DEVICE_ID" >> /tmp/mouse-swap.log

