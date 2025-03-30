#!/bin/bash

xbindkeys

sudo virsh pool-destroy default 2> /dev/null
sudo virsh pool-undefine default 2> /dev/null

sudo virsh pool-create-as --name default --type dir --target ~/virtual_images

rescuetime &
blueman-manager &
