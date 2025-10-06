#!/bin/bash
current=$(dconf read /org/gnome/desktop/peripherals/mouse/left-handed)
if [[ "$current" == "true" ]]; then
  dconf write /org/gnome/desktop/peripherals/mouse/left-handed false
else
  dconf write /org/gnome/desktop/peripherals/mouse/left-handed true
fi
