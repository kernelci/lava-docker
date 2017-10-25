#!/bin/bash
# Set LAVA Master IP
if [[ -n "$LAVA_MASTER" ]]; then
	sed -i -e "s/{LAVA_MASTER}/$LAVA_MASTER/g" /etc/lava-dispatcher/lava-slave
fi

service tftpd-hpa start || exit 4

# FIXME lava-slave does not run if old pid is present
rm -f /var/run/lava-slave.pid
service lava-slave start || exit 5

if [ -e /etc/lavapdu ];then
	/etc/init.d/postgresql start || exit 6

	echo "== Start lavapdu listen =="
	/etc/init.d/lavapdu-listen start || exit 7
	# lava listen create the database, let it some time
	sleep 5
	echo "== Start lavapdu runner =="
	/etc/init.d/lavapdu-runner start || exit 8
fi

touch /var/run/conmux-registry
/usr/sbin/conmux-registry 63000 /var/run/conmux-registry&
sleep 2
for item in $(ls /etc/conmux/*cf)
do
	echo "Add $item"
	/usr/sbin/conmux $item &
done

# start an http file server for boot/transfer_overlay support
(cd /var/lib/lava/dispatcher; python -m SimpleHTTPServer 80)
