#!/system/bin/sh
#logger
find /dev > /dev/kmsg

date=`date +%F_%H-%M-%S`
logcat -v time -f  /data/media/logcat_${date}.txt