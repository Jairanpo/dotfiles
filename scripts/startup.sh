#!/bin/bash

xbindkeys

xrandr --output HDMI-A-1 --scale 0.5x0.5

sudo virsh pool-destroy default 2> /dev/null
sudo virsh pool-undefine default 2> /dev/null

sudo virsh pool-create-as --name default --type dir --target ~/virtual_images

blueman-manager &
