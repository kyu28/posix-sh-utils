#!/bin/sh
DEVICE="/sys/class/backlight/amdgpu_bl0/brightness"
MAX=255
brightness=$(cat $DEVICE)
if [ $1 = "up" ]; then
  brightness=$(($brightness * 2 + 1))
  if [ $brightness -gt $MAX ]; then
    brightness=$MAX
  fi
else
  brightness=$((($brightness + 1) / 2))
fi
echo $brightness > $DEVICE
