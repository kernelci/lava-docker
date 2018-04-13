#!/bin/bash

if [ ! -e "/root/devices/$(hostname)" ];then
	echo "Static slave for $LAVA_MASTER"
	exit 0
fi

if [ -z "$LAVA_MASTER_URI" ];then
	echo "ERROR: Missing LAVA_MASTER_URI"
	exit 11
fi

echo "Dynamic slave for $LAVA_MASTER ($LAVA_MASTER_URI)"
cd /root/lavacli
LAVACLIOPTS="--uri $LAVA_MASTER_URI"

# This directory is used for storing device-types already added
mkdir -p /root/.lavadocker/
if [ -e /root/device-types ];then
	for i in $(ls /root/device-types/*jinja2)
	do
		devicetype=$(basename $i |sed 's,.jinja2,,')
		echo "Adding custom $devicetype"
		lavacli $LAVACLIOPTS device-types list || exit $?
		touch /root/.lavadocker/devicetype-$devicetype
	done
fi

for worker in $(ls /root/devices/)
do
	lavacli $LAVACLIOPTS workers list |grep -q $worker
	if [ $? -eq 0 ];then
		echo "Remains of $worker, cleaning it"
		/usr/local/bin/retire.sh $LAVA_MASTER_URI $worker
		#lavacli $LAVACLIOPTS workers update $worker || exit $?
	else
		echo "Adding worker $worker"
		lavacli $LAVACLIOPTS workers add $worker || exit $?
	fi
	if [ ! -z "$LAVA_DISPATCHER_IP" ];then
		/usr/local/bin/setdispatcherip.py $LAVA_MASTER_URI $worker $LAVA_DISPATCHER_IP
		echo "Add dispatcher_ip $LAVA_DISPATCHER_IP to $worker"
	fi
	for device in $(ls /root/devices/$worker/)
	do
		devicename=$(echo $device | sed 's,.jinja2,,')
		devicetype=$(grep -h extends /root/devices/$worker/$device| grep -o '[a-zA-Z0-9_-]*.jinja2' | sed 's,.jinja2,,')
		if [ -e /root/.lavadocker/devicetype-$devicetype ];then
			echo "Skip devicetype $devicetype"
		else
			echo "Add devicetype $devicetype"
			lavacli $LAVACLIOPTS device-types list | grep -q $devicetype
			if [ $? -eq 0 ];then
				echo "Skip devicetype $devicetype"
			else
				lavacli $LAVACLIOPTS device-types add $devicetype || exit $?
			fi
			touch /root/.lavadocker/devicetype-$devicetype
		fi
		echo "Add device $devicename on $worker"
		lavacli $LAVACLIOPTS devices list -a | grep -q $devicename
		if [ $? -eq 0 ];then
			echo "$devicename already present"
			#verify if present on another worker
			#TODO
			lavacli $LAVACLIOPTS devices show $devicename |grep ^worker |grep -q $worker
			if [ $? -ne 0 ];then
				echo "ERROR: $devicename already present on another worker"
				exit 1
			fi
			lavacli $LAVACLIOPTS devices update --worker $worker --status IDLE --health UNKNOWN $devicename || exit $?
		else
			lavacli $LAVACLIOPTS devices add --type $devicetype --worker $worker $devicename || exit $?
			lavacli $LAVACLIOPTS devices dict set $devicename /root/devices/$worker/$device || exit $?
		fi
	done
done
