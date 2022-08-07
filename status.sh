#!/bin/sh
print1() { printf %s "$1"; }
print2() { printf %s "$2"; }
print4() { printf %s "$4"; }
print8() { printf %s "$8"; }
print9() { printf %s "$9"; }
print11() { printf %s "${11}"; }
while true; do
  wifi=$(cat /sys/class/net/wlp2s0/operstate)
  eth=$(cat /sys/class/net/eno1/operstate)
  mem=$(free -h)
  mem=$(print9 $mem)'/'$(print8 $mem)
  #sys_load=$(print1 $(cat /proc/loadavg))
  #disk=$(print11 $(df -h /))
  #battery="$(cat /sys/class/power_supply/BAT0/status) $(cat /sys/class/power_supply/BAT0/capacity)%"
  #temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))"°C"
  date=$(date +"%Y-%m-%d %H:%M")
  voldata=$(pactl list sinks| grep -B 2 -A 7 "Name: $(pactl get-default-sink)")
  voldevice=$(print2 $voldata)
  if [ $(print1 ${voldata#*Mute:}) = "no" ]; then
    volume=$(print4 ${voldata#*Volume:})
  else
    volume="Muted"
  fi
  output="W: $wifi | E: $eth | Vol: $voldevice $volume | $mem | $date"
  xsetroot -name "$output"
  sleep 5
done
