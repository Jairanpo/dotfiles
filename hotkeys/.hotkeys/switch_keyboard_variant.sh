#!/usr/bin/bash

layout="us"
variant=$(setxkbmap -query | grep "variant" | awk '{print $2}')

if [ -z "$variant" ]; then
  echo "no variant"
  setxkbmap -layout $layout -variant intl
else
  echo "$variant"
  setxkbmap -layout us
fi
