# Packages

## From pacman repo
- xbindkeys
- xorg-xev

## For audio manimupation:
- pamixer

## From https://aur.archlinux.org
- xvkbd

Clone repository then cd into the cloned repo folder and
run:
```sh
makepkg -si
```

To figure out what button is what run:
```sh
xev | grep ', button'
```
The result should be something similar to this:

```sh
# Sample result for kensington mouse left button:
state 0x200, button 2, same_screen YES
# Sample result for kensington mouse right button:
state 0x0, button 8, same_screen YES
```
(This will be handled by the playbook script)
From there we need to create a file at home directory called
~/**.xbidkeysrc**

This is a sample of the content:
```
#
"pamixer --unmute --increase 3"
b:2
"pamixer --unmute --decrease 3"
b:8

```

## Reload Config
1. Kill the app
```
killall -s1 xbindkeys
```
2. Load again
```
xbindkeys -f ~/.xbindkeysrc
```

