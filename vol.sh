#!/bin/sh
vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep 'Volume:' | head -n $(( $SINK + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
if [ $@ = "up" ]; then
  vol=$[ $vol + 10 ]
  if [ $vol -le 100 ]; then
    pactl set-sink-volume @DEFAULT_SINK@ +10%
  fi
elif [ $@ = "down" ]; then
  pactl set-sink-volume @DEFAULT_SINK@ -10%
else
  pactl set-sink-mute @DEFAULT_SINK@ toggle
fi

kill $(ps --no-headers -C status.sh | awk '{print $1}')
exec status.sh
