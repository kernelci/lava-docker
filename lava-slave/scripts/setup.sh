#!/bin/bash

if [ ! -e "/root/devices/$(hostname)" ];then
	echo "Static slave for $LAVA_MASTER"
	exit 0
fi

if [ -z "$LAVA_MASTER_URI" ];then
	echo "ERROR: Missing LAVA_MASTER_URI"
	exit 11
fi

# Install PXE
OPWD=$(pwd)
cd /var/lib/lava/dispatcher/tmp && grub-mknetdir --net-directory=.
cp /root/grub.cfg /var/lib/lava/dispatcher/tmp/boot/grub/
cd $OPWD

lavacli identities add --uri $LAVA_MASTER_BASEURI --token $LAVA_MASTER_TOKEN --username $LAVA_MASTER_USER default

echo "Dynamic slave for $LAVA_MASTER ($LAVA_MASTER_URI)"
LAVACLIOPTS="--uri $LAVA_MASTER_URI"

# do a sort of ping for letting master to be up
TIMEOUT=1200
while [ $TIMEOUT -ge 1 ];
do
	STEP=2
	lavacli $LAVACLIOPTS device-types list >/dev/null
	if [ $? -eq 0 ];then
		TIMEOUT=0
	else
		echo "Wait for master.... (${TIMEOUT}s remains)"
		sleep $STEP
	fi
	TIMEOUT=$(($TIMEOUT-$STEP))
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

lavacli $LAVACLIOPTS device-types list > /tmp/device-types.list
if [ $? -ne 0 ];then
	echo "ERROR: fail to list device-types"
	exit 1
fi
lavacli $LAVACLIOPTS devices list -a > /tmp/devices.list
if [ $? -ne 0 ];then
	echo "ERROR: fail to list devices"
	exit 1
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
		# does we ran 2020.09+ and worker need a token
	fi
	grep -q "TOKEN" /root/entrypoint.sh
	if [ $? -eq 0 ];then
		# This is 2020.09+
		echo "DEBUG: Worker need a TOKEN"
		if [ -z "$LAVA_WORKER_TOKEN" ];then
			echo "DEBUG: get token dynamicly"
			# Does not work on 2020.09, since token was not added yet in RPC2
			WTOKEN=$(getworkertoken.py $LAVA_MASTER_URI $worker)
			if [ $? -ne 0 ];then
				echo "ERROR: cannot get WORKER TOKEN"
				exit 1
			fi
			if [ -z "$WTOKEN" ];then
				echo "ERROR: got an empty token"
				exit 1
			fi
		else
			echo "DEBUG: got token from env"
			WTOKEN=$LAVA_WORKER_TOKEN
		fi
		echo "DEBUG: write token in /var/lib/lava/dispatcher/worker/"
		mkdir -p /var/lib/lava/dispatcher/worker/
		echo "$WTOKEN" > /var/lib/lava/dispatcher/worker/token
		# lava worker ran under root
		chown root:root /var/lib/lava/dispatcher/worker/token
		chmod 640 /var/lib/lava/dispatcher/worker/token
		sed -i "s,.*TOKEN.*,TOKEN=\"--token-file /var/lib/lava/dispatcher/worker/token\"," /etc/lava-dispatcher/lava-worker || exit $?

		echo "DEBUG: set master URL to $LAVA_MASTER_URL"
		sed -i "s,^# URL.*,URL=\"$LAVA_MASTER_URL\"," /etc/lava-dispatcher/lava-worker || exit $?
		cat /etc/lava-dispatcher/lava-worker
	else
		echo "DEBUG: Worker does not need a TOKEN"
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
			grep -q "$devicetype[[:space:]]" /tmp/device-types.list
			if [ $? -eq 0 ];then
				echo "Skip devicetype $devicetype"
			else
				lavacli $LAVACLIOPTS device-types add $devicetype || exit $?
			fi
			touch /root/.lavadocker/devicetype-$devicetype
		fi
		DEVICE_OPTS=""
		if [ -e /root/deviceinfo/$devicename ];then
			echo "Found customization for $devicename"
			. /root/deviceinfo/$devicename
			if [ ! -z "$DEVICE_USER" ];then
				echo "DEBUG: give $devicename to $DEVICE_USER"
				DEVICE_OPTS="$DEVICE_OPTS --user $DEVICE_USER"
			fi
			if [ ! -z "$DEVICE_GROUP" ];then
				echo "DEBUG: give $devicename to group $DEVICE_GROUP"
				DEVICE_OPTS="$DEVICE_OPTS --group $DEVICE_GROUP"
			fi
		fi
		echo "Add device $devicename on $worker"
		grep -q "$devicename[[:space:]]" /tmp/devices.list
		if [ $? -eq 0 ];then
			echo "$devicename already present"
			#verify if present on another worker
			lavacli $LAVACLIOPTS devices show $devicename |grep ^worker > /tmp/current-worker
			if [ $? -ne 0 ]; then
				CURR_WORKER=""
			else
				CURR_WORKER=$(cat /tmp/current-worker | sed '^.* ,,')
			fi
			if [ ! -z "$CURR_WORKER" -a "$CURR_WORKER" != "$worker" ];then
				echo "ERROR: $devicename already present on another worker $CURR_WORKER"
				exit 1
			fi
			DEVICE_HEALTH=$(grep "$devicename[[:space:]]" /tmp/devices.list | sed 's/.*,//')
			case "$DEVICE_HEALTH" in
			Retired)
				echo "DEBUG: Keep $devicename state: $DEVICE_HEALTH"
				DEVICE_HEALTH='RETIRED'
			;;
			Maintenance)
				echo "DEBUG: Keep $devicename state: $DEVICE_HEALTH"
				DEVICE_HEALTH='MAINTENANCE'
			;;
			*)
				echo "DEBUG: Set $devicename state to UNKNOWN (from $DEVICE_HEALTH)"
				DEVICE_HEALTH='UNKNOWN'
			;;
			esac
			lavacli $LAVACLIOPTS devices update --worker $worker --health $DEVICE_HEALTH $DEVICE_OPTS $devicename || exit $?
			# always reset the device dict in case of update of it
			lavacli $LAVACLIOPTS devices dict set $devicename /root/devices/$worker/$device || exit $?
		else
			lavacli $LAVACLIOPTS devices add --type $devicetype --worker $worker $DEVICE_OPTS $devicename || exit $?
			lavacli $LAVACLIOPTS devices dict set $devicename /root/devices/$worker/$device || exit $?
		fi
		if [ -e /root/tags/$devicename ];then
			while read tag
			do
				echo "DEBUG: Add tag $tag to $devicename"
				lavacli $LAVACLIOPTS devices tags add $devicename $tag || exit $?
			done < /root/tags/$devicename
		fi
	done
done

for devicetype in $(ls /root/aliases/)
do
	lavacli $LAVACLIOPTS device-types aliases list $devicetype > /tmp/device-types-aliases-$devicetype.list
	while read alias
	do
		grep -q " $alias$" /tmp/device-types-aliases-$devicetype.list
		if [ $? -eq 0 ];then
			echo "DEBUG: $alias for $devicetype already present"
			continue
		fi
		echo "DEBUG: Add alias $alias to $devicetype"
		lavacli $LAVACLIOPTS device-types aliases add $devicetype $alias || exit $?
		echo " $alias" >> /tmp/device-types-aliases-$devicetype.list
	done < /root/aliases/$devicetype
done

exit 0
