#!/bin/sh
brightness=$(cat /sys/class/backlight/amdgpu_bl0/brightness)
if [ $@ = "up" ]; then
  brightness=$(($brightness * 2 + 1))
  if [ $brightness -gt 255 ]; then
    brightness=255
  fi
else
  brightness=$((($brightness + 1) / 2))
fi
echo $brightness > /sys/class/backlight/amdgpu_bl0/brightness
