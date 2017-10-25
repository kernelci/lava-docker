#!/bin/bash

if [ -e /root/lava-users ];then
	for ut in $(ls /root/lava-users)
	do
		# User is the filename
		USER=$ut
		. /root/lava-users/$ut
		if [ -z "$PASSWORD" -o "$PASSWORD" = "$TOKEN" ];then
			echo "Generating password..."
			#Could be very long, should be avoided
			PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		fi
		echo "Adding username $USER DEBUG(with $TOKEN / $PASSWORD)"
		lava-server manage users add --passwd $PASSWORD $USER || exit 1
		if [ ! -z "$TOKEN" ];then
			lava-server manage tokens add --user $USER --secret $TOKEN || exit 1
		fi
	done
fi

if [ -e /root/lava-callback-tokens ];then
	for ct in $(ls /root/lava-callback-tokens)
	do
		. /root/lava-callback-tokens/$ct
		if [ -z "$USER" ];then
			echo "Missing USER"
			exit 1
		fi
		if [ -z "$TOKEN" ];then
			echo "Missing TOKEN for $USER"
			exit 1
		fi
		if [ -z "$DESCRIPTION" ];then
			echo "Missing DESCRIPTION for $USER"
			exit 1
		fi
		echo "Adding $USER ($DESCRIPTION) DEBUG($TOKEN)"
		lava-server manage tokens add --user $USER --secret $TOKEN --description $DESCRIPTION || exit 1
	done
fi

# This directory is used for storing device-types already added
mkdir -p /root/.lavadocker/
if [ -e /root/device-types ];then
	for i in $(ls /root/device-types/*yaml)
	do
		cp /root/device-types/$i /etc/lava-server/dispatcher-config/device-types/
		devicetype=$(basename $i)
		lava-server manage device-types add $devicetype || exit 1
		touch /root/.lavadocker/devicetype-$devicetype
	done
fi

for worker in $(ls /root/devices/)
do
	echo "Adding worker $worker"
	lava-server manage workers add $worker || exit $?
	for device in $(ls /root/devices/$worker/)
	do
		devicename=$(echo $device | sed 's,.jinja2,,')
		devicetype=$(grep -h extends /root/devices/$worker/$device| grep -o '[a-zA-Z0-9_-]*.jinja2' | sed 's,.jinja2,,')
		if [ -e /root/.lavadocker/devicetype-$devicetype ];then
			echo "Skip devicetype $devicetype"
		else
			echo "Add devicetype $devicetype"
			lava-server manage device-types add $devicetype || exit $?
			touch /root/.lavadocker/devicetype-$devicetype
		fi
		echo "Add device $devicename on $worker"
		cp /root/devices/$worker/$device /etc/lava-server/dispatcher-config/devices/ || exit $?
		lava-server manage devices add --device-type $devicetype --worker $worker $devicename || exit $?
	done
done
