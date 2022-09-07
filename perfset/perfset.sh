mode=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
if [ "$mode" = "performance" ]
then
  echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  xbacklight -dec 15
else
  echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  xbacklight -inc 15
fi
