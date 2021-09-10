#!/bin/sh

mkdir /mnt/sdcard
mount /dev/mmcblk0p1 /mnt/sdcard
DATALOGGER=/mnt/sdcard/$(date +'%s')
ping -c 4 -I eth0 10.30.30.1 > $DATALOGGER
dmesg >> $DATALOGGER
sync
umount /dev/mmcblk0p1


set -x

if [ ! -e /data/fcount ]; then
	echo 0 > /data/fcount
fi

count=$(cat /data/fcount)
count=$(expr ${count} + 1)
echo ${count} > /data/fcount

if dmesg | grep -q 'MDIO device at address 0 is missing'; then
	echo "PHY not detected, idling forever..."
	rm -f /data/fcount
	tail -f /dev/null
fi

if [ "${count}" -gt 101 ]; then
	echo "Completed reboot test"
	rm -f /data/fcount
	exit 0
fi

echo "Reboot count ${count}...rebooting in 2 seconds"
sleep 2

result=1
while [ "${result}" -ne 0 ]; do
	curl -X POST --header "Content-Type:application/json" "$BALENA_SUPERVISOR_ADDRESS/v1/reboot?apikey=$BALENA_SUPERVISOR_API_KEY"
	result=$?
	sleep 20
done
while true; do echo "Waiting for reboot.."; sleep 5; done
