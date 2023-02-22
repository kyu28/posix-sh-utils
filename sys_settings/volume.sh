#!/bin/sh
if [ "$1" = "up" ]; then
  set -- $(pactl get-sink-volume @DEFAULT_SINK@)
  vol=$((${5%'%'} + 10))
  if [ $vol -le 100 ]; then
    pactl set-sink-volume @DEFAULT_SINK@ +10%
  fi
elif [ "$1" = "down" ]; then
  pactl set-sink-volume @DEFAULT_SINK@ -10%
else
  pactl set-sink-mute @DEFAULT_SINK@ toggle
fi

psdata=$(ps -A -o comm -o pid)
set -- ${psdata#*'status.sh'} # refresh status.sh
kill $1
exec status.sh
