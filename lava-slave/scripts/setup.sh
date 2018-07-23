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

# do a sort of ping for letting master to be up
TIMEOUT=30
while [ $TIMEOUT -ge 1 ];
do
	lavacli $LAVACLIOPTS device-types list 2>/dev/null >/dev/null
	if [ $? -eq 0 ];then
		TIMEOUT=0
	else
		echo "Wait for master...."
		sleep 2	
	fi
	TIMEOUT=$(($TIMEOUT-1))
done

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
		lavacli $LAVACLIOPTS workers add --description "LAVA dispatcher on $(cat /root/phyhostname)" $worker || exit $?
	fi
	if [ ! -z "$LAVA_DISPATCHER_IP" ];then
		echo "Add dispatcher_ip $LAVA_DISPATCHER_IP to $worker"
		/usr/local/bin/setdispatcherip.py $LAVA_MASTER_URI $worker $LAVA_DISPATCHER_IP || exit $?
	fi
	for device in $(ls /root/devices/$worker/)
	do
		devicename=$(echo $device | sed 's,.jinja2,,')
		devicetype=$(grep -h extends /root/devices/$worker/$device| grep -o '[a-zA-Z0-9_-]*.jinja2' | sed 's,.jinja2,,')
		if [ -e /root/.lavadocker/devicetype-$devicetype ];then
			echo "Skip devicetype $devicetype"
		else
			echo "Add devicetype $devicetype"
			lavacli $LAVACLIOPTS device-types list | grep -q "$devicetype[[:space:]]"
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
			lavacli $LAVACLIOPTS devices update --worker $worker --health UNKNOWN $devicename || exit $?
			# always reset the device dict in case of update of it
			lavacli $LAVACLIOPTS devices dict set $devicename /root/devices/$worker/$device || exit $?
		else
			lavacli $LAVACLIOPTS devices add --type $devicetype --worker $worker $devicename || exit $?
			lavacli $LAVACLIOPTS devices dict set $devicename /root/devices/$worker/$device || exit $?
		fi
	done
done

if [ -e /etc/lava-dispatcher/certificates.d/$(hostname).key ];then
	echo "INFO: Enabling encryption"
	sed -i 's,.*ENCRYPT=.*,ENCRYPT="--encrypt",' /etc/lava-dispatcher/lava-slave
	sed -i "s,.*SLAVE_CERT=.*,SLAVE_CERT=\"--slave-cert /etc/lava-dispatcher/certificates.d/$(hostname).key_secret\"," /etc/lava-dispatcher/lava-slave
	sed -i "s,.*MASTER_CERT=.*,MASTER_CERT=\"--master-cert /etc/lava-dispatcher/certificates.d/$LAVA_MASTER.key\"," /etc/lava-dispatcher/lava-slave
fi
exit 0
