#!/bin/sh
printn() {
  eval printf %s \$$1
}
while true; do
  wifi=$(cat /sys/class/net/wlp2s0/operstate)
  eth=$(cat /sys/class/net/eno1/operstate)
  mem=$(free -h|grep Mem)
  mem=$(printn 4 $mem)'/'$(printn 3 $mem)
  #system_load=$(cat /proc/loadavg)
  #disk=$(df -h| awk '{ if ($6 == "/") print $4}')
  #battery="$(cat /sys/class/power_supply/BAT0/status) $(cat /sys/class/power_supply/BAT0/capacity)%"
  #temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))"°C"
  date=$(date +"%Y-%m-%d %H:%M")
  voldata=$(pactl list sinks| grep -B 2 -A 7 "Name: $(pactl get-default-sink)" | grep -e "Sink" -e "Volume:" -e "Mute:")
  voldevice=$(printn 3 $voldata)
  if [ $(printn 5 $voldata) = "no" ]; then
    volume=$(printn 9 ${voldata#* })
  else
    volume="Muted"
  fi
  output="W: $wifi | E: $eth | Vol: $voldevice $volume | $mem | $date"
  xsetroot -name "$output"
  sleep 5
done
