#!/bin/bash

xbindkeys

xrandr --output HDMI-1 --scale 0.5x0.5

sudo virsh pool-destroy default 2> /dev/null
sudo virsh pool-undefine default 2> /dev/null

sudo virsh pool-create-as --name default --type dir --target ~/virtual_images

# Define and start libvirt networks for Vagrant
sudo virsh net-define /etc/libvirt/qemu/networks/vagrant-libvirt.xml 2> /dev/null
sudo virsh net-start vagrant-libvirt 2> /dev/null
sudo virsh net-autostart vagrant-libvirt 2> /dev/null

blueman-manager &
i3-msg reload &
