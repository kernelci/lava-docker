#!/bin/bash

LAVA_MASTER_URI=$1

if [ -z "$LAVA_MASTER_URI" ];then
	echo "retire.sh: remove an offline worker"
	echo "Usage: $0 LAVA_MASTER_URI"
	echo "ERROR: Missing LAVA_MASTER_URI"
	exit 11
fi

LAVACLIOPTS="--uri $LAVA_MASTER_URI"

retire_worker() {
	worker=$1
	lavacli $LAVACLIOPTS workers list |grep -q $worker
	if [ $? -eq 0 ];then
		echo "Removing $worker"
		lavacli $LAVACLIOPTS workers update $worker || exit $?
	else
		echo "SKIP: worker $worker does not exists"
		return 0
	fi
	lavacli $LAVACLIOPTS devices list -a | grep '^\*' | cut -d' ' -f2 |
	while read devicename
	do
		lavacli $LAVACLIOPTS devices show $devicename |grep -q "^worker.*$worker$"
		if [ $? -eq 0 ];then
			echo "Retire $devicename"
			lavacli $LAVACLIOPTS devices update --health RETIRED --worker $worker $devicename || exit $?
		fi
	done
	return 0
}

if [ -z "$2" ];then
	for ww in $(ls devices/)
	do
		retire_worker $ww
	done
else
	retire_worker $2
fi
