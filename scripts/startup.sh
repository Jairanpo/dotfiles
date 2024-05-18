#!/bin/bash

# Get root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

xrandr --output HDMI-1 --scale .8x.8
xbindkeys

sudo virsh pool-destroy default 2> /dev/null
sudo virsh pool-undefine default 2> /dev/null

sudo virsh pool-create-as --name default --type dir --target ~/virtual_images

rescuetime &
blueman-manager &
redshift -l "21.12908:-101.67374" &


# List of websites to block
BLOCKED_SITES=(
    "www.youtube.com"
)


# Loop through blocked sites and add them to hosts file
for site in "${BLOCKED_SITES[@]}"; do
    if grep -q $site /etc/hosts; then
        echo "$site is already blocked."
    else
        echo "Blocking $site..."
        echo "127.0.0.1 $site" >> /etc/hosts
    fi
done

echo "All sites have been blocked."
