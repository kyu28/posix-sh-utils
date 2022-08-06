#!/bin/sh
print2() {
  printf %s "$2"
}
print3() {
  printf %s "$3"
}
print4() {
  printf %s "$4"
}
print9() {
  printf %s "$9"
}
while true; do
  wifi=$(cat /sys/class/net/wlp2s0/operstate)
  eth=$(cat /sys/class/net/eno1/operstate)
  mem=$(free -h|grep Mem:)
  mem=$(print3 $mem)'/'$(print2 $mem)
  #system_load=$(cat /proc/loadavg)
  #disk=$(df -h /|grep /)
  #disk=$(print4 $disk)
  #battery="$(cat /sys/class/power_supply/BAT0/status) $(cat /sys/class/power_supply/BAT0/capacity)%"
  #temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))"°C"
  date=$(date +"%Y-%m-%d %H:%M")
  voldata=$(pactl list sinks| grep -B 2 -A 7 "Name: $(pactl get-default-sink)" | grep -e "Sink" -e "Volume:" -e "Mute:")
  voldevice=$(print2 $voldata)
  if [ $(print4 $voldata) = "no" ]; then
    volume=$(print9 $voldata)
  else
    volume="Muted"
  fi
  output="W: $wifi | E: $eth | Vol: $voldevice $volume | $mem | $date"
  xsetroot -name "$output"
  sleep 5
done
