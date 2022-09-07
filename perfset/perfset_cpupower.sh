mode=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
if [ "$mode" = "performance" ]
then
	sudo cpupower frequency-set -g powersave
	xbacklight -dec 15
else
	sudo cpupower frequency-set -g performance
	xbacklight -inc 15
fi
