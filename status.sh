#!/bin/sh
builtin_cat() {
  while IFS= read t; do
    printf "%s\n" "$t"
  done < $1
}
alias arr='set --'
while true; do
  wifi=$(builtin_cat /sys/class/net/wlp1s0/operstate)
#  eth=$(builtin_cat /sys/class/net/eno1/operstate)
  arr $(free -h) && mem=$9'/'$8
#  arr $(builtin_cat /proc/loadavg) && sys_load=$1
#  arr $(df -h /) && disk=${11}
  battery="$(builtin_cat /sys/class/power_supply/BAT0/status) $(builtin_cat /sys/class/power_supply/BAT0/capacity)%"
#  temp=$(($(builtin_cat /sys/class/thermal/thermal_zone0/temp) / 1000))"°C"
  date=$(date +"%Y-%m-%d %H:%M")
  voldata=$(pactl list sinks| grep -B 2 -A 7 "Name: $(pactl get-default-sink)")
  arr $voldata && voldevice=$2
  arr ${voldata#*Mute:}
  if [ "$1" = "no" ]; then
    volume=$6
  else
    volume="Muted"
  fi
  xsetroot -name "W: $wifi | $battery | Vol: $voldevice $volume | $mem | $date"
  sleep 5
done
