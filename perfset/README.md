# perfset.sh
Automatic toggle performance mode and powersave mode in a shell script file
******
**(cpupower version only) *cpupower* must be installed first, *xbacklight* is also needed for visual feedback but not necessary.**

This shell script file can automatically detect the scaling governor that CPU is using now and change it from performance to powersave or powersave to performance.

When switching to performance, the backlight will be turned up a bit (won't if *xbacklight* isn't installed).

When switching to powersave, the backlight will be turned down a bit (won't if *xbacklight* isn't installed).

******
# Usage
1.Make the script executable first by `chmod 755 ./perfset.sh`.

2.Change your *sudoers* file and add `%user ALL = (root)NOPASSWD:/usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor` at the end of the file in order to make the governor can be changed without password.

2(for cpupower version).Change your *sudoers* file and add `%user ALL = (root)NOPASSWD:/usr/bin/cpupower` at the end of the file in order to make the governor can be changed without password.

3.Execute it directly in a terminal, such as `./perfset.sh` or `bash perfset.sh` or `source perfset.sh`.


Tips:Binding a shortcut key such as Fn+Q with the script may make it works like the performance key that Lenovo provided in Windows.
