#!/bin/bash

/setup.sh || exit $?

# Set LAVA Master IP
if [[ -n "$LAVA_MASTER" ]]; then
	sed -i -e "s/{LAVA_MASTER}/$LAVA_MASTER/g" /etc/lava-dispatcher/lava-slave
fi

echo "LOGFILE=/var/log/lava-dispatcher/lava-slave.log" >> /etc/lava-dispatcher/lava-slave

service tftpd-hpa start || exit 4
if [ -s /etc/ser2net.yaml ];then
	service ser2net start || exit 7
fi

# start an http file server for boot/transfer_overlay support
(cd /var/lib/lava/dispatcher; python3 -m http.server 80) &

# FIXME lava-slave does not run if old pid is present
rm -f /var/run/lava-slave.pid
#service lava-slave start || exit 5
#/etc/init.d/lava-slave start

/root/entrypoint.sh

sleep 3650d
