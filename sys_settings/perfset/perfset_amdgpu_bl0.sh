#!/bin/bash
mode=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
brightness=$(cat /sys/class/backlight/amdgpu_bl0/brightness)
echo $brightness
if [ "$mode" = "performance" ]
then
  echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  brightness=$((brightness-25))
  if [ $brightness -lt 0 ]
  then
    brightness=0
  fi
  echo $brightness
  echo $brightness > /sys/class/backlight/amdgpu_bl0/brightness
else
  echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  brightness=$((brightness+25))
  if [ $brightness -gt 255 ]
  then
    brightness=255
  fi
  echo $brightness
  echo $brightness > /sys/class/backlight/amdgpu_bl0/brightness
fi
